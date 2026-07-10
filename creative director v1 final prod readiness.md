# Fix Prompt: Creative Director v1 — Final Production Readiness Pass

**Target file:** `workflows/creative_director_v1.json`

Confirmed already fixed from the last pass, no action needed: Buffer's GraphQL mutation (union-type fragments + correct result parsing), all 5 original bugs (false success messages, AIV polling, scrape guards, JSON.parse robustness), platform validation, multi-platform posting, AI/Pinterest image sourcing, and the video_route mapping. The new Shorts-clipping pipeline (YouTube link → auto-clipped vertical Shorts) is well-built: proper error-output branches on both the yt-dlp download and FFmpeg render steps, with a clear Telegram failure message instead of a silent crash.

TikTok posts through Buffer normally, same as Instagram/Facebook/Pinterest — no changes needed anywhere in the workflow for it. `BUFFER_PROFILE_ID_TIKTOK` just needs to be set in n8n's variables (add it to `pin-test.md`'s variables table too, since it's currently missing from that list).

One real item left before this is fully production ready.

---

## Fix 1 — Extend retry coverage to the 3 new clipping HTTP nodes (and the still-open 31 from before)

**Problem:** Retry coverage is unchanged from the last pass — still 17 of 51 HTTP nodes have `retryOnFail`. The 3 new nodes added for Shorts-clipping (`🎙️ Clip: Transcribe`, and the OpenRouter clip-ranker call) have none either, so a transient Whisper/OpenRouter hiccup fails the whole clip job outright rather than retrying once or twice first.

**Fix:** Add `retryOnFail: true, maxTries: 3, waitBetweenTries: 2000` to `🎙️ Clip: Transcribe` and `🤖 OpenRouter: Clip Ranker` — same pattern as the other LLM/transcription calls already covered. If you want to close the rest of the gap from the previous pass in the same sweep (imgbb hosts, Pexels/Pinterest fetches, video storage upload — the "safe to retry" group from before), do it now; the posting-call caveat about idempotency from the last pass still applies and hasn't changed.

---

## Pre-launch checklist (manual steps, not code — `pin-test.md` already documents these, just confirm they're actually done before calling this live)

- [ ] `settings.errorWorkflow` is still blank in the JSON — select the error handler workflow in n8n's UI after importing both files (this can't be set from the JSON itself pre-import).
- [ ] Replace `TG_CRED_ID` in `creative_director_error_handler.json` with your real Telegram credential.
- [ ] Confirm the main workflow's Telegram Trigger and YouTube nodes have your real credentials selected (not the `TG_CRED_ID`/`YT_CRED_ID` placeholders), and that all `BUFFER_PROFILE_ID_*` variables (including `BUFFER_PROFILE_ID_TIKTOK`) are set to your real channel IDs.
- [ ] Do one real test post to each Buffer-connected platform (instagram, facebook, pinterest, tiktok) and confirm it actually appears in Buffer's queue — this is the one part of the whole system that needed a live-schema fix last round, worth a manual confirmation rather than trusting the code alone.
- [ ] Test the job-token concurrency guard specifically against the new clipping pipeline: send a content-creation request, then immediately paste a YouTube link before it finishes, and confirm neither run corrupts the other's state. This interaction wasn't part of either prior review pass and is worth one real test before relying on it.

---

## Verdict

Once Fix 1 is done, `BUFFER_PROFILE_ID_TIKTOK` is confirmed set, and the checklist above is confirmed, this is production ready. Nothing else found in this pass is a blocker.
