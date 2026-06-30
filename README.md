# 🤖 Pinterest AI Automation Team — n8n Workflows

A fully automated Pinterest content pipeline powered by a smart team of AI agents built in n8n. The system runs on a schedule, discovers trends, generates images with DALL-E 3, writes SEO-optimised copy, and posts directly to Pinterest (with Buffer as fallback) — all hands-free.

---

## 🏗️ Architecture Overview

```
⏰ Schedule (Every 4 Hours)
        │
        ▼
🧠 ORCHESTRATOR (Main Brain)
        │
        ├── Queue < 3 ready? → Run Content Pipeline:
        │       │
        │       ├─ 📈 Trend Finder      → Finds 10 trending topics (OpenAI)
        │       ├─ 💡 Idea Generator    → 5 pin ideas per trend (OpenAI)
        │       ├─ ✍️  Prompt Generator  → DALL-E 3 image prompts (OpenAI)
        │       ├─ 🎨 Thumbnail Designer → Generates images (DALL-E 3 → Imgbb)
        │       └─ 📝 Content Creator   → SEO title + desc + hashtags (OpenAI)
        │
        └── Items ready? → 📮 Posting Manager
                │
                ├─ Try: Pinterest API v5
                └─ Fallback: Buffer API

⏰ Daily 9 AM → 📊 Analytics Tracker → Pinterest Analytics API → Google Sheets
```

---

## 👥 The AI Team

| Agent | File | Role | Trigger |
|-------|------|------|---------|
| 🧠 Orchestrator | `00_orchestrator.json` | Main brain, decides what to run | Every 4 hours |
| 📈 Trend Finder | `01_trend_finder.json` | Finds trending topics for girls content | Called by Orchestrator |
| 💡 Idea Generator | `02_idea_generator.json` | Generates 5 pin ideas per trend | Called by Orchestrator |
| ✍️ Prompt Generator | `03_prompt_generator.json` | Creates DALL-E 3 image prompts | Called by Orchestrator |
| 🎨 Thumbnail Designer | `04_thumbnail_designer.json` | Generates & hosts images | Called by Orchestrator |
| 📝 Content Creator | `05_content_creator.json` | Writes pin titles, descriptions, hashtags | Called by Orchestrator |
| 📮 Posting Manager | `06_posting_manager.json` | Posts to Pinterest API → Buffer fallback | Called by Orchestrator |
| 📊 Analytics Tracker | `07_analytics_tracker.json` | Tracks pin performance daily | Daily at 9 AM |

---

## 📋 Prerequisites

- n8n (self-hosted or n8n Cloud)
- OpenAI account with API access (GPT-4o-mini + DALL-E 3)
- Pinterest Developer App (Standard Access for public pins)
- Buffer account (optional, as posting fallback)
- Google account with Google Sheets API enabled
- Pexels API key (free, for image fallback)
- Imgbb API key (free, for image hosting)

---

## 🚀 Setup Guide

### Step 1 — Create the Google Sheet

