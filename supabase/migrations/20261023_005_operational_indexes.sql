-- Índices operativos para expedientes, avales y pedidos; no alteran datos ni permisos.
begin;
create index if not exists idx_credit_movements_order on public.credit_movements(service_order_id);
create index if not exists idx_credit_movements_actor on public.credit_movements(created_by);
create index if not exists idx_promotion_applications_decider on public.promotion_applications(decided_by);
create index if not exists idx_promotion_audit_actor on public.promotion_audit(actor_id);
create index if not exists idx_promotion_audit_application on public.promotion_audit(application_id,happened_at desc);
create index if not exists idx_promotion_endorsements_originario on public.promotion_endorsements(originario_id);
create index if not exists idx_service_orders_service on public.service_orders(service_id);
commit;