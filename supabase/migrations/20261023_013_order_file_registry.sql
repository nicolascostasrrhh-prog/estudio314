begin;
create table public.service_order_files(
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.service_orders(id) on delete cascade,
 uploaded_by uuid not null references auth.users(id),
 storage_path text not null unique,
 display_name text not null check(char_length(display_name) between 1 and 180),
 created_at timestamptz not null default now()
);
create index service_order_files_order_time on public.service_order_files(order_id,created_at);
alter table public.service_order_files enable row level security;
revoke all on public.service_order_files from public,anon,authenticated;
grant select on public.service_order_files to authenticated;
create policy order_files_read on public.service_order_files for select to authenticated
using ((select public.is_platform_admin(auth.uid())) or exists(
 select 1 from public.service_orders o where o.id=order_id and o.member_id=(select auth.uid())));
create function public.register_order_file(p_order uuid,p_path text,p_name text)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare v_actor uuid:=auth.uid();v_admin boolean;v_id uuid;v_status public.order_status;
begin
 if v_actor is null then raise exception 'Iniciá sesión'; end if;
 v_admin:=public.is_platform_admin(v_actor);
 select status into v_status from public.service_orders
 where id=p_order and (member_id=v_actor or v_admin);
 if not found or v_status in ('cancelada','entregada') then raise exception 'Pedido sin permiso para cargar archivos'; end if;
 if p_path not like p_order::text||'/'||v_actor::text||'/%'
 or char_length(coalesce(p_name,'')) not between 1 and 180 then raise exception 'Nombre o ruta no válidos'; end if;
 if not exists(select 1 from storage.objects where bucket_id='estudio314-order-files' and name=p_path) then
 raise exception 'El archivo no se encontró en almacenamiento'; end if;
 insert into public.service_order_files(order_id,uploaded_by,storage_path,display_name)
 values(p_order,v_actor,p_path,btrim(p_name)) returning id into v_id;
 return v_id;
end $fn$;
revoke execute on function public.register_order_file(uuid,text,text) from public,anon;
grant execute on function public.register_order_file(uuid,text,text) to authenticated;
commit;