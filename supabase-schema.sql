-- ============================================================
-- Creative Director — Consolidated Supabase Schema
-- ============================================================
-- One conversational bot (n8n workflow: workflows/creative_director_v1.json)
-- for all platforms, backed by Supabase (Postgres + Storage).
--
-- The workflow talks to exactly 4 tables via the Supabase REST API
-- (/rest/v1/<table>): cd_state, cd_memory, cd_scheduled, cd_references,
-- and a PUBLIC Storage bucket named "videos" for rendered Reels/Shorts.
--
-- This file is idempotent and safe to re-run: paste the whole thing into
-- Supabase -> SQL Editor and run top-to-bottom. `create table if not exists`
-- builds fresh installs; the `add column if not exists` guards migrate any
-- older/partial tables to the current shape.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Extensions
-- ------------------------------------------------------------
-- gen_random_uuid() (used as cd_scheduled.id default) lives in pgcrypto.
create extension if not exists pgcrypto;


-- ------------------------------------------------------------
-- 1) cd_state  —  per-chat brand state (PRIMARY KEY: chat_id)
-- ------------------------------------------------------------
-- The workflow upserts here with `?on_conflict=chat_id` and header
-- `Prefer: resolution=merge-duplicates`, so chat_id MUST be the unique/PK
-- the merge resolves against. It also reads `select=*` and
-- `select=active_job_token`, and PATCHes by `?chat_id=eq.<id>`.
create table if not exists cd_state (
  chat_id            text primary key,
  niche              text default '',
  style              text default '',        -- e.g. "Disney Pixar 3D", "moody cinematic"
  platform           text default 'instagram', -- legacy single platform (kept for old rows)
  content_type       text default 'video',   -- image | carousel | video
  visual_source      text default 'ai',      -- ai | pexels | pinterest (image/carousel)
  image_model        text default 'openai/gpt-image-1',   -- OpenRouter image model
  video_model        text default 'google/veo-3.1-lite',  -- OpenRouter image->video model
  posting_method     text default 'buffer',  -- buffer | api
  reference          text default '',         -- reference clip/style search phrase
  brand_bible        text default '',         -- AI-maintained style memory
  pending_action     jsonb,                   -- in-flight proposal awaiting confirm
  history            jsonb default '[]'::jsonb,   -- rolling short conversation memory
  render_engine      text default 'ffmpeg',   -- ffmpeg | hyperframes
  post_mode          text default 'now',      -- now | scheduled
  post_time          text default '',         -- 24h IST "HH:MM"
  winners            text default '',         -- analytics: top-performing topics/styles
  platforms          jsonb default '["instagram"]'::jsonb, -- multi-platform array
  video_route        text default 'ai',       -- ai | pexels | pinterest | hyperframes (video)
  posts_per_platform int  default 2,
  narration_voice    text default 'onyx',     -- OpenAI TTS voice
  auto_mode          boolean default false,   -- skip mid-flow approval gates
  custom_preferences text default '',         -- freeform standing instructions
  subtitle_color     text default 'white',    -- video caption color
  subtitle_size      int  default 64,         -- video caption size (px)
  active_job_token   text default '',         -- marks an in-flight creation for this chat
  updated_at         timestamptz default now()
);

-- Migration guards (bring older cd_state tables up to date; no-ops on fresh installs).
alter table cd_state add column if not exists history            jsonb   default '[]'::jsonb;
alter table cd_state add column if not exists render_engine      text    default 'ffmpeg';
alter table cd_state add column if not exists post_mode          text    default 'now';
alter table cd_state add column if not exists post_time          text    default '';
alter table cd_state add column if not exists winners            text    default '';
alter table cd_state add column if not exists platforms          jsonb   default '["instagram"]'::jsonb;
alter table cd_state add column if not exists video_route        text    default 'ai';
alter table cd_state add column if not exists posts_per_platform int     default 2;
alter table cd_state add column if not exists narration_voice    text    default 'onyx';
alter table cd_state add column if not exists auto_mode          boolean default false;
alter table cd_state add column if not exists custom_preferences text    default '';
alter table cd_state add column if not exists subtitle_color     text    default 'white';
alter table cd_state add column if not exists subtitle_size      int     default 64;
alter table cd_state add column if not exists active_job_token   text    default '';


