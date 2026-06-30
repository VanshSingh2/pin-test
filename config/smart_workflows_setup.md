# Smart Conversational Workflows — YouTube & Pinterest (+ Pinterest clip b-roll)

Both of these work like the Instagram bot: a **Manager Brain** chats with you, **proposes a plan, waits for your "yes"**, and remembers a **niche + style** per chat in Supabase.

- `workflows/youtube_tiktok_v5_smart.json` — Shorts/Reels from **Pexels OR Pinterest clips** (b-roll), posts via Buffer
- `workflows/pinterest_v2_smart.json` — AI pins (image + SEO copy) posted via the Pinterest API

Run `config/smart_state_schema.sql` first (adds `yt_state`, `pin_state`).

> The YouTube one needs **self-hosted n8n** (FFmpeg). The Pinterest one runs anywhere.

---

## 🎬 Smart YouTube/TikTok — b-roll from Pinterest or Pexels

Set everything by chatting (all remembered per chat):

| You say | Effect |
|---------|--------|
| "set niche to home workouts" | niche saved |
| "use cinematic realism style" | style saved |
| "use pinterest for clips" / "use pexels" | **b-roll source** |
| "reference style: dark moody gym" | clips are searched with THIS phrase |
| "platform both" | posts to YouTube + TikTok (Buffer) |
| "make a short about 5 quick ab moves" | proposes → you say "yes" → it builds + posts |
| "script: Most people train abs wrong..." | uses YOUR script |

**How b-roll works:**
- Each scene gets a search term from the script (or your `reference` phrase if set).
- `broll_source = pinterest` → the workflow **scrapes Pinterest search** for video pins and pulls the clip `.mp4`.
- `broll_source = pexels` → free, license-clear stock clips (recommended).
- If no clip is found, the scene falls back to a clean color background so it never fails.
- FFmpeg stitches clips + OpenAI TTS voice + burned captions → vertical MP4 → Buffer.

### ⚠️ Pinterest-clip honest caveats
- There's **no official API** to download Pinterest video pins — the workflow **scrapes the search page**, which can break when Pinterest changes their markup, and may be **against their ToS**.
- Pinterest clips are **someone else's copyrighted content** — reposting risks strikes/takedowns.
- **Pexels is the safe default.** Treat the Pinterest source as experimental / use-at-your-own-risk.

Extra variables for this one: `BUFFER_PROFILE_ID_YOUTUBE`, `BUFFER_PROFILE_ID_TIKTOK`, `PEXELS_API_KEY` (others shared with v4).

---

## 📌 Smart Pinterest — conversational pin maker

| You say | Effect |
|---------|--------|
| "set niche to minimalist home decor" | niche saved |
| "style: scandinavian, warm light" | style saved |
| "make a pin about small bedroom ideas" | proposes → "yes" → creates + posts the pin |

Pipeline: Manager Brain → (confirm) → SEO + image plan → OpenRouter image → Imgbb host → **Pinterest API v5 create pin** → Telegram confirmation.

Uses `PINTEREST_ACCESS_TOKEN` and a board id (`PINTEREST_BOARD_ID_LIFESTYLE` fallback, or set `board_id` in `pin_state`).

> Pinterest **Trial Access** pins are private until you get **Standard Access** (see the Pinterest README section).

---

## Shared variables (both)
`OPENROUTER_API_KEY`, `OPENROUTER_LLM_MODEL`, `OPENROUTER_IMAGE_MODEL`, `IMGBB_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, Telegram Bot credential (`TG_CRED_ID`). The YouTube one also uses `OPENAI_API_KEY` (TTS), `OPENROUTER_VIDEO_MODEL` (unused in clip mode), `BUFFER_ACCESS_TOKEN`, and a public Supabase Storage bucket `videos`.
