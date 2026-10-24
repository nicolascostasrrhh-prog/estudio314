-- Operación de pedidos reales de Estudio 3.14: solo administradores pueden cambiar estados.
begin;
create table public.service_order_events(
 id bigint generated always as identity primary key,
 order_id uuid not null references public.service_orders(id),
 actor_id uuid not null references auth.users(id),
 previous_status public.order_status,
 new_status public.order_status not null,
 note text not null check(char_length(btrim(note)) between 10 and 1000),
 created_at timestamptz not null default now()
);
create index service_order_events_order_date on public.service_order_events(order_id,created_at);
create index service_order_events_actor on public.service_order_events(actor_id);
alter table public.service_order_events enable row level security;
revoke all on public.service_order_events from public,anon,authenticated;
grant select on public.service_order_events to authenticated;
create policy order_events_read on public.service_order_events for select to authenticated
using (public.is_platform_admin((select auth.uid())) or exists(
 select 1 from public.service_orders o where o.id=order_id and o.member_id=(select auth.uid())
));

create function public.admin_advance_order(p_order uuid,p_next public.order_status,p_note text)
returns void language plpgsql security definer set search_path=''
as $func$
declare v_order public.service_orders%rowtype; v_actor uuid := auth.uid();
begin
 if v_actor is null or not public.is_platform_admin(v_actor) then raise exception 'Acceso exclusivo de administración'; end if;
 if char_length(btrim(coalesce(p_note,''))) not between 10 and 1000 then raise exception 'El fundamento debe tener entre 10 y 1000 caracteres'; end if;
 select * into v_order from public.service_orders where id=p_order for update;
 if not found then raise exception 'Pedido inexistente'; end if;
 if not (
  (v_order.status='solicitada' and p_next in ('en_revision','cancelada')) or
  (v_order.status='en_revision' and p_next in ('en_proceso','cancelada')) or
  (v_order.status='en_proceso' and p_next in ('entregada','cancelada'))
 ) then raise exception 'Transición no permitida'; end if;
 -- La fila del miembro serializa cualquier reserva, devolución y saldo concurrentes.
 perform 1 from public.member_profiles where user_id=v_order.member_id for update;
 if p_next='cancelada' and v_order.credits_reserved>0 then
   if exists(select 1 from public.credit_movements where service_order_id=p_order and movement_type='devolucion') then
     raise exception 'El pedido ya tiene devolución';
   end if;
   insert into public.credit_movements(member_id,movement_type,amount,note,service_order_id,created_by)
   values(v_order.member_id,'devolucion',v_order.credits_reserved,'Devolución completa por cancelación',p_order,v_actor);
 end if;
 update public.service_orders set status=p_next where id=p_order;
 insert into public.service_order_events(order_id,actor_id,previous_status,new_status,note)
 values(p_order,v_actor,v_order.status,p_next,btrim(p_note));
end $func$;
revoke execute on function public.admin_advance_order(uuid,public.order_status,text) from public,anon;
grant execute on function public.admin_advance_order(uuid,public.order_status,text) to authenticated;
commit;