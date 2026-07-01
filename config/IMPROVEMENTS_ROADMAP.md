# 📈 Improvements Roadmap — thinking like a Dev + Social Specialist + Manager

This is an honest review of where the project is strong, what was just improved, and what would take it from "good" to "outstanding". Nothing here is required to use the workflows — it's a prioritized backlog.

---

## ✅ Just shipped (quality upgrades)
- **Brief is now specialist-grade** and acts as five specialists in one pass: **Trend Strategist, Script Writer, Script Doctor (self-review), Art Director, Music Supervisor**.
- **Brand overlay + background music** (FFmpeg engine): set `BRAND_LOGO_URL` (watermark, top-right) and `BRAND_MUSIC_URL` (ducked under the voiceover) as n8n variables — optional, skipped if unset.
- **Brand + style are locked**: they no longer drift between posts — only change when you explicitly change the style. Always confirms before creating.
- **Conversation memory = last 20 turns** (stored in `cd_state.history`).
- **"Show settings" + idea suggestions**: ask the bot what's set, or for ideas, anytime.

---

## 🔥 High impact (recommended next)

### 1. Preview-before-render approval (saves money + guarantees quality)
Right now confirm → it generates and posts. Better: after the **cheap** steps (script + thumbnail), send a **preview to Telegram with ✅ / ✏️ / ❌ buttons** and only render the **expensive** video on approval. Cuts wasted AI-video spend and lets you tweak.
*How: Telegram inline keyboard + an n8n `Wait` (resume-on-webhook) node.*

### 2. Best-time scheduling (not just instant posting)
Add optional "post at 7pm" / "post at best time". Store `scheduled_time`, and a 15-min publish-queue trigger posts when due. Best-time slots per platform (from analytics or sensible defaults). *Specialist note: consistent optimal-time posting is one of the biggest growth levers.*

### 3. Analytics feedback loop (close the loop)
Pull each post's views/likes/saves into `cd_memory`, then feed the **top performers** back into the Brief so the bot doubles down on what works. We log creations but don't yet read performance back.

### 4. A/B variants
Generate **2 titles + 2 thumbnails**, auto-pick (or ask you), and track which wins over time.

---

## 🎯 Quality & brand polish
- **Logo/watermark overlay** in FFmpeg for consistent branding.
- **First-comment hashtags** (IG/Pinterest) instead of stuffing the caption.
- **Real word-level captions** (Whisper timestamps) for snappier subtitles vs current per-scene text.
- **Safe-zones**: keep captions clear of the TikTok/Reels UI (right-side icons, bottom bar).
- **Music bed**: royalty-free track under the voiceover (ducking).
- **Multi-format repurpose**: one master brief → a Reel + a carousel + a pin in one go.

---

## 🛠️ Engineering hardening
- **Failure alerts**: if a step fails, Telegram-notify with the error + which post (currently `neverError` can silently pass weak output downstream).
- **Retries/backoff** on transient API errors (OpenRouter/Buffer/Pinterest).
- **Cost guardrails**: per-day spend cap + a confirmation when a job will be expensive (e.g. AI video).
- **Idempotency**: dedupe topics against `cd_memory` so you don't repeat content.
- **Rate-limit awareness**: YouTube quota (~6 uploads/day), Pinterest trial visibility, TikTok audit state.
- **Secrets hygiene**: keep all keys in n8n Variables/credentials (already the pattern) and rotate periodically.

---

## ⚠️ Known caveats (by design / external limits)
- **Pinterest clips/images are scraped** (no official API) — can break, may breach ToS, and are others' copyright. **Pexels/AI are the safe defaults.**
- **Buffer carousels**: classic API posts one media; true IG carousels need the Instagram Graph API.
- **TikTok via API** posts privately until your app passes audit.
- **AI video** in the Director uses AI stills + clips via FFmpeg; for true generative motion use `youtube_tiktok_v4_ondemand_openrouter.json` (selectable video model).

---

## Suggested order to build next
1. Preview-before-render approval (cost + quality)
2. Best-time scheduling
3. Analytics feedback loop
4. Failure alerts + retries
5. Music + watermark + first-comment

Tell me which and I'll implement it.
