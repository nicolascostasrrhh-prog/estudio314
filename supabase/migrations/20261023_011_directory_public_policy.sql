begin;
drop policy lawyer_directory_visible on public.lawyer_directory_profiles;
create policy directory_public_read on public.lawyer_directory_profiles
 for select to anon
 using(visible=true and private.is_published_eligible_member(user_id));
create policy directory_signed_in_read on public.lawyer_directory_profiles
 for select to authenticated
 using(
 (visible=true and private.is_published_eligible_member(user_id))
 or user_id=(select auth.uid())
 or (select public.is_platform_admin(auth.uid()))
 );
commit;