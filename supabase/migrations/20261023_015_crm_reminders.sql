begin;
-- Resumen privado de seguimientos; invoker + filtro propietario + RLS.
create function public.my_crm_digest()
returns table(total bigint,active bigint,overdue bigint,due_today bigint,due_next_7_days bigint,won bigint)
language sql stable security invoker set search_path=''
as $fn$
 select
 count(*)::bigint,
 count(*) filter(where c.stage not in ('ganado','cerrado'))::bigint,
 count(*) filter(where c.stage not in ('ganado','cerrado') and c.follow_up_on<current_date)::bigint,
 count(*) filter(where c.stage not in ('ganado','cerrado') and c.follow_up_on=current_date)::bigint,
 count(*) filter(where c.stage not in ('ganado','cerrado') and c.follow_up_on>current_date and c.follow_up_on<=current_date+7)::bigint,
 count(*) filter(where c.stage='ganado')::bigint
 from public.crm_opportunities c where c.owner_id=(select auth.uid())
$fn$;
revoke execute on function public.my_crm_digest() from public,anon;
grant execute on function public.my_crm_digest() to authenticated;

-- No hay envío automático a terceros; la bandeja lee solo datos del titular.
create index if not exists crm_reminder_owner_date on public.crm_opportunities(owner_id,follow_up_on)
 where stage not in ('ganado','cerrado') and follow_up_on is not null;
commit;