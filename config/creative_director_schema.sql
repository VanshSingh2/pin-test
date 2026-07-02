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



-- ------------------------------------------------------------
-- Added later: SCHEDULER (post now vs post at a set IST time)
-- ------------------------------------------------------------
-- post_mode: 'now' posts right after you approve; 'scheduled' queues it for post_time.
-- post_time: 24h IST "HH:MM" (e.g. 19:30). Change both by chatting, e.g. "post daily at 7pm".
alter table cd_state add column if not exists post_mode text default 'now';
alter table cd_state add column if not exists post_time text default '';

-- Queue of approved posts waiting for their scheduled time. The "Schedule Trigger"
-- runs every 15 min, grabs rows whose due_at has passed, posts them, marks them 'posted'.
create table if not exists cd_scheduled (
  id         uuid primary key default gen_random_uuid(),
  chat_id    text,
  due_at     timestamptz,          -- when to publish (UTC)
  status     text default 'pending', -- pending | posted
  payload    jsonb,                -- the full ready-to-post package (media urls, caption, platform...)
  posted_at  timestamptz,
  created_at timestamptz default now()
);
create index if not exists cd_scheduled_due_idx on cd_scheduled (status, due_at);
alter table cd_scheduled disable row level security;



-- ------------------------------------------------------------
-- Added later: ANALYTICS feedback loop
-- ------------------------------------------------------------
-- Every 6h the "Analytics Trigger" pulls each Buffer-posted update's stats,
-- scores it, and writes the top performers back into cd_state.winners so the
-- Master Brief doubles down on what actually works.
alter table cd_memory add column if not exists buffer_id text;             -- Buffer update id (for stats lookup)
alter table cd_memory add column if not exists metrics jsonb;              -- {likes,comments,shares,saves,reach,clicks}
alter table cd_memory add column if not exists score numeric default 0;    -- weighted engagement score
alter table cd_memory add column if not exists metrics_updated_at timestamptz;

alter table cd_state  add column if not exists winners text default '';     -- short summary of top-performing topics/styles


-- ------------------------------------------------------------
-- Added later: multi-platform posting + video_route (Platform Rules upgrade)
-- ------------------------------------------------------------
-- platforms replaces the old single `platform` column (kept, unused going forward, for backward compat with old rows).
alter table cd_state add column if not exists platforms jsonb default '["instagram"]'::jsonb;
-- video_route replaces the visual_source+render_engine choice for content_type=video only
-- (ai | pinterest | hyperframes). visual_source/render_engine columns are kept and still populated
-- (derived from video_route) for backward compat with anything reading them directly.
alter table cd_state add column if not exists video_route text default 'ai';

-- cd_memory gains the same platforms array; old `platform` (text, first platform) is kept populated too.
alter table cd_memory add column if not exists platforms jsonb;
-- posted: false when generation succeeded but the publish step (Buffer/YouTube/Pinterest) failed.
alter table cd_memory add column if not exists posted boolean default true;

-- posts_per_platform: how many pieces of content per platform per request (foundation for a future batch-generation stage — not yet multiplied into generation)
alter table cd_state add column if not exists posts_per_platform int default 2;
-- narration_voice: chat-settable, remembered OpenAI TTS voice used for every video (both ffmpeg and hyperframes engines)
alter table cd_state add column if not exists narration_voice text default 'onyx';

-- Named reference images: send a photo to the bot with a caption = the name to save it here.
create table if not exists cd_references (
  id         bigint generated always as identity primary key,
  chat_id    text,
  name       text,
  url        text,
  created_at timestamptz default now()
);
alter table cd_references disable row level security;

-- auto_mode: when true, skips the script/image/Pinterest-clip approval gates (only the final
-- posting approval still fires). Chat-settable ("automate this" / "ask me each time").
alter table cd_state add column if not exists auto_mode boolean default false;
