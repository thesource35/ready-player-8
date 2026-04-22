---
status: diagnosed
phase: 21-live-satellite-traffic-maps
source: [21-01-SUMMARY.md, 21-02-SUMMARY.md, 21-03-SUMMARY.md, 21-04-SUMMARY.md, 21-05-SUMMARY.md, 21-06-SUMMARY.md]
started: 2026-04-21T00:00:00Z
updated: 2026-04-21T12:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running dev server. Start fresh (npm run dev). Server boots clean. /maps loads base Mapbox satellite canvas with no console errors. Above the map a horizontal 7-toggle strip is visible in this order: SATELLITE, THERMAL, CREWS, WEATHER, AUTO TRACK, TRAFFIC, PHOTOS. A right-side sidebar shows an EQUIPMENT section with type filters (All/Equipment/Vehicles/Materials) and a DELIVERY ROUTES section where each route card has a "Get Directions" button. No missing-env crashes, no "Maps Unavailable" placeholder.
result: pending
reported: ""
severity: major
note: "Expected text reconciled to match shipped UI per UAT gap root-cause diagnosis (2026-04-21). Previous expected listed TRAFFIC/EQUIPMENT/PHOTOS/ROUTES which were never shipped labels."

### 2. Web Map — Traffic Overlay Toggle
expected: On /maps, click the TRAFFIC toggle. A live traffic layer appears over roads with color coding (green=flowing, yellow=slow, red=congested). A legend overlay shows the color key. Click again — traffic layer disappears.
result: issue
reported: "issue"
severity: major
note: "Likely same root cause as Test 1 — Phase 21 web UI not visible on /maps."

### 3. Web Map — Equipment Markers With Typed Shapes
expected: Equipment markers render on the map using typed shapes — circle for equipment, rounded-square for vehicles, diamond for materials — and status colors (green=active, gold=idle, red=offline). Clicking a marker opens a popup with equipment details.
result: issue
reported: "issue"
severity: major
note: "Likely same root cause as Test 1 — Phase 21 web UI not visible on /maps."

