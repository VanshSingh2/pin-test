# 🎯 Creative Director — Unified Conversational Studio

`workflows/creative_director_v1.json` is **one Telegram bot for everything**: you chat, it understands, **confirms**, then creates and posts an **image, carousel, or video/reel** to **Instagram, YouTube, TikTok, or Pinterest** — always **on-brand** because it remembers what you've made.

> Reels/Shorts need **self-hosted n8n** (FFmpeg). Images, carousels & pins run anywhere.

---

## What it does (everything you asked for)

| Capability | How |
|------------|-----|
| **Pick what to make** | "make a carousel / image / reel about X" → it sets `content_type` |
| **Pick the style** | "use Disney Pixar 3D" / "moody cinematic" → applied to every asset |
| **AI visuals OR clips** | `visual_source = ai` (AI images) · `pexels` · `pinterest` (scraped clips) |
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

1. Run `config/creative_director_schema.sql` (adds `cd_state`, `cd_memory`). Create the public `videos` Storage bucket.
2. n8n Variables (mostly shared with the other workflows):
   `OPENROUTER_API_KEY`, `OPENROUTER_LLM_MODEL`, `OPENAI_API_KEY` (TTS), `IMGBB_API_KEY`, `PEXELS_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `BUFFER_ACCESS_TOKEN`, `BUFFER_PROFILE_ID_INSTAGRAM/YOUTUBE/TIKTOK/PINTEREST`, `PINTEREST_ACCESS_TOKEN`, `PINTEREST_BOARD_ID_LIFESTYLE`, `TELEGRAM_CHAT_ID`, `FFMPEG_FONT`, `OPENAI_TTS_VOICE`.
3. Credentials: **Telegram Bot** (`TG_CRED_ID`), **YouTube OAuth2** (`YT_CRED_ID`).

---

## Defaults you can change by chatting

`platform` (instagram·youtube·tiktok·pinterest·both) · `content_type` (image·carousel·video) · `visual_source` (ai·pexels·pinterest) · `image_model` (default `openai/gpt-image-1`) · `posting_method` (buffer·api) · `style` · `niche` · `reference`.

---

## Honest caveats
- **Pinterest clips**: no official download API — the bot **scrapes** the search page (can break, may breach ToS, clips are others' copyright). **Pexels is the safe default.**
- **Buffer carousels**: Buffer's classic API posts a single media; the bot stores all slide URLs. For true multi-image IG carousels use the Instagram Graph API.
- **AI video**: this Director animates AI **stills** + clips via FFmpeg. For true generative **image→video** (Veo/Kling/Wan), use `youtube_tiktok_v4_ondemand_openrouter.json` (it already selects the video model).
- **TikTok via API** posts privately until your app is audited.
