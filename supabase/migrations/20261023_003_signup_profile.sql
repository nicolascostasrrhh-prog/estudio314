-- Estudio 3.14: aprovisionamiento seguro de perfiles desde Supabase Auth.
-- Ejecutar después de 001_initial.sql y 002_service_credits.sql.
begin;

create or replace function public.create_member_after_signup()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_name text;
begin
  v_name := coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'),''),'Miembro pendiente');
  v_name := left(v_name,120);
  insert into public.member_profiles(user_id,display_name,category,member_since,subscription,is_verified,active)
  values(new.id,v_name,'asociado',current_date,'plataforma',false,true)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists estudio314_member_signup on auth.users;
create trigger estudio314_member_signup
after insert on auth.users for each row
execute function public.create_member_after_signup();

-- Política complementaria de lectura: el miembro consulta su propio perfil.
-- Ninguna escritura de categoría, antigüedad, verificación o créditos se concede al navegador.
commit;