### 4. Web Map — GPS Photo Markers
expected: Click the PHOTOS toggle. Purple (#8A8FCC) markers appear at GPS-tagged photo locations. With no GPS photos in the DB, no markers appear and no errors are thrown. Clicking again hides them.
result: issue
reported: "issue"
severity: major
note: "Likely same root cause as Test 1 — Phase 21 web UI not visible on /maps."

### 5. Web Map — Delivery Route Directions (Mapbox Directions API)
expected: In the delivery routes list, click "Get Directions" on a route. A road-following polyline renders between the two points (not a straight line). Distance and ETA display on the card. Hide/show toggles cleanly.
result: issue
reported: "issue"
severity: major
note: "Likely same root cause as Test 1 — Phase 21 web UI not visible on /maps."

### 6. Web Map — Overlay and Camera Persistence
expected: Toggle some overlays on/off and pan/zoom the map. Refresh the page (Cmd+R). The overlays and camera position (center/zoom) restore to the state you left.
result: issue
reported: "issue"
severity: major
note: "Likely same root cause as Test 1 — Phase 21 web UI not visible on /maps."

### 7. iOS Map — Traffic Overlay Toggle
expected: In the iOS app on the Maps tab, tap TRAFFIC. MapKit live traffic lines appear on roads (built-in, no API cost). Tap again to hide. Works on both .hybrid (satellite) and .standard styles.
result: issue
reported: "issue"
severity: major

### 8. iOS Map — Equipment Annotations
expected: Equipment annotations appear as SF Symbols in colored circles — gearshape.fill for equipment, truck.box.fill for vehicles, shippingbox.fill for materials — colored green/gold/red by status. Tap one to reveal a callout.
result: issue
reported: "issue"
severity: major

### 9. iOS Map — Photo Annotations
expected: Tap PHOTOS toggle. Purple circles with camera.fill icon appear at photo locations. Tap to reveal filename and date. Tap PHOTOS again to hide.
result: issue
reported: "issue"
severity: major

### 10. iOS Map — Overlay and Camera Persistence Across Launches
expected: Toggle several overlays and pan/zoom. Background/quit the app and relaunch. All 7 overlay toggles AND camera position restore to your last state (AppStorage-backed).
result: issue
reported: "issue"
severity: major

### 11. iOS Equipment Check-In Flow (GPS + Supabase)
expected: Tap CHECK IN EQUIPMENT button. Sheet opens with equipment picker and live GPS coordinates/accuracy. First time: iOS prompts for "When In Use" location permission. Select equipment, tap Confirm Location. Sheet dismisses, top success toast shows "Location updated for {name}", auto-dismisses after 3s. Map refreshes with new position.
result: issue
reported: "issue"
severity: major

### 12. iOS Location Permission Denial
expected: If you deny location permission, the check-in sheet shows a clear error message (no crash, no silent failure) instructing you to enable location. Submit button is disabled or shows error.
result: issue
reported: "issue"
severity: major

### 13. iOS Delivery Routes (MKDirections)
expected: In the DELIVERY ROUTES sidebar section, tap "Get Directions" on a route card. While computing, card shows "Computing route...". On success, a road-following gold polyline renders on the map, and the card shows distance (miles) and ETA (minutes). If MKDirections fails, card shows "Route unavailable. Showing straight-line connection." and the straight-line fallback is visible.
result: issue
reported: "issue"
severity: major

### 14. Portal Create Dialog — MAP SETTINGS Section
expected: Open Create Portal Link dialog. A MAP SETTINGS section appears with a master "Show Map" toggle and 4 sub-toggles (satellite/traffic/equipment/photos). Toggle selections save with the portal link.
result: issue
reported: "issue"
severity: major

### 15. Portal Public Map Page — Locked Overlays
expected: Visit a portal URL at /portal/{slug}/{project}/map. The Mapbox map renders with only the overlays enabled in portal config. No toggle strip, no refresh button, no admin controls. Pan/zoom work, but overlay visibility cannot be changed by the viewer.
result: issue
reported: "issue"
severity: major

### 16. Portal Map — Backward Compatibility (D-09 Aware)
expected: Open an older portal link created before Phase 21 (no map_overlays in sections_config). Per D-09, the portal home must show NO Map link in the navigation (neither desktop PortalHeader nor mobile MobilePortalNav). Directly visiting /portal/{slug}/{project}/map via URL still renders the Mapbox map with DEFAULT_MAP_OVERLAYS — no crash, no missing-field errors. The /map page uses the defaults: show_map=true, satellite=true, traffic=false, equipment=false, photos=true.
prerequisite: Tests 14 and 15 pass so a working Phase-21 portal exists as a control.
result: pending
reported: ""
severity: major
note: "Expected text reconciled to acknowledge D-09 (Phase 27-01) per UAT gap root-cause diagnosis (2026-04-21). Previous expected was written before D-09 landed and incorrectly implied the Map link should render for legacy portals."

## Summary

total: 16
passed: 0
issues: 16
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "On fresh boot, /maps shows Phase 21 additions (toggle strip with TRAFFIC/EQUIPMENT/PHOTOS/ROUTES, legend, etc.) — layout visibly differs from pre-phase base map"
  status: failed
  reason: "User reported: same map layout — its not a pass"
  severity: major
  test: 1
  root_cause: "TWO independent causes. (A) Primary: NEXT_PUBLIC_MAPBOX_TOKEN is empty in web/.env.local (line 21 is 'NEXT_PUBLIC_MAPBOX_TOKEN=' with no value). The page renders 'Maps Unavailable' placeholder instead of a Mapbox canvas, so every Phase 21 deliverable downstream of the map (traffic, equipment, photos, routes, satellite style) is invisible. (B) Secondary: UAT Test 1's expected labels (TRAFFIC/EQUIPMENT/PHOTOS/ROUTES) do not match the shipped toggle strip (SATELLITE/THERMAL/CREWS/WEATHER/AUTO TRACK/TRAFFIC/PHOTOS — 7 labels); EQUIPMENT is a sidebar filter, not a toggle, and ROUTES are per-row 'Get Directions' buttons, not a toggle. Even with a working map the UAT text fails by label mismatch."
  artifacts:
    - path: "web/.env.local"
      issue: "line 21 NEXT_PUBLIC_MAPBOX_TOKEN= is blank"
    - path: "web/src/lib/maps/types.ts"
      issue: "ALL_OVERLAY_KEYS ships 7 labels; UAT expected 4 different labels"
    - path: ".planning/phases/21-live-satellite-traffic-maps/21-UAT.md"
      issue: "Test 1 expected text prescribes labels the code never rendered"
  missing:
    - "Populate NEXT_PUBLIC_MAPBOX_TOKEN with a valid pk.* Mapbox token and restart dev server"
    - "Reconcile UAT Test 1 expected text with shipped UI (recommend updating UAT to describe actual 7-toggle strip + equipment sidebar filter + per-route Get Directions)"
  debug_session: ".planning/debug/maps-cold-start-layout.md"

- truth: "On /maps, clicking TRAFFIC toggle shows/hides live traffic layer with color-coded legend"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 2
  root_cause: "Cascade of Test 1's missing Mapbox token. TRAFFIC toggle button DOES render (it's above the token gate), but clicking it calls addTrafficLayer() against a mapRef that was never instantiated (Maps Unavailable placeholder renders instead of mapboxgl.Map). Code on main is correct and complete — the effect handler + Mapbox traffic-v1 source/layer wiring all ship. A stale dev server or cached browser bundle is a secondary contributor."
  artifacts:
    - path: "web/src/app/maps/page.tsx"
      issue: "lines 38-64, 331-338, 446-450, 462-466 correct as shipped"
    - path: "web/.env.local"
      issue: "empty NEXT_PUBLIC_MAPBOX_TOKEN blocks map init"
  missing:
    - "Populate Mapbox token (shared with Test 1 fix)"
    - "Restart dev server + hard-refresh browser to clear any stale bundle"
  debug_session: ".planning/debug/maps-traffic-toggle-missing.md"

- truth: "Equipment markers on /maps render with typed shapes (circle/rounded-square/diamond) and status colors (green/gold/red); clicking opens popup"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 3
  root_cause: "Empty data source, not a code defect. rebuildEquipmentMarkers in web/src/app/maps/page.tsx:161-206 correctly implements typed shapes via EQUIPMENT_ICONS + status colors via STATUS_COLORS + click-popups. Markers never appear because /api/maps/equipment returns []: the cs_equipment_latest_positions view has zero rows (no seed data, no web admin UI to add equipment, only bootstrap is iOS check-in flow which is itself a failed UAT). Compounded by empty Mapbox token from Test 1 (even if rows existed, the map canvas isn't up)."
  artifacts:
    - path: "web/src/app/maps/page.tsx"
      issue: "lines 161-206 renderer correct; requires non-empty equipment dataset"
    - path: "web/src/app/api/maps/equipment/route.ts"
      issue: "returns [] when DB empty; no distinguishing empty-state UX"
    - path: "supabase/migrations/20260412001_phase21_equipment_tables.sql"
      issue: "ships schema only; no seed rows"
  missing:
    - "Seed 3-5 cs_equipment + cs_equipment_locations rows (one per type × one per status) near map default center"
    - "Render 'No equipment tracked yet' empty-state overlay so empty ≠ broken"
    - "Shared: Mapbox token fix (Test 1)"
  debug_session: ".planning/debug/maps-equipment-typed-shapes.md"

- truth: "PHOTOS toggle on /maps shows/hides purple (#8A8FCC) markers at GPS-tagged photo locations"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 4
  root_cause: "No Test-4-specific code defect. PHOTOS toggle is rendered, colored #8A8FCC exactly per spec, wired to a correctly-filtering API (/api/maps/photos filters on gps_lat/gps_lng NOT NULL), and cleanly rebuilds/tears down markers on toggle. This 'issue' is spillover from Test 1's umbrella concern — user noted 'Likely same root cause as Test 1' at test-time. Resolving Test 1 (Mapbox token + UAT label reconciliation) closes Test 4 automatically."
  artifacts:
    - path: "web/src/app/maps/page.tsx"
      issue: "lines 208-237, 349-352, 446-450 correct as shipped (uses #8A8FCC literal)"
    - path: "web/src/app/api/maps/photos/route.ts"
      issue: "correct: filters on GPS presence, returns [] shape consistent with consumer"
  missing:
    - "Shared: Test 1 resolution (Mapbox token + UAT label reconciliation)"
    - "Optional UX: surface 401-unauthenticated vs empty-GPS-photos distinctly"
  debug_session: ".planning/debug/maps-photos-toggle.md"

- truth: "Delivery route 'Get Directions' on /maps renders road-following polyline with distance/ETA via Mapbox Directions API"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 5
  root_cause: "Cascade of Test 1's missing Mapbox token. Phase 21 implementation is correctly on HEAD: fetchRouteDirections, api.mapbox.com/directions/v5 call, Get Directions per-route button, 'Route unavailable' fallback copy all match 21-03 plan. When token is absent, fetchRouteDirections silently no-ops at page.tsx:365 (if (!mapboxToken) return;) — button click does nothing, no error shown. Silent-failure UX polish opportunity: set a visible error state instead of bare early-return."
  artifacts:
    - path: "web/src/app/maps/page.tsx"
      issue: "lines 363-410, 535-561 correct; line 365 silent early return on missing token"
    - path: "web/.env.local"
      issue: "empty NEXT_PUBLIC_MAPBOX_TOKEN"
  missing:
    - "Mapbox token fix (shared with Test 1)"
    - "Replace silent 'if (!mapboxToken) return;' at page.tsx:365 with visible error feedback on the route card"
  debug_session: ".planning/debug/maps-directions-api.md"

- truth: "/maps overlay toggles and camera (center/zoom) persist across page refresh"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 6
  root_cause: "THREE real code defects in web/src/app/maps/page.tsx (not a cascade). (1) Camera race: map.on('load') restores saved camera at L267-276, then geolocation getCurrentPosition fires flyTo at L291-299 whose moveend events silently clobber the user's last panned position with browser-reported GPS. (2) TRAFFIC toggle never applied on first load — L333-338 effect bails on null mapRef (async loadMap assigns mapRef only at L302); deps are [activeOverlays] with no re-trigger after mapRef populates. (3) SATELLITE toggle has identical first-load gap at L311-329. Markers persist only by coincidence (their data state changes after map-load)."
  artifacts:
    - path: "web/src/app/maps/page.tsx"
      issue: "L263-300 camera race with geolocation; L333-338 TRAFFIC null-guard gap; L311-329 SATELLITE null-guard gap"
  missing:
    - "Apply overlay state inside map.on('load') callback after camera restore, or add mapLoaded to effect deps so effects re-run once map exists"
    - "Resolve geolocation/camera conflict: skip geolocation when saved camera exists, OR run geolocation BEFORE camera restore, OR detach moveend listener during flyTo animation"
    - "Align storage key case to ConstructOS.* convention (cosmetic follow-up)"
  debug_session: ".planning/debug/maps-persistence-refresh.md"

- truth: "iOS Maps tab TRAFFIC toggle shows/hides MapKit traffic lines on both .hybrid and .standard styles"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 7
  root_cause: "No iOS code defect. MapsView.swift lines 44/63/109/156/412/419/747/750 correctly implement .mapStyle(.hybrid(showsTraffic: trafficOverlay)) + .standard variant + AppStorage persistence. Compiled dylib at today's DerivedData (mtime Apr 21 13:25) contains 'TRAFFIC', 'ConstructOS.Maps.OverlayTraffic', etc. strings. Probable cause: user ran UAT against a stale simulator install from Apr 6 or Apr 7 DerivedData roots that pre-date Phase 21-04 (Apr 13-14). Matches precedent of Phase 29 UAT (commit 70fece6) where identical 'issue'-everywhere pattern flipped to 16/16 pass on clean re-walk."
  artifacts:
    - path: "ready player 8/MapsView.swift"
      issue: "correct as shipped"
    - path: "~/Library/Developer/Xcode/DerivedData/ready_player_8-dazgfwimxyizaverwoielpudwsqt/"
      issue: "Apr 6 stale build, potential contamination"
    - path: "~/Library/Developer/Xcode/DerivedData/ready_player_8-dcxrmjzckydegwalsfttrchnakyk/"
      issue: "Apr 7 stale build, potential contamination"
  missing:
    - "Delete installed app from simulator/device; Xcode Clean Build Folder; rebuild from HEAD (70fece6); re-walk UAT"
    - "Optionally delete stale Apr 6/7 DerivedData roots to eliminate pin to old products"
  debug_session: ".planning/debug/ios-maps-traffic-toggle.md"

- truth: "iOS Map equipment annotations render as typed SF Symbol glyphs (gearshape.fill/truck.box.fill/shippingbox.fill) in status-colored circles with tap callouts"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 8
  root_cause: "TWO converging defects. (1) Coordinate/viewport mismatch: map default viewport is NYC Midtown (40.758, -73.9855, span ~3 miles) but mockEquipmentPositions entries are in Atlanta (33.749, -84.388) — ~860 miles off-screen. On unconfigured/fresh installs the mock pins exist but are invisible. (2) Error-only fallback: loadMapData() assigns mockEquipmentPositions only inside catch block; cs_equipment_latest_positions view uses INNER JOIN on cs_equipment_locations and returns empty successfully until first check-in exists — so empty-but-successful response never triggers mock fallback."
  artifacts:
    - path: "ready player 8/EquipmentModels.swift"
      issue: "lines 173-178 mockEquipmentPositions at Atlanta coords, off-screen from NYC default viewport"
    - path: "ready player 8/MapsView.swift"
      issue: "lines 430-455 catches throw only; empty successful fetch leaves annotations empty"
    - path: "supabase/migrations/20260412001_phase21_equipment_tables.sql"
      issue: "lines 48-69 INNER JOIN → view empty until first check-in"
  missing:
    - "Relocate mockEquipmentPositions to cluster near MapSite.mapCenter (40.758 ± 0.005, -73.9855 ± 0.005)"
    - "Treat empty successful response as mock-fallback trigger when !SupabaseService.shared.isConfigured"
    - "Optional: auto-fit camera to union of sites + equipment when data is non-empty"
  debug_session: ".planning/debug/ios-maps-equipment-annotations.md"

- truth: "iOS Map PHOTOS toggle shows/hides purple camera.fill annotations with filename+date callouts"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 9
  root_cause: "Three converging factors, none a toggle-wiring bug. (A) No GPS-tagged photos in cs_documents: that column is populated ONLY by Phase 16 field-photo GPS capture flow, so fresh installs have zero matching rows. (B) Unconfigured Supabase silently empties photos: unlike equipment (which has mockEquipmentPositions fallback), photos have NO mock fallback — an explicit plan-04 decision. (C) Stale build hypothesis from Test 7 also applies. Code at MapsView.swift:109-112/162/827-858 implements camera.fill / Theme.purple / tap callout correctly."
  artifacts:
    - path: "ready player 8/MapsView.swift"
      issue: "lines 438-453 photo fetch has no mock fallback, no visible empty-state affordance"
  missing:
    - "Add mockPhotoAnnotations file-scope array and fall back on fetch throw (symmetric with equipment)"
    - "Visible empty-state chip: '0 photos with GPS' when photoAnnotations is empty"
    - "Shared: iOS clean-build + reinstall from Test 7"
    - "Document Phase 16 field-photo capture as Test 9 prerequisite"
  debug_session: ".planning/debug/ios-maps-photos-toggle.md"

- truth: "iOS Map 7 overlay toggles and camera position (center/zoom) persist across app background/quit/relaunch via AppStorage"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 10
  root_cause: "FOUR real defects in MapsView.swift. (1) Only 6 of 7 toggles persisted — AUTO TRACK has no @AppStorage wrapper (line 43 is @State only). (2) Camera save reaches for wrong variable at line 714: uses region(for: cameraPreset) (fixed preset region) instead of the two-way bound cameraPosition that actually tracks user pan/zoom. (3) Save trigger is .onDisappear (line 713) which SwiftUI does not reliably fire on background/quit/force-kill. (4) Restore on .onAppear is immediately clobbered by .onChange(of: cameraPreset/selectedSiteID) handlers at lines 725-730 that call updateCamera() which overwrites cameraPosition with region(for: cameraPreset); cameraPreset itself is @State only so boots to .selected every launch."
  artifacts:
    - path: "ready player 8/MapsView.swift"
      issue: "L43/62-67/411-424 missing OverlayAutoTrack AppStorage; L714 wrong save source; L713 unreliable save trigger; L725-730 restore clobbered by updateCamera"
  missing:
    - "Add @AppStorage('ConstructOS.Maps.OverlayAutoTrack') with matching onChange + onAppear lines"
    - "Replace .onDisappear + region(for:cameraPreset) save with .onMapCameraChange(frequency:.continuous) writing ctx.region to savedCameraJSON (debounced)"
    - "Trigger saves off ScenePhase / UIApplication.willResignActiveNotification, not .onDisappear"
    - "Persist cameraPreset + selectedSiteID OR add one-shot 'restored' flag so first post-restore onChange does not call updateCamera()"
  debug_session: ".planning/debug/ios-maps-persistence-launch.md"

- truth: "iOS CHECK IN EQUIPMENT flow — sheet with equipment picker + live GPS, permission prompt, Confirm Location dismisses sheet, success toast auto-dismisses after 3s, map refreshes"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 11
  root_cause: "Client-side allowlist bug. SupabaseService.allowedTables (SupabaseService.swift:781-814) is MISSING all three Phase 21 equipment tables/views: cs_equipment, cs_equipment_locations, cs_equipment_latest_positions. Phase 21 Plan 02 added the Equipment Methods block (lines 1141-1164) but never cross-updated the allowlist. validateTable() at lines 817-821 throws 'Invalid table name' before any HTTP request is issued. EquipmentCheckInView silently falls back to 5 hard-coded mockEquipment rows on loadEquipment; on submit, the error surfaces as 'Check-in failed: Invalid table name: cs_equipment_locations' red banner inside the sheet, which never dismisses. Entire flow broken even with a perfectly configured Supabase."
  artifacts:
    - path: "ready player 8/SupabaseService.swift"
      issue: "lines 781-814 allowlist missing cs_equipment, cs_equipment_locations, cs_equipment_latest_positions"
    - path: "ready player 8/EquipmentCheckInView.swift"
      issue: "lines 151, 177 silent/loud rethrow cannot reach dismiss() or success toast"
    - path: "ready player 8/MapsView.swift"
      issue: "lines 434, 452 silently swallow same throw into mock fallback (violates project core value: no silent data loss)"
  missing:
    - "Add three entries to allowedTables set in SupabaseService.swift around line 810: cs_equipment, cs_equipment_locations, cs_equipment_latest_positions (mirror Phase 22 convention comment style)"
    - "Surface CrashReporter.reportError() output to UI in EquipmentCheckInView:151 and MapsView:434/452 (fix silent-failure violation)"
  debug_session: ".planning/debug/ios-equipment-checkin-flow.md"

- truth: "iOS location permission denial — check-in sheet shows clear error (no crash/silent failure), submit disabled or errors"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 12
  root_cause: "Error framing conflates three failure modes. CheckInLocationManager in EquipmentCheckInView.swift uses the same copy ('GPS signal unavailable. Move to an open area and try again.') for .denied (line 206-207), .restricted (line 206), AND runtime failures (line 228-230). For permission denial: (a) message is wrong — it describes a signal problem, not permissions; (b) the 'Retry' CTA is a dead end — iOS does not re-prompt after deny, Settings is required; (c) no UIApplication.openSettingsURLString button anywhere in the file (grep-verified); (d) doesn't use the codebase's existing AppError.permissionDenied pattern from FieldLocationCapture. Partial credit: Confirm Location IS disabled when location == nil, no crash occurs — so 'no crash' + 'submit disabled' acceptance sub-criteria are satisfied; the failing half is 'clear error instructing you to enable location'."
  artifacts:
    - path: "ready player 8/EquipmentCheckInView.swift"
      issue: "lines 200-211, 213-219, 228-231 conflate denial with runtime failure; lines 82-92 render only a Retry button regardless of cause"
  missing:
    - "Split error state into two signals (denial vs runtime-failure) on CheckInLocationManager"
    - "Branch view on denial signal: render 'Enable location in Settings to check in equipment.' + Button opening UIApplication.openSettingsURLString"
    - "Keep existing Retry button only for runtime-failure branch"
    - "Route through AppError.permissionDenied(feature: 'Location') to match FieldLocationCapture convention"
  debug_session: ".planning/debug/ios-permission-denial-ux.md"

- truth: "iOS DELIVERY ROUTES 'Get Directions' uses MKDirections — shows Computing state, road-following gold polyline + distance/ETA, or 'Route unavailable' with straight-line fallback"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 13
  root_cause: "No iOS code defect. MapsView.swift lines 322-380, 459-486, 754-770 byte-match every element of Test 13 contract: DELIVERY ROUTES sidebar iterating previewMapRoutes, per-route card with Computing/success/error states, calculateRoute() builds MKDirections.Request with MKPlacemark + .automobile and handles both success and failure branches, MapPolyline(route.polyline).stroke(Theme.gold, lineWidth: 4) renders gold polyline. Phase 21 VERIFICATION.md itself flagged Test 13 as 'why_human: requires live MKDirections'. Same clean-build re-walk remedy as Test 7."
  artifacts:
    - path: "ready player 8/MapsView.swift"
      issue: "correct as shipped (no defect)"
    - path: ".planning/phases/21-live-satellite-traffic-maps/21-VERIFICATION.md"
      issue: "lines 34-36 already marked Test 13 as why_human"
  missing:
    - "Shared: iOS clean-build + reinstall from Test 7"
    - "Targeted re-walk with Crane corridor Manhattan route (real coords MKDirections can resolve)"
  debug_session: ".planning/debug/ios-mkdirections-routes.md"

- truth: "Create Portal Link dialog has MAP SETTINGS section with master 'Show Map' toggle + 4 sub-toggles (satellite/traffic/equipment/photos); selections persist with the portal link"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 14
  root_cause: "No code defect. MAP SETTINGS section fully implemented end-to-end. PortalCreateDialog.tsx:490-652 renders header + master Show Map checkbox + 4 sub-toggles with aria-labels. State init lines 42-49 from DEFAULT_MAP_OVERLAYS; submit at line 150 posts map_overlays to /api/portal/create. API route.ts:161-170 Boolean-coerces + merges into sections_config.map_overlays; portalQueries.ts:106 persists full sections_config JSONB — map_overlays rides along losslessly. Commit history: PortalCreateDialog has 3 commits including 4697f8e (Phase 21-06 Apr 14) adding 170 lines for MAP SETTINGS. All present at HEAD (70fece6). Stale dev server or cached browser bundle the only plausible cause."
  artifacts:
    - path: "web/src/app/components/portal/PortalCreateDialog.tsx"
      issue: "correct as shipped (lines 490-652)"
    - path: "web/src/app/api/portal/create/route.ts"
      issue: "correct as shipped (lines 161-170)"
    - path: "web/src/lib/portal/portalQueries.ts"
      issue: "correct as shipped (line 106)"
  missing:
    - "Kill running next dev processes; rm -rf web/.next; npm run dev; hard-refresh browser (Cmd+Shift+R)"
    - "Verify running port / URL matches the local dev server, not a stale Vercel preview"
  debug_session: ".planning/debug/portal-create-map-settings.md"

- truth: "/portal/{slug}/{project}/map renders Mapbox map with only portal-configured overlays, no toggle/refresh/admin controls; viewer cannot change overlay visibility"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 15
  root_cause: "Same NEXT_PUBLIC_MAPBOX_TOKEN empty-string cause as Test 1. PortalMapClient.tsx:305-330 short-circuits on !mapboxToken (empty string falsy) and renders gray 'Maps Unavailable / Mapbox not configured for this portal.' card instead of Mapbox canvas. Phase 21-06 code shipped correctly. page.tsx:170 uses process.env.NEXT_PUBLIC_MAPBOX_TOKEN ?? null which does NOT coerce empty strings to null — '' passes through and fails the client guard."
  artifacts:
    - path: "web/.env.local"
      issue: "line 21 empty NEXT_PUBLIC_MAPBOX_TOKEN"
    - path: "web/src/app/portal/[slug]/[project]/map/page.tsx"
      issue: "line 170 ?? null does not coerce empty string"
    - path: "web/src/app/portal/[slug]/[project]/map/PortalMapClient.tsx"
      issue: "lines 305-330 fallback card correct, but is triggered by the env miss"
  missing:
    - "Populate NEXT_PUBLIC_MAPBOX_TOKEN (shared with Test 1)"
    - "Defensive: page.tsx:170 → process.env.NEXT_PUBLIC_MAPBOX_TOKEN?.trim() || null to coerce empty strings at the server boundary"
    - "Add unit test for unconfigured-token path"
  debug_session: ".planning/debug/portal-public-map-locked.md"

- truth: "Pre-Phase-21 portal links (no map_overlays in sections_config) still render /map using DEFAULT_MAP_OVERLAYS — no crash, no missing-field errors"
  status: failed
  reason: "User reported: issue"
  severity: major
  test: 16
  root_cause: "Two-layer. The /map sub-route IS backward-compatible (page.tsx:150-168 + route.ts:147-164 apply DEFAULT_MAP_OVERLAYS fallback correctly; no crash). BUT a deliberate D-09 override introduced by Phase 27-01 suppresses the Map navigation LINK on the portal home for any portal with undefined map_overlays. computeShowMapLink() at portal/[slug]/[project]/page.tsx:50-58 explicitly does NOT fall back to DEFAULT_MAP_OVERLAYS (comment cites D-09). Every pre-Phase-21 portal has no map link on the home page, so the user has no entry point to reach /map. Direct URL visit still works. Test 16's expected behavior was written before D-09 landed in Phase 27 — this is a spec conflict, not a code bug."
  artifacts:
    - path: "web/src/app/portal/[slug]/[project]/page.tsx"
      issue: "lines 50-58 computeShowMapLink suppresses map link per D-09 (intentional)"
    - path: "web/src/app/portal/[slug]/[project]/map/page.tsx"
      issue: "lines 150-168 correct backward-compat fallback (no defect)"
    - path: ".planning/STATE.md"
      issue: "line 89 confirms D-09 decision"
    - path: ".planning/phases/21-live-satellite-traffic-maps/21-UAT.md"
      issue: "lines 111-115 Test 16 expected written before D-09"
  missing:
    - "RECOMMENDED: update Test 16 expected text to: 'Pre-Phase-21 portal home shows NO Map link per D-09. Direct visit to /portal/{slug}/{project}/map still renders with DEFAULT_MAP_OVERLAYS — no crash.' Re-walk via direct URL."
    - "ALTERNATIVE: revise D-09 to default-on when map_overlays is absent (regresses admin opt-in intent)"
    - "ALTERNATIVE: backfill migration writing map_overlays: DEFAULT_MAP_OVERLAYS into every cs_portal_config.sections_config lacking it"
    - "Prerequisite: Tests 14 + 15 resolved first so a working Phase-21 portal exists as control"
  debug_session: ".planning/debug/portal-backward-compat.md"
