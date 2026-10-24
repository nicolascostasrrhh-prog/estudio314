begin;
alter table public.lawyer_directory_profiles
 add column if not exists years_experience integer
 check (years_experience between 0 and 75);
create index if not exists lawyer_directory_experience
 on public.lawyer_directory_profiles(years_experience)
 where visible = true;
create or replace function public.set_my_lawyer_experience(p_years integer)
returns void language plpgsql security definer set search_path=''
as $$
declare v_user uuid := auth.uid();
begin
 if v_user is null or p_years is null or p_years < 0 or p_years > 75 then
   raise exception 'Años de experiencia no válidos';
 end if;
 if not exists (select 1 from public.member_profiles where user_id=v_user and is_verified and active and category in ('asociado','titular','distinguido','originario')) then
   raise exception 'Se requiere perfil profesional verificado';
 end if;
 update public.lawyer_directory_profiles set years_experience=p_years, updated_at=now() where user_id=v_user;
 if not found then raise exception 'Guardá primero el perfil profesional'; end if;
end $$;
revoke execute on function public.set_my_lawyer_experience(integer) from public,anon;
grant execute on function public.set_my_lawyer_experience(integer) to authenticated;

-- Las funciones privilegiadas de lectura de rol sólo admiten inspeccionar al propio usuario
-- cuando se invocan desde las APIs; internamente su uso con auth.uid() continúa intacto.
create or replace function public.is_platform_admin(p_user uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select coalesce(p_user = auth.uid(),false) and exists(
 select 1 from public.platform_admins a where a.user_id=p_user)
$$;
create or replace function public.is_active_originario(p_user uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select coalesce(p_user = auth.uid(),false) and exists(
 select 1 from public.member_profiles m where m.user_id=p_user and m.category='originario' and m.active and m.is_verified)
$$;
commit;