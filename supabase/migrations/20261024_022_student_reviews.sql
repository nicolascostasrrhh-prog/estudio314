begin;
create table public.student_application_events(
 id bigint generated always as identity primary key,
 application_id uuid not null references public.student_applications(id) on delete cascade,
 actor_id uuid not null references auth.users(id),
 old_status text not null,
 new_status text not null check(new_status in ('recibida','en_revision','contactado','cerrada')),
 rationale text not null check(length(btrim(rationale)) between 10 and 600),
 created_at timestamptz not null default now()
);
create index student_application_events_recent on public.student_application_events(application_id,created_at desc);
alter table public.student_application_events enable row level security;
revoke all on public.student_application_events from public,anon,authenticated;
grant select on public.student_application_events to authenticated;
create policy student_events_owner_admin on public.student_application_events for select to authenticated using
(exists(select 1 from public.student_applications s where s.id=application_id and (s.user_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())))));
create function public.review_student_application(p_application uuid,p_new_status text,p_reason text)
returns void language plpgsql security definer set search_path=''
as $fn$
declare actor uuid:=auth.uid(); row_data public.student_applications%rowtype;
begin
 if actor is null or not public.is_platform_admin(actor) then raise exception 'Solo administración autorizada';end if;
 if p_new_status not in ('en_revision','contactado','cerrada') or length(btrim(coalesce(p_reason,''))) not between 10 and 600
 then raise exception 'Estado o motivo inválidos';end if;
 select * into row_data from public.student_applications where id=p_application for update;
 if not found then raise exception 'Postulación no encontrada';end if;
 if row_data.status='cerrada' then raise exception 'La postulación está cerrada';end if;
 if row_data.status=p_new_status then raise exception 'La postulación ya tiene ese estado';end if;
 update public.student_applications set status=p_new_status,updated_at=now() where id=p_application;
 insert into public.student_application_events(application_id,actor_id,old_status,new_status,rationale)
 values(p_application,actor,row_data.status,p_new_status,btrim(p_reason));
end $fn$;
revoke execute on function public.review_student_application(uuid,text,text) from public,anon;
grant execute on function public.review_student_application(uuid,text,text) to authenticated;
commit;