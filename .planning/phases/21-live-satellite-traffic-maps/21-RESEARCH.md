# Phase 21: Live Satellite & Traffic Maps - Research

**Researched:** 2026-04-12 (updated 2026-04-12)
**Domain:** MapKit (iOS), Mapbox GL JS (web), Supabase equipment tracking, real-time traffic overlays
**Confidence:** HIGH

## Summary

Phase 21 enhances the existing map views on both platforms with real-time traffic overlays, equipment/vehicle/material tracking, GPS-tagged photo display, and delivery route visualization. Both platforms already have working map implementations -- iOS uses MapKit with `Map` SwiftUI view (`MapsView.swift`, 493 lines) and web uses Mapbox GL JS (`web/src/app/maps/page.tsx`, 218 lines). The work is primarily additive: new toggle buttons, new Supabase tables, new annotation/marker layers, and data source swap from hardcoded arrays to Supabase.

Traffic overlays use platform-native solutions at zero extra API cost: iOS MapKit's `.mapStyle(.hybrid(showsTraffic: true))` and Mapbox Traffic v1 vector tileset (`mapbox://mapbox.mapbox-traffic-v1`) on web. Equipment tracking requires two new Supabase tables (`cs_equipment`, `cs_equipment_locations`) with a manual check-in workflow on iOS. Delivery routes support both straight-line polylines (default) and road-following routes via MapKit Directions (iOS) / Mapbox Directions API (web).

Portal map overlay configuration extends the existing `PortalSectionsConfig` type and `sections_config` JSONB column from Phase 20. The portal already uses a typed JSON config per link; adding a `map_overlays` section follows the same pattern.

**Primary recommendation:** Implement in layers: (1) schema migration + Supabase data layer, (2) traffic toggle on both platforms, (3) equipment check-in + map markers, (4) photo overlay + delivery routes, (5) portal map configuration.

## Project Constraints (from CLAUDE.md)

- **File structure**: Don't break apart monolithic files -- fix bugs in place
- **Both platforms**: Fixes must cover both iOS Swift app and Next.js web app
- **Backward compatible**: Don't break existing features while fixing issues
- **Tests required**: Add tests for critical paths as we fix them
- **Supabase**: Use existing Supabase backend -- don't migrate to different database
- **Error handling**: Use `AppError` enum on iOS; `NextResponse.json({ error })` with status on web
- **State management**: `@State`, `@AppStorage`, `@StateObject` on iOS; `useState`, hooks on web
- **Design system**: `Theme` struct on iOS; CSS custom properties on web (`var(--surface)`, etc.)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Platform-native traffic overlays. iOS uses MapKit's built-in `.showsTraffic`. Web uses Mapbox Traffic v1 tile layer. Zero extra API cost, automatic updates.
- **D-02:** Traffic appears on Maps tab + client portal. Other map surfaces stay lightweight without traffic.
- **D-03:** Portal uses Mapbox traffic tiles (portal is web-only, Mapbox already in use).
- **D-04:** New TRAFFIC toggle button alongside existing overlay toggles (SATELLITE, THERMAL, CREWS, WEATHER, AUTO TRACK).
- **D-05:** Hybrid data entry model. Launch with manual crew check-in on iOS (select equipment, confirm GPS location). Data model supports future telematics API.
- **D-06:** All asset types trackable: equipment, vehicles, materials.
- **D-07:** Typed icons with status colors on map. Different icon shapes per asset type. Color: green=active, gold=idle, red=needs attention. Labels on tap/select.
- **D-08:** Flexible assignment model. Assets assigned to project OR org-wide pool. Filter by project, type, or status.
- **D-09:** Phase 21 includes the full check-in loop: iOS check-in UI -> store in Supabase -> display on map.
- **D-10:** Two Supabase tables: `cs_equipment` (master) + `cs_equipment_locations` (history with lat/lng/accuracy/source/recorded_at/recorded_by).
- **D-11:** Overlay preferences persist locally per device. iOS: AppStorage. Web: localStorage. No Supabase sync.
- **D-12:** Per-project camera position persists locally. iOS: `ConstructOS.Maps.Camera.{projectId}`.
- **D-13:** Portal maps have portal-specific overlay configuration per link. Client cannot toggle -- sees exactly what was configured.
- **D-14:** Supabase-first with mock fallback. New `cs_map_sites` table or extend `cs_projects` with location columns.
- **D-15:** Equipment positions load on map open. Pull-to-refresh (iOS) or refresh button (web). No real-time push or polling.
- **D-16:** Delivery routes support both visual connections (straight-line polylines) AND road-following routes via directions API. Visual connection is default; road route computed on demand.
- **D-17:** GPS-tagged photos appear as toggleable PHOTOS overlay. Shows markers at GPS coordinates from `cs_documents.gps_lat/gps_lng`. Tap to preview.

