---
id: SEED-001
status: dormant
planted: 2026-04-22
planted_during: v2.1 Gap Closure — end of Phase 21
trigger_when: Phase 22.1 gap closure OR a new "traffic-cameras" / "public-live-feeds" milestone is planned
scope: medium
---

# SEED-001: DOT Public Traffic Cameras Integration

## Why This Matters

User requested "live traffic video" during Phase 21 execution. Phase 22 already ships
private HLS camera feeds per project (user-uploaded streams). This seed extends that
pipeline with **public DOT / 511 traffic camera feeds** — a free, high-coverage,
zero-capture-hardware data source that dramatically increases the map's informational
value without changing the upload economics of user-captured streams.

Layering both feed types behind one schema means the map UI (Mapbox Popup on web,
MKAnnotation callout on iOS) renders identically regardless of source — the user
sees one "traffic camera" marker type with one player UX.

## When to Surface

**Trigger:** Phase 22.1 gap closure, OR a new milestone scoped around "traffic cameras",
"public live feeds", or "map data enrichment".

This seed should be presented during `/gsd-new-milestone` when the milestone scope
matches any of these conditions:
- Milestone mentions "traffic", "DOT", "511", "public camera", or "map video"
- Phase 22 gets a ".1" decimal phase for gap closure or enhancement
- User asks about adding more map data layers

## Scope Estimate

**Medium** — estimated 1-2 weeks, 3-4 phases:
1. **Schema + DOT indexer** — add `cs_camera_feeds.feed_type` column (`dot_public` | `user_rtc`),
   build a daily pg_cron that refreshes camera metadata per state (start with 511NY,
   Caltrans, TxDOT, FDOT — the four largest public indexes)
2. **Web player** — HLS.js `<video>` inside Mapbox Popup when a `dot_public` marker is clicked
3. **iOS player** — `AVPlayerViewController` inside `MKAnnotation` callout
4. **Per-region layer toggle** — Mapbox + MapKit sidebar filter for camera density
   (DOT feeds are dense — without a toggle the map becomes unreadable in cities)

## Breadcrumbs

Related code and decisions in the current codebase:

- Phase 22 shipped artifacts:
  - `.planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/` (22-00 through 22-04 all SUMMARY.md landed)
  - `web/src/app/maps/page.tsx` — Mapbox canvas + 7-toggle strip (Phase 21 wiring)
  - `ready player 8/MapsView.swift` — MapKit 7-toggle strip + annotation rendering
- Phase 21 token infrastructure (already landed):
  - `web/.env.local` — `NEXT_PUBLIC_MAPBOX_TOKEN` populated
  - `web/src/app/portal/[slug]/[project]/map/PortalMapClient.test.tsx` — fallback regression suite
- Schema pointers (Phase 21):
  - `supabase/migrations/20260412001_phase21_equipment_tables.sql` — `cs_equipment_locations` pattern
    for append-only tamper-proof geospatial rows; DOT camera metadata can follow the same pattern

Related decisions:
- D-09 (Phase 27): portal map-link suppression for legacy portals — same pattern would apply
  to dot_public cameras (admin controls which camera layers the portal client can see)

## Notes

User prompted this with "how can you add live traffic video" followed by "could I do both"
(DOT + user-RTC). The accepted architecture was: **same table, one feed_type column,
shared player**. This seed preserves that design choice so the implementer in Phase 22.1
doesn't re-litigate it.

Public DOT feeds vary in format (MJPEG vs HLS vs raw still-image refresh every 30s) —
the indexer's job is to normalize metadata (URL, format, refresh cadence, jurisdiction)
so the player can switch strategies per feed without surfacing that complexity to the map UI.

Cost envelope: DOT feeds are free. User-RTC streams via Cloudflare Stream run ~$1/1000 min
ingress — but that's Phase 22's existing cost envelope, not this seed's concern.
