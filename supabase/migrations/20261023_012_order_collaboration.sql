begin;
-- Conversaciones y entregas sólo visibles para titular del pedido y administradores.
create table public.service_order_messages(
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.service_orders(id) on delete cascade,
 sender_id uuid not null references auth.users(id),
 message_kind text not null check(message_kind in ('consulta','respuesta','entrega','ajuste')),
 body text not null check(char_length(btrim(body)) between 5 and 3000),
 created_at timestamptz not null default now()
);
create index service_order_messages_order_date on public.service_order_messages(order_id,created_at);
alter table public.service_order_messages enable row level security;
revoke all on public.service_order_messages from public,anon,authenticated;
grant select on public.service_order_messages to authenticated;
create policy order_messages_read on public.service_order_messages for select to authenticated
using ((select public.is_platform_admin(auth.uid())) or exists(
 select 1 from public.service_orders o where o.id=order_id and o.member_id=(select auth.uid())));
create function public.add_order_message(p_order uuid,p_kind text,p_body text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare v_actor uuid := auth.uid(); v_order public.service_orders%rowtype; v_id uuid; v_admin boolean;
begin
 if v_actor is null then raise exception 'Iniciá sesión'; end if;
 if p_kind not in ('consulta','respuesta','entrega','ajuste') or char_length(btrim(coalesce(p_body,''))) not between 5 and 3000 then raise exception 'Mensaje inválido'; end if;
 select * into v_order from public.service_orders where id=p_order;
 if not found then raise exception 'Pedido inexistente'; end if;
 v_admin:=public.is_platform_admin(v_actor);
 if not v_admin and v_order.member_id<>v_actor then raise exception 'Acceso no autorizado'; end if;
 if v_order.status='cancelada' then raise exception 'El pedido está cancelado'; end if;
 if p_kind='entrega' and not v_admin then raise exception 'Solo administración puede informar una entrega'; end if;
 if p_kind='respuesta' and not v_admin then raise exception 'Solo administración puede responder como operador'; end if;
 if p_kind='ajuste' and v_admin then raise exception 'Los ajustes los solicita el miembro'; end if;
 insert into public.service_order_messages(order_id,sender_id,message_kind,body)
 values(p_order,v_actor,p_kind,btrim(p_body)) returning id into v_id;
 return v_id;
end $fn$;
revoke execute on function public.add_order_message(uuid,text,text) from public,anon;
grant execute on function public.add_order_message(uuid,text,text) to authenticated;

-- Archivos privados: el contenido vive en Storage; la tabla sólo lleva metadatos.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('estudio314-order-files','estudio314-order-files',false,20971520,
array['application/pdf','image/png','image/jpeg','video/mp4'])
on conflict(id) do nothing;
create policy estudio314_order_file_read on storage.objects for select to authenticated
using(bucket_id='estudio314-order-files' and
 exists(select 1 from public.service_orders o
 where o.id=(split_part(name,'/',1))::uuid and
 (o.member_id=(select auth.uid()) or (select public.is_platform_admin(auth.uid())))));
create policy estudio314_order_file_upload on storage.objects for insert to authenticated
with check(bucket_id='estudio314-order-files'
 and (select auth.uid())::text=split_part(name,'/',2)
 and exists(select 1 from public.service_orders o
 where o.id=(split_part(name,'/',1))::uuid and o.member_id=(select auth.uid())
 and o.status not in ('cancelada','entregada')));
create policy estudio314_admin_file_upload on storage.objects for insert to authenticated
with check(bucket_id='estudio314-order-files'
 and (select auth.uid())::text=split_part(name,'/',2)
 and (select public.is_platform_admin(auth.uid()))
 and exists(select 1 from public.service_orders o where o.id=(split_part(name,'/',1))::uuid and o.status<>'cancelada'));
commit;