# 🤖 Social Media AI Automation — n8n Workflows

This repo contains **two** all-in-one n8n automation workflows, both backed by **Supabase**:

| Workflow | File | What it does |
|----------|------|--------------|
| 📌 **Pinterest** | `workflows/pinterest_ai_complete.json` | Trends → ideas → DALL-E images → SEO copy → post (Pinterest API **or** Buffer toggle) |
| 🎬 **YouTube + TikTok** | `workflows/youtube_tiktok_v4_ondemand_openrouter.json` | ⭐ **v4** — on-demand Telegram bot, OpenRouter image→video, Script Writer + Doctor |

Jump to: [Pinterest](#-pinterest-automation) · [YouTube + TikTok](#-youtube--tiktok-automation)

---

## 📌 Pinterest Automation

A fully automated Pinterest content machine in a **single n8n workflow**. It discovers trends, writes ideas, generates images with DALL-E 3, writes SEO copy, and posts to Pinterest — with a **toggle** to switch between posting via the **Pinterest API** or **Buffer**. Data is stored in **Supabase**.

---

## ✨ Key Features

- 🧩 **One workflow file** — import a single JSON, no sub-workflows to wire up
- 🎛️ **Posting toggle** — flip between `pinterest` and `buffer` in one node
- 🗄️ **Supabase database** — Postgres backend via REST API
- 🎨 **AI images** — DALL-E 3 generated, hosted on Imgbb
- 📊 **Built-in analytics** — second trigger pulls daily Pinterest stats
- 🔌 **Master on/off switch** — disable the whole automation instantly

---

## 🏗️ Architecture

```
TRIGGER 1: ⏰ Posting Schedule (every 4h)
   │
   ▼
⚙️ CONTROL PANEL  ← 🎛️ TOGGLE: postingMethod, postsPerRun, enabled
   │
   ▼
❓ Enabled? ──no──▶ ⏭️ Skip
   │ yes
   ▼
💡 OpenAI: Generate Ideas  →  💾 Supabase: Insert Ideas
   │
   ▼
🔄 Process Each Pin (loop):
     ✍️ Image Prompt (OpenAI)
       → 🎨 DALL-E 3 → ☁️ Imgbb host
       → 📝 Pin Copy (OpenAI: title/desc/hashtags)
       → 🔀 TOGGLE ─── buffer ──▶ 📱 Buffer: Post
       │              └ pinterest ▶ 📌 Pinterest: Create Pin
       → 💾 Supabase: Update Result
   │
   ▼
✅ Run Complete

TRIGGER 2: ⏰ Analytics Schedule (daily 9AM)
   │
   ▼
💾 Supabase: Get Posted Pins → 📊 Pinterest Analytics → 💾 Supabase: Save Analytics
```

---

## 🎛️ The Posting Toggle (most important part)

Open the workflow → click the **`⚙️ CONTROL PANEL`** node → change values:

| Field | Options | What it does |
|-------|---------|--------------|
| `postingMethod` | `pinterest` \| `buffer` | **Switches which service posts your pins** |
| `postsPerRun` | number (e.g. `2`) | How many pins to create & post per run |
| `niche` | text | Your content niche for idea generation |
| `enabled` | `true` \| `false` | Master switch — set `false` to pause everything |

> Set `postingMethod` to `buffer` → all pins go through Buffer.
> Set it to `pinterest` → pins post directly via the Pinterest API.
> No re-wiring needed — the **🔀 TOGGLE** node routes automatically.

---

## 📋 Prerequisites

- n8n (self-hosted or Cloud)
- Supabase account (free tier works)
- OpenAI API key (GPT-4o-mini + DALL-E 3, billing enabled)
- Pinterest Developer App (Standard Access for public pins)
- Imgbb API key (free image hosting)
- Buffer account (only if using `buffer` mode)

---

## 🚀 Setup Guide

### Step 1 — Set up Supabase
1. Create a project at [supabase.com](https://supabase.com)
2. **SQL Editor → New Query** → paste [`config/supabase_schema.sql`](config/supabase_schema.sql) → **Run**
3. **Project Settings → API** → copy the **Project URL** and **`service_role`** key

### Step 2 — Set n8n Variables
Add all variables from [`config/n8n_variables.md`](config/n8n_variables.md) under **Settings → Variables**:
```
OPENAI_API_KEY, IMGBB_API_KEY,
SUPABASE_URL, SUPABASE_SERVICE_KEY,
PINTEREST_ACCESS_TOKEN, PINTEREST_BOARD_ID_FASHION/BEAUTY/LIFESTYLE/QUOTES,
BUFFER_ACCESS_TOKEN, BUFFER_PROFILE_ID
```
> See [`config/credentials_guide.md`](config/credentials_guide.md) for how to get each one.

### Step 3 — Import the Workflow
In n8n: **Workflows → Import from File** → select
[`workflows/pinterest_ai_complete.json`](workflows/pinterest_ai_complete.json)

### Step 4 — Set Your Toggle
Open the **⚙️ CONTROL PANEL** node and choose your `postingMethod` and `postsPerRun`.

### Step 5 — Activate
Toggle the workflow **Active**. It now runs every 4 hours and posts automatically.
Analytics run daily at 9 AM into your Supabase `analytics` table.

---

## 🗄️ Database (Supabase)

| Table | Purpose |
|-------|---------|
| `content_queue` | Main pipeline — every pin and its status |
| `trends` | Discovered trending topics |
| `analytics` | Daily pin performance metrics |
| `logs` | Optional run logs |

**Status lifecycle** (`content_queue.status`):
```
new_idea → has_image → ready_to_post → posted | posted_buffer | failed
```

---

## 📁 File Structure

```
pin-test/
├── README.md
├── workflows/
│   └── pinterest_ai_complete.json   ← THE single all-in-one workflow
└── config/
    ├── supabase_schema.sql          ← Run this in Supabase SQL Editor
    ├── n8n_variables.md             ← All variables to set
    └── credentials_guide.md         ← How to get each API key
```

---

## ⚙️ Customization

| Want to change... | Where |
|-------------------|-------|
| Posting service (Pinterest/Buffer) | ⚙️ CONTROL PANEL → `postingMethod` |
| Posts per run | ⚙️ CONTROL PANEL → `postsPerRun` |
| Pause everything | ⚙️ CONTROL PANEL → `enabled = false` |
| Posting frequency | "⏰ Posting Schedule" node → interval |
| Content niche | ⚙️ CONTROL PANEL → `niche` |
| Image style | "✍️ Build Image Prompt" node → prompt text |

---

## ❗ Pinterest Trial vs Standard Access

When you first get Pinterest API access you're on **Trial Access** — pins are created
successfully but are **only visible to you**. To make pins public, request **Standard Access**
in the Pinterest developer portal (usually approved in a few days). The workflow works on
Trial Access for testing; Buffer mode is unaffected by this.

---

## 🐛 Troubleshooting

| Problem | Fix |
|---------|-----|
| Supabase insert fails (401) | Use the `service_role` key, not `anon` |
| DALL-E image broken on Pinterest | Imgbb hosting handles this; check `IMGBB_API_KEY` |
| Pins not public | You're on Pinterest Trial Access — request Standard |
| Buffer posts not appearing | Check `BUFFER_PROFILE_ID` matches your Pinterest profile |
| Nothing posts | Check ⚙️ CONTROL PANEL → `enabled = true` |
| Wrong service posting | Check ⚙️ CONTROL PANEL → `postingMethod` value |

---

## 🛠️ Tech Stack

| Component | Tech |
|-----------|------|
| Automation | n8n (single workflow) |
| Database | Supabase (Postgres + REST) |
| AI Text | OpenAI GPT-4o-mini |
| AI Images | OpenAI DALL-E 3 |
| Image Hosting | Imgbb |
| Posting | Pinterest API v5 **or** Buffer (toggle) |

---

*Built with ❤️ — a single-workflow, toggle-driven Pinterest content machine.*


---

## 🎬 YouTube + TikTok Automation

> **Four versions available:**
> - **`youtube_tiktok_v4_ondemand_openrouter.json`** ⭐⭐⭐ **newest** — **on-demand** Telegram bot, **OpenRouter image→video** (real AI video clips), **Script Writer + Script Doctor** reviewer
> - `youtube_tiktok_v3_ffmpeg_telegram.json` — Telegram bot + FFmpeg, OpenAI-only, IST scheduling
> - `youtube_tiktok_v2.json` — data-driven strategy + multi-scene (JSON2Video render)
> - `youtube_tiktok_complete.json` — original single-image version (reference)

A second all-in-one workflow that creates and publishes **short-form videos** to YouTube and/or TikTok automatically. It's modeled on the multi-agent architecture from [darkzOGx/youtube-automation-agent](https://github.com/darkzOGx/youtube-automation-agent), rebuilt for n8n with a TikTok publishing path added. *(Architecture notes were summarized/rephrased for licensing compliance.)*

### ⭐ What's new in v2

| Area | v1 | v2 (better) |
|------|----|-------------|
| **Strategy** | Picks a topic blind | **Data-driven** — feeds past top-performers + recent topics back into the strategy agent, and avoids repeats |
| **Script** | One narration blob | **Retention framework** — hook → 3-4 value beats → payoff → CTA, scene-by-scene |
| **Visuals** | Single static AI image | **Multi-scene** — real Pexels stock b-roll per scene + word-by-word captions |
| **Model** | gpt-4o-mini | **gpt-4o** with `response_format: json_object` (reliable parsing) |
| **Per-scene** | — | Each scene has its own narration, caption, and b-roll keyword |

v2 needs the extra schema columns — run [`config/video_supabase_schema_v2.sql`](config/video_supabase_schema_v2.sql) **after** the base schema, and add `PEXELS_API_KEY`.

### ⭐⭐ v3 — Telegram bot + FFmpeg (newest, OpenAI-only, near-free)

The newest version is **controlled entirely from Telegram** and renders video with **FFmpeg** on your own server (no JSON2Video subscription). Full guide: [`config/video_v3_setup.md`](config/video_v3_setup.md).

**Talk to it in plain English (times are IST):**
- _"make a video about morning routines, post at best time"_
- _"create a short on saving money, post tomorrow 7pm"_
- _"set daily posting time to 18:30"_ → auto-posts daily at that time
- _"set platform to both"_ · _"status"_

**Three triggers:** `💬 Telegram Command` (on-demand) · `⏰ Daily Check` (hourly, fires at your set IST time) · `⏰ Publish Queue` (every 15 min, publishes when due).

**Premium agents (OpenAI only):**
- **Script** — gpt-4o, pattern-interrupt hook → value beats → payoff → CTA
- **Thumbnail** — `gpt-image-1` (replaces deprecated DALL-E 3)
- **Voiceover** — `tts-1-hd`
- **Video** — FFmpeg stitches Pexels b-roll + voice + burned captions → vertical 1080×1920 MP4 → Supabase Storage

| | v3 |
|---|---|
| Render | **FFmpeg** (self-hosted, $0) |
| Control | **Telegram bot** + scheduled |
| Cost | ~$0.10–0.25/video (OpenAI only) |
| Requires | **self-hosted n8n** with ffmpeg/curl |

> ⚠️ v3 needs **self-hosted n8n** (FFmpeg can't run on n8n Cloud). Run all three schema files (`_v2`, `_v3`) and create a public Supabase Storage bucket named `videos`.

### ⭐⭐⭐ v4 — On-demand + OpenRouter image→video (real AI video, one key)

The newest version is **fully on-demand** (no schedules) and animates **ChatGPT-style AI images into real video clips** using **OpenRouter** (one API key for the LLM, image generation, *and* image-to-video). Full guide: [`config/video_v4_setup.md`](config/video_v4_setup.md).

**You give it a topic OR your own script:**
- _"make a video about morning routines for students"_ → it writes the script
- _"script: Ever wonder why... [your full script]"_ → it uses YOUR words

**Pipeline:** Request → ✍️ Script Writer → 🩺 **Script Doctor** (reviews & improves) → 🔍 SEO → 🎨 AI image per scene → 🎬 OpenRouter image→video → 🎞️ FFmpeg (voice + captions) → ▶️ post → 💬 Telegram.

| | v4 |
|---|---|
| Trigger | **On-demand only** (Telegram) |
| Visuals | **AI image → AI video clip** per scene (OpenRouter) |
| Brains | OpenRouter (one key): LLM + image + video |
| Script QC | dedicated **Script Doctor** reviewer agent |
| Cost | ~$0.6–1.6/video (model-dependent) |
| Requires | self-hosted n8n (FFmpeg) + OpenRouter key |

> The **Script Doctor** is a separate reviewer brain — it polishes the hook/pacing/CTA of either the AI draft or your supplied script, and tells you what it changed.


### 🤝 The Agent Pipeline (mirrors the original 7 agents)

| Agent | Role | Implemented with |
|-------|------|------------------|
| 1. Content Strategy | Picks a trending short-form topic + hook | OpenAI GPT-4o-mini |
| 2. Script Writer | Writes 30-45s narration + caption lines | OpenAI |
| 4. SEO Optimizer | Title, description, tags, hashtags | OpenAI |
| 3. Thumbnail Designer | Generates thumbnail | DALL-E 3 → Imgbb |
| 5. Production | Renders the video (image + TTS voice + captions) | JSON2Video |
| 6. Publishing | Uploads on schedule | YouTube Data API v3 / TikTok Content Posting API |
| 7. Analytics & Strategy | Daily stats + weekly review | OpenAI + Supabase |

### 🎛️ Platform + Posting-Method Toggles

Open the **⚙️ CONTROL PANEL** node and set two toggles:

**`platform`** — which channel:
| Value | Result |
|-------|--------|
| `youtube` | Publish to YouTube only |
| `tiktok` | Publish to TikTok only |
| `both` | Publish to YouTube **and** TikTok |

**`postingMethod`** — how to post:
| Value | Result |
|-------|--------|
| `api` | Native YouTube Data API + TikTok Content Posting API |
| `buffer` | Post via **Buffer** to your connected YouTube/TikTok channels |

Other toggles: `videosPerRun`, `bufferDays` (smart buffer — skip generating if enough queued), `niche`, `videoStyle`, `scheduleHour`, `enabled` (master switch).

### ⏰ Four Schedules (same cadence as the original agent)

| Trigger | Cron | Purpose |
|---------|------|---------|
| Content Gen | `0 6 * * *` | Generate new videos daily (respects buffer) |
| Publish Queue | `*/15 * * * *` | Check renders + publish due videos |
| Analytics | `0 9 * * *` | Collect views/likes/comments |
| Weekly Strategy | `0 8 * * 0` | Review top performers, suggest next topics |

### 🔄 Video Pipeline Flow

```
idea → rendering (JSON2Video) → ready → published → (analytics)
```

### 🚀 Setup
1. Run [`config/video_supabase_schema.sql`](config/video_supabase_schema.sql) in Supabase
2. Set the variables in [`config/video_variables.md`](config/video_variables.md)
   (OpenAI, Imgbb, JSON2Video, Supabase, TikTok token)
3. Create a **YouTube OAuth2** credential and select it in the YouTube nodes
4. Import `workflows/youtube_tiktok_complete.json`
5. Set the **⚙️ CONTROL PANEL** toggle (`youtube` / `tiktok` / `both`)
6. Activate

### ⚠️ Important Notes
- **TikTok:** unaudited apps can only post privately (`SELF_ONLY`). Pass TikTok's app
  audit to publish publicly, then change `privacy_level` in the **🎵 TikTok: Publish** node.
  `PULL_FROM_URL` also requires a verified domain in the TikTok developer portal.
- **Video rendering** uses JSON2Video (built-in TTS voice) — no separate voiceover service
  needed. Swap the voice/style in the **🎬 Agent5: Build Render Job** node.
- **YouTube quota:** uploads cost ~1600 quota units each; the default 10k/day quota allows
  ~6 uploads/day unless you request more.

### 📁 Video Automation Files
```
workflows/youtube_tiktok_v4_ondemand_openrouter.json  ← ⭐⭐⭐ newest (on-demand, OpenRouter image→video)
workflows/youtube_tiktok_v3_ffmpeg_telegram.json      ← Telegram + FFmpeg, OpenAI-only
workflows/youtube_tiktok_v2.json                      ← data-driven, multi-scene (JSON2Video)
workflows/youtube_tiktok_complete.json                ← original version (reference)
config/video_supabase_schema.sql                      ← base Supabase tables
config/video_supabase_schema_v2.sql                   ← v2 extra columns
config/video_supabase_schema_v3.sql                   ← v3 settings table + storage cols
config/video_variables.md                             ← v1/v2 variables guide
config/video_v3_setup.md                              ← v3 Telegram + FFmpeg setup
config/video_v4_setup.md                              ← v4 on-demand + OpenRouter setup
```

---

## 🙏 Credits

The YouTube + TikTok workflow's agent architecture is inspired by
[darkzOGx/youtube-automation-agent](https://github.com/darkzOGx/youtube-automation-agent)
by Haithum Abdelfattah.
