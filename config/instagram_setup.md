# Instagram AI — Conversational Manager (Setup)

`workflows/instagram_v1_telegram.json` is a **chat-driven** Instagram bot. You talk to it on Telegram; it understands you, **confirms**, then creates a **carousel**, **image**, or **Reel (AI video)** — all matched to a **niche** and a **visual style** you set per chat.

> ⚠️ Reels need **self-hosted n8n** with `ffmpeg`/`curl`. Carousels & images work on any n8n.

---

## What makes it intelligent

- **🧠 Manager Brain** (OpenRouter LLM) reads your message + your saved niche/style + any pending action, replies naturally, and only creates after you **confirm**.
- **Niche** + **Style** are remembered per chat (`ig_state` table). Every script, image, slide, and Reel is generated to fit them.
- **Style examples:** `Disney Pixar 3D`, `animated stick figure`, `cinematic realism`, `flat vector illustration`, `anime`, `claymation`.

---

## Setup

1. **Supabase:** run `config/instagram_supabase_schema.sql` (adds `ig_state`, `ig_queue`). Reuse the public `videos` Storage bucket (from the video setup) for Reels.
2. **n8n Variables:**

| Variable | Notes |
|----------|-------|
| `OPENROUTER_API_KEY` | LLM + image + image→video |
| `OPENROUTER_LLM_MODEL` | default `openai/gpt-4o` |
| `OPENROUTER_IMAGE_MODEL` | default `openai/gpt-image-1` |
| `OPENROUTER_VIDEO_MODEL` | default `google/veo-3.1-lite` (Reels) |
| `OPENAI_API_KEY` | Reel voiceover (tts-1-hd) |
| `IMGBB_API_KEY` | hosts images |
| `SUPABASE_URL` / `SUPABASE_SERVICE_KEY` | DB + Reel storage |
| `BUFFER_ACCESS_TOKEN` | Buffer posting |
| `BUFFER_PROFILE_ID_INSTAGRAM` | your IG profile id in Buffer |
| `VIDEO_CLIP_SECONDS` | Reel clip length per scene (default 4) |
| `FFMPEG_FONT` | caption font path |

3. **Credentials:** Telegram Bot (`TG_CRED_ID`). Connect your Instagram account inside Buffer.
4. Import the workflow and activate.

---

## Talk to it (examples)

| You say | It does |
|---------|---------|
| "set my niche to budget travel for students" | saves niche |
| "use Disney Pixar 3D style" | saves style |
| "make a 6-slide carousel about packing hacks" | proposes → you say "yes" → builds + posts carousel |
| "post an image about hidden European towns" | proposes → confirm → image post |
| "make a reel: 5 cheap countries to visit" | proposes → confirm → AI Reel |
| "script: Most students overpay for flights because..." | uses YOUR script for the Reel |
| "status" / "cancel" | info / cancels pending |

It always **confirms before creating** (reply "yes"/"go").

---

## Posting via Buffer — honest note

Buffer's classic API posts a **single media** per update, so:
- **Image** & **Reel** post cleanly via Buffer.
- **Carousel:** Buffer gets the first slide; the bot sends you **all slide URLs** in Telegram and stores them in `ig_queue`. For a true multi-image IG carousel, either post the slides in Buffer's dashboard, or switch this node to the **Instagram Graph API** (create child containers → carousel container → publish), which needs an IG Business account + Facebook app token.

---

## Cost per item (approx)

| Type | Cost |
|------|------|
| Image | ~$0.05–0.10 |
| Carousel (6 slides) | ~$0.30–0.60 |
| Reel (4 AI clips) | ~$0.6–1.6 (video model dependent) |

LLM/captions are a few cents; Imgbb/Supabase/Telegram are free.
