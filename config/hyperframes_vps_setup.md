# HyperFrames render engine — Ubuntu VPS setup

The Creative Director can render video with **FFmpeg** (fast, default) or **HyperFrames** (HTML motion-graphics → nicer animated captions/transitions). You choose per chat:

```
you: use hyperframes for video      → render_engine = hyperframes
you: use ffmpeg                      → render_engine = ffmpeg (default)
```

HyperFrames ([heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)) is a Node CLI that renders HTML compositions to MP4 using headless Chrome + FFmpeg — it runs headless on an Ubuntu VPS (the same box as your self-hosted n8n).

## Install on the n8n host (once)

```bash
# Node 22+
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs ffmpeg

# headless-Chrome libraries + fonts
sudo apt-get install -y \
  libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
  libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
  libpango-1.0-0 libcairo2 fonts-liberation fonts-dejavu

# sanity check
npx --yes hyperframes --version
```

## Requirements / notes
- **RAM:** headless Chrome is memory-hungry — use **≥ 4 GB RAM / 2 vCPU** (add swap as a cushion). Don't use a 1 GB box.
- **Chrome sandbox:** on a bare/root VPS you may need `--no-sandbox`; if renders fail, run n8n as a non-root user or set Puppeteer's no-sandbox flag.
- **Docker n8n:** use an image that includes Node 22 + Chrome deps, or install them in your Dockerfile. The `Execute Command` node must be able to run `npx`/`ffmpeg`/`curl`.
- **First run** downloads the HyperFrames CLI and a Chromium build (slower once).
- **CLI flags:** the workflow tries `hyperframes render index.html --output final.mp4` with a fallback. If your installed CLI version uses different flags, tweak the command in the **🎬 HF: Build Composition** node.

## How it works in the workflow
`🎞️ Video: Build FFmpeg` → **🔀 Render Engine** →
- `ffmpeg` → existing FFmpeg path (clips/stills + drawtext captions)
- `hyperframes` → **🎬 HF: Build Composition** writes an `index.html` (image/clip layers + GSAP-animated captions + per-scene OpenAI TTS audio), runs `hyperframes render`, then uploads the MP4 and posts — same as the FFmpeg path.

## Cost
Same as FFmpeg for compute ($0 on your VPS) + the usual OpenAI TTS/LLM cents. No HyperFrames fees (Apache-2.0, no per-render cost).

> This is an experimental integration — the HTML composition is intentionally simple (image/clip + animated caption + voiceover). You can make it far richer using HyperFrames' catalog blocks (charts, transitions, overlays) by editing the composition in the HF build node.
