# 🤖 Pinterest AI Automation — All-in-One n8n Workflow

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
