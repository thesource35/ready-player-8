---
status: partial
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
source: [22-VERIFICATION.md]
started: 2026-04-15T06:30:00Z
updated: 2026-04-15T06:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Live Mux Ingest UAT
expected: Push RTMP stream via OBS, verify LL-HLS plays on both iOS and web within ~5s
result: [pending]

### 2. VOD Upload-to-Play UAT
expected: Upload MP4 on both platforms, verify transcode pipeline end-to-end (uploading > transcoding > ready within ~2 min)
result: [pending]

### 3. Portal Exposure UAT
expected: Portal link shows head-only live, streaming-only VOD, drone clips blocked (403)
result: [pending]

### 4. Retention Prune UAT
expected: Trigger prune-expired-videos edge function, verify row + storage + Mux live-input cleanup
result: [pending]

### 5. Visual Animation Quality
expected: Status badge transitions use 200ms fade animation (no instant badge-swap)
result: [pending]

### 6. Stream Key One-Time Reveal
expected: AddCameraWizard shows RTMP key once in step 2, not re-fetchable after dismissal
result: [pending]

### 7. Audio Jurisdiction Warning
expected: D-35 confirmation modal with jurisdiction consent copy fires when audio toggle enabled
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
