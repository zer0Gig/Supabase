-- ─────────────────────────────────────────────────────────────────────────────
-- User feedback — testimoni dan masukan dari pengguna platform.
--
-- Form di frontend: /feedback. Data dikumpulkan untuk ditampilkan
-- sebagai testimoni real users di landing page nanti.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists user_feedback (
  id                uuid          primary key default gen_random_uuid(),

  -- Identitas pengirim
  name              text          not null,
  country           text          not null,
  status            text          not null,  -- 'student', 'worker', 'freelancer', 'entrepreneur', 'other'

  -- Feedback teknis
  feedback_type     text          not null default 'general',  -- 'general', 'bug', 'feature', 'ux', 'economy-concept'
  rating            integer       check (rating >= 1 and rating <= 5),
  message           text          not null,

  -- Metadata
  source            text          default 'feedback-page',
  wallet_address    text,                     -- optional, kalau user sudah connect wallet
  is_displayed      boolean       not null default false,  -- admin toggle untuk testimoni

  created_at        timestamptz   not null default now(),
  updated_at        timestamptz   not null default now()
);

create index if not exists user_feedback_created_at_idx on user_feedback(created_at desc);
create index if not exists user_feedback_status_idx     on user_feedback(status);
create index if not exists user_feedback_is_displayed_idx on user_feedback(is_displayed) where is_displayed = true;

-- RLS — anon CAN insert (feedback terbuka), hanya service_role yang bisa read/update/delete.
alter table user_feedback enable row level security;

drop policy if exists "user_feedback_anon_insert" on user_feedback;
create policy "user_feedback_anon_insert"
  on user_feedback
  for insert
  to anon
  with check (true);

drop policy if exists "user_feedback_service_all" on user_feedback;
create policy "user_feedback_service_all"
  on user_feedback
  for all
  to service_role
  using (true)
  with check (true);
