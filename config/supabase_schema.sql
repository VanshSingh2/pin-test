-- ============================================================
-- Pinterest AI Automation — Supabase Database Schema
-- Run this in Supabase → SQL Editor → New Query → Run
-- ============================================================

-- ----------------------------------------------------------------
-- Table 1: content_queue  (the main pipeline table)
-- ----------------------------------------------------------------
create table if not exists content_queue (
  id              bigint generated always as identity primary key,
  trend_topic     text,
  title_idea      text,
  category        text,
  content_type    text,
  image_prompt    text,
  image_url       text,
  pin_title       text,
  pin_description text,
  hashtags        text,
  board_id        text,
  board_name      text,
  status          text default 'new_idea',   -- new_idea | has_prompt | has_image | ready_to_post | posted | posted_buffer | failed
  platform        text,                       -- pinterest | buffer
  pin_id          text,
  link_url        text,
  error_notes     text,
  posted_at       timestamptz,
  created_at      timestamptz default now()
);

create index if not exists idx_content_queue_status on content_queue (status);

-- ----------------------------------------------------------------
-- Table 2: trends  (discovered trending topics)
-- ----------------------------------------------------------------
create table if not exists trends (
  id           bigint generated always as identity primary key,
  trend_topic  text not null,
  category     text,
  keywords     text,
  source       text default 'openai',
  score        int  default 7,
  used         boolean default false,
  created_at   timestamptz default now()
);

create unique index if not exists idx_trends_topic on trends (lower(trend_topic));

-- ----------------------------------------------------------------
-- Table 3: analytics  (daily pin performance)
-- ----------------------------------------------------------------
create table if not exists analytics (
  id              bigint generated always as identity primary key,
  pin_id          text,
  pin_title       text,
  impressions     int default 0,
  saves           int default 0,
  clicks          int default 0,
  outbound_clicks int default 0,
  save_rate       numeric(5,2) default 0,
  click_rate      numeric(5,2) default 0,
  snapshot_date   date default current_date,
  created_at      timestamptz default now()
);

-- ----------------------------------------------------------------
-- Table 4: logs  (workflow run logs)
-- ----------------------------------------------------------------
create table if not exists logs (
  id         bigint generated always as identity primary key,
  level      text default 'INFO',   -- INFO | WARN | ERROR
  message    text,
  details    jsonb,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------------
-- Optional: disable Row Level Security so the n8n service key
-- can read/write freely. (You are using the service_role key.)
-- ----------------------------------------------------------------
alter table content_queue disable row level security;
alter table trends        disable row level security;
alter table analytics     disable row level security;
alter table logs          disable row level security;
