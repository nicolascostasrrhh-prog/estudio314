begin;
create table public.growth_operator_notes(
 plan_id uuid primary key references public.growth_plans(id) on delete cascade,
 note text not null default '' check(length(note)<=1600),
 updated_at timestamptz not null default now()
);
alter table public.growth_operator_notes enable row level security;
revoke all on public.growth_operator_notes from public,anon,authenticated;
grant select on public.growth_operator_notes to authenticated;
create policy growth_internal_notes_admin on public.growth_operator_notes for select to authenticated using(public.is_platform_admin((select auth.uid())));
create table public.growth_request_decisions(
 request_id uuid primary key references public.growth_requests(id) on delete cascade,
 note text not null check(length(btrim(note)) between 10 and 1200),
 updated_at timestamptz not null default now()
);
alter table public.growth_request_decisions enable row level security;
revoke all on public.growth_request_decisions from public,anon,authenticated;
grant select on public.growth_request_decisions to authenticated;
create policy growth_decision_admin on public.growth_request_decisions for select to authenticated using(public.is_platform_admin((select auth.uid())));
insert into public.growth_operator_notes(plan_id,note) select id,operator_note from public.growth_plans where operator_note<>'';
insert into public.growth_request_decisions(request_id,note) select id,admin_note from public.growth_requests where admin_note<>'';
alter table public.growth_plans drop column operator_note;
alter table public.growth_requests drop column admin_note;
create or replace function public.manage_growth_plan(p_member uuid,p_objective text,p_diagnosis text,p_status text,p_note text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid(); v_id uuid;
begin
 if who is null or not public.is_platform_admin(who) then raise exception 'Solo administración';end if;
 if p_member is null or length(coalesce(p_objective,''))>1200 or length(coalesce(p_diagnosis,''))>3000 or length(coalesce(p_note,''))>1600
  or p_status not in ('diagnostico','planificado','en_marcha','en_revision','pausado') then raise exception 'Datos inválidos';end if;
 if not exists(select 1 from public.member_profiles where user_id=p_member and active and is_verified) then raise exception 'Profesional no habilitado';end if;
 insert into public.growth_plans(member_id,objective,diagnosis,status)
 values(p_member,btrim(coalesce(p_objective,'')),btrim(coalesce(p_diagnosis,'')),p_status)
 on conflict(member_id) do update set objective=excluded.objective,diagnosis=excluded.diagnosis,status=excluded.status,updated_at=now()
 returning id into v_id;
 insert into public.growth_operator_notes(plan_id,note) values(v_id,btrim(coalesce(p_note,'')))
 on conflict(plan_id) do update set note=excluded.note,updated_at=now();
 return v_id;
end $fn$;
create or replace function public.review_growth_request(p_request uuid,p_status text,p_note text)
returns void language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid();
begin
 if who is null or not public.is_platform_admin(who) then raise exception 'Solo administración';end if;
 if p_status not in ('en_revision','incorporada','cerrada') or length(btrim(coalesce(p_note,''))) not between 10 and 1200 then raise exception 'Estado o fundamento inválido';end if;
 update public.growth_requests set status=p_status,updated_at=now() where id=p_request;
 if not found then raise exception 'Solicitud inexistente';end if;
 insert into public.growth_request_decisions(request_id,note) values(p_request,btrim(p_note))
 on conflict(request_id) do update set note=excluded.note,updated_at=now();
end $fn$;
revoke execute on function public.manage_growth_plan(uuid,text,text,text,text) from public,anon;
revoke execute on function public.review_growth_request(uuid,text,text) from public,anon;
grant execute on function public.manage_growth_plan(uuid,text,text,text,text) to authenticated;
grant execute on function public.review_growth_request(uuid,text,text) to authenticated;
commit;