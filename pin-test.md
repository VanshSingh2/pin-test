# pin-test — Creative Director (n8n)

A single conversational **Telegram bot** that runs a multi-platform content studio on **n8n** + **Supabase**: it chats, confirms, then creates **images / carousels / videos** and posts (after your approval) to Instagram, YouTube, Pinterest, Facebook via Buffer/API. It also turns any **YouTube link you send it into vertical 9:16 Shorts**.

- `workflows/creative_director_v1.json` — the main workflow (import this).
- `workflows/creative_director_error_handler.json` — error-alert workflow.
- `config/creative_director_schema.sql` — the Supabase tables.

> ⚠️ Nothing is auto-posted. Every post waits for your approval in Telegram, and you pick the platform(s) before choosing how to post.

---

## 1. What you need first (accounts + keys)

Create these and keep the keys handy — you'll paste them into n8n in step 4.

- **Telegram bot token** — message [@BotFather](https://t.me/BotFather) → `/newbot`.
- **Supabase** project → its `SUPABASE_URL` and **service_role** key (Project Settings → API).
- **OpenRouter** API key (LLM + images) and **OpenAI** API key (Whisper transcription + TTS).
- **Pexels** API key (stock video b-roll) and **ImgBB** API key (image hosting).
- **Buffer** access token + the channel/profile IDs you want to post to (optional; needed only for posting).
- *(Optional)* Pinterest access token + board id; YouTube OAuth2 (for direct API upload).

**Supabase setup:** open the Supabase SQL Editor, paste the contents of `config/creative_director_schema.sql`, run it. Then Storage → create a **public** bucket named `videos`.

---

## 2. Two ways to run it

n8n must run on a machine that also has **ffmpeg**, **ffprobe**, **yt-dlp**, and **curl** installed (the workflow shells out to them for video rendering and YouTube clipping).

### Option A — VPS (Docker, recommended for always-on)

On any Ubuntu/Debian VPS with Docker installed:

```bash
# 1. clone
git clone https://github.com/VanshSingh2/pin-test.git
cd pin-test

# 2. build an n8n image that includes ffmpeg + yt-dlp
cat > Dockerfile <<'EOF'
FROM n8nio/n8n:latest
USER root
RUN apk add --no-cache ffmpeg python3 py3-pip curl \
 && pip3 install --break-system-packages -U yt-dlp
USER node
EOF
docker build -t pin-test-n8n .

# 3. run it (replace YOUR_VPS_DOMAIN with your domain or public IP)
docker run -d --name n8n --restart unless-stopped \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  -e N8N_HOST="YOUR_VPS_DOMAIN" \
  -e N8N_PROTOCOL="https" \
  -e WEBHOOK_URL="https://YOUR_VPS_DOMAIN/" \
  -e GENERIC_TIMEZONE="Asia/Kolkata" \
  pin-test-n8n
```

Put it behind HTTPS (Telegram requires it) with a reverse proxy such as Caddy or Nginx pointing at port `5678`. Then open `https://YOUR_VPS_DOMAIN` and continue to step 3.

### Option B — GitHub Codespace (quick test, no server needed)

1. On the GitHub repo click **Code → Codespaces → Create codespace on main**.
2. In the Codespace terminal:

```bash
sudo apt-get update && sudo apt-get install -y ffmpeg curl
python3 -m pip install --user -U yt-dlp
export PATH="$HOME/.local/bin:$PATH"

npx n8n            # first run downloads n8n, then starts it on port 5678
```

3. Open the **Ports** tab, find port **5678**, set its visibility to **Public**, and copy the forwarded URL (e.g. `https://xxxx-5678.app.github.dev`).
4. Stop n8n (`Ctrl+C`) and restart it so Telegram webhooks use that public URL:

```bash
export WEBHOOK_URL="https://xxxx-5678.app.github.dev/"
export N8N_HOST="xxxx-5678.app.github.dev"
export N8N_PROTOCOL="https"
export GENERIC_TIMEZONE="Asia/Kolkata"
npx n8n
```

5. Open the forwarded URL and continue to step 3.

> Codespaces are ephemeral and stop when idle — great for testing, not for 24/7 running.

---

## 3. Set up n8n credentials

In the n8n UI → **Credentials → New**:

- **Telegram API** — paste your bot token. After saving, note it as the "Telegram Bot" credential.
- *(Optional)* **YouTube OAuth2 API** — if you want direct YouTube uploads.

---

## 4. Set the variables

In n8n → **Settings → Variables**, add each of these (the workflow reads them as `$vars.*`):

| Variable | Value |
|---|---|
| `OPENROUTER_API_KEY` | OpenRouter key |
| `OPENROUTER_LLM_MODEL` | e.g. `openai/gpt-4o` |
| `OPENAI_API_KEY` | OpenAI key (Whisper + TTS) |
| `CLIP_LLM_MODEL` | *(optional)* clip ranker, default `deepseek/deepseek-chat` |
| `PEXELS_API_KEY` | Pexels key |
| `IMGBB_API_KEY` | ImgBB key |
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | Supabase service_role key |
| `TELEGRAM_CHAT_ID` | your Telegram chat/user id |
| `BUFFER_ACCESS_TOKEN` | Buffer token *(for posting)* |
| `BUFFER_PROFILE_ID_INSTAGRAM` / `_YOUTUBE` / `_PINTEREST` / `_FACEBOOK` / `_TIKTOK` | Buffer channel ids |
| `PINTEREST_ACCESS_TOKEN`, `PINTEREST_BOARD_ID_LIFESTYLE` | *(optional)* Pinterest API |
| `FFMPEG_FONT` | e.g. `/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf` |
| `OPENAI_TTS_VOICE` | e.g. `onyx` |

> Buffer note: posting goes to Instagram, Facebook, Pinterest, YouTube, and TikTok — set the matching `BUFFER_PROFILE_ID_*` channel id for each one you use.

---

## 5. Import & activate the workflow

1. n8n → **Workflows → Import from File** → `workflows/creative_director_v1.json`.
2. Import `workflows/creative_director_error_handler.json` too, then in the main workflow open **Settings → Error Workflow** and select it.
3. Open the main workflow, confirm the **Telegram Trigger** and **YouTube** nodes show your saved credentials (they use placeholder ids `TG_CRED_ID` / `YT_CRED_ID` — re-select yours).
4. Toggle the workflow **Active**.

---

## 6. Use it

Message your Telegram bot:

```
set niche to indie coffee shops
use a warm cinematic style
make a reel about 3 latte art tricks
→ pick platform(s), then post method → the bot asks you to approve → yes

https://youtu.be/XXXXXXXXXXX          ← auto-clips the video into Shorts
clip this into 5: https://youtu.be/XXX
```

The bot always proposes first, you choose platforms and posting method, it renders, you approve, and only then does it post.
