-- Estudio 3.14 / esquema inicial v0.1 (Supabase PostgreSQL)
-- Aplicar en un proyecto Supabase propio, NO se ejecuta al subir a GitHub.
-- Datos de demostración NO migran desde localStorage.
begin;

create extension if not exists pgcrypto;

create type public.membership_category as enum ('asociado','titular','distinguido','originario','formacion');
create type public.subscription_mode as enum ('plataforma','integral');
create type public.application_status as enum ('pendiente','aprobada','rechazada');
create type public.order_status as enum ('solicitada','en_revision','en_proceso','entregada','cancelada');
create type public.credit_movement_type as enum ('asignacion','compra','reserva','devolucion','ajuste');

create table public.member_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 2 and 120),
  category public.membership_category not null default 'asociado',
  member_since date not null default current_date,
  subscription public.subscription_mode not null default 'plataforma',
  is_verified boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
-- Nunca insertar administradores desde el frontend; provisión manual desde el panel seguro.

create table public.promotion_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references public.member_profiles(user_id),
  requested_category public.membership_category not null check (requested_category in ('titular','distinguido')),
  status public.application_status not null default 'pendiente',
  submitted_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users(id),
  decision_reason text,
  unique (id, applicant_id)
);
create unique index promotion_one_pending_per_member on public.promotion_applications(applicant_id) where status='pendiente';

create table public.promotion_endorsements (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.promotion_applications(id) on delete restrict,
  originario_id uuid not null references public.member_profiles(user_id),
  rationale text not null check (char_length(trim(rationale)) between 10 and 1500),
  endorsed_at timestamptz not null default now(),
  unique (application_id, originario_id)
);
create table public.promotion_audit (
  id bigint generated always as identity primary key,
  application_id uuid not null references public.promotion_applications(id),
  actor_id uuid not null references auth.users(id),
  event_type text not null check (event_type in ('solicitud','aval','aprobacion','rechazo')),
  details jsonb not null default '{}'::jsonb,
  happened_at timestamptz not null default now()
);

create table public.service_catalog (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text not null,
  scope jsonb not null default '{}'::jsonb,
  credit_cost integer not null check (credit_cost >= 0),
  active boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.service_orders (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.member_profiles(user_id),
  service_id uuid not null references public.service_catalog(id),
  status public.order_status not null default 'solicitada',
  requirements jsonb not null default '{}'::jsonb,
  credits_reserved integer not null check (credits_reserved >= 0),
  created_at timestamptz not null default now()
);
create table public.credit_movements (
  id bigint generated always as identity primary key,
  member_id uuid not null references public.member_profiles(user_id),
  movement_type public.credit_movement_type not null,
  amount integer not null check (amount <> 0),
  note text,
  service_order_id uuid references public.service_orders(id),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);
create index on public.credit_movements(member_id, created_at desc);
create index on public.service_orders(member_id, created_at desc);
create index on public.promotion_applications(applicant_id, submitted_at desc);

create function public.is_platform_admin(p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.platform_admins a where a.user_id=p_user) $$;

create function public.is_active_originario(p_user uuid) returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.member_profiles m
where m.user_id=p_user and m.category='originario' and m.active and m.is_verified) $$;

create function public.request_promotion(p_category public.membership_category) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare p public.member_profiles%rowtype; v_id uuid; v_months integer;
begin
 if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
 select * into p from public.member_profiles where user_id=auth.uid() for update;
 if not found or not p.is_verified or not p.active then raise exception 'Membresía no habilitada'; end if;
 if p_category not in ('titular','distinguido') then raise exception 'Categoría no postulable'; end if;
 if p_category='titular' and p.category<>'asociado' then raise exception 'La categoría de origen debe ser Asociado'; end if;
 if p_category='distinguido' and p.category<>'titular' then raise exception 'La categoría de origen debe ser Titular'; end if;
 v_months := (extract(year from age(current_date,p.member_since))::integer*12)
             + extract(month from age(current_date,p.member_since))::integer;
 if v_months < (case when p_category='titular' then 12 else 24 end) then
   raise exception 'Antigüedad insuficiente';
 end if;
 insert into public.promotion_applications(applicant_id,requested_category)
 values(auth.uid(),p_category) returning id into v_id;
 insert into public.promotion_audit(application_id,actor_id,event_type)
 values(v_id,auth.uid(),'solicitud');
 return v_id;
end; $$;

create function public.endorse_promotion(p_application uuid,p_reason text) returns void
language plpgsql security definer set search_path = ''
as $$
declare p public.promotion_applications%rowtype;
begin
 if not public.is_active_originario(auth.uid()) then raise exception 'Solo Originarios verificados pueden avalar'; end if;
 if char_length(trim(coalesce(p_reason,''))) < 10 then raise exception 'Fundamento insuficiente'; end if;
 select * into p from public.promotion_applications where id=p_application for update;
 if not found or p.status<>'pendiente' then raise exception 'Postulación no pendiente'; end if;
 if p.applicant_id=auth.uid() then raise exception 'No se admite autoaval'; end if;
 insert into public.promotion_endorsements(application_id,originario_id,rationale)
 values(p_application,auth.uid(),trim(p_reason));
 insert into public.promotion_audit(application_id,actor_id,event_type)
 values(p_application,auth.uid(),'aval');
