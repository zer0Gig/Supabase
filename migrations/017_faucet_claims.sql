-- Migration: faucet_claims
-- Tracks OG faucet distributions to prevent double-claims.

create table if not exists public.faucet_claims (
  id uuid default gen_random_uuid() primary key,
  wallet_address text not null,
  amount text not null,
  tx_hash text,
  claimed_at timestamptz default now() not null
);

-- Prevent duplicate claims from the same wallet
create unique index if not exists idx_faucet_claims_wallet
  on public.faucet_claims (wallet_address);

-- RLS
alter table public.faucet_claims enable row level security;

create policy "Anyone can read faucet claims"
  on public.faucet_claims for select
  to anon, authenticated
  using (true);

create policy "Service role can manage faucet claims"
  on public.faucet_claims for all
  to service_role
  using (true)
  with check (true);
