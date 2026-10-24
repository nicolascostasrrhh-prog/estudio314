begin;
create table public.growth_plans(
 id uuid primary key default gen_random_uuid(),
 member_id uuid not null unique references public.member_profiles(user_id),
 objective text not null default '' check(length(objective)<=1200),
 diagnosis text not null default '' check(length(diagnosis)<=3000),
 status text not null default 'diagnostico' check(status in ('diagnostico','planificado','en_marcha','en_revision','pausado')),
 month_start date not null default date_trunc('month',current_date)::date,
 operator_note text not null default '' check(length(operator_note)<=1600),
 updated_at timestamptz not null default now()
);
alter table public.growth_plans enable row level security;
revoke all on public.growth_plans from public,anon,authenticated;
grant select on public.growth_plans to authenticated;
create policy growth_plans_member_or_admin on public.growth_plans for select to authenticated
 using(member_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())));
create table public.growth_actions(
 id uuid primary key default gen_random_uuid(),
 plan_id uuid not null references public.growth_plans(id) on delete cascade,
 title text not null check(length(btrim(title)) between 5 and 160),
 detail text not null default '' check(length(detail)<=1200),
 status text not null default 'pendiente' check(status in ('pendiente','en_proceso','completada','cancelada')),
 sort_order integer not null default 0 check(sort_order between 0 and 100),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.growth_actions enable row level security;
revoke all on public.growth_actions from public,anon,authenticated;
grant select on public.growth_actions to authenticated;
create policy growth_actions_visible on public.growth_actions for select to authenticated using
(exists(select 1 from public.growth_plans p where p.id=plan_id and (p.member_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())))));
create table public.growth_requests(
 id uuid primary key default gen_random_uuid(),
 member_id uuid not null references public.member_profiles(user_id),
 topic text not null check(topic in ('presencia','consultas','organizacion','otro')),
 message text not null check(length(btrim(message)) between 15 and 1500),
 status text not null default 'recibida' check(status in ('recibida','en_revision','incorporada','cerrada')),
 admin_note text not null default '' check(length(admin_note)<=1200),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.growth_requests enable row level security;
revoke all on public.growth_requests from public,anon,authenticated;
grant select on public.growth_requests to authenticated;
create policy growth_requests_member_admin on public.growth_requests for select to authenticated
 using(member_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())));
create function public.submit_growth_request(p_topic text,p_message text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid(); v_id uuid;
begin
 if who is null then raise exception 'Iniciá sesión';end if;
 if p_topic not in ('presencia','consultas','organizacion','otro') or length(btrim(coalesce(p_message,''))) not between 15 and 1500 then raise exception 'Completá la solicitud';end if;
 if not exists(select 1 from public.member_profiles where user_id=who and active and is_verified) then raise exception 'Se requiere membresía profesional habilitada';end if;
 if (select count(*) from public.growth_requests where member_id=who and status in ('recibida','en_revision'))>=2 then raise exception 'Ya tenés dos solicitudes abiertas; aguardá su revisión';end if;
 insert into public.growth_requests(member_id,topic,message) values(who,p_topic,btrim(p_message)) returning id into v_id;
 return v_id;
end $fn$;
revoke execute on function public.submit_growth_request(text,text) from public,anon;
grant execute on function public.submit_growth_request(text,text) to authenticated;
create function public.manage_growth_plan(p_member uuid,p_objective text,p_diagnosis text,p_status text,p_note text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid(); v_id uuid;
begin
 if who is null or not public.is_platform_admin(who) then raise exception 'Solo administración';end if;
 if p_member is null or length(coalesce(p_objective,''))>1200 or length(coalesce(p_diagnosis,''))>3000 or length(coalesce(p_note,''))>1600
  or p_status not in ('diagnostico','planificado','en_marcha','en_revision','pausado') then raise exception 'Datos inválidos';end if;
 if not exists(select 1 from public.member_profiles where user_id=p_member and active and is_verified) then raise exception 'Profesional no habilitado';end if;
 insert into public.growth_plans(member_id,objective,diagnosis,status,operator_note)
 values(p_member,btrim(coalesce(p_objective,'')),btrim(coalesce(p_diagnosis,'')),p_status,btrim(coalesce(p_note,'')))
 on conflict(member_id) do update set objective=excluded.objective,diagnosis=excluded.diagnosis,status=excluded.status,operator_note=excluded.operator_note,updated_at=now()
 returning id into v_id;
 return v_id;
end $fn$;
revoke execute on function public.manage_growth_plan(uuid,text,text,text,text) from public,anon;
grant execute on function public.manage_growth_plan(uuid,text,text,text,text) to authenticated;
create function public.manage_growth_action(p_plan uuid,p_action uuid,p_title text,p_detail text,p_status text,p_order integer)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid(); result_id uuid;
begin
 if who is null or not public.is_platform_admin(who) then raise exception 'Solo administración';end if;
 if not exists(select 1 from public.growth_plans where id=p_plan) or length(btrim(coalesce(p_title,''))) not between 5 and 160 or length(coalesce(p_detail,''))>1200 or p_status not in ('pendiente','en_proceso','completada','cancelada') or p_order not between 0 and 100 then raise exception 'Acción inválida';end if;
 if p_action is null then
 insert into public.growth_actions(plan_id,title,detail,status,sort_order) values(p_plan,btrim(p_title),btrim(coalesce(p_detail,'')),p_status,p_order) returning id into result_id;
 else
 update public.growth_actions set title=btrim(p_title),detail=btrim(coalesce(p_detail,'')),status=p_status,sort_order=p_order,updated_at=now() where id=p_action and plan_id=p_plan returning id into result_id;
 if result_id is null then raise exception 'Acción no encontrada';end if;
 end if;
 return result_id;
end $fn$;
revoke execute on function public.manage_growth_action(uuid,uuid,text,text,text,integer) from public,anon;
grant execute on function public.manage_growth_action(uuid,uuid,text,text,text,integer) to authenticated;
create function public.review_growth_request(p_request uuid,p_status text,p_note text)
returns void language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid();
begin
 if who is null or not public.is_platform_admin(who) then raise exception 'Solo administración';end if;
 if p_status not in ('en_revision','incorporada','cerrada') or length(btrim(coalesce(p_note,''))) not between 10 and 1200 then raise exception 'Estado o fundamento inválido';end if;
 update public.growth_requests set status=p_status,admin_note=btrim(p_note),updated_at=now() where id=p_request;
 if not found then raise exception 'Solicitud inexistente';end if;
end $fn$;
revoke execute on function public.review_growth_request(uuid,text,text) from public,anon;
grant execute on function public.review_growth_request(uuid,text,text) to authenticated;
commit;