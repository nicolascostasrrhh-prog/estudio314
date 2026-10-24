begin;
-- Intenciones de compra para asociar cada checkout con un único miembro.
create table public.credit_checkout_intents(
 id uuid primary key default gen_random_uuid(),
 member_id uuid not null references public.member_profiles(user_id),
 package_id uuid not null references public.credit_packages(id),
 expected_amount_ars integer not null check(expected_amount_ars>0),
 expected_credits integer not null check(expected_credits>0),
 provider_preference_id text unique,
 status text not null default 'pending' check(status in ('pending','credited','expired')),
 payment_id text unique,
 created_at timestamptz not null default now(),
 credited_at timestamptz,
 constraint credited_requires_payment check(status<>'credited' or (payment_id is not null and credited_at is not null))
);
create index credit_checkout_by_member on public.credit_checkout_intents(member_id,created_at desc);
alter table public.credit_checkout_intents enable row level security;
revoke all on public.credit_checkout_intents from public,anon,authenticated;
grant select on public.credit_checkout_intents to authenticated;
create policy credit_checkout_owner_read on public.credit_checkout_intents
for select to authenticated using (member_id=(select auth.uid()) or public.is_platform_admin((select auth.uid())));
commit;