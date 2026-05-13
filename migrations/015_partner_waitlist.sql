-- ─────────────────────────────────────────────────────────────────────────────
-- Partner waitlist — PT / company partnership applications.
--
-- Sits in front of /onboarding so corporate visitors can register their
-- interest before the individual signup flow. Each row is one company's
-- partnership pitch + a contact rep. The rep still completes /onboarding
-- afterwards as the individual representing that company.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists partner_waitlist (
  id                uuid          primary key default gen_random_uuid(),

  -- Company identity
  company_name      text          not null,
  company_website   text,
  industry          text,
  company_size      text,        -- '1-10', '11-50', '51-200', '201-1000', '1000+'

  -- Contact rep
  contact_name      text          not null,
  contact_email     text          not null,
  contact_phone     text,
  contact_country   text          default 'ID',

  -- Intent
  partnership_type  text,        -- 'agent-ops', 'custom-dev', 'integration', 'reseller', 'other'
  use_case          text,

  -- Pipeline state
  status            text          not null default 'pending',  -- pending / reviewing / approved / rejected
  source            text,         -- ref / utm / 'landing'

  created_at        timestamptz   not null default now(),
  updated_at        timestamptz   not null default now()
);

create index if not exists partner_waitlist_email_idx  on partner_waitlist(contact_email);
create index if not exists partner_waitlist_status_idx on partner_waitlist(status);
create index if not exists partner_waitlist_created_at_idx on partner_waitlist(created_at desc);

-- RLS — only service role writes. Anon CAN read aggregate counts (via a view
-- if needed later) but cannot read raw rows.
alter table partner_waitlist enable row level security;

drop policy if exists "partner_waitlist_service_all" on partner_waitlist;
create policy "partner_waitlist_service_all"
  on partner_waitlist
  for all
  to service_role
  using (true)
  with check (true);
