begin;
create table public.student_applications(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade unique,
 full_name text not null check(length(btrim(full_name)) between 4 and 120),
 university text not null check(length(btrim(university)) between 2 and 160),
 academic_year integer not null check(academic_year between 1 and 10),
 approved_subjects integer not null check(approved_subjects between 0 and 120),
 academic_summary text not null check(length(btrim(academic_summary)) between 10 and 1500),
 preferred_practice text not null check(length(btrim(preferred_practice)) between 3 and 120),
 motivation text not null check(length(btrim(motivation)) between 30 and 1800),
 availability text not null check(length(btrim(availability)) between 3 and 200),
 cv_path text,
 consent_at timestamptz not null default now(),
 status text not null default 'recibida' check(status in ('recibida','en_revision','contactado','cerrada')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.student_applications enable row level security;
revoke all on public.student_applications from public,anon,authenticated;
grant select on public.student_applications to authenticated;
create policy student_applicant_view on public.student_applications for select to authenticated
using(user_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())));
create function public.submit_student_application(p_name text,p_university text,p_year integer,p_subjects integer,p_summary text,p_practice text,p_motivation text,p_availability text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid(); application uuid;
begin
 if who is null then raise exception 'Iniciá sesión';end if;
 if length(btrim(coalesce(p_name,''))) not between 4 and 120
 or length(btrim(coalesce(p_university,''))) not between 2 and 160
 or p_year not between 1 and 10 or p_subjects not between 0 and 120
 or length(btrim(coalesce(p_summary,''))) not between 10 and 1500
 or length(btrim(coalesce(p_practice,''))) not between 3 and 120
 or length(btrim(coalesce(p_motivation,''))) not between 30 and 1800
 or length(btrim(coalesce(p_availability,''))) not between 3 and 200
 then raise exception 'Revisá el formulario de formación';end if;
 insert into public.student_applications(user_id,full_name,university,academic_year,approved_subjects,academic_summary,preferred_practice,motivation,availability)
 values(who,btrim(p_name),btrim(p_university),p_year,p_subjects,btrim(p_summary),btrim(p_practice),btrim(p_motivation),btrim(p_availability))
 on conflict(user_id) do update set full_name=excluded.full_name,university=excluded.university,
 academic_year=excluded.academic_year,approved_subjects=excluded.approved_subjects,
 academic_summary=excluded.academic_summary,preferred_practice=excluded.preferred_practice,
 motivation=excluded.motivation,availability=excluded.availability,updated_at=now()
 returning id into application;
 return application;
end $fn$;
revoke execute on function public.submit_student_application(text,text,integer,integer,text,text,text,text) from public,anon;
grant execute on function public.submit_student_application(text,text,integer,integer,text,text,text,text) to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('estudio314-student-cvs','estudio314-student-cvs',false,5242880,array['application/pdf'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['application/pdf'];
create policy student_cv_owner_upload on storage.objects for insert to authenticated
with check(bucket_id='estudio314-student-cvs' and (storage.foldername(name))[1]=(select auth.uid())::text
and exists(select 1 from public.student_applications a where a.user_id=(select auth.uid())));
create policy student_cv_owner_read on storage.objects for select to authenticated
using(bucket_id='estudio314-student-cvs' and ((storage.foldername(name))[1]=(select auth.uid())::text or public.is_platform_admin((select auth.uid()))));
create function public.register_student_cv(p_path text)
returns void language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid();
begin
 if who is null or p_path is null or p_path !~ ('^'||who::text||'/[a-zA-Z0-9_-]+[.]pdf$')
 then raise exception 'Ruta de CV inválida';end if;
 if not exists(select 1 from storage.objects where bucket_id='estudio314-student-cvs' and name=p_path)
 then raise exception 'CV no encontrado';end if;
 update public.student_applications set cv_path=p_path,updated_at=now() where user_id=who;
 if not found then raise exception 'Presentá la postulación antes de adjuntar el CV';end if;
end $fn$;
revoke execute on function public.register_student_cv(text) from public,anon;
grant execute on function public.register_student_cv(text) to authenticated;
commit;