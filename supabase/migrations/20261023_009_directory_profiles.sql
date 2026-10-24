-- Perfiles públicos opt-in, separados de información interna de membresía.
begin;
create table public.lawyer_directory_profiles(
 user_id uuid primary key references public.member_profiles(user_id) on delete cascade,
 display_name text not null check(char_length(btrim(display_name)) between 2 and 120),
 province text not null check(char_length(btrim(province)) between 2 and 80),
 locality text not null check(char_length(btrim(locality)) between 2 and 80),
 specialty text not null check(char_length(btrim(specialty)) between 3 and 120),
 bio text not null default '' check(char_length(bio)<=1200),
 visible boolean not null default false,
 updated_at timestamptz not null default now()
);
create index lawyer_directory_location on public.lawyer_directory_profiles(province,locality);
create index lawyer_directory_specialty on public.lawyer_directory_profiles(specialty);
alter table public.lawyer_directory_profiles enable row level security;
revoke all on public.lawyer_directory_profiles from public,anon,authenticated;
grant select on public.lawyer_directory_profiles to anon,authenticated;
create policy lawyer_directory_visible on public.lawyer_directory_profiles for select to anon,authenticated
using(
 (visible=true and exists(select 1 from public.member_profiles m where m.user_id=user_id and m.active=true and m.is_verified=true and m.category in ('asociado','titular','distinguido','originario')))
 or (select auth.uid())=user_id
 or (select public.is_platform_admin(auth.uid()))
);

create function public.save_my_directory_profile(p_name text,p_province text,p_locality text,p_specialty text,p_bio text,p_visible boolean)
returns void language plpgsql security definer set search_path=''
as $func$
declare v_user uuid := auth.uid();
begin
 if v_user is null then raise exception 'Iniciá sesión'; end if;
 if not exists(select 1 from public.member_profiles where user_id=v_user and is_verified=true and active=true and category in ('asociado','titular','distinguido','originario')) then
   raise exception 'Solo profesionales habilitados pueden tener un perfil público';
 end if;
 if char_length(btrim(coalesce(p_name,''))) not between 2 and 120
 or char_length(btrim(coalesce(p_province,''))) not between 2 and 80
 or char_length(btrim(coalesce(p_locality,''))) not between 2 and 80
 or char_length(btrim(coalesce(p_specialty,''))) not between 3 and 120
 or char_length(coalesce(p_bio,''))>1200 or p_visible is null then
   raise exception 'Revisá los campos obligatorios y sus límites';
 end if;
 insert into public.lawyer_directory_profiles(user_id,display_name,province,locality,specialty,bio,visible,updated_at)
 values(v_user,btrim(p_name),btrim(p_province),btrim(p_locality),btrim(p_specialty),btrim(coalesce(p_bio,'')),p_visible,now())
 on conflict(user_id) do update set display_name=excluded.display_name,province=excluded.province,
 locality=excluded.locality,specialty=excluded.specialty,bio=excluded.bio,visible=excluded.visible,updated_at=now();
end $func$;
revoke execute on function public.save_my_directory_profile(text,text,text,text,text,boolean) from public,anon;
grant execute on function public.save_my_directory_profile(text,text,text,text,text,boolean) to authenticated;
commit;