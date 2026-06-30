# Credentials Setup Guide

## 1. Google Sheets OAuth2
1. Go to **n8n → Credentials → New**
2. Search "Google Sheets OAuth2 API"
3. Add Client ID + Client Secret from Google Cloud Console
4. Enable Google Sheets API in your Google Cloud project
5. Add OAuth redirect URI: `https://your-n8n-domain/rest/oauth2-credential/callback`
6. Name the credential: `Google Sheets OAuth`

## 2. Pinterest Access Token (OAuth2)
1. Go to [developers.pinterest.com](https://developers.pinterest.com)
2. Create an App → Get App ID + App Secret
3. Run OAuth flow to get Access Token:
   - Scopes needed: `boards:read`, `pins:read`, `pins:write`
4. Store token in n8n Variable: `PINTEREST_ACCESS_TOKEN`
5. Request Standard Access for public pins visibility

## 3. OpenAI API Key
1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create new secret key
3. Store in n8n Variable: `OPENAI_API_KEY`
4. Models used: `gpt-4o-mini` (text), `dall-e-3` (images)

## 4. Buffer API
1. Go to [buffer.com/developers](https://buffer.com/developers)
2. Create app and get Access Token
3. Find your Profile ID from Buffer API:
   `GET https://api.bufferapp.com/1/profiles.json?access_token=YOUR_TOKEN`
4. Store token: `BUFFER_ACCESS_TOKEN`, profile ID: `BUFFER_PROFILE_ID`

## 5. Pexels API (free image fallback)
1. Go to [pexels.com/api](https://www.pexels.com/api/)
2. Free tier: 200 requests/hour, 20,000/month
3. Store key in: `PEXELS_API_KEY`

## 6. Imgbb API (free image hosting)
1. Go to [api.imgbb.com](https://api.imgbb.com)
2. Free tier: unlimited uploads
3. Store key in: `IMGBB_API_KEY`