1. Create a new Google Sheet at [sheets.google.com](https://sheets.google.com)
2. Add **5 tabs** with these exact names:
   - `Trends`
   - `Content_Queue`
   - `Analytics`
   - `Config`
   - `Logs`
3. Add column headers to each tab as defined in [`config/google_sheets_schema.md`](config/google_sheets_schema.md)
4. Copy the Sheet ID from the URL:
   `https://docs.google.com/spreadsheets/d/`**`THIS_IS_YOUR_SHEET_ID`**`/edit`

### Step 2 — Set Up Credentials in n8n

Follow [`config/credentials_guide.md`](config/credentials_guide.md) to create:

- **Google Sheets OAuth2** credential (named exactly: `Google Sheets OAuth`)
- Store all API keys as **n8n Variables** (Settings → Variables)

### Step 3 — Set n8n Variables

Go to **n8n → Settings → Variables** and add all variables from [`config/n8n_variables.md`](config/n8n_variables.md):

```
OPENAI_API_KEY          = sk-...
PINTEREST_ACCESS_TOKEN  = pina_...
BUFFER_ACCESS_TOKEN     = ...
PEXELS_API_KEY          = ...
IMGBB_API_KEY           = ...
GOOGLE_SHEET_ID         = 1BxiM...
PINTEREST_BOARD_ID_FASHION    = ...
PINTEREST_BOARD_ID_BEAUTY     = ...
PINTEREST_BOARD_ID_LIFESTYLE  = ...
PINTEREST_BOARD_ID_QUOTES     = ...
BUFFER_PROFILE_ID       = ...
```
> ⚠️ Leave the `WF_*` variables empty for now — you will fill them in Step 5.

### Step 4 — Import Workflows in Order

In n8n go to **Workflows → Import from file** and import in this exact order:

1. `workflows/01_trend_finder.json`
2. `workflows/02_idea_generator.json`
3. `workflows/03_prompt_generator.json`
4. `workflows/04_thumbnail_designer.json`
5. `workflows/05_content_creator.json`
6. `workflows/06_posting_manager.json`
7. `workflows/07_analytics_tracker.json`
8. `workflows/00_orchestrator.json` ← **import last**

After importing each workflow, **note the numeric ID** shown in the URL:
`https://your-n8n.com/workflow/`**`123`** ← this is the ID

### Step 5 — Set Sub-Workflow ID Variables

Go back to **Settings → Variables** and fill in the IDs from Step 4:

```
WF_TREND_FINDER       = (ID of 01_trend_finder)
WF_IDEA_GENERATOR     = (ID of 02_idea_generator)
WF_PROMPT_GENERATOR   = (ID of 03_prompt_generator)
WF_THUMBNAIL_DESIGNER = (ID of 04_thumbnail_designer)
WF_CONTENT_CREATOR    = (ID of 05_content_creator)
WF_POSTING_MANAGER    = (ID of 06_posting_manager)
```

### Step 6 — Update Google Sheets Credential ID

In each workflow, the Google Sheets nodes reference credential ID `GSHEETS_CRED_ID`.
After importing, open each workflow and re-select your **Google Sheets OAuth** credential in every Google Sheets node (n8n will prompt you).

### Step 7 — Activate Workflows

Activate all workflows **except** the Orchestrator first:
1. Activate workflows 01–07 (set Active = ON)
2. Activate `00_orchestrator.json` last

The system will now run automatically every 4 hours!

---


## 🔄 Content Pipeline Flow

```
Google Sheets: Content_Queue — Status Lifecycle
─────────────────────────────────────────────────
new_idea          ← Idea Generator saves ideas
    │
    ▼
has_prompt        ← Prompt Generator adds DALL-E prompt
    │
    ▼
has_image         ← Thumbnail Designer adds hosted image URL
    │
    ▼
ready_to_post     ← Content Creator adds title/desc/hashtags
    │
    ▼
posted            ← Posting Manager: Pinterest API success
posted_buffer     ← Posting Manager: Buffer fallback success
failed            ← Posting Manager: both APIs failed
```

---

## 📁 File Structure

```
pin-test/
├── README.md                        ← This file
├── workflows/
│   ├── 00_orchestrator.json         ← Main brain (import last)
│   ├── 01_trend_finder.json         ← Trend discovery agent
│   ├── 02_idea_generator.json       ← Pin idea generator
│   ├── 03_prompt_generator.json     ← DALL-E prompt creator
│   ├── 04_thumbnail_designer.json   ← Image generation & hosting
│   ├── 05_content_creator.json      ← SEO copy writer
│   ├── 06_posting_manager.json      ← Pinterest + Buffer poster
│   └── 07_analytics_tracker.json   ← Daily analytics fetcher
└── config/
    ├── google_sheets_schema.md      ← Full Sheets column definitions
    ├── n8n_variables.md             ← All variables to set in n8n
    └── credentials_guide.md        ← How to get each API key/credential
```

---

## ⚙️ Configuration

### Posting Frequency
Edit the Orchestrator's Schedule Trigger node:
- Every 4 hours (default): `{ "field": "hours", "hoursInterval": 4 }`
- Daily: `{ "field": "hours", "hoursInterval": 24 }`
- Every 6 hours: `{ "field": "hours", "hoursInterval": 6 }`

### Content Volume
In `00_orchestrator.json` Code node **"Analyze Pipeline State"**, change:
```js
needsContentPipeline: readyToPost < 3,  // change 3 to desired buffer size
```

In `06_posting_manager.json` Google Sheets read node, change `limit` from `2` to post more per run.

### Pinterest Boards
Set board IDs per category in n8n Variables. The Content Creator automatically assigns:
- `fashion` → `PINTEREST_BOARD_ID_FASHION`
- `beauty` → `PINTEREST_BOARD_ID_BEAUTY`
- `lifestyle / diy / wellness / food` → `PINTEREST_BOARD_ID_LIFESTYLE`
- `quotes` → `PINTEREST_BOARD_ID_QUOTES`

---

## 🔧 API Rate Limits

| Service | Limit | Notes |
|---------|-------|-------|
| OpenAI GPT-4o-mini | 500 RPM | Well within limits |
| OpenAI DALL-E 3 | 5 images/min | Workflow processes 3 at a time |
| Pinterest API (Trial) | 1,000 req/day | Pins only visible to you |
| Pinterest API (Standard) | 100 req/sec | Request Standard Access for public pins |
| Buffer Free | 10 posts queued | Upgrade for more |
| Pexels | 200 req/hour | Free fallback images |
| Imgbb | Unlimited | Free image hosting |

---

## ❗ Pinterest Trial vs Standard Access

> **Important:** When you first get Pinterest API access, you are on **Trial Access**.
> Pins created via Trial Access are **only visible to you** — they won't appear publicly.
>
> To make pins public, go to [developers.pinterest.com](https://developers.pinterest.com),
> open your App, and **Request Standard Access**. Approval typically takes a few days.
>
> The workflow works perfectly on Trial Access for testing — pins are created successfully,
> just not publicly visible until you have Standard Access.

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `WF_TREND_FINDER` not found | Set the variable in Settings → Variables after importing workflows |
| Google Sheets auth error | Re-select the Google Sheets credential in each Sheets node |
| DALL-E images not saving | Check `IMGBB_API_KEY` is valid; Pexels fallback will activate |
| Pinterest returns 401 | Regenerate your access token at developers.pinterest.com |
| Pins not publicly visible | You're on Trial Access — request Standard Access |
| Buffer posts not appearing | Check `BUFFER_PROFILE_ID` matches your Pinterest profile in Buffer |
| OpenAI JSON parse error | Handled automatically — Code nodes have try/catch fallback parsing |

---

## 💡 Tips for Girls Content Niche

- **Best posting times:** 8–11 PM, 2–4 PM (when your audience is active)
- **Top categories that perform well:** outfit ideas, motivational quotes, skincare routines, aesthetic room inspo, study tips, self-care rituals
- **Image ratio:** 2:3 (1000×1500px) — already configured in DALL-E prompts
- **Hashtag strategy:** Mix broad (#fashion) + niche (#cottagecoreoutfit) + seasonal tags
- **Pin frequency:** 3–5 pins/day is optimal for algorithm growth

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Automation | n8n |
| AI Text | OpenAI GPT-4o-mini |
| AI Images | OpenAI DALL-E 3 |
| Image Hosting | Imgbb (free) |
| Image Fallback | Pexels API (free) |
| Database | Google Sheets |
| Primary Posting | Pinterest API v5 |
| Fallback Posting | Buffer API |

---

*Built with ❤️ — fully automated Pinterest content machine for girls niche*