### Claude's Discretion
- Exact icon set for equipment types (SF Symbols on iOS, SVG on web)
- Map clustering behavior when many markers overlap at low zoom
- Thermal and weather overlay visual effects
- Satellite pass data model (keep mock or create Supabase table)
- Loading states for map data
- Equipment check-in form layout and field ordering
- RLS policy specifics for cs_equipment and cs_equipment_locations
- Whether delivery route polylines are cached or recomputed each session

### Deferred Ideas (OUT OF SCOPE)
- Telematics API integration (Samsara, Verizon Connect)
- Offline map tile caching
- Real-time WebSocket updates for equipment positions
- Route optimization / multi-stop routing
- Equipment CRUD management (add/edit/retire) -- minimal check-in UI only
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAP-01 | User can toggle between standard, satellite, and hybrid map layers on all map views | iOS: `.mapStyle(.standard/.hybrid/.imagery)` already partially implemented (satellite toggle exists). Web: Mapbox style switching between `satellite-streets-v12`, `dark-v11`, `streets-v12`. Add TRAFFIC toggle per D-04. |
| MAP-02 | User can see real-time traffic flow overlays on project area maps | iOS: `.mapStyle(.hybrid(showsTraffic: true))` [VERIFIED: Apple docs]. Web: Mapbox Traffic v1 tileset `mapbox://mapbox.mapbox-traffic-v1` added as vector source with congestion-colored line layer [VERIFIED: Mapbox docs]. |
| MAP-03 | User can view construction equipment/vehicle locations on a project site map | New `cs_equipment` + `cs_equipment_locations` Supabase tables per D-10. iOS check-in with CLLocationManager (reuse Phase 16 GPS pipeline). Typed map annotations with SF Symbols (iOS) / SVG markers (web). |
| MAP-04 | All map features (MapsView iOS, /maps web, field photos, project locations) use the enhanced map system | Data source swap from hardcoded arrays to Supabase fetch with mock fallback. Photo overlay reads `cs_documents.gps_lat/gps_lng` from Phase 16. Portal map configuration extends Phase 20 `sections_config` JSONB with `map_overlays` key. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MapKit (SwiftUI) | iOS 18.2+ / Swift 6.2 | iOS map rendering, annotations, polylines, traffic | Built-in, zero cost, `.showsTraffic` parameter on map styles [VERIFIED: Apple docs] |
| mapbox-gl | 3.21.0 | Web map rendering, markers, layers, popups | Already installed at ^3.20.0, latest is 3.21.0 [VERIFIED: npm registry] |
| @supabase/supabase-js | 2.101.1 | Database operations for equipment tracking | Already in project [VERIFIED: codebase] |
| CoreLocation | iOS 18.2+ | GPS coordinates for equipment check-in | Already used in Phase 16 [VERIFIED: codebase] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Mapbox Directions API | REST v5 | Road-following route geometry | On-demand when user requests road route (D-16) [CITED: docs.mapbox.com/api/navigation/directions/] |
| MKDirections | iOS 18.2+ | iOS road-following route geometry | On-demand road route calculation on iOS (D-16) [VERIFIED: Apple docs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual Mapbox traffic source + layers | @mapbox/mapbox-gl-traffic plugin (1.0.2) | Plugin is simpler but has no updates since v1, limited styling control. Manual approach gives full control over congestion colors matching the app theme. **Recommend manual approach** for theme consistency. |
| Mapbox Directions REST API | @mapbox/mapbox-gl-directions plugin | Plugin adds full search UI we don't want. REST API is better for programmatic route-only use. Use REST API directly. |
| MKClusterAnnotation (iOS) | Manual clustering | MKClusterAnnotation is built-in; manual gives more control. Use built-in for simplicity. |

**Installation:**
```bash
# No new npm packages needed. Mapbox traffic uses manual source/layer approach.
# Mapbox GL JS 3.21.0 already installed.
```

**Version verification:**
- mapbox-gl: 3.21.0 (latest, installed at ^3.20.0) [VERIFIED: npm registry 2026-04-12]
- @mapbox/mapbox-gl-traffic: 1.0.2 available but NOT recommended -- manual approach preferred for theme control [VERIFIED: npm registry 2026-04-12]
- vitest: 4.1.4 (installed) [VERIFIED: local npx]
- Node.js: 25.8.2, npm: 11.11.1 [VERIFIED: local]
- Xcode: 26.3, Swift: 6.2.4 [VERIFIED: local]

## Architecture Patterns

### Recommended Project Structure
```
ready player 8/
  MapsView.swift              # Enhanced with traffic toggle, equipment layer, photo overlay
  EquipmentCheckInView.swift  # NEW: Equipment check-in sheet (GPS + equipment selection)
  EquipmentModels.swift       # NEW: Equipment, EquipmentLocation Codable models
  SupabaseService.swift       # Extended with cs_equipment, cs_equipment_locations methods

web/src/app/maps/
  page.tsx                    # Enhanced with traffic layer, equipment markers, photo markers
  _components/                # NEW: extracted map sub-components (optional, inline ok per project style)
    EquipmentMarker.tsx       # Equipment marker with typed icon + status color
    PhotoMarker.tsx           # Photo thumbnail marker

web/src/lib/portal/
  types.ts                    # Extended: PortalSectionsConfig adds map_overlays
```

### Pattern 1: Traffic Overlay Toggle (iOS)
**What:** MapKit `.mapStyle()` modifier with `showsTraffic` parameter
**When to use:** When user toggles TRAFFIC button
**Example:**
```swift
// Source: Apple Developer Documentation - MapKit for SwiftUI
@State private var trafficOverlay = false

var body: some View {
    Map(position: $cameraPosition) {
        // annotations...
    }
    .mapStyle(
        satelliteMode
            ? .hybrid(elevation: .realistic, showsTraffic: trafficOverlay)
            : .standard(showsTraffic: trafficOverlay)
    )
}
```
[VERIFIED: Apple docs showsTraffic parameter on MapStyle]

### Pattern 2: Traffic Overlay Toggle (Web / Mapbox) -- Manual Approach
**What:** Add Mapbox Traffic v1 as a vector source with congestion-colored line layer using app theme colors
**When to use:** When user toggles TRAFFIC button on web
**Example:**
```typescript
// Source: docs.mapbox.com/data/tilesets/reference/mapbox-traffic-v1/
// Manual source + layer for full theme control
function addTrafficLayer(map: mapboxgl.Map) {
  if (map.getSource('mapbox-traffic')) return;

  map.addSource('mapbox-traffic', {
    type: 'vector',
    url: 'mapbox://mapbox.mapbox-traffic-v1'
  });
  map.addLayer({
    id: 'traffic-layer',
    type: 'line',
    source: 'mapbox-traffic',
    'source-layer': 'traffic',
    paint: {
      'line-color': [
        'match', ['get', 'congestion'],
        'low', '#69D294',       // var(--green)
        'moderate', '#FCC757',  // var(--gold)
        'heavy', '#FF8C42',     // orange
        'severe', '#D94D48',    // var(--red)
        '#69D294'               // default
      ],
      'line-width': 2,
      'line-opacity': 0.7
    }
  });
}

function removeTrafficLayer(map: mapboxgl.Map) {
  if (map.getLayer('traffic-layer')) map.removeLayer('traffic-layer');
  if (map.getSource('mapbox-traffic')) map.removeSource('mapbox-traffic');
}
```
[VERIFIED: Mapbox Traffic v1 tileset docs -- congestion property values are 'low', 'moderate', 'heavy', 'severe']

### Pattern 3: Equipment Check-in (iOS)
**What:** Sheet-based form with CLLocationManager for GPS capture
**When to use:** User taps "Check In Equipment" on Maps tab
**Example:**
```swift
// Source: Project pattern from Phase 16 FieldPhotoCaptureView.swift
struct EquipmentCheckInView: View {
    @State private var selectedEquipment: Equipment?
    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var accuracy: CLLocationAccuracy = 0
    
    var body: some View {
        NavigationStack {
            Form {
                // Equipment picker (from cs_equipment)
                // Current GPS coordinates display
                // Status selector (active/idle/needs_attention)
                // Notes field
            }
            .task { await captureLocation() }
        }
    }
}
```
[ASSUMED: Form structure -- discretion item]

### Pattern 4: Road-Following Route (iOS)
**What:** MKDirections request returning MKRoute with polyline
**When to use:** User requests road route for delivery (D-16 on-demand)
**Example:**
```swift
// Source: Apple MKDirections documentation
func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
    request.transportType = .automobile
    
    let directions = MKDirections(request: request)
    do {
        let response = try await directions.calculate()
        return response.routes.first
    } catch {
        CrashReporter.shared.reportError("MKDirections failed: \(error.localizedDescription)")
        return nil
    }
}

// Display in Map view:
if let route {
    MapPolyline(route.polyline)
        .stroke(Theme.gold, lineWidth: 4)
}
```
[VERIFIED: Apple MKDirections docs + SwiftUI MapPolyline API]

### Pattern 5: Road-Following Route (Web / Mapbox Directions API)
**What:** REST call to Mapbox Directions API returning GeoJSON route geometry
**When to use:** User requests road route for delivery on web
**Example:**
```typescript
// Source: docs.mapbox.com/api/navigation/directions/
async function fetchRoute(from: [number, number], to: [number, number]): Promise<GeoJSON.LineString | null> {
  const token = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
  const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${from[0]},${from[1]};${to[0]},${to[1]}?geometries=geojson&overview=full&access_token=${token}`;
  
  const res = await fetch(url);
  if (!res.ok) return null;
  
  const data = await res.json();
  return data.routes?.[0]?.geometry ?? null;
}

