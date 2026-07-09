# 🎯 Creative Director — Unified Conversational Content Studio (n8n)

One conversational **Telegram bot** that runs an entire multi-platform content studio, backed by **Supabase**. You chat with it; it understands, **confirms**, then creates and posts **images, carousels, or videos/reels** to **Instagram, YouTube, TikTok, Pinterest, or Facebook** — staying **on-brand** because it remembers everything it has made.

> **NEW ⭐ — YouTube → Shorts clipping:** paste a **YouTube link** into the bot and it downloads the video, transcribes it, ranks the most **viral moments** with an LLM, and sends you back ready-to-post **vertical 9:16 Shorts** with burned-in captions. Inspired by [JayWebtech/autoshorts](https://github.com/JayWebtech/autoshorts). *(Approach summarized/rephrased for licensing compliance.)*

| File | What it is |
|------|-----------|
| `workflows/creative_director_v1.json` | ⭐ **THE workflow** — the all-in-one conversational studio (191 nodes) |
| `workflows/creative_director_error_handler.json` | Error workflow — Telegram alert on any hard failure |
| `config/creative_director_setup.md` | Full setup, commands, caveats |
| `config/creative_director_schema.sql` | Supabase schema (run in SQL Editor, safe to re-run) |

---

## ✨ What it does

- 🧠 **Director Brain** (OpenRouter LLM) — conversational, concise, remembers recent turns, proposes **2-3 distinct on-brand angle options**, and **always confirms** before spending credits.
- 🎨 **Master Creative Brief** — one brief acts as five specialists (Trend Strategist, Script Writer, Script Doctor, Art Director, Music Supervisor) and now enforces a **variety mandate + anti-repetition** (rotating hook angle + creative seed) so you don't get the same output twice.
- 🖼️ **Images / carousels / videos** — AI images, AI-motion video, Pexels stock b-roll, or scraped Pinterest clips.
- 📌 **Brand memory** — a rolling *brand bible* keeps every new post visually and tonally consistent.
- ✅ **Human-in-the-loop approval gates** — approve/revise the script, the AI images, the clips, and the final post from Telegram.
- ⏰ **Scheduling** — post now or queue for a set IST time; a 15-min trigger publishes due posts.
- 📊 **Analytics loop** — every 6h it scores Buffer-posted performance and feeds the winners back into the brief.
- 🎬 **YouTube clipping** (new) — paste a link, get back ranked vertical Shorts.

---

## 🎬 YouTube → Shorts clipping (AutoShorts-style)

Send the bot a YouTube URL (optionally say "into 5 clips"). It runs this pipeline:

```
YouTube link (Telegram)
  → ⬇️ yt-dlp download + audio extract (ffmpeg)
  → 🎙️ Transcribe (OpenAI Whisper, word/segment timestamps)
  → 🧠 Rank viral moments (LLM: DeepSeek via OpenRouter) → start/end + hook + score
  → 🎞️ FFmpeg: cut each moment, center-crop to vertical 1080×1920, burn synced captions
  → 💬 sends each 9:16 Short back to you in Telegram (ranked, with a virality score)
```

- **Default:** 3 clips per video. Say e.g. *"clip this into 5"* to change it (max 8).
- **Clip length:** 15–60s each, snapped to sentence boundaries, non-overlapping.
- **Model:** DeepSeek by default (cheap + strong reasoning); override with the `CLIP_LLM_MODEL` variable (any OpenRouter model).
- **Requires** `yt-dlp` **and** `ffmpeg`/`ffprobe` on the self-hosted n8n host, plus `OPENAI_API_KEY` (Whisper) and `OPENROUTER_API_KEY`.

> ⚠️ OpenAI Whisper caps uploaded audio at **25 MB** (~90 min at the 32 kbps mono the workflow extracts). For longer videos, swap in a chunked or Deepgram-based transcription step.

---

## 💬 Talk to it (examples)

```
set niche to indie coffee shops
use warm film-grain cinematic style
use pexels for video clips
make a reel about 3 latte art tricks, post via buffer
→ (bot proposes 2-3 angles) → yes

make a 6-slide carousel on cold brew myths
post an image about our new menu
schedule daily at 7pm

https://youtu.be/XXXX          ← auto-clips into Shorts
clip this into 5: https://youtu.be/XXXX
```

---

## 🚀 Setup (short version)

1. **Supabase** — run `config/creative_director_schema.sql`, create a public Storage bucket named `videos`.
2. **n8n Variables** — `OPENROUTER_API_KEY`, `OPENROUTER_LLM_MODEL`, `OPENAI_API_KEY`, `IMGBB_API_KEY`, `PEXELS_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `BUFFER_ACCESS_TOKEN`, `BUFFER_PROFILE_ID_*`, `PINTEREST_ACCESS_TOKEN`, `PINTEREST_BOARD_ID_LIFESTYLE`, `TELEGRAM_CHAT_ID`, `FFMPEG_FONT`, `OPENAI_TTS_VOICE`, and (optional) `CLIP_LLM_MODEL`.
3. **Credentials** — Telegram Bot (`TG_CRED_ID`) and YouTube OAuth2 (`YT_CRED_ID`).
4. **Host** — self-hosted n8n with `ffmpeg`, `ffprobe`, `yt-dlp`, and `curl` on PATH (required for video render + clipping).
5. Import `creative_director_error_handler.json`, activate it, and set `creative_director_v1.json` → `settings.errorWorkflow` to its workflow id.
6. Import `creative_director_v1.json`, set your defaults by chatting, and **activate**.

Full guide, all chat commands, and honest caveats: **[`config/creative_director_setup.md`](config/creative_director_setup.md)**.

---

## 🛠️ Tech stack

| Component | Tech |
|-----------|------|
| Automation | n8n (single workflow, self-hosted) |
| Database / storage | Supabase (Postgres + Storage) |
| LLM / images | OpenRouter (LLM, image, image→video) |
| Transcription / TTS | OpenAI (Whisper, tts-1-hd) |
| Clip ranking | DeepSeek via OpenRouter (`CLIP_LLM_MODEL`) |
| Video / clipping | yt-dlp + FFmpeg (vertical 9:16, burned captions) |
| Posting | Buffer (GraphQL) · YouTube Data API · Pinterest API v5 |

---

## ⚠️ Honest caveats

- **Pinterest clips/images** are **scraped** (no official download API) — fragile and repost-risky. **Pexels is the safe default.**
- **AI video** (`video_route=ai`) animates AI stills via an image→video model + FFmpeg; the generative-video provider endpoint must be wired to a real service.
- **Buffer** posts one channel per call; carousels post as separate media.
- **TikTok / Instagram via native API** aren't supported here (require app review / Graph API) — those fall back to Buffer.
- **Whisper 25 MB limit** applies to the YouTube clipping transcription step.

---

## 🙏 Credits

- YouTube → Shorts clipping inspired by **[JayWebtech/autoshorts](https://github.com/JayWebtech/autoshorts)** by Adamu Jethro (transcribe → AI viral-moment ranking → FFmpeg 9:16 auto-crop with captions). Reimplemented for n8n; approach summarized/rephrased for licensing compliance.
