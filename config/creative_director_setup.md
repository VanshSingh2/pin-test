# 🎯 Creative Director — Unified Conversational Studio

`workflows/creative_director_v1.json` is **one Telegram bot for everything**: you chat, it understands, **confirms**, then creates and posts an **image, carousel, or video/reel** to **Instagram, YouTube, TikTok, or Pinterest** — always **on-brand** because it remembers what you've made.

> Reels/Shorts need **self-hosted n8n** (FFmpeg). Images, carousels & pins run anywhere.

---

## What it does (everything you asked for)

| Capability | How |
|------------|-----|
| **Pick what to make** | "make a carousel / image / reel about X" → it sets `content_type` |
| **Pick the style** | "use Disney Pixar 3D" / "moody cinematic" → applied to every asset |
| **AI visuals OR Pinterest** | `visual_source = ai` (AI images) · `ai_video` (**AI motion clips via image→video model**) · `pexels` · `pinterest` — Pinterest gives **scraped clips** for video and **scraped images** for image/carousel |
| **Render engine (video)** | `render_engine = ffmpeg` (fast, default) · `hyperframes` (HTML motion graphics — nicer captions/transitions, needs Node 22 + Chrome libs on the host; see `hyperframes_vps_setup.md`) |
| **Pinterest-style search** | "find clips like dark moody gym" → sets `reference`, searches Pinterest/Pexels with it |
| **Choose the AI model** | "use flux for images" / set `image_model` (any OpenRouter image model) |
| **Give a script or topic** | paste a script, or just a topic — it writes one |
| **Choose posting** | "post via buffer" or "post via api" — or it **asks you** during the proposal |
| **Brand consistency** | a **brand bible** is saved & reused so new posts match past ones |
| **Master brief** | every job first generates a **master creative brief** (style bible) reused for image **and** video |
| **Always confirms** | proposes a plan, waits for your **"yes"** before spending credits |

---

## How a request flows

```
You (Telegram) → 🧠 Director Brain (reads niche/style/settings + BRAND BIBLE)
   → proposes a plan → you say "yes"
   → 🎯 Master Creative Brief (style bible + caption + image prompts + scenes)
   → 🧠 Brand memory updated (stays consistent next time)
   → content type? ─ image ─→ AI image
                   ├ carousel → AI slides
                   └ video ──→ per scene: AI image / Pexels clip / Pinterest clip → FFmpeg
   → posting? ─ buffer ─→ Buffer
              └ api ────→ YouTube upload (video) / Pinterest API (image)
   → 💬 "Posted!" + logged to brand memory
```

---

## Talk to it (examples)

```
set niche to indie coffee shops
use warm film-grain cinematic style
use pinterest for clips
reference style: latte art slow motion
make a reel about 3 latte art tricks, post via buffer
→ (bot proposes the plan) → yes
```
or simply: `make a 6-slide carousel on cold brew myths` · `post an image about our new menu` · `make a youtube short: why beans matter` (paste a full script anytime).

---

## Setup

1. Run `config/creative_director_schema.sql` (adds `cd_state`, `cd_memory`, `cd_scheduled` + the scheduler/analytics columns — safe to re-run). Create the public `videos` Storage bucket.
2. n8n Variables (mostly shared with the other workflows):
   `OPENROUTER_API_KEY`, `OPENROUTER_LLM_MODEL`, `OPENAI_API_KEY` (TTS), `IMGBB_API_KEY`, `PEXELS_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `BUFFER_ACCESS_TOKEN`, `BUFFER_PROFILE_ID_INSTAGRAM/YOUTUBE/TIKTOK/PINTEREST`, `PINTEREST_ACCESS_TOKEN`, `PINTEREST_BOARD_ID_LIFESTYLE`, `TELEGRAM_CHAT_ID`, `FFMPEG_FONT`, `OPENAI_TTS_VOICE`.
3. Credentials: **Telegram Bot** (`TG_CRED_ID`), **YouTube OAuth2** (`YT_CRED_ID`).
4. Import `workflows/creative_director_error_handler.json`, activate it, then set `creative_director_v1.json`'s `settings.errorWorkflow` to its workflow ID (n8n shows the ID in the URL after import) so any hard failure gets a Telegram alert.

---

## Defaults you can change by chatting

`platforms` (comma list of instagram·youtube·tiktok·pinterest·facebook — "both" is gone, just name the platforms) · `content_type` (image·carousel·video — validated against each platform's supported types; pinterest has no carousel, tiktok/youtube are video-only) · `visual_source` for image/carousel (ai·pinterest) · `video_route` for video (ai·pinterest·hyperframes — replaces the old visual_source+render_engine combo) · `image_model` (default `openai/gpt-image-1`) · `video_model` · `posting_method` (buffer·api — API posting only works natively for youtube/pinterest; any other platform requested via API automatically falls back to Buffer with a heads-up message) · `post_mode` (now·scheduled) · `post_time` (IST HH:MM) · `style` · `niche` · `reference`.

**Buffer setup (current GraphQL API, not the deprecated legacy REST API):**
1. Generate an API key at `https://publish.buffer.com/settings/api` → set it as `BUFFER_ACCESS_TOKEN` (used as a Bearer token now, not a query-string access_token).
2. Connect each platform you want to post to inside Buffer's own dashboard (buffer.com → Connect a channel) — a channel only exists once it's connected there.
3. Get your organization id and each connected channel's real id/service by POSTing to `https://api.buffer.com` with header `Authorization: Bearer <your key>` and body `{"query":"query { account { organizations { id } } channels(input: { organizationId: \"YOUR_ORG_ID\" }) { id service } }"}` (two calls, or nest them). Match each returned `service` (instagram/youtube/tiktok/pinterest/facebook) to its `id`, and set that as `BUFFER_PROFILE_ID_INSTAGRAM` etc.
4. Note: `createPost` posts to one channel per call — if you post to multiple platforms via Buffer in the same request, the workflow now sends one GraphQL call per platform (each logs and notifies independently).

