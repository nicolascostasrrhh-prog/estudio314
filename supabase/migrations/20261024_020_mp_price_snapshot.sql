begin;
create or replace function public.credit_verified_checkout_intent(p_intent uuid,p_payment_id text,p_amount_ars integer)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare v_intent public.credit_checkout_intents%rowtype;
 v_movement bigint;v_receipt uuid;v_prior public.credit_purchase_receipts%rowtype;
begin
 if current_setting('request.jwt.claim.role',true) is distinct from 'service_role' then raise exception 'Solo backend habilitado';end if;
 if p_payment_id is null or length(trim(p_payment_id)) not between 1 and 160 then raise exception 'Pago inválido';end if;
 select * into v_intent from public.credit_checkout_intents where id=p_intent for update;
 if not found then raise exception 'Compra inexistente';end if;
 if v_intent.status='credited' then
  if v_intent.payment_id<>trim(p_payment_id) then raise exception 'Intento acreditado con otro pago';end if;
  select id into v_receipt from public.credit_purchase_receipts where payment_id=trim(p_payment_id);
  if v_receipt is null then raise exception 'Acreditación inconsistente';end if;
  return v_receipt;
 end if;
 if v_intent.status<>'pending' or v_intent.expected_amount_ars<>p_amount_ars
  or v_intent.expected_credits<=0 or v_intent.expected_amount_ars<=0
 then raise exception 'Compra no pagable o importe distinto';end if;
 -- El precio y la cantidad quedan fijados al crear el checkout:
 -- modificar el catálogo posteriormente no afecta compras ya iniciadas.
 if not exists(select 1 from public.credit_packages where id=v_intent.package_id) then raise exception 'Paquete inexistente';end if;
 if not exists(select 1 from public.member_profiles where user_id=v_intent.member_id and active and is_verified)
 then raise exception 'Miembro sin habilitación';end if;
 select * into v_prior from public.credit_purchase_receipts where payment_id=trim(p_payment_id);
 if found then raise exception 'Pago asociado a otra compra';end if;
 insert into public.credit_movements(member_id,movement_type,amount,note)
 values(v_intent.member_id,'compra',v_intent.expected_credits,'Mercado Pago · compra aprobada')
 returning id into v_movement;
 insert into public.credit_purchase_receipts(payment_id,member_id,package_id,amount_ars,credits,credit_movement_id)
 values(trim(p_payment_id),v_intent.member_id,v_intent.package_id,p_amount_ars,v_intent.expected_credits,v_movement)
 returning id into v_receipt;
 update public.credit_checkout_intents set status='credited',payment_id=trim(p_payment_id),credited_at=now() where id=p_intent;
 return v_receipt;
end $fn$;
revoke execute on function public.credit_verified_checkout_intent(uuid,text,integer) from public,anon,authenticated;
grant execute on function public.credit_verified_checkout_intent(uuid,text,integer) to service_role;
commit;