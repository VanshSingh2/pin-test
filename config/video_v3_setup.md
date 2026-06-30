# YouTube + TikTok v3 — FFmpeg + Telegram Bot Setup

The v3 workflow (`workflows/youtube_tiktok_v3_ffmpeg_telegram.json`) renders videos with **FFmpeg** (no JSON2Video) and is **controlled from Telegram**. It uses **OpenAI only** for the brains (gpt-4o scripts, gpt-image-1 thumbnails, tts-1-hd voiceover).

> ⚠️ **Requires self-hosted n8n** with `ffmpeg`, `ffprobe`, and `curl` installed (the Execute Command node runs them). n8n Cloud cannot run FFmpeg.

---

## 1. Prerequisites on your n8n server

```bash
# Debian/Ubuntu example
apt-get update && apt-get install -y ffmpeg curl fonts-dejavu
ffmpeg -version   # confirm it works
```
If you run n8n in Docker, use an image that includes ffmpeg, or install it in your Dockerfile.

---

## 2. n8n Variables (Settings → Variables)

| Variable | Value | Notes |
|----------|-------|-------|
| `OPENAI_API_KEY` | `sk-...` | scripts, gpt-image-1, tts-1-hd |
| `PEXELS_API_KEY` | `...` | free b-roll video |
| `IMGBB_API_KEY` | `...` | hosts the thumbnail |
| `SUPABASE_URL` | `https://xxx.supabase.co` | — |
| `SUPABASE_SERVICE_KEY` | `eyJ...` | service_role key |
| `TIKTOK_ACCESS_TOKEN` | `act...` | only for TikTok |
| `TELEGRAM_CHAT_ID` | `123456789` | your chat id (daily notifications) |
| `OPENAI_TTS_VOICE` | `onyx` | optional: alloy/echo/fable/onyx/nova/shimmer |
| `FFMPEG_FONT` | `/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf` | optional override |
| `BEST_TIMES_YOUTUBE` | `15:00,18:00,20:00` | optional (IST) |
| `BEST_TIMES_TIKTOK` | `12:00,19:00,21:00` | optional (IST) |

---

## 3. Telegram bot

1. Open [@BotFather](https://t.me/BotFather) → `/newbot` → copy the token
2. n8n → Credentials → New → **Telegram API** → paste token → name it `Telegram Bot`
3. Open the workflow and select that credential in every Telegram node (placeholder `TG_CRED_ID`)
4. Get your chat id: message your bot, then visit
   `https://api.telegram.org/bot<TOKEN>/getUpdates` → copy `chat.id` → set `TELEGRAM_CHAT_ID`

---

## 4. YouTube + Supabase Storage

- **YouTube OAuth2** credential (YouTube Data API v3) — select it in the YouTube nodes (`YT_CRED_ID`)
- In Supabase → **Storage → New bucket → name `videos` → Public ON** (rendered MP4s go here so YouTube/TikTok can fetch a public URL)
- Run the SQL files in order: `video_supabase_schema.sql` → `_v2.sql` → `_v3.sql`

---

## 5. How to talk to the bot

Just message your bot in plain English (times are **IST**):

| You say | What happens |
|---------|--------------|
| "make a video about morning routines, post at best time" | Generates + schedules at next best slot |
| "create a short on saving money, post tomorrow 7pm" | Generates + schedules for 19:00 IST tomorrow |
| "set daily posting time to 18:30" | Auto-generates & posts daily at 18:30 IST |
| "set platform to both" | Default publishing → YouTube + TikTok |
| "status" | Shows the last 10 items in the queue |

It replies when the video is **ready/scheduled** and again when it's **published**.

---

## 6. How it works (flow)

```
Telegram message ── or ── Daily Check (hourly, fires at your set time)
        ↓
🧠 Parse intent (gpt-4o)
        ↓
🧭 Strategy → ✍️ Script (hook→beats→payoff→CTA) → 🔍 SEO → 🎨 Thumbnail (gpt-image-1)
        ↓
🎬 Per scene: Pexels b-roll + OpenAI TTS voice + burned captions
        ↓
🖥️ FFmpeg stitches → vertical 1080x1920 MP4
        ↓
☁️ Upload to Supabase Storage (public URL)
        ↓
💾 Queue as "ready" with scheduled_time
        ↓
⏰ Publish Queue (every 15 min) → YouTube / TikTok → 💬 Telegram "Published!"
```

---

## 7. Cost (OpenAI only + free services)

| Item | Cost |
|------|------|
| FFmpeg rendering | **$0** (your server) |
| Pexels / Imgbb / Supabase / Telegram | **$0** (free tiers) |
| OpenAI per video (gpt-4o + gpt-image-1 + tts-1-hd) | ~$0.10–0.25 |

So roughly **a few dollars a month** for daily videos — no JSON2Video subscription.

---

## 8. Notes & limits

- **TikTok**: unaudited apps post privately (`SELF_ONLY`). After TikTok approves your app, change `privacy_level` to `PUBLIC_TO_EVERYONE` in the **🎵 TikTok: Publish** node. `PULL_FROM_URL` needs a verified domain — Supabase public Storage URLs usually work once your domain is added.
- **Fonts**: if captions don't render, fix `FFMPEG_FONT` to a font that exists on your server.
- **YouTube quota**: ~6 uploads/day on the default quota.
- **Render time**: a 5-scene short typically renders in ~30–90s depending on your server.
