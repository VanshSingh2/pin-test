# n8n Variables Setup

Go to **n8n → Settings → Variables** and add all of these.

---

## API Keys

| Variable Name | Value | Where to Get |
|--------------|-------|--------------|
| `OPENAI_API_KEY` | `sk-...` | platform.openai.com |
| `PINTEREST_ACCESS_TOKEN` | `pina_...` | developers.pinterest.com |
| `BUFFER_ACCESS_TOKEN` | `...` | buffer.com/developers |
| `PEXELS_API_KEY` | `...` | pexels.com/api |
| `IMGBB_API_KEY` | `...` | api.imgbb.com |
| `SERPAPI_KEY` | `...` | serpapi.com (optional) |

---

## Google Sheets

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `GOOGLE_SHEET_ID` | `1BxiM...` | From Google Sheets URL |

---

## Pinterest Config

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `PINTEREST_BOARD_ID_FASHION` | `123456789` | From board URL |
| `PINTEREST_BOARD_ID_BEAUTY` | `123456789` | From board URL |
| `PINTEREST_BOARD_ID_LIFESTYLE` | `123456789` | From board URL |
| `PINTEREST_BOARD_ID_QUOTES` | `123456789` | From board URL |

---

## Buffer Config

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `BUFFER_PROFILE_ID` | `...` | From Buffer profile settings |

---

## Sub-Workflow IDs (fill AFTER importing all workflows)

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `WF_TREND_FINDER` | `1` | ID shown in n8n after import |
| `WF_IDEA_GENERATOR` | `2` | ID shown in n8n after import |
| `WF_PROMPT_GENERATOR` | `3` | ID shown in n8n after import |
| `WF_THUMBNAIL_DESIGNER` | `4` | ID shown in n8n after import |
| `WF_CONTENT_CREATOR` | `5` | ID shown in n8n after import |
| `WF_POSTING_MANAGER` | `6` | ID shown in n8n after import |
| `WF_ANALYTICS_TRACKER` | `7` | ID shown in n8n after import |
