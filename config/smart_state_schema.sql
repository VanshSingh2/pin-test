-- ============================================================
-- Smart Conversational Workflows — Supabase state tables
-- Powers the YouTube & Pinterest "manager brain" bots (like Instagram's ig_state).
-- Run in Supabase → SQL Editor. Safe to re-run.
-- ============================================================

-- YouTube/TikTok smart bot per-chat state
create table if not exists yt_state (
  chat_id        text primary key,
  niche          text default '',
  style          text default '',     -- e.g. "Disney Pixar 3D", "cinematic realism"
  broll_source   text default 'pexels',-- pexels | pinterest
  reference      text default '',      -- optional reference style/search term for clips
  platform       text default 'youtube', -- youtube | tiktok | both (Buffer profiles)
  pending_action jsonb,
  updated_at     timestamptz default now()
);

-- Pinterest smart bot per-chat state
create table if not exists pin_state (
  chat_id        text primary key,
  niche          text default '',
  style          text default '',
  board_id       text default '',
  pending_action jsonb,
  updated_at     timestamptz default now()
);

alter table yt_state  disable row level security;
alter table pin_state disable row level security;

-- Reuses the public "videos" Storage bucket (from the video setup) for rendered Shorts.
