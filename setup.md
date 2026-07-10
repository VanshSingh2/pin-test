# Setup Guide

A single conversational Telegram content-studio bot that runs on self-hosted **n8n** + **Supabase** — it chats with you to design, render, and (with your approval) publish reels/posts, and can auto-clip YouTube videos into vertical Shorts.

---

## 1. Prereqs / Keys

Gather these before you start:

| Key / Account | Where to get it |
| --- | --- |
| **Telegram bot token** | [@BotFather](https://t.me/BotFather) |
| **Supabase project** | Project **URL** + **service_role key** |
| **OpenRouter API key** | openrouter.ai |
| **OpenAI API key** | platform.openai.com |
| **Pexels API key** | pexels.com/api |
| **ImgBB API key** | api.imgbb.com |
| **Buffer** *(optional)* | Personal API key + profile ids |
| **Pinterest** *(optional)* | Access token + board id |
| **YouTube OAuth** *(optional)* | Google Cloud OAuth client |

**Host requirements:** the machine running n8n must have `ffmpeg`, `ffprobe`, `yt-dlp`, and `curl` available on `PATH` (needed for video render + YouTube→Shorts clipping).

---

## 2. Supabase Setup

1. Open your Supabase project → **SQL Editor**.
2. Paste and run the contents of **`supabase-schema.sql`** (at the repo root) to create all tables.
3. Go to **Storage** → create a **public** bucket named:

```
videos
```

---

## 3. Option A — GitHub Codespace (quick test)

Good for a quick trial. Codespaces are **ephemeral** — great for testing, not for 24/7 use.

In the Codespace terminal:

```bash
sudo apt-get update && sudo apt-get install -y ffmpeg curl
python3 -m pip install --user -U yt-dlp
export PATH="$HOME/.local/bin:$PATH"
npx n8n
```

Then:

1. Open the **Ports** tab, set port **5678** visibility to **Public**.
2. Copy the forwarded URL (e.g. `https://xxxx-5678.app.github.dev`).
3. Stop n8n (`Ctrl+C`) and re-run it pointed at that URL:

```bash
export WEBHOOK_URL="https://YOUR-FORWARDED-URL/"
export N8N_HOST="YOUR-FORWARDED-URL"
export N8N_PROTOCOL=https
export GENERIC_TIMEZONE=Asia/Kolkata
npx n8n
```

---

## 4. Option B — VPS (Docker)

For always-on hosting. Telegram **requires HTTPS**, so put a reverse proxy (Caddy/Nginx) in front.

```bash
git clone <this-repo>
cd <this-repo>
```

Create a small `Dockerfile`:

```dockerfile
FROM n8nio/n8n:latest
USER root
RUN apk add --no-cache ffmpeg python3 py3-pip curl \
    && pip3 install --break-system-packages -U yt-dlp
USER node
```

Build and run:

```bash
docker build -t pin-test-n8n .

docker run -d --restart unless-stopped \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  -e N8N_HOST="YOUR_DOMAIN" \
  -e N8N_PROTOCOL=https \
  -e WEBHOOK_URL="https://YOUR_DOMAIN/" \
  -e GENERIC_TIMEZONE=Asia/Kolkata \
  pin-test-n8n
```

Then front it with **Caddy** or **Nginx** to terminate HTTPS on `YOUR_DOMAIN`.

---

## 5. n8n Credentials

In the n8n UI (**Credentials** → **New**):

- **Telegram API** — paste your bot token.
- **YouTube OAuth2** *(optional)* — for YouTube nodes.

> The workflow JSON ships with placeholder credential ids `TG_CRED_ID` and `YT_CRED_ID`. After importing, open the **Telegram Trigger** / **YouTube** nodes and **re-select** your real credentials.

---

## 6. n8n Variables

Add these under **Settings → Variables** (n8n Variables table):

| Variable | Notes / Example |
| --- | --- |
| `OPENROUTER_API_KEY` | |
| `OPENROUTER_LLM_MODEL` | e.g. `openai/gpt-4o` |
| `OPENAI_API_KEY` | |
| `CLIP_LLM_MODEL` | optional, default `deepseek/deepseek-chat` |
| `PEXELS_API_KEY` | |
| `IMGBB_API_KEY` | |
| `SUPABASE_URL` | |
| `SUPABASE_SERVICE_KEY` | |
| `TELEGRAM_CHAT_ID` | |
| `BUFFER_ACCESS_TOKEN` | must be a **personal API key** — Buffer's post metrics/analytics are personal-use only |
| `BUFFER_PROFILE_ID_INSTAGRAM` | |
| `BUFFER_PROFILE_ID_YOUTUBE` | |
| `BUFFER_PROFILE_ID_PINTEREST` | |
| `BUFFER_PROFILE_ID_FACEBOOK` | |
| `BUFFER_PROFILE_ID_TIKTOK` | |
| `PINTEREST_ACCESS_TOKEN` | optional |
| `PINTEREST_BOARD_ID_LIFESTYLE` | optional |
| `FFMPEG_FONT` | e.g. `/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf` |
| `OPENAI_TTS_VOICE` | e.g. `onyx` |

---

## 7. Import & Activate

1. Import both workflow JSONs:
   - `workflows/creative_director_v1.json` (main)
   - `workflows/creative_director_error_handler.json` (error alerts)
2. Open the **main** workflow → **Settings** → **Error Workflow** → select the imported error handler.
3. Toggle the main workflow **Active**.

---

## 8. Use It

DM your bot on Telegram:

- Set a **niche / style**, then ask it to make a reel or post.
- It **proposes** an idea — you pick the **platform** + **posting method**, it renders, you **approve**, then it posts. **Nothing auto-posts.**
- Paste a **YouTube link** to auto-clip it into vertical **Shorts**.
