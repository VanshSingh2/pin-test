-- ============================================================
-- YouTube + TikTok Automation v3 — Schema additions
-- Run AFTER video_supabase_schema.sql and _v2.sql. Safe to re-run.
-- Adds: settings table (Telegram-controlled config) + storage note.
-- ============================================================

-- Key/value settings, controlled from Telegram
create table if not exists settings (
  key        text primary key,
  value      text,
  updated_at timestamptz default now()
);

-- Sensible defaults (IST = Asia/Kolkata)
insert into settings (key, value) values
  ('daily_time',  '18:00')        on conflict (key) do nothing;
insert into settings (key, value) values
  ('timezone',    'Asia/Kolkata') on conflict (key) do nothing;
insert into settings (key, value) values
  ('platform',    'youtube')      on conflict (key) do nothing;
insert into settings (key, value) values
  ('daily_enabled','true')        on conflict (key) do nothing;
-- Best-time slots (IST, comma separated HH:MM) used when "best time" is requested
insert into settings (key, value) values
  ('best_times_youtube','15:00,18:00,20:00') on conflict (key) do nothing;
insert into settings (key, value) values
  ('best_times_tiktok','12:00,19:00,21:00')  on conflict (key) do nothing;

alter table settings disable row level security;

-- Track the local render path + public URL on the queue
alter table video_queue add column if not exists video_path  text;
alter table video_queue add column if not exists source      text;   -- telegram | schedule
alter table video_queue add column if not exists chat_id     text;   -- Telegram chat to notify

-- ------------------------------------------------------------
-- STORAGE: create a PUBLIC bucket named "videos" in Supabase
--   Dashboard → Storage → New bucket → name: videos → Public: ON
-- Rendered MP4s are uploaded there so YouTube/TikTok can fetch a
-- public URL: {SUPABASE_URL}/storage/v1/object/public/videos/<file>
-- ------------------------------------------------------------
