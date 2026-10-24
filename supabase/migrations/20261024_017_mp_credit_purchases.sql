begin;
-- Catálogo de packs: sin precios o enlaces inventados. Solo packs habilitados aparecerán.
create table public.credit_packages(
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(trim(title)) between 3 and 100),
 credits integer not null check(credits>0),
 price_ars integer not null check(price_ars>0),
 active boolean not null default false,
 created_at timestamptz not null default now()
);
alter table public.credit_packages enable row level security;
revoke all on public.credit_packages from public,anon,authenticated;
grant select on public.credit_packages to authenticated;
create policy active_packages_visible on public.credit_packages
 for select to authenticated using(active or public.is_platform_admin((select auth.uid())));

-- Liquidaciones verificadas. Una operación de MP jamás puede acreditar dos veces.
create table public.credit_purchase_receipts(
 id uuid primary key default gen_random_uuid(),
 payment_provider text not null default 'mercadopago' check(payment_provider='mercadopago'),
 payment_id text not null unique check(length(trim(payment_id)) between 1 and 160),
 member_id uuid not null references public.member_profiles(user_id),
 package_id uuid not null references public.credit_packages(id),
 amount_ars integer not null check(amount_ars>0),
 credits integer not null check(credits>0),
 status text not null default 'approved' check(status='approved'),
 credited_at timestamptz not null default now(),
 credit_movement_id bigint not null unique references public.credit_movements(id)
);
create index credit_purchases_member_date on public.credit_purchase_receipts(member_id,credited_at desc);
alter table public.credit_purchase_receipts enable row level security;
revoke all on public.credit_purchase_receipts from public,anon,authenticated;
grant select on public.credit_purchase_receipts to authenticated;
create policy purchase_receipts_owner on public.credit_purchase_receipts
 for select to authenticated using(member_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())));

-- Exclusivamente para un backend con credencial de service_role y pago ya verificado
-- consultando la API oficial de Mercado Pago. NUNCA invocar desde el navegador.
create function public.credit_verified_mercadopago_payment(
 p_payment_id text,p_member uuid,p_package uuid,p_amount_ars integer
) returns uuid language plpgsql security definer set search_path=''
as $fn$
declare v_pack public.credit_packages%rowtype;v_existing public.credit_purchase_receipts%rowtype;v_movement bigint;v_receipt uuid;
begin
 if current_setting('request.jwt.claim.role',true) is distinct from 'service_role'
 then raise exception 'Credencial de backend requerida';end if;
 if p_payment_id is null or length(trim(p_payment_id)) not between 1 and 160 then
 raise exception 'Pago inválido';end if;
 select * into v_pack from public.credit_packages where id=p_package;
 if not found or not v_pack.active or v_pack.price_ars<>p_amount_ars then
 raise exception 'Paquete o importe no válido';end if;
 if not exists(select 1 from public.member_profiles where user_id=p_member and active and is_verified)
 then raise exception 'Miembro sin habilitación';end if;
 -- Evita procesar dos veces el mismo pago, incluso con webhooks concurrentes.
 perform pg_advisory_xact_lock(hashtextextended('mp:'||p_payment_id,0));
 select * into v_existing from public.credit_purchase_receipts where payment_id=p_payment_id;
 if found then
   if v_existing.member_id<>p_member or v_existing.package_id<>p_package or v_existing.amount_ars<>p_amount_ars
   then raise exception 'Pago asociado a otra operación';end if;
   return v_existing.id;
 end if;
 insert into public.credit_movements(member_id,movement_type,amount,note)
 values(p_member,'compra',v_pack.credits,'Compra acreditada por Mercado Pago')
 returning id into v_movement;
 insert into public.credit_purchase_receipts(payment_id,member_id,package_id,amount_ars,credits,credit_movement_id)
 values(trim(p_payment_id),p_member,p_package,p_amount_ars,v_pack.credits,v_movement)
 returning id into v_receipt;
 return v_receipt;
end $fn$;
revoke execute on function public.credit_verified_mercadopago_payment(text,uuid,uuid,integer) from public,anon,authenticated;
grant execute on function public.credit_verified_mercadopago_payment(text,uuid,uuid,integer) to service_role;
commit;