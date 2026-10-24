begin;
create or replace function public.submit_membership_request(p_mode public.subscription_mode,p_province text,p_license text,p_bar text)
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
 if not exists(select 1 from public.member_profiles
   where user_id=v_user and active=true and is_verified=false) then
  raise exception 'Solo perfiles pendientes pueden solicitar admisión';
 end if;
 if exists(select 1 from public.membership_requests where user_id=v_user and status='pendiente') then
  raise exception 'Ya existe una solicitud pendiente';
 end if;
 insert into public.membership_requests(user_id,requested_mode,province,license_number,bar_association)
 values(v_user,p_mode,btrim(p_province),btrim(p_license),btrim(p_bar))
 returning id into v_id;
 return v_id;
end $func$;
revoke execute on function public.submit_membership_request(public.subscription_mode,text,text,text) from public,anon;
grant execute on function public.submit_membership_request(public.subscription_mode,text,text,text) to authenticated;
commit;