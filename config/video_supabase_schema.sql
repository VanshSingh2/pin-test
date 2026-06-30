-- ============================================================
-- YouTube + TikTok Automation — Supabase Database Schema
-- Run this in Supabase → SQL Editor → New Query → Run
-- (Separate from the Pinterest schema; can live in the same project)
-- ============================================================

-- ----------------------------------------------------------------
-- Table 1: video_queue  (the main pipeline table)
-- status: idea | rendering | ready | published | failed
-- ----------------------------------------------------------------
create table if not exists video_queue (
  id               bigint generated always as identity primary key,
  platform         text default 'youtube',   -- youtube | tiktok | both
  niche            text,
  topic            text,
  hook             text,
  script           text,                      -- full narration script
  title            text,
  description      text,
  tags             text,                      -- comma-separated (YouTube)
  hashtags         text,                      -- space-separated (TikTok/Shorts)
  thumbnail_url    text,
  video_url        text,                      -- final rendered MP4 URL
  render_id        text,                      -- JSON2Video project id
  status           text default 'idea',
  scheduled_time   timestamptz,
  published_at     timestamptz,
  youtube_video_id text,
  tiktok_video_id  text,
  error_notes      text,
  created_at       timestamptz default now()
);

create index if not exists idx_video_queue_status on video_queue (status);
create index if not exists idx_video_queue_sched  on video_queue (scheduled_time);

-- ----------------------------------------------------------------
-- Table 2: video_analytics  (per-video performance snapshots)
-- ----------------------------------------------------------------
create table if not exists video_analytics (
  id            bigint generated always as identity primary key,
  platform      text,
  external_id   text,        -- youtube_video_id or tiktok_video_id
  title         text,
  views         bigint default 0,
  likes         bigint default 0,
  comments      bigint default 0,
  shares        bigint default 0,
  performance   numeric(6,2) default 0,   -- simple score
  snapshot_date date default current_date,
  created_at    timestamptz default now()
);

-- ----------------------------------------------------------------
-- Table 3: video_strategy  (weekly review insights)
-- ----------------------------------------------------------------
create table if not exists video_strategy (
  id             bigint generated always as identity primary key,
  week_start     date,
  top_topics     jsonb,
  avg_score      numeric(6,2),
  recommendation text,
  insights       jsonb,
  created_at     timestamptz default now()
);

-- ----------------------------------------------------------------
-- Optional: disable RLS so the n8n service_role key can read/write
-- ----------------------------------------------------------------
alter table video_queue     disable row level security;
alter table video_analytics disable row level security;
alter table video_strategy  disable row level security;
