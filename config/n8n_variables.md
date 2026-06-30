# n8n Variables Setup

Go to **n8n → Settings → Variables** and add all of these.
(n8n Variables require the self-hosted "Pro" feature or n8n Cloud. If unavailable, paste the values directly into the nodes, or use Credentials.)

---

## 🔑 API Keys

| Variable Name | Value | Where to Get |
|--------------|-------|--------------|
| `OPENAI_API_KEY` | `sk-...` | platform.openai.com |
| `PINTEREST_ACCESS_TOKEN` | `pina_...` | developers.pinterest.com |
| `BUFFER_ACCESS_TOKEN` | `1/...` | buffer.com/developers |
| `IMGBB_API_KEY` | `...` | api.imgbb.com |

---

## 🗄️ Supabase

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `SUPABASE_URL` | `https://xxxx.supabase.co` | Project Settings → API → Project URL |
| `SUPABASE_SERVICE_KEY` | `eyJ...` | Project Settings → API → `service_role` secret key |

> ⚠️ Use the **`service_role`** key (not the `anon` key) so the workflow can write to tables. Keep it secret.

---

## 📌 Pinterest Boards

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `PINTEREST_BOARD_ID_FASHION` | `123...` | From board URL |
| `PINTEREST_BOARD_ID_BEAUTY` | `123...` | From board URL |
| `PINTEREST_BOARD_ID_LIFESTYLE` | `123...` | Default/fallback board |
| `PINTEREST_BOARD_ID_QUOTES` | `123...` | From board URL |

---

## 📱 Buffer

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `BUFFER_PROFILE_ID` | `...` | Your Pinterest profile ID in Buffer |

---

## 🎛️ Posting Toggle (NOT a variable — set inside the workflow)

The posting method toggle lives in the **`⚙️ CONTROL PANEL`** node inside the workflow,
so you can flip it without touching variables:

| Field | Options | Meaning |
|-------|---------|---------|
| `postingMethod` | `pinterest` or `buffer` | Which service posts the pin |
| `postsPerRun` | number (e.g. `2`) | How many pins to create per run |
| `niche` | text | Your content niche description |
| `enabled` | `true` / `false` | Master on/off switch for the whole automation |

To switch posting: open the workflow → click **⚙️ CONTROL PANEL** → change `postingMethod`.
