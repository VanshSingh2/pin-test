# v4 — On-Demand Video Bot (OpenRouter Image→Video + Telegram)

The v4 workflow (`workflows/youtube_tiktok_v4_ondemand_openrouter.json`) is **on-demand only** — no schedules. You message the bot a **topic** *or* a **full script**, and it creates the video with **ChatGPT-style AI images animated into video clips** (OpenRouter), then posts immediately.

> ⚠️ **Requires self-hosted n8n** with `ffmpeg`, `ffprobe`, `curl` (Execute Command runs them). n8n Cloud can't run FFmpeg.

---

## How it works

```
Telegram message (topic OR script)
        ↓
🤖 Parse request (topic vs script) + ack reply
        ↓
✍️ Script Writer  →  🩺 Script Doctor (reviews & improves)  →  🔍 SEO
        ↓  (per scene)
🎨 OpenRouter image (gpt-image-1)  →  ☁️ host  →  🎬 OpenRouter image→video
        ↓  (poll until all clips render)
🖥️ FFmpeg: clips + OpenAI TTS voice + burned captions → vertical MP4
        ↓
☁️ Supabase Storage (public URL)  →  ▶️ YouTube / 🎵 TikTok  →  💬 Telegram "Posted!"
```

The **Script Doctor** is a dedicated reviewer brain: it critiques the draft (or your provided script) and improves the hook, pacing, and CTA only where it helps — then tells you what it changed.

---

## The agents (all experts)

| Agent | Job |
|-------|-----|
| 🧠 Request Parser | topic vs script, platform |
| ✍️ Script Writer | writes/structures the scene script |
| 🩺 Script Doctor | reviews & sharpens the script |
| 🔍 SEO | title, description, tags, hashtags |
| 🎨 Image Artist | ChatGPT image per scene (OpenRouter) |
| 🎬 Motion Director | image→video per scene (OpenRouter) |
| 🎞️ Video Editor | FFmpeg assembly + voice + captions |
| 📣 Social Manager | posts to YouTube/TikTok + notifies you |

---

## n8n Variables

| Variable | Value | Notes |
|----------|-------|-------|
| `OPENROUTER_API_KEY` | `sk-or-...` | one key: LLM + image + video |
| `OPENROUTER_LLM_MODEL` | `openai/gpt-4o` | script/SEO brain |
| `OPENROUTER_IMAGE_MODEL` | `openai/gpt-image-1` | ChatGPT images (or `google/gemini-2.5-flash-image`) |
| `OPENROUTER_VIDEO_MODEL` | `google/veo-3.1-lite` | image→video (cheap: `wan`/`ltx`; premium: `google/veo-3.1`, `kling`) |
| `OPENAI_API_KEY` | `sk-...` | voiceover (tts-1-hd) |
| `OPENAI_TTS_VOICE` | `onyx` | optional |
| `IMGBB_API_KEY` | `...` | hosts scene images (gives the public URL the video model needs) |
| `SUPABASE_URL` / `SUPABASE_SERVICE_KEY` | — | final MP4 hosting |
| `TELEGRAM_CHAT_ID` | `123...` | fallback notify chat |
| `VIDEO_SCENES` | `4` | scenes per video (each = 1 AI clip) |
| `VIDEO_CLIP_SECONDS` | `4` | clip length per scene |
| `FFMPEG_FONT` | `/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf` | caption font |

Plus credentials: **Telegram Bot** (`TG_CRED_ID`) and **YouTube OAuth2** (`YT_CRED_ID`). Create a public Supabase Storage bucket named `videos`.

---

## Talk to the bot

| You send | Result |
|----------|--------|
| "make a video about morning routines for students" | writes script → makes → posts |
| "script: Ever wonder why... [your full script]" | uses YOUR script, Doctor polishes, makes → posts |
| "...post to tiktok" / "...both" | chooses platform (default youtube) |

It replies twice: an instant ack, then "Posted!" with the link + what the Script Doctor improved.

---

## 💰 Cost per video (on-demand)

| Item | Approx |
|------|--------|
| LLM (script/SEO) via OpenRouter | ~$0.02 |
| Images (4 × gpt-image-1) | ~$0.15–0.30 |
| Image→video (4 clips, Veo Lite) | ~$0.40–1.20 (model-dependent) |
| TTS (OpenAI) | ~$0.02 |
| FFmpeg / Imgbb / Supabase / Telegram | $0 |
| **Total** | **~$0.6–1.6 per video** |

> Cheapest: set `OPENROUTER_VIDEO_MODEL` to a budget model (Wan/LTX) and reduce `VIDEO_SCENES`.

---

## Notes

- **OpenRouter image-to-video** is async — the workflow polls every 30s (up to ~10 min) until clips are ready.
- The scene image must be a public URL (that's why images are hosted on Imgbb first).
- **TikTok**: unaudited apps post privately (`SELF_ONLY`); flip to `PUBLIC_TO_EVERYONE` after audit.
- If `openai/gpt-image-1` isn't enabled on your OpenRouter account, switch `OPENROUTER_IMAGE_MODEL` to `google/gemini-2.5-flash-image`.
