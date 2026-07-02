# Connecting n8n to a Domain — VPS and GitHub Codespaces

Why this matters: Telegram's "Send and Wait" approval buttons and the Telegram trigger both need a **public HTTPS URL** n8n can be reached at. `localhost` only works for local testing without Telegram actually round-tripping approvals.

---

## Option A: VPS (persistent, recommended for production)

### 1. Point your domain at the VPS
In your domain registrar/DNS provider, add an **A record**: `n8n.yourdomain.com` → your VPS's public IP. Wait for propagation (`dig n8n.yourdomain.com` should return your IP).

### 2. Put a reverse proxy in front of n8n (Caddy — simplest, automatic HTTPS)
```bash
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update && sudo apt-get install -y caddy
```

Edit `/etc/caddy/Caddyfile`:
```
n8n.yourdomain.com {
    reverse_proxy localhost:5678
}
```
```bash
sudo systemctl reload caddy
```
Caddy automatically gets and renews a Let's Encrypt HTTPS certificate — no manual certbot steps needed.

### 3. Tell n8n it's now reachable at that domain
Set these before starting n8n (add to your pm2 ecosystem file, a `.env` n8n reads, or `~/.bashrc`):
```bash
export N8N_HOST="n8n.yourdomain.com"
export N8N_PROTOCOL="https"
export N8N_PORT="5678"
export WEBHOOK_URL="https://n8n.yourdomain.com/"
```
```bash
pm2 restart n8n
```

### 4. Verify
Open `https://n8n.yourdomain.com` in a browser — should load the n8n UI over HTTPS. Re-activate `creative_director_v1.json` (deactivate then reactivate) so it re-registers its Telegram webhook against the new public URL.

---

## Option B: GitHub Codespaces (fast to test, **not** for 24/7 production)

Important limitation first: **Codespaces stop automatically after a period of inactivity** (default 30 min idle timeout, configurable up to a max). Your bot goes offline whenever the codespace sleeps — fine for testing/development, not reliable for a bot that should always be listening. Use this to verify everything works, then move to the VPS for real use.

### 1. Start n8n inside the codespace
```bash
npm install -g n8n
n8n start
```
(For rendering/HyperFrames you'd also need Node 22/FFmpeg/Chrome deps installed in the codespace, same packages as the VPS guide — Codespaces containers usually already have recent Node, check with `node -v`.)

### 2. Forward and publicize the port
In VS Code's **Ports** tab (bottom panel): find port `5678` → right-click → **Port Visibility** → **Public**. By default, forwarded ports require GitHub auth to view, which blocks Telegram's webhook calls from reaching it — Public visibility is required for Telegram to actually deliver updates.

### 3. Copy the generated URL
It'll look like `https://<codespace-name>-5678.app.github.dev` — already HTTPS, no certificate setup needed (GitHub handles it).

### 4. Set the same n8n env vars, using that URL
```bash
export N8N_HOST="<codespace-name>-5678.app.github.dev"
export N8N_PROTOCOL="https"
export WEBHOOK_URL="https://<codespace-name>-5678.app.github.dev/"
n8n start
```

### 5. Re-activate the workflow
Same as the VPS: deactivate/reactivate `creative_director_v1.json` after setting these so Telegram's webhook re-registers against the new URL. Note the URL **changes every time you rebuild/recreate the codespace** — you'd need to redo steps 3-5 each time, another reason it's dev-only.

---

## Quick comparison

| | VPS | Codespaces |
|---|---|---|
| Uptime | 24/7 (with pm2) | Sleeps when idle |
| URL stability | Permanent (your domain) | Changes on rebuild |
| Cost | VPS hosting fee | Free tier hours, then billed |
| Best for | Running the bot for real | Testing changes before deploying |
