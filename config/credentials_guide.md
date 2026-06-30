# Credentials & API Setup Guide

This workflow uses **n8n Variables** for all secrets (no credential objects needed except optionally Supabase). Everything is called via HTTP Request nodes.

---

## 1. Supabase (Database)

1. Create a free project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor → New Query**, paste the contents of [`supabase_schema.sql`](supabase_schema.sql), and click **Run**
3. Go to **Project Settings → API** and copy:
   - **Project URL** → store as n8n Variable `SUPABASE_URL`
   - **`service_role` secret key** → store as `SUPABASE_SERVICE_KEY`
4. The workflow talks to Supabase through its REST API (PostgREST) — no extra setup needed.

## 2. OpenAI

1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create a secret key → store as `OPENAI_API_KEY`
3. Models used: `gpt-4o-mini` (text) and `dall-e-3` (images)
4. Make sure your account has billing enabled for DALL-E 3.

## 3. Pinterest Access Token

1. Go to [developers.pinterest.com](https://developers.pinterest.com) → create an App
2. Run the OAuth flow with scopes: `boards:read`, `pins:read`, `pins:write`, and `user_accounts:read` (for analytics)
3. Store the access token as `PINTEREST_ACCESS_TOKEN`
4. Grab your board IDs from each board's URL and store them in the `PINTEREST_BOARD_ID_*` variables
5. **Trial Access** pins are only visible to you — request **Standard Access** for public pins.

## 4. Buffer (only needed if postingMethod = buffer)

1. Go to [buffer.com/developers](https://buffer.com/developers) → create an app → get an Access Token
2. Find your Pinterest profile ID:
   `GET https://api.bufferapp.com/1/profiles.json?access_token=YOUR_TOKEN`
3. Store `BUFFER_ACCESS_TOKEN` and `BUFFER_PROFILE_ID`

## 5. Imgbb (Image Hosting)

1. Go to [api.imgbb.com](https://api.imgbb.com) → get a free API key
2. Store as `IMGBB_API_KEY`
3. This hosts the DALL-E images so Pinterest/Buffer can fetch a permanent public URL
   (DALL-E URLs expire after ~1 hour, so hosting is required).

---

## Summary: What You Need Per Posting Mode

| Variable | Pinterest mode | Buffer mode |
|----------|:--:|:--:|
| `OPENAI_API_KEY` | ✅ | ✅ |
| `IMGBB_API_KEY` | ✅ | ✅ |
| `SUPABASE_URL` / `SUPABASE_SERVICE_KEY` | ✅ | ✅ |
| `PINTEREST_ACCESS_TOKEN` + board IDs | ✅ | ➖ (still needed for analytics) |
| `BUFFER_ACCESS_TOKEN` / `BUFFER_PROFILE_ID` | ➖ | ✅ |
