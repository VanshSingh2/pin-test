-- ============================================================
-- Instagram Automation — Supabase Database Schema
-- Run in Supabase → SQL Editor → New Query → Run.
-- (Can live in the same project as the Pinterest/video schemas.)
-- ============================================================

-- Per-chat conversation state: niche, video/visual style, and any
-- pending action the Manager Brain proposed and is awaiting confirm.
create table if not exists ig_state (
  chat_id        text primary key,
  niche          text default '',
  style          text default '',     -- e.g. "Disney Pixar 3D", "animated stick figure", "cinematic realism"
  pending_action jsonb,               -- { action_type, topic, script, slide_count }
  updated_at     timestamptz default now()
);

-- Log of everything created/posted
create table if not exists ig_queue (
  id          bigint generated always as identity primary key,
  chat_id     text,
  type        text,                   -- carousel | video | image
  niche       text,
  style       text,
  topic       text,
  caption     text,
  media_urls  jsonb,                  -- array of hosted image/video URLs
  buffer_id   text,
  status      text default 'created', -- created | posted | failed
  error_notes text,
  created_at  timestamptz default now()
);

alter table ig_state disable row level security;
alter table ig_queue disable row level security;

-- Reuse the public "videos" Storage bucket from the v3/v4 video setup
-- for rendered Instagram Reels (create it if you haven't: Storage → New
-- bucket → name: videos → Public: ON).
