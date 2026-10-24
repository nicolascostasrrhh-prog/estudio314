begin;
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon,authenticated;
create function private.is_published_eligible_member(p_user uuid) returns boolean
language sql stable security definer set search_path=''
as $func$
 select exists(select 1 from public.member_profiles m
 where m.user_id=p_user and m.active=true and m.is_verified=true
 and m.category in ('asociado','titular','distinguido','originario'))
$func$;
revoke execute on function private.is_published_eligible_member(uuid) from public;
grant execute on function private.is_published_eligible_member(uuid) to anon,authenticated;
drop policy lawyer_directory_visible on public.lawyer_directory_profiles;
create policy lawyer_directory_visible on public.lawyer_directory_profiles for select to anon,authenticated
using ((visible=true and (select private.is_published_eligible_member(user_id)))
or user_id=(select auth.uid()) or (select public.is_platform_admin(auth.uid())));
commit;