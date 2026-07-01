-- ============================================================
-- Creative Director — Supabase schema
-- One conversational bot for all platforms with BRAND MEMORY so
-- everything you make stays visually consistent.
-- Run in Supabase → SQL Editor. Safe to re-run.
-- ============================================================

-- Per-chat state: all the config you can set by chatting, plus a
-- rolling "brand bible" that keeps your content on-style/on-brand.
create table if not exists cd_state (
  chat_id        text primary key,
  niche          text default '',
  style          text default '',      -- e.g. "Disney Pixar 3D", "moody cinematic"
  platform       text default 'instagram', -- instagram | youtube | tiktok | pinterest | both
  content_type   text default 'video', -- image | carousel | video
  visual_source  text default 'ai',    -- ai | pexels | pinterest
  image_model    text default 'openai/gpt-image-1',  -- OpenRouter image model
  video_model    text default 'google/veo-3.1-lite', -- (used by the v4 generative-video workflow)
  posting_method text default 'buffer',-- buffer | api
  reference      text default '',      -- reference clip/style search phrase
  brand_bible    text default '',      -- AI-maintained style memory (palette, mood, motifs...)
  pending_action jsonb,
  updated_at     timestamptz default now()
);

-- Log of everything created, with the style descriptors used — so the
-- Director can look back and keep new posts consistent with past ones.
create table if not exists cd_memory (
  id          bigint generated always as identity primary key,
  chat_id     text,
  platform    text,
  content_type text,
  topic       text,
  style       text,
  visual_source text,
  caption     text,
  media_urls  jsonb,
  style_tags  text,        -- short descriptors (palette/mood) for consistency
  created_at  timestamptz default now()
);

alter table cd_state  disable row level security;
alter table cd_memory disable row level security;

-- Reuses the public "videos" Storage bucket (from the video setup) for Reels/Shorts.


-- ------------------------------------------------------------
-- Added later: short conversation memory + Facebook support
-- ------------------------------------------------------------
alter table cd_state add column if not exists history jsonb default '[]'::jsonb;
-- Set n8n variable BUFFER_PROFILE_ID_FACEBOOK to your Facebook page profile id in Buffer.
-- platform now accepts: instagram | youtube | tiktok | pinterest | facebook | both


-- Render engine choice (video): ffmpeg (fast clips/stills + captions) or hyperframes (HTML motion graphics)
alter table cd_state add column if not exists render_engine text default 'ffmpeg';
-- HyperFrames requires Node 22+, FFmpeg and headless-Chrome libs on the n8n host (see config/hyperframes_vps_setup.md)