**API posting caveat:** Instagram/TikTok have no usable native posting API here (Instagram needs a Graph API container→publish flow with a business token; TikTok needs app review). Requesting `posting_method=api` for those platforms posts via Buffer instead and tells you so — it no longer silently misroutes.

**Failed posts:** if generation succeeds but the actual publish call fails (bad token, rate limit, etc.), you get a "⚠️ posting FAILED" message instead of a false "✅ posted!" — check credentials and retry manually.

---

## Honest caveats
- **Pinterest clips**: no official download API — the bot **scrapes** the search page (can break, may breach ToS, clips are others' copyright). **Pexels is the safe default.**
- **Buffer carousels**: Buffer's classic API posts a single media; the bot stores all slide URLs. For true multi-image IG carousels use the Instagram Graph API.
- **AI video**: this Director animates AI **stills** + clips via FFmpeg. For true generative **image→video** (Veo/Kling/Wan), use `youtube_tiktok_v4_ondemand_openrouter.json` (it already selects the video model).
- **TikTok via API** posts privately until your app is audited.


---

## ✅ QA / Approval gates (human-in-the-loop)

The Director now delegates and **pauses for your approval** at each key step (Telegram send-and-wait — you tap ✅/❌). Nothing proceeds or posts without you.

| Gate | When it fires | Why |
|------|---------------|-----|
| 📝 **Approve: Script** | After the master brief (script/scenes/caption) | Review the script before anything is generated |
| 🎨 **Approve: AI Images** | `visual_source=ai_video`, after scene images are generated, **before** the paid image→video model | Don't spend on AI video for images you don't like |
| 📌 **Approve: Pinterest Clips** | `visual_source=pinterest`, after clips are found | Confirm the scraped clips fit before rendering |
| 🧑‍⚖️ **Approve: Post** | After the video/carousel/image is rendered (FFmpeg **or** HyperFrames) | Final sign-off before it publishes |

Reject at any gate → the Director now asks **what to change** and **revises** (it no longer just stops). Approve → it continues. The Director stays as the orchestrator/relay between you and the agents.

> These use n8n's Telegram *Send and Wait for Response*, so the workflow must be **active** and reachable by webhook (self-hosted n8n handles this). Approvals resume the exact run.

---

## ♻️ Revisions (reject = "change it", not "stop")

Every gate now loops back so you can iterate without starting over:

| You reject… | It asks | What happens |
|-------------|---------|--------------|
| 📝 **Script** | "What should I change?" (free text) | Regenerates the brief with your notes, keeps everything else on-brand, re-asks |
| 🎨 **AI images** | "Which image(s), and how? e.g. `scene 2: brighter`, `redo 1 and 3`" | **Only the scenes you name are re-generated**; the rest are kept, then it re-asks |
| 🧑‍⚖️ **Post** | "What should I change? caption / new video / redo subtitles / rewrite script" | An LLM routes your request: **caption/title edit** (no re-render) · **new media** (same script, fresh video/images) · **rewrite script** (back to the brief) |

So you can tweak the script, swap 1–2 specific images, regenerate the video, change captions/subtitles, or ask for anything — then it re-renders and asks again.

---

## ⏰ Scheduling (post now, or at a set IST time)

Tell the Director when to post — it remembers it like any other setting:

```
post now                      → post_mode = now (default; posts right after you approve)
schedule daily at 7pm         → post_mode = scheduled, post_time = 19:30 (IST)
change posting time to 21:00  → updates post_time
```

- On **now**: the approved post publishes immediately.
- On **scheduled**: the ready-to-post package is saved to `cd_scheduled` with the next IST occurrence of `post_time`. A **Schedule Trigger runs every 15 min**, grabs anything due, posts it through the same Buffer/API chain, and marks it `posted` (so it never double-posts). You still approve the content first; only the *publish* is deferred.

---

## 📊 Analytics feedback loop (double down on what works)

Every **6 hours** an Analytics Trigger pulls each Buffer-posted update's stats, computes a weighted engagement **score** (`likes + comments×3 + shares×5 + saves×4 + clicks×0.5 + reach×0.01`), stores it on the `cd_memory` row, and writes the **top performers** into `cd_state.winners`. The Director Brain and the Master Brief then read `winners` and **lean into the angles/styles that actually performed**.

> **Caveat:** metrics are read from **Buffer** (the default posting method). Posts sent via the native APIs (YouTube/Pinterest) have no `buffer_id`, so they're skipped for now — the same pattern can be extended to the YouTube Data API / Pinterest v5 analytics.



---

## 🎬 YouTube → Shorts clipping (new, AutoShorts-style)

Paste a **YouTube link** into the bot and it turns the long video into ready-to-post **vertical 9:16 Shorts**, ranked by viral potential. Inspired by [JayWebtech/autoshorts](https://github.com/JayWebtech/autoshorts) (approach summarized/rephrased for licensing compliance).

**How it works** — the moment the Intake node sees a YouTube URL in your message, it routes to a dedicated clipping pipeline (it does **not** go through the Director/brief flow):

```
Intake detects YouTube URL
  → 💬 Clip: Ack (instant "downloading…" reply)
  → 🧩 Clip: Prep      (builds a yt-dlp + ffmpeg shell job)
  → ⬇️ Clip: Download  (yt-dlp best ≤1080p mp4 + extracts 16 kHz mono mp3)
  → 📂 Clip: Read Audio → 🎙️ Clip: Transcribe (OpenAI Whisper, verbose_json segments)
  → 🧠 Clip: Rank Prompt → 🤖 OpenRouter: Clip Ranker (DeepSeek by default)
  → 📋 Clip: Parse Moments (clamps to 10–90 s, non-overlapping, ranked)
  → 🎞️ Clip: Build FFmpeg (center-crop to 1080×1920 + burned SRT captions per clip)
  → 🖥️ Clip: Render → 📤 Explode → 📂 Read MP4 → 💬 Clip: Send (one video per clip)
```

**Usage:**
```
https://youtu.be/XXXXXXXX               → 3 clips (default)
clip this into 5: https://youtu.be/XXX  → 5 clips (max 8)
```

**Requirements (self-hosted n8n host):**
- `yt-dlp` on PATH (`pip install -U yt-dlp` or your package manager) — for downloading the source video.
- `ffmpeg` + `ffprobe` on PATH — already required for the video render engine.
- `OPENAI_API_KEY` (Whisper transcription) and `OPENROUTER_API_KEY` (moment ranking) — both already used elsewhere.

**New variable (optional):**
- `CLIP_LLM_MODEL` — OpenRouter model used to rank viral moments. Defaults to `deepseek/deepseek-chat` (cheap, strong reasoning; matches the AutoShorts recommendation). You can set it to `anthropic/claude-3.5-sonnet` for premium hook copywriting or any other OpenRouter model.

**Caveats:**
- OpenAI Whisper caps uploaded audio at **25 MB** (~90 min at the 32 kbps mono this workflow extracts). Longer videos will fail transcription with a clear error — split them, or replace `🎙️ Clip: Transcribe` with a chunked or Deepgram-based step.
- Clips are center-cropped (faces/action off-center may get cut). Captions are burned from the Whisper transcript, synced per clip.
- Clips are sent straight back to Telegram (not auto-posted). To publish one, download it and feed it back through the normal create/post flow, or extend `💬 Clip: Send` into the Buffer/API posting chain.

---

## 🔧 Production-readiness fixes applied

- **`video_route=pexels` is now wired.** Previously the `🔀 Visual Source` switch had no `pexels` output, so choosing Pexels for video silently fell through to the AI-video path and the `📷 Scene: Pexels Clip` node was unreachable. Pexels is now a first-class, reliable video b-roll route (`ai · pexels · pinterest · hyperframes`).
- **`🔀 Content Type`** now has a fallback → a friendly "unsupported type" reply instead of silently dropping the run.
- **`🔀 API Route`** fallback fixed (was an invalid `fallbackOutput` value) → routes unexpected values to the "API not supported" reply.

> Still requires your attention after import: set `settings.errorWorkflow` to the imported error-handler's id (n8n can't know the id until you import it), and verify your Buffer GraphQL endpoint/token against Buffer's current API.
