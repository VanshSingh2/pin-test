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