end; $$;

create function public.decide_promotion(p_application uuid,p_approve boolean,p_reason text) returns void
language plpgsql security definer set search_path = ''
as $$
declare p public.promotion_applications%rowtype; v_count integer;
begin
 if not public.is_platform_admin(auth.uid()) then raise exception 'Acción reservada a administración'; end if;
 if char_length(trim(coalesce(p_reason,''))) < 10 then raise exception 'Fundamento obligatorio'; end if;
 select * into p from public.promotion_applications where id=p_application for update;
 if not found or p.status<>'pendiente' then raise exception 'Postulación no pendiente'; end if;
 select count(distinct originario_id) into v_count from public.promotion_endorsements where application_id=p_application;
 if v_count<2 then raise exception 'Se requieren dos avales de Originarios distintos'; end if;
 -- Los requisitos de permanencia se comprueban de nuevo al decidir.
 if not exists (
   select 1 from public.member_profiles m where m.user_id=p.applicant_id and m.active and m.is_verified
   and m.category=case when p.requested_category='titular' then 'asociado'::public.membership_category else 'titular'::public.membership_category end
   and m.member_since <= (current_date - (case when p.requested_category='titular' then interval '12 months' else interval '24 months' end))
 ) then raise exception 'El postulante ya no reúne los requisitos'; end if;
 update public.promotion_applications set status=case when p_approve then 'aprobada'::public.application_status else 'rechazada'::public.application_status end,
 decided_at=now(), decided_by=auth.uid(), decision_reason=trim(p_reason) where id=p_application;
 if p_approve then update public.member_profiles set category=p.requested_category, updated_at=now() where user_id=p.applicant_id; end if;
 insert into public.promotion_audit(application_id,actor_id,event_type,details)
 values(p_application,auth.uid(),case when p_approve then 'aprobacion' else 'rechazo' end,
 jsonb_build_object('razon',p_reason));
end; $$;

alter table public.member_profiles enable row level security;
alter table public.platform_admins enable row level security;
alter table public.promotion_applications enable row level security;
alter table public.promotion_endorsements enable row level security;
alter table public.promotion_audit enable row level security;
alter table public.service_catalog enable row level security;
alter table public.service_orders enable row level security;
alter table public.credit_movements enable row level security;

create policy profile_self_select on public.member_profiles for select to authenticated
using (user_id=auth.uid() or public.is_platform_admin(auth.uid()));
create policy applications_visible on public.promotion_applications for select to authenticated
using (applicant_id=auth.uid() or public.is_platform_admin(auth.uid()) or (status='pendiente' and public.is_active_originario(auth.uid())));
create policy endorsements_visible on public.promotion_endorsements for select to authenticated
using (originario_id=auth.uid() or public.is_platform_admin(auth.uid()) or exists (
 select 1 from public.promotion_applications a where a.id=application_id and a.applicant_id=auth.uid()
));
create policy audit_visible on public.promotion_audit for select to authenticated
using (public.is_platform_admin(auth.uid()) or exists (
 select 1 from public.promotion_applications a where a.id=application_id and a.applicant_id=auth.uid()
));
create policy services_public on public.service_catalog for select to anon, authenticated using(active=true);
create policy orders_member on public.service_orders for select to authenticated
using(member_id=auth.uid() or public.is_platform_admin(auth.uid()));
create policy credits_member on public.credit_movements for select to authenticated
using(member_id=auth.uid() or public.is_platform_admin(auth.uid()));

-- Escrituras únicamente por funciones controladas o proceso servidor (service_role).
revoke all on public.platform_admins from anon,authenticated;
revoke insert,update,delete on public.member_profiles from anon,authenticated;
revoke insert,update,delete on public.promotion_applications from anon,authenticated;
revoke insert,update,delete on public.promotion_endorsements from anon,authenticated;
revoke insert,update,delete on public.promotion_audit from anon,authenticated;
revoke insert,update,delete on public.credit_movements from anon,authenticated;
revoke insert,update,delete on public.service_orders from anon,authenticated;
revoke insert,update,delete on public.service_catalog from anon,authenticated;
revoke execute on function public.is_platform_admin(uuid),public.is_active_originario(uuid),
 public.request_promotion(public.membership_category),public.endorse_promotion(uuid,text),
 public.decide_promotion(uuid,boolean,text) from public,anon;
grant execute on function public.request_promotion(public.membership_category),
 public.endorse_promotion(uuid,text),public.decide_promotion(uuid,boolean,text) to authenticated;
-- Helper functions can be invoked in RLS as owners; grant authenticated SELECT policies require the helpers.
grant execute on function public.is_platform_admin(uuid),public.is_active_originario(uuid) to authenticated;
commit;
