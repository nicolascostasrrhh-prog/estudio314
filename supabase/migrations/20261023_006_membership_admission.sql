begin;
create type public.membership_request_status as enum ('pendiente','aprobada','rechazada');
create table public.membership_requests(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 requested_mode public.subscription_mode not null,
 province text not null check(char_length(btrim(province)) between 2 and 80),
 license_number text not null check(char_length(btrim(license_number)) between 3 and 80),
 bar_association text not null check(char_length(btrim(bar_association)) between 3 and 140),
 status public.membership_request_status not null default 'pendiente',
 submitted_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id),
 review_reason text,
 check((status='pendiente' and reviewed_at is null and reviewed_by is null) or
 (status<>'pendiente' and reviewed_at is not null and reviewed_by is not null))
);
create unique index membership_one_pending on public.membership_requests(user_id) where status='pendiente';
create index membership_requests_user_date on public.membership_requests(user_id,submitted_at desc);
create index membership_requests_status_date on public.membership_requests(status,submitted_at);
alter table public.membership_requests enable row level security;
revoke all on public.membership_requests from public,anon,authenticated;
grant select on public.membership_requests to authenticated;
create policy membership_request_owner on public.membership_requests for select to authenticated
using (user_id=(select auth.uid()) or (select public.is_platform_admin(auth.uid())));

create function public.submit_membership_request(p_mode public.subscription_mode,p_province text,p_license text,p_bar text)
returns uuid language plpgsql security definer set search_path = ''
as $func$
declare v_id uuid; v_user uuid := auth.uid();
begin
 if v_user is null then raise exception 'Debés iniciar sesión'; end if;
 if p_mode is null or char_length(btrim(coalesce(p_province,''))) not between 2 and 80
 or char_length(btrim(coalesce(p_license,''))) not between 3 and 80
 or char_length(btrim(coalesce(p_bar,''))) not between 3 and 140 then
  raise exception 'Completá provincia, matrícula y colegio profesional';
 end if;
 if not exists(select 1 from public.member_profiles where user_id=v_user and active) then
  raise exception 'Perfil no encontrado o inactivo';
 end if;
 if exists(select 1 from public.membership_requests where user_id=v_user and status='pendiente') then
  raise exception 'Ya existe una solicitud pendiente';
 end if;
 insert into public.membership_requests(user_id,requested_mode,province,license_number,bar_association)
 values(v_user,p_mode,btrim(p_province),btrim(p_license),btrim(p_bar))
 returning id into v_id;
 return v_id;
end $func$;

create function public.review_membership_request(p_request uuid,p_approve boolean,p_reason text)
returns void language plpgsql security definer set search_path = ''
as $func$
declare v_request public.membership_requests%rowtype; v_admin uuid := auth.uid();
begin
 if v_admin is null or not public.is_platform_admin(v_admin) then
  raise exception 'Solo administración autorizada';
 end if;
 if char_length(btrim(coalesce(p_reason,''))) < 10 then
  raise exception 'Ingresá un fundamento de al menos diez caracteres';
 end if;
 select * into v_request from public.membership_requests where id=p_request for update;
 if not found or v_request.status<>'pendiente' then raise exception 'Solicitud no pendiente'; end if;
 update public.membership_requests set
  status=case when p_approve then 'aprobada'::public.membership_request_status else 'rechazada'::public.membership_request_status end,
  reviewed_at=now(), reviewed_by=v_admin, review_reason=btrim(p_reason)
  where id=p_request;
 if p_approve then
  update public.member_profiles set is_verified=true,subscription=v_request.requested_mode,updated_at=now()
  where user_id=v_request.user_id and active=true;
  if not found then raise exception 'Perfil inactivo o inexistente'; end if;
 end if;
end $func$;
revoke execute on function public.submit_membership_request(public.subscription_mode,text,text,text),
public.review_membership_request(uuid,boolean,text) from public,anon;
grant execute on function public.submit_membership_request(public.subscription_mode,text,text,text),
public.review_membership_request(uuid,boolean,text) to authenticated;
commit;