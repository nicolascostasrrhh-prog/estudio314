begin;
-- El expediente administrativo interno no debe ser legible por los postulantes.
drop policy if exists student_events_owner_admin on public.student_application_events;
create policy student_events_admin_only on public.student_application_events
 for select to authenticated using(public.is_platform_admin((select auth.uid())));
-- Un CV solo puede sustituirse cuando la solicitud sigue recibida.
create or replace function public.register_student_cv(p_path text)
returns void language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid();
begin
 if who is null or p_path is null or p_path !~ ('^'||who::text||'/[a-zA-Z0-9_-]+[.]pdf$')
 then raise exception 'Ruta de CV inválida';end if;
 if not exists(select 1 from storage.objects where bucket_id='estudio314-student-cvs' and name=p_path)
 then raise exception 'CV no encontrado';end if;
 update public.student_applications set cv_path=p_path,updated_at=now()
 where user_id=who and status='recibida';
 if not found then raise exception 'Solo podés adjuntar CV mientras tu solicitud esté recibida';end if;
end $fn$;
-- Impedir cambios silenciosos de información curricular después de comenzar la evaluación.
create or replace function public.submit_student_application(p_name text,p_university text,p_year integer,p_subjects integer,p_summary text,p_practice text,p_motivation text,p_availability text)
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
 where public.student_applications.status='recibida'
 returning id into application;
 if application is null then raise exception 'La postulación ya está en evaluación o cerrada y no admite edición';end if;
 return application;
end $fn$;
revoke execute on function public.submit_student_application(text,text,integer,integer,text,text,text,text) from public,anon;
revoke execute on function public.register_student_cv(text) from public,anon;
grant execute on function public.submit_student_application(text,text,integer,integer,text,text,text,text) to authenticated;
grant execute on function public.register_student_cv(text) to authenticated;
commit;