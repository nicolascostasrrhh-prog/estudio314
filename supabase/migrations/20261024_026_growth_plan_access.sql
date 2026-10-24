begin;
create or replace function public.submit_growth_request(p_topic text,p_message text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare who uuid:=auth.uid(); v_id uuid;
begin
 if who is null then raise exception 'Iniciá sesión';end if;
 if p_topic not in ('presencia','consultas','organizacion','otro') or length(btrim(coalesce(p_message,''))) not between 15 and 1500 then raise exception 'Completá la solicitud';end if;
 if not exists(select 1 from public.member_profiles where user_id=who and active and is_verified and subscription='integral') then
 raise exception 'Se requiere la modalidad Crecimiento Profesional habilitada';end if;
 if (select count(*) from public.growth_requests where member_id=who and status in ('recibida','en_revision'))>=2 then raise exception 'Ya tenés dos solicitudes abiertas; aguardá su revisión';end if;
 insert into public.growth_requests(member_id,topic,message) values(who,p_topic,btrim(p_message)) returning id into v_id;
 return v_id;
end $fn$;
revoke execute on function public.submit_growth_request(text,text) from public,anon;
grant execute on function public.submit_growth_request(text,text) to authenticated;
commit;