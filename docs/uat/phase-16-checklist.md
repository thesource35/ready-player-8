# Phase 16 — Field Tools UAT Checklist

Manual acceptance script for Phase 16 field-capture features. Run on a physical
device (iPhone + Apple Pencil-capable iPad where noted). Tick each item and
attach a screenshot or short clip for any failures.

## 1. Permission prompt UX

- [ ] Fresh install: opening Field Capture for the first time prompts for
      Location "When In Use" with a clear purpose string.
- [ ] Denying permission surfaces an inline banner explaining why location is
      needed and a button to open Settings.
- [ ] Re-granting permission from Settings refreshes the capture view without
      requiring an app relaunch.

## 2. Outdoor capture (fresh fix)

- [ ] Outdoors with clear sky, tapping "Capture" records a location within
      5 seconds and shows horizontal accuracy ≤ 20 m.
- [ ] The captured photo's EXIF (or attached metadata) matches the on-screen
      coordinates.
- [ ] Timestamp is in device local timezone and matches wall-clock time.

## 3. Indoor (last-known) capture fallback

- [ ] Indoors where GPS is weak, after the configured timeout the UI falls back
      to the last-known location and clearly labels it "approximate".
- [ ] A "Refine location" affordance lets the user retry a fresh fix.

## 4. Manual pin correction

- [ ] User can drag the pin on the map preview to correct the captured point.
- [ ] Saving persists the corrected lat/lng, not the original fix.
- [ ] An audit note records that the location was manually adjusted.

## 5. Annotation draw on Apple Pencil (iPad)

- [ ] PencilKit canvas loads within 1 second over a captured photo.
- [ ] Freehand, arrow, rectangle, and text tools all render and persist.
- [ ] Undo / redo work for at least 20 steps.
- [ ] Saving then reopening a photo restores every stroke in the correct place
      in both portrait and landscape.

## 6. Daily log create with weather + crew pre-fill

- [ ] Creating a new daily log auto-populates today's date, project, weather
      (temp + conditions), and the active crew roster.
- [ ] Weather pre-fill falls back gracefully when Open-Meteo is unreachable
      (shows "weather unavailable" rather than blocking save).
- [ ] User edits to any pre-filled field survive save and reload.
- [ ] Submitted log appears in the project feed within 10 seconds.
