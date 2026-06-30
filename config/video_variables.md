# YouTube + TikTok Workflow — Variables & Credentials

This workflow (`workflows/youtube_tiktok_complete.json`) is modeled on the
[darkzOGx/youtube-automation-agent](https://github.com/darkzOGx/youtube-automation-agent)
multi-agent architecture, rebuilt for n8n with YouTube **and** TikTok publishing.
*(Architecture notes were rephrased/summarized for licensing compliance.)*

---

## 🔑 n8n Variables (Settings → Variables)

| Variable | Value | Where to get it |
|----------|-------|-----------------|
| `OPENAI_API_KEY` | `sk-...` | platform.openai.com |
| `IMGBB_API_KEY` | `...` | api.imgbb.com (thumbnail hosting) |
| `JSON2VIDEO_API_KEY` | `...` | json2video.com (video rendering) |
| `SUPABASE_URL` | `https://xxxx.supabase.co` | Supabase → Settings → API |
| `SUPABASE_SERVICE_KEY` | `eyJ...` | Supabase → Settings → API → `service_role` |
| `TIKTOK_ACCESS_TOKEN` | `act....` | TikTok for Developers (Content Posting API) |

> YouTube uses an **OAuth2 credential** (not a variable) — see below.

---

## 🔐 YouTube OAuth2 Credential

1. In **Google Cloud Console**, enable the **YouTube Data API v3**
2. Create an **OAuth Client ID** (Web application)
3. Add redirect URI: `https://<your-n8n>/rest/oauth2-credential/callback`
4. In n8n → Credentials → New → **YouTube OAuth2 API**, paste Client ID + Secret, authorize
5. The nodes reference a credential placeholder `YT_CRED_ID` — after import, open
   **▶️ YouTube: Upload** and **📊 YouTube: Video Stats** and select your credential.

---

## 🎵 TikTok Content Posting API

1. Create an app at [developers.tiktok.com](https://developers.tiktok.com)
2. Request the **Content Posting API** scope (`video.publish`) and **Video Query** scope
3. Complete the OAuth flow to get an access token → store as `TIKTOK_ACCESS_TOKEN`
4. ⚠️ **Unaudited apps** can only post with `privacy_level: SELF_ONLY` (private). The
   workflow uses `SELF_ONLY` by default — once your app passes TikTok audit, change it to
   `PUBLIC_TO_EVERYONE` in the **🎵 TikTok: Publish** node.
5. `PULL_FROM_URL` requires your domain to be verified in the TikTok developer portal.

---

## 🎛️ The CONTROL PANEL Toggle (inside the workflow)

Open the **⚙️ CONTROL PANEL** node to configure everything without touching variables:

| Field | Options | Meaning |
|-------|---------|---------|
| `platform` | `youtube` \| `tiktok` \| `both` | **Where videos get published** |
| `videosPerRun` | number | Videos generated per run |
| `bufferDays` | number | Skip generating if this many already queued (smart buffer) |
| `niche` | text | Your content niche |
| `videoStyle` | text | Visual style fed to the script/render |
| `scheduleHour` | 0-23 | Hour of day to publish |
| `enabled` | `true` \| `false` | Master on/off switch |

---

## ⏰ Schedules (mirrors the darkzOGx agent)

| Trigger | Cron | Purpose |
|---------|------|---------|
| Content Gen | `0 6 * * *` | Daily — generate new videos (respects buffer) |
| Publish Queue | `*/15 * * * *` | Every 15 min — check renders + publish due videos |
| Analytics | `0 9 * * *` | Daily — collect view/like/comment stats |
| Weekly Strategy | `0 8 * * 0` | Sundays — review top performers, suggest next topics |
