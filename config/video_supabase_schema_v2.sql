-- ============================================================
-- YouTube + TikTok Automation v2 — Schema additions
-- Run AFTER video_supabase_schema.sql (adds columns for the
-- upgraded multi-scene, data-driven pipeline). Safe to re-run.
-- ============================================================

alter table video_queue add column if not exists scenes          jsonb;
alter table video_queue add column if not exists cta             text;
alter table video_queue add column if not exists target_audience text;
alter table video_queue add column if not exists content_pillar  text;
alter table video_queue add column if not exists research_used    jsonb;

-- Watch-time / retention friendly analytics columns
alter table video_analytics add column if not exists avg_watch_seconds numeric(8,2) default 0;
alter table video_analytics add column if not exists retention_pct      numeric(5,2) default 0;
