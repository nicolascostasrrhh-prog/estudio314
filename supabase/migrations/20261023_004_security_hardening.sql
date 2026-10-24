-- Endurecimiento de permisos para el proyecto público Estudio 3.14.
begin;
revoke truncate, trigger, references on all tables in schema public from anon,authenticated;
-- Un trigger de Auth invoca internamente esta función; no debe estar accesible vía API.
revoke execute on function public.create_member_after_signup() from public,anon,authenticated;
-- Impedir llamadas anónimas a funciones de servidor.
revoke execute on function public.available_credits(uuid),
 public.request_service(uuid,jsonb),
 public.is_platform_admin(uuid),
 public.is_active_originario(uuid),
 public.request_promotion(public.membership_category),
 public.endorse_promotion(uuid,text),
 public.decide_promotion(uuid,boolean,text)
 from public,anon;
commit;