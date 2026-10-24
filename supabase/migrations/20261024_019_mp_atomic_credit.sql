begin;
-- Relaciona de manera atómica la acreditación con una intención única.
create function public.credit_verified_checkout_intent(p_intent uuid,p_payment_id text,p_amount_ars integer)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare v_intent public.credit_checkout_intents%rowtype; v_pack public.credit_packages%rowtype;
v_movement bigint;v_receipt uuid;v_prior public.credit_purchase_receipts%rowtype;
begin
 if current_setting('request.jwt.claim.role',true) is distinct from 'service_role'
 then raise exception 'Solo backend habilitado';end if;
 if p_payment_id is null or length(trim(p_payment_id)) not between 1 and 160 then raise exception 'Identificador de pago inválido';end if;
 select * into v_intent from public.credit_checkout_intents where id=p_intent for update;
 if not found then raise exception 'Compra inexistente';end if;
 if v_intent.status='credited' then
   if v_intent.payment_id<>trim(p_payment_id) then raise exception 'Intento ya acreditado con otro pago';end if;
   select id into v_receipt from public.credit_purchase_receipts where payment_id=trim(p_payment_id);
   if v_receipt is null then raise exception 'Acreditación inconsistente';end if;
   return v_receipt;
 end if;
 if v_intent.status<>'pending' then raise exception 'Checkout no pendiente';end if;
 select * into v_pack from public.credit_packages where id=v_intent.package_id;
 if not found or not v_pack.active or v_pack.price_ars<>p_amount_ars
  or v_pack.credits<>v_intent.expected_credits or v_pack.price_ars<>v_intent.expected_amount_ars
 then raise exception 'Importe o paquete inválido';end if;
 if not exists(select 1 from public.member_profiles where user_id=v_intent.member_id and active and is_verified)
 then raise exception 'Miembro no habilitado';end if;
 select * into v_prior from public.credit_purchase_receipts where payment_id=trim(p_payment_id);
 if found then raise exception 'Pago previamente asociado a otra compra';end if;
 insert into public.credit_movements(member_id,movement_type,amount,note)
 values(v_intent.member_id,'compra',v_pack.credits,'Mercado Pago · compra aprobada')
 returning id into v_movement;
 insert into public.credit_purchase_receipts(payment_id,member_id,package_id,amount_ars,credits,credit_movement_id)
 values(trim(p_payment_id),v_intent.member_id,v_intent.package_id,p_amount_ars,v_pack.credits,v_movement)
 returning id into v_receipt;
 update public.credit_checkout_intents set status='credited',payment_id=trim(p_payment_id),credited_at=now() where id=p_intent;
 return v_receipt;
end $fn$;
revoke execute on function public.credit_verified_checkout_intent(uuid,text,integer) from public,anon,authenticated;
grant execute on function public.credit_verified_checkout_intent(uuid,text,integer) to service_role;
-- Deshabilita ruta anterior que no fijaba compra individual
revoke execute on function public.credit_verified_mercadopago_payment(text,uuid,uuid,integer) from service_role;
commit;