// Add to map as GeoJSON source + line layer
map.addSource('route-1', {
  type: 'geojson',
  data: { type: 'Feature', geometry: routeGeometry, properties: {} }
});
map.addLayer({
  id: 'route-1-line',
  type: 'line',
  source: 'route-1',
  paint: { 'line-color': '#FCC757', 'line-width': 4 }
});
```
[CITED: docs.mapbox.com/api/navigation/directions/]

### Pattern 6: Portal Map Overlay Configuration (D-13)
**What:** Extend `PortalSectionsConfig` type with a `map_overlays` field
**When to use:** When creating/editing portal links
**Example:**
```typescript
// Source: Verified from web/src/lib/portal/types.ts (Phase 20 implementation)
// PortalSectionsConfig currently has: schedule, budget, photos, change_orders, documents
// Each is { enabled: boolean, ... }. Extend with:

export type PortalMapOverlays = {
  show_map: boolean;
  satellite: boolean;
  traffic: boolean;
  equipment: boolean;
  photos: boolean;
};

// Add to PortalSectionsConfig:
export type PortalSectionsConfig = {
  schedule: { enabled: boolean; date_range?: { start: string; end: string } };
  budget: { enabled: boolean; date_range?: { start: string; end: string } };
  photos: { enabled: boolean; date_range?: { start: string; end: string } };
  change_orders: { enabled: boolean; date_range?: { start: string; end: string } };
  documents: { enabled: boolean; allowed_document_ids?: string[] };
  map_overlays?: PortalMapOverlays;  // NEW: Phase 21
};
```
[VERIFIED: Portal types.ts structure confirmed from codebase -- sections_config is JSONB, extensible]

### Anti-Patterns to Avoid
- **Polling for equipment positions:** D-15 explicitly says pull-to-refresh only, no polling. Do not add setInterval for position updates.
- **Syncing overlay preferences to Supabase:** D-11 says local-only. Do not create a user_preferences table for map overlays.
- **Building a full fleet management UI:** D-09 limits scope to check-in loop only. No equipment CRUD (create/edit/retire).
- **Using mapbox-gl-directions plugin for route display:** The plugin adds search UI we do not want. Use the Directions REST API directly for geometry, then render as a GeoJSON layer.
- **Breaking apart MapsView.swift:** CLAUDE.md says don't break apart monolithic files. Add new views (EquipmentCheckInView, EquipmentModels) as separate files but extend MapsView in place.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Traffic overlay data | Custom traffic API integration | MapKit `.showsTraffic` / Mapbox Traffic v1 tileset | Platform-native, free, auto-updating, zero maintenance |
| Map marker clustering | Custom spatial grouping algorithm | MapKit `MKClusterAnnotation` / Mapbox GL built-in `cluster: true` on GeoJSON source | Proven clustering with smooth animations, handles thousands of points |
| Road-following routes | Waypoint-to-waypoint line drawing | MKDirections / Mapbox Directions API | Follows actual road geometry, provides ETA + distance |
| GPS coordinate capture | Manual `navigator.geolocation` wrapper | CLLocationManager (iOS, reuse Phase 16) | Already implemented with accuracy tracking and permission handling |
| HTML escaping in popups | Custom sanitizer | Existing `escapeHtml()` function in maps/page.tsx | Already present and tested |

**Key insight:** Both platforms have mature, built-in mapping ecosystems. Traffic, directions, clustering, and annotation rendering are all solved problems. The custom work is data modeling (equipment tables) and UI integration (toggle buttons, check-in form, marker styling).

## Common Pitfalls

### Pitfall 1: Mapbox Style Change Destroys Layers
**What goes wrong:** Calling `map.setStyle()` removes all custom sources and layers (traffic, equipment markers, route lines).
**Why it happens:** Mapbox GL JS treats `setStyle` as a full replacement. The existing code already calls `setStyle` when toggling satellite mode (line 128 of maps/page.tsx).
**How to avoid:** Listen for the `style.load` event after each `setStyle` call and re-add all custom sources and layers. Store the current layer state so it can be reconstructed.
**Warning signs:** Markers/layers disappear after toggling SATELLITE overlay.

### Pitfall 2: MapKit MapPolyline Route Display
**What goes wrong:** `MapPolyline(route.polyline)` requires an `MKRoute` object, not raw coordinates. Confusing the two patterns leads to compiler errors.
**Why it happens:** SwiftUI MapKit has two `MapPolyline` initializers: one from `MKPolyline` (for routes) and one from `[CLLocationCoordinate2D]` (for manual lines).
**How to avoid:** Use `MapPolyline(coordinates:)` for straight-line visual connections (D-16 default). Use `MapPolyline(route.polyline)` only when you have an actual MKRoute from MKDirections.
**Warning signs:** Type mismatch errors in Map content builder.

### Pitfall 3: Equipment Location History Table Growth
**What goes wrong:** `cs_equipment_locations` grows unbounded as check-ins accumulate.
**Why it happens:** Each check-in creates a new row (location history per D-10).
**How to avoid:** Add an index on `(equipment_id, recorded_at DESC)` for efficient latest-location queries. Consider a retention policy (90 days) as a future concern but not Phase 21 scope.
**Warning signs:** Slow "latest equipment positions" queries once table exceeds ~100K rows.

### Pitfall 4: Mapbox Token Exposure in Portal
**What goes wrong:** Mapbox access token used in portal maps is visible in client-rendered pages.
**Why it happens:** Portal pages are public (token-only access per Phase 20 D-06). The `NEXT_PUBLIC_MAPBOX_TOKEN` is exposed in client JS.
**How to avoid:** Use Mapbox URL restrictions (restrict token to specific domains). This is the standard pattern -- Mapbox tokens are designed to be public with domain restrictions.
**Warning signs:** Token usage spikes from unauthorized domains.

### Pitfall 5: CLLocationManager Permission Flow
**What goes wrong:** Equipment check-in silently fails to get GPS if location permission was never requested or was denied.
**Why it happens:** CLLocationManager requires explicit authorization request.
**How to avoid:** Reuse Phase 16's permission flow. Check `CLLocationManager.authorizationStatus` before attempting capture. Show clear error if denied per UI-SPEC copy.
**Warning signs:** Equipment locations stored with null/zero coordinates.

### Pitfall 6: Mapbox Traffic Layer on Style Reload
**What goes wrong:** Traffic layer must be re-added after satellite/dark style toggle since `setStyle` clears all layers.
**Why it happens:** Same root cause as Pitfall 1, but specifically affects the traffic source which uses `mapbox://mapbox.mapbox-traffic-v1` URL.
**How to avoid:** Track `trafficEnabled` state separately and re-add in `style.load` handler.
**Warning signs:** Traffic disappears after toggling SATELLITE.

## Code Examples

### Supabase Schema: Equipment Tables (D-10)
```sql
-- Source: Decision D-10 from CONTEXT.md
create table if not exists cs_equipment (
  id              uuid primary key default gen_random_uuid(),
  org_id          uuid not null,
  name            text not null,
  type            text not null check (type in ('equipment', 'vehicle', 'material')),
  subtype         text,  -- e.g., 'crane', 'excavator', 'concrete_truck', 'steel'
  assigned_project uuid references cs_projects(id),
  status          text not null default 'active' check (status in ('active', 'idle', 'needs_attention')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create table if not exists cs_equipment_locations (
  id              uuid primary key default gen_random_uuid(),
  equipment_id    uuid not null references cs_equipment(id) on delete cascade,
  lat             numeric(9,6) not null,
  lng             numeric(9,6) not null,
  accuracy_m      numeric,
  source          text not null default 'manual' check (source in ('manual', 'gps_tracker', 'telematics')),
  recorded_at     timestamptz not null default now(),
  recorded_by     uuid references auth.users(id),
  notes           text
);

create index cs_equipment_org_idx on cs_equipment(org_id);
create index cs_equipment_project_idx on cs_equipment(assigned_project);
create index cs_equip_loc_latest_idx on cs_equipment_locations(equipment_id, recorded_at desc);
```
[ASSUMED: Schema details -- follows established project patterns from existing migrations]

### Extending cs_projects with Location Columns (D-14)
```sql
-- Add lat/lng to existing cs_projects for map site display
-- cs_projects currently has: id, name, client, type, status, progress, budget, score, team, created_at
-- No location columns exist yet [VERIFIED: SupabaseService.swift schema comments]
alter table cs_projects add column if not exists lat numeric(9,6);
alter table cs_projects add column if not exists lng numeric(9,6);
```
[VERIFIED: cs_projects schema confirmed from SupabaseService.swift -- no lat/lng columns present]

### RLS Policies (Equipment)
```sql
-- Source: Follows org_id pattern from existing migrations
alter table cs_equipment enable row level security;
alter table cs_equipment_locations enable row level security;

create policy "Users read own org equipment"
  on cs_equipment for select
  using (org_id = (auth.jwt() ->> 'org_id')::uuid);

create policy "Users insert own org equipment"
  on cs_equipment for insert
  with check (org_id = (auth.jwt() ->> 'org_id')::uuid);

create policy "Users read own org equipment locations"
  on cs_equipment_locations for select
  using (equipment_id in (
    select id from cs_equipment where org_id = (auth.jwt() ->> 'org_id')::uuid
  ));

create policy "Users insert equipment locations"
  on cs_equipment_locations for insert
  with check (equipment_id in (
    select id from cs_equipment where org_id = (auth.jwt() ->> 'org_id')::uuid
  ));
```
[ASSUMED: RLS structure -- discretion item, follows project pattern]

### Mapbox Clustering for Equipment Markers (Web)
```typescript
// Source: docs.mapbox.com/mapbox-gl-js/example/cluster/
map.addSource('equipment', {
  type: 'geojson',
  data: equipmentGeoJSON,
  cluster: true,
  clusterMaxZoom: 14,
  clusterRadius: 50
});

map.addLayer({
  id: 'equipment-clusters',
  type: 'circle',
  source: 'equipment',
  filter: ['has', 'point_count'],
  paint: {
    'circle-color': ['step', ['get', 'point_count'], '#69D294', 10, '#FCC757', 30, '#D94D48'],
    'circle-radius': ['step', ['get', 'point_count'], 15, 10, 20, 30, 25]
  }
});

// Unclustered individual equipment markers use DOM elements (matching existing site marker pattern)
```
[CITED: docs.mapbox.com/mapbox-gl-js/example/cluster/]

### iOS Equipment Annotation with SF Symbols
```swift
// Source: MapKit Annotation API + project Theme pattern
ForEach(equipmentItems) { item in
    Annotation(item.name, coordinate: item.coordinate, anchor: .bottom) {
        VStack(spacing: 2) {
            Image(systemName: item.sfSymbolName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(item.statusColor)  // green/gold/red per D-07
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
            
            if selectedEquipmentID == item.id {
                Text(item.name)
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Theme.surface.opacity(0.85))
                    .cornerRadius(4)
            }
        }
        .onTapGesture { selectedEquipmentID = item.id }
    }
}
```
[ASSUMED: SF Symbol approach -- discretion item]

### Recommended SF Symbols per Asset Type
```swift
// Discretion recommendation: SF Symbols for equipment types
extension Equipment {
    var sfSymbolName: String {
        switch type {
        case "equipment":
            switch subtype {
            case "crane": return "arrow.up.and.down.and.sparkles"
            case "excavator": return "snowplow"
            case "forklift": return "shippingbox.and.arrow.clockwise"
            default: return "wrench.and.screwdriver"
            }
        case "vehicle":
            return "truck.box"
        case "material":
            return "shippingbox"
        default:
            return "mappin"
        }
    }
    
    var statusColor: Color {
        switch status {
        case "active": return Theme.green
        case "idle": return Theme.gold
        case "needs_attention": return Theme.red
        default: return Theme.muted
        }
    }
}
```
[ASSUMED: Specific SF Symbol choices -- discretion item]

### Latest Equipment Positions Query Pattern
```typescript
// Fetch latest position per equipment item (uses DISTINCT ON in Postgres)
// Source: Established Supabase fetch pattern from web/src/lib/supabase/fetch.ts
const { data } = await supabase
  .from('cs_equipment_locations')
  .select('*, cs_equipment!inner(*)')
  .order('recorded_at', { ascending: false });

// For latest-per-equipment, use a Supabase RPC or view:
// CREATE VIEW cs_equipment_latest_positions AS
// SELECT DISTINCT ON (equipment_id) * FROM cs_equipment_locations
// ORDER BY equipment_id, recorded_at DESC;
```
[ASSUMED: Query pattern -- standard Postgres DISTINCT ON]

### Style Reload Handler (Pitfall 1 + 6 Prevention)
```typescript
// After setStyle(), all custom layers are removed. Re-add them.
function setupStyleReloadHandler(
  map: mapboxgl.Map,
  state: { trafficEnabled: boolean; equipmentGeoJSON: GeoJSON.FeatureCollection | null }
) {
  map.on('style.load', () => {
    // Re-add traffic if enabled
    if (state.trafficEnabled) addTrafficLayer(map);
    // Re-add equipment markers if data exists
    if (state.equipmentGeoJSON) addEquipmentLayer(map, state.equipmentGeoJSON);
    // Re-add site markers, route lines, photo markers...
  });
}
```
[VERIFIED: Mapbox GL JS `style.load` event fires after `setStyle` completes]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| MKMapView + UIViewRepresentable | SwiftUI `Map` view with native annotations | iOS 17+ (2023) | Already using new API in `LiveMapView` |
| mapbox-gl v1 markers | mapbox-gl v3 with symbol layers + expressions | 2024 | Current codebase uses v3 DOM markers; can upgrade to symbol layers for equipment |
| Manual traffic API integration | Platform-native traffic (MapKit showsTraffic / Mapbox Traffic v1) | Always available | Zero-cost, automatic updates |

**Deprecated/outdated:**
- `MKMapView.showsTraffic` property (UIKit): Still works but SwiftUI equivalent is `.mapStyle(.standard(showsTraffic: true))` [VERIFIED: Apple docs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Equipment schema structure (column names, constraints, types) | Code Examples - Schema | Low -- schema is flexible and follows established patterns |
| A2 | RLS policy structure using `auth.jwt() ->> 'org_id'` | Code Examples - RLS | Medium -- org_id JWT claim availability was flagged as unverified in Phase 17 decisions. Fallback: use user_orgs join like updateOwnedRow |
| A3 | SF Symbol names for equipment types | Code Examples - SF Symbols | Low -- symbols can be swapped easily; no functional impact |
| A4 | Equipment check-in form layout | Architecture Pattern 3 | Low -- discretion item, UI layout is flexible |
| A5 | `DISTINCT ON` query for latest equipment positions | Code Examples - Latest Positions | Low -- standard Postgres pattern; could also use subquery approach |

## Open Questions (RESOLVED)

1. **RESOLVED: cs_projects location columns vs. separate cs_map_sites table (D-14)**
   - What we know: D-14 says "New cs_map_sites table (or extend cs_projects with location columns)"
   - Resolution: Extend cs_projects with lat/lng columns (implemented in Plan 01 migration)
   - Recommendation: Extend `cs_projects` with `lat`/`lng` columns. Projects already have a `location` text field (city name). Adding coordinates avoids a join table. Simpler migration. [VERIFIED: cs_projects has no lat/lng columns currently]

2. **RESOLVED: Satellite pass data source**
   - What we know: Both platforms display mock satellite pass data (hardcoded arrays)
   - Resolution: Keep mock data -- no real external source in this app context
   - Recommendation: Keep mock data. Satellite pass data has no real external source in this app context. Focus effort on equipment tracking.

3. **RESOLVED: Delivery route caching (discretion)**
   - What we know: D-16 says road routes are computed on demand
   - Resolution: Do NOT cache -- on-demand only, re-computing is fast
   - Recommendation: Do NOT cache. Routes are computed rarely (user clicks "Get Directions"). Re-computing is fast (~500ms). Caching adds staleness risk.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | iOS builds | Yes | 26.3 | -- |
| Swift | iOS code | Yes | 6.2.4 | -- |
| Node.js | Web builds | Yes | 25.8.2 | -- |
| npm | Package management | Yes | 11.11.1 | -- |
| vitest | Web tests | Yes | 4.1.4 | -- |
| mapbox-gl | Web maps | Yes | ^3.20.0 (3.21.0 latest) | -- |
| MapKit | iOS maps | Yes | Built-in (iOS 18.2+) | -- |
| CoreLocation | GPS capture | Yes | Built-in (iOS 18.2+) | -- |
| Supabase | Data storage | Yes | 2.101.1 (JS client) | Mock data fallback |
| Mapbox Directions API | Road routes (web) | Yes (via Mapbox token) | REST v5 | Straight-line fallback |
| MKDirections | Road routes (iOS) | Yes | Built-in | Straight-line fallback |

**Missing dependencies with no fallback:** None

**Missing dependencies with fallback:** None

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework (web) | vitest 4.1.4 |
| Framework (iOS) | XCTest |
| Config file (web) | `web/vitest.config.ts` |
| Quick run command (web) | `cd web && npx vitest run --reporter=verbose` |
| Quick run command (iOS) | `xcodebuild test -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 16"` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAP-01 | Map layer toggle (standard/satellite/hybrid) | unit (web) | `cd web && npx vitest run src/app/maps/__tests__/map-layers.test.ts -x` | Wave 0 |
| MAP-02 | Traffic overlay toggle + data source | unit (web) + unit (iOS) | `cd web && npx vitest run src/app/maps/__tests__/traffic-overlay.test.ts -x` | Wave 0 |
| MAP-03 | Equipment location CRUD + display | unit (web) + unit (iOS) | `cd web && npx vitest run src/app/maps/__tests__/equipment-tracking.test.ts -x` | Wave 0 |
| MAP-04 | All map surfaces use enhanced system | integration (manual) | Manual verification -- multiple map surfaces | Manual-only: requires visual verification across 4 surfaces |

### Sampling Rate
- **Per task commit:** `cd web && npx vitest run --reporter=verbose`
- **Per wave merge:** `cd web && npx vitest run --reporter=verbose` + Xcode test run
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `web/src/app/maps/__tests__/map-layers.test.ts` -- covers MAP-01
- [ ] `web/src/app/maps/__tests__/traffic-overlay.test.ts` -- covers MAP-02
- [ ] `web/src/app/maps/__tests__/equipment-tracking.test.ts` -- covers MAP-03
- [ ] `ready player 8Tests/Phase21/EquipmentModelsTests.swift` -- covers MAP-03 (iOS models)
- [ ] `ready player 8Tests/Phase21/EquipmentCheckInTests.swift` -- covers MAP-03 (iOS check-in)
- [ ] `web/src/app/maps/__tests__/photo-overlay.test.ts` -- covers MAP-04 (photo layer)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Equipment check-in requires authenticated user (existing auth) |
| V3 Session Management | No | Uses existing session management |
| V4 Access Control | Yes | RLS on cs_equipment + cs_equipment_locations (org_id scoping) |
| V5 Input Validation | Yes | Validate lat/lng ranges (-90/90, -180/180), equipment type enum, status enum |
| V6 Cryptography | No | No crypto needed |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-org equipment data access | Information Disclosure | RLS policies scoped to org_id via JWT claim |
| GPS coordinate spoofing | Tampering | Accept as-is for manual check-in; note `source: manual` in location record |
| Mapbox token abuse | Denial of Service | Domain-restricted Mapbox token (existing pattern) |
| Portal map data leakage | Information Disclosure | Portal overlay configuration limits what clients see (D-13) |
| XSS in equipment name/notes | Tampering | Escape all user-provided strings in map popups (existing `escapeHtml` function on web) |
| Invalid lat/lng injection | Tampering | Server-side validation: lat in [-90,90], lng in [-180,180], reject nulls |

## Sources

### Primary (HIGH confidence)
- Apple MapKit for SwiftUI documentation -- showsTraffic parameter, MapPolyline, MKDirections
- Mapbox Traffic v1 tileset reference (docs.mapbox.com/data/tilesets/reference/mapbox-traffic-v1/) -- source ID, congestion levels, properties
- Mapbox GL JS clustering example (docs.mapbox.com/mapbox-gl-js/example/cluster/) -- GeoJSON source clustering
- npm registry -- mapbox-gl 3.21.0, @mapbox/mapbox-gl-traffic 1.0.2 [VERIFIED: 2026-04-12]
- Codebase analysis -- MapsView.swift (493 lines), web/src/app/maps/page.tsx (218 lines), ThemeAndModels.swift (models at lines 136-225), SupabaseService.swift (schema + CRUD), web/src/lib/portal/types.ts (PortalSectionsConfig structure)

### Secondary (MEDIUM confidence)
- Mapbox Directions API docs (docs.mapbox.com/api/navigation/directions/) -- REST endpoint format, geometry options
- Phase 16 CONTEXT.md -- GPS capture decisions (D-02, D-05, D-06)
- Phase 20 CONTEXT.md -- Portal architecture decisions (D-01, D-07)

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries verified via npm registry and codebase; platform APIs verified via official docs
- Architecture: HIGH -- extending well-understood existing patterns; both map views already working; portal types verified from codebase
- Pitfalls: HIGH -- based on direct codebase analysis (style change issue visible in existing code) and known MapKit/Mapbox patterns

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (stable -- MapKit and Mapbox GL JS are mature, slow-moving APIs)
