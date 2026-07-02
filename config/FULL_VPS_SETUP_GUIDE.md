# Creative Director v1 — Full VPS Setup Guide

End-to-end guide to get `creative_director_v1.json` running on your own Ubuntu VPS, from a bare server to a working Telegram bot. Follow in order — each step depends on the last.

---

## 0. Why self-hosted (not n8n Cloud)

This workflow uses `Execute Command` (FFmpeg/HyperFrames rendering) and reads files off disk (`Read/Write File`). Those only work on **self-hosted n8n**. Image/carousel/Pinterest-pin generation would work on n8n Cloud, but video rendering will not — so self-host if you want video at all.

**Minimum VPS spec:** 4 GB RAM / 2 vCPU (headless Chrome for HyperFrames is memory-hungry — don't try 1 GB). Ubuntu 22.04 LTS recommended.

---

## 1. Provision the VPS and install base packages

SSH into your fresh VPS as a sudo-capable user, then:

```bash
sudo apt-get update && sudo apt-get upgrade -y

# Node.js 22+
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs ffmpeg git curl

# headless-Chrome libraries + fonts (needed for HyperFrames rendering)
sudo apt-get install -y \
  libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
  libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
  libpango-1.0-0 libcairo2 fonts-liberation fonts-dejavu

# sanity checks
node -v          # should print v22.x
ffmpeg -version
npx --yes hyperframes --version   # first run downloads the CLI + a Chromium build, slower once
```

## 2. Install n8n

Easiest path — global npm install with a process manager (pm2). Docker is also fine (see note below).

```bash
sudo npm install -g n8n pm2

# Run n8n on boot, keep it alive
pm2 start n8n --name n8n
pm2 save
pm2 startup   # follow the printed command to enable on-boot start
```

n8n now listens on `http://localhost:5678`. To reach the UI from your browser, either:
- **SSH tunnel** (simplest, no public exposure): `ssh -L 5678:localhost:5678 you@your-vps-ip`, then open `http://localhost:5678` locally, or
- Put it behind a reverse proxy (nginx/Caddy) with HTTPS if you want a real domain and public access (needed for Telegram's "Send and Wait" approval buttons to resume correctly if n8n is reachable via webhook from Telegram's servers — a public HTTPS URL is required for that to work reliably).

> **Docker alternative:** use an n8n image that already includes Node 22 + Chrome deps, or add them to a custom Dockerfile — the container needs `npx`/`ffmpeg`/`curl` runnable inside it, since `Execute Command` runs there directly.

Set n8n's webhook URL (required for Telegram trigger + "Send and Wait" approvals to work) via environment variable before starting n8n:
```bash
export WEBHOOK_URL="https://your-domain-or-ip:5678/"
export N8N_HOST="your-domain-or-ip"
```
(Add these to your pm2 ecosystem file or `~/.bashrc` so they persist across restarts.)

## 3. Set up Supabase

1. You already have a project (`kdcnnssxueraxumszqrx`). Go to its **SQL Editor**.
2. Run `config/creative_director_schema.sql` in full — safe to re-run any time, only adds tables/columns.
3. In **Storage**, create a public bucket named `videos` (used for rendered MP4s).

## 4. Get every credential/key you need

See `.env` in this repo (gitignored, local reference only — n8n does not read it directly, you paste values into n8n's UI):

| Already have | Still needed |
|---|---|
| Supabase URL/service key, imgbb key, OpenAI key, Telegram chat id, Buffer API key | **`OPENROUTER_API_KEY`** (get at openrouter.ai — nothing works without this), Telegram **bot token** (via @BotFather), Buffer channel IDs (connect platforms in Buffer's dashboard, then query `channels()` — see `config/creative_director_setup.md`) |

## 5. Import the workflows

In the n8n UI:
1. **Workflows → Import from File** → `workflows/creative_director_v1.json`
2. **Workflows → Import from File** → `workflows/creative_director_error_handler.json`

## 6. Add credentials (Credentials tab)

| Credential | Type | Notes |
|---|---|---|
| Telegram Bot | Telegram API | Paste your BotFather token. Select it on every Telegram node in both imported workflows (n8n won't auto-match the placeholder `TG_CRED_ID`). |
| YouTube OAuth2 | YouTube OAuth2 API | Only needed if you'll post to YouTube via native API. Requires a Google Cloud OAuth client (see YouTube node's built-in setup instructions in n8n). |

## 7. Add variables (Settings → Variables)

Copy every value from `.env` into n8n as a Variable (name must match exactly — these are the `$vars.X` references throughout the workflow):

**Required:** `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `OPENROUTER_API_KEY`, `IMGBB_API_KEY`, `TELEGRAM_CHAT_ID`

**Needed for what you'll use:** `OPENAI_API_KEY` (video narration), `BUFFER_ACCESS_TOKEN` + `BUFFER_PROFILE_ID_*` (Buffer posting), `PINTEREST_ACCESS_TOKEN` + `PINTEREST_BOARD_ID_LIFESTYLE` (native Pinterest posting)

**Optional (has defaults):** `OPENROUTER_LLM_MODEL`, `OPENAI_TTS_VOICE`, `FFMPEG_FONT`, `VIDEO_CLIP_SECONDS`, `BRAND_LOGO_URL`, `BRAND_MUSIC_URL`

## 8. Wire the error handler

1. Activate `creative_director_error_handler.json`.
2. Copy its workflow ID from the browser URL (`.../workflow/<ID>`).
3. Open `creative_director_v1.json` → Settings (top-right menu) → set **Error Workflow** to that ID → save.

Without this step, OpenRouter/imgbb hard failures fail silently with no Telegram message — see the earlier conversation for exactly which failure paths need this vs. which already notify you regardless.

## 9. Activate and test

1. Activate `creative_director_v1.json` (top-right toggle) — needed for the Telegram trigger, the 15-min scheduler, and the 6h analytics trigger to run.
2. Message your bot. First test (cheapest, fastest full-pipeline exercise):
   ```
   set niche to test, set style to simple
   make an image about a sunset, post via buffer
   ```
   Approve when asked. Watch for either "✅ posted!" or "⚠️ posting FAILED" with a real error.
3. Once that works, try a video (`make a reel about ...`) to exercise FFmpeg, and try HyperFrames per `config/hyperframes_vps_setup.md` if you want the richer render engine.

## 10. Ongoing operation

- `pm2 logs n8n` — tail logs if something misbehaves.
- `pm2 restart n8n` — after changing env vars or updating n8n.
- Re-import a workflow JSON any time you get an updated version from this repo — n8n will ask whether to overwrite, say yes (it preserves credential *selections* you've already made on matching node IDs, but double-check after re-import).

## Troubleshooting quick-reference

| Symptom | Likely cause |
|---|---|
| Bot never replies to Telegram messages | Workflow not activated, or `WEBHOOK_URL`/`N8N_HOST` not set / not publicly reachable |
| "OpenRouter call failed or returned no choices" in n8n execution log, nothing in Telegram | `settings.errorWorkflow` not set (step 8) |
| Video renders as a placeholder gray screen or shows "⚠️ Scene render timed out" | AI-video job took longer than ~4 minutes to render (5 retries × 45s) — check OpenRouter video job status/quota |
| HyperFrames render fails | Missing Chrome libs (step 1) or insufficient RAM — see `config/hyperframes_vps_setup.md` |
| "✅ posted!" but nothing shows up on the platform | Check the `link` in the message — if it says "Queued in Buffer", confirm the post actually went out in Buffer's own dashboard (Buffer scheduling ≠ instant in all cases) |