-- ------------------------------------------------------------
-- 2) cd_memory  —  log of everything created + analytics (PRIMARY KEY: id)
-- ------------------------------------------------------------
-- Workflow INSERTs finished posts, reads `?buffer_id=not.is.null&select=*`
-- for the analytics loop, and PATCHes metrics by `?id=eq.<id>`.
create table if not exists cd_memory (
  id                  bigint generated always as identity primary key,
  chat_id             text,
  platform            text,          -- first/primary platform (kept populated)
  platforms           jsonb,         -- full platform array
  content_type        text,
  topic               text,
  style               text,
  visual_source       text,
  caption             text,
  media_urls          jsonb,
  style_tags          text,          -- short descriptors (palette/mood) for consistency
  buffer_id           text,          -- Buffer update id (for stats lookup)
  metrics             jsonb,         -- {likes,comments,shares,saves,reach,clicks}
  score               numeric default 0,   -- weighted engagement score
  metrics_updated_at  timestamptz,
  posted              boolean default true, -- false if generation ok but publish failed
  created_at          timestamptz default now()
);

-- Migration guards for older cd_memory tables.
alter table cd_memory add column if not exists platforms          jsonb;
alter table cd_memory add column if not exists buffer_id          text;
alter table cd_memory add column if not exists metrics            jsonb;
alter table cd_memory add column if not exists score              numeric default 0;
alter table cd_memory add column if not exists metrics_updated_at timestamptz;
alter table cd_memory add column if not exists posted             boolean default true;


-- ------------------------------------------------------------
-- 3) cd_scheduled  —  queue of approved posts awaiting their time (PK: id)
-- ------------------------------------------------------------
-- The Schedule Trigger fetches `?status=eq.pending&due_at=lte.<now>`,
-- claims them (PATCH status=posting), then marks them by `?id=eq.<id>`.
create table if not exists cd_scheduled (
  id         uuid primary key default gen_random_uuid(),
  chat_id    text,
  due_at     timestamptz,             -- when to publish (UTC)
  status     text default 'pending',  -- pending | posting | posted
  payload    jsonb,                   -- full ready-to-post package
  posted_at  timestamptz,
  created_at timestamptz default now()
);
create index if not exists cd_scheduled_due_idx on cd_scheduled (status, due_at);


-- ------------------------------------------------------------
-- 4) cd_references  —  named reference images per chat (PRIMARY KEY: id)
-- ------------------------------------------------------------
-- Workflow INSERTs saved photos and reads `?chat_id=eq.<id>&select=name,url`.
create table if not exists cd_references (
  id         bigint generated always as identity primary key,
  chat_id    text,
  name       text,
  url        text,
  created_at timestamptz default now()
);


-- ------------------------------------------------------------
-- 5) Row Level Security
-- ------------------------------------------------------------
-- The workflow uses the service key for all REST calls, so RLS is disabled
-- to keep those calls unblocked. (Enable + add policies if you ever expose
-- these tables to anon/authenticated clients.)
alter table cd_state      disable row level security;
alter table cd_memory     disable row level security;
alter table cd_scheduled  disable row level security;
alter table cd_references disable row level security;


-- ============================================================
-- 6) PUBLIC Storage bucket:  "videos"
-- ============================================================
-- Rendered videos are uploaded to:
--   POST /storage/v1/object/videos/<job>.mp4
-- and served publicly from:
--   GET  /storage/v1/object/public/videos/<job>.mp4
-- so the bucket MUST be public.
--
-- Option A (SQL — run here): create/ensure the bucket is public.
insert into storage.buckets (id, name, public)
values ('videos', 'videos', true)
on conflict (id) do update set public = true;

-- Option B (Dashboard — recommended to also verify):
--   Storage -> New bucket -> name "videos" -> toggle "Public bucket" ON.
--
-- Note: for a PUBLIC bucket, objects are readable without auth, so no extra
-- storage.objects SELECT policy is required for public playback. Writes in
-- this workflow use the service key, which bypasses storage RLS. If you later
-- make the bucket private, add explicit storage.objects policies instead.
-- ============================================================
