-- Estudio 3.14: reserva transaccional de créditos para servicios
-- La migración presupone 20261023_001_initial.sql.
begin;
create function public.available_credits(p_member uuid) returns bigint
language sql stable security definer set search_path=''
as $$
 select coalesce(sum(cm.amount),0)::bigint
 from public.credit_movements cm
 where cm.member_id=p_member
   and (p_member=auth.uid() or public.is_platform_admin(auth.uid()))
$$;

create function public.request_service(p_service uuid,p_requirements jsonb) returns uuid
language plpgsql security definer set search_path=''
as $$
declare p public.member_profiles%rowtype; s public.service_catalog%rowtype; available bigint; v_id uuid;
begin
 if auth.uid() is null then raise exception 'Autenticación requerida'; end if;
 -- Lock por miembro: dos pedidos simultáneos no pueden gastar el mismo saldo.
 select * into p from public.member_profiles where user_id=auth.uid() for update;
 if not found or not p.active or not p.is_verified then raise exception 'Cuenta profesional no habilitada'; end if;
 select * into s from public.service_catalog where id=p_service and active;
 if not found then raise exception 'Servicio no disponible'; end if;
 if p_requirements is null or jsonb_typeof(p_requirements)<>'object' then raise exception 'Requisitos inválidos'; end if;
 if pg_column_size(p_requirements)>16000 then raise exception 'Solicitud demasiado extensa'; end if;
 select coalesce(sum(amount),0) into available from public.credit_movements where member_id=auth.uid();
 if available<s.credit_cost then raise exception 'Créditos insuficientes'; end if;
 insert into public.service_orders(member_id,service_id,requirements,credits_reserved)
 values(auth.uid(),p_service,p_requirements,s.credit_cost) returning id into v_id;
 if s.credit_cost>0 then
 insert into public.credit_movements(member_id,movement_type,amount,service_order_id,note,created_by)
 values(auth.uid(),'reserva',-s.credit_cost,v_id,'Reserva de créditos por pedido',auth.uid());
 end if;
 return v_id;
end; $;
revoke execute on function public.available_credits(uuid),public.request_service(uuid,jsonb) from public,anon;
grant execute on function public.available_credits(uuid),public.request_service(uuid,jsonb) to authenticated;
commit;
