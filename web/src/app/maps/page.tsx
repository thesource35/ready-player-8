"use client";
import { useEffect, useRef, useState, useCallback } from "react";
import type { EquipmentWithPosition, GpsPhoto, MapSiteRow, MapOverlayKey } from "@/lib/maps/types";
import { ALL_OVERLAY_KEYS, DEFAULT_ACTIVE_OVERLAYS, STATUS_COLORS, EQUIPMENT_ICONS, MAP_STORAGE_KEYS } from "@/lib/maps/types";

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

const sites = [
  { name: "Riverside Lofts", lat: 29.7604, lng: -95.3698, status: "ACTIVE", crews: 24, deliveries: 3, alerts: 1, zone: "Zone A — North" },
  { name: "Harbor Crossing", lat: 29.7480, lng: -95.3580, status: "ACTIVE", crews: 18, deliveries: 1, alerts: 0, zone: "Zone B — East" },
  { name: "Pine Ridge Ph.2", lat: 29.7855, lng: -95.4010, status: "DELAYED", crews: 12, deliveries: 2, alerts: 2, zone: "Zone C — West" },
  { name: "Skyline Tower", lat: 29.7590, lng: -95.3694, status: "MOBILIZING", crews: 6, deliveries: 0, alerts: 0, zone: "Zone A — Downtown" },
];

const satellites = [
  { name: "SAT-A1", eta: "04 min", coverage: "North yard", confidence: 97, color: "#4AC4CC" },
  { name: "SAT-C4", eta: "19 min", coverage: "Concrete deck", confidence: 91, color: "#FCC757" },
  { name: "THERM-2", eta: "42 min", coverage: "Roof membrane", confidence: 88, color: "#69D294" },
];

const routes = [
  { from: "Yard / Staging", to: "Riverside Lofts", fromLng: -95.38, fromLat: 29.77, toLng: -95.3698, toLat: 29.7604, distance: "4.2 mi", eta: "12 min", traffic: "Light" },
  { from: "Concrete Batch Plant", to: "Harbor Crossing", fromLng: -95.34, fromLat: 29.76, toLng: -95.3580, toLat: 29.7480, distance: "8.7 mi", eta: "22 min", traffic: "Moderate" },
  { from: "Steel Fabricator", to: "Skyline Tower", fromLng: -95.40, fromLat: 29.79, toLng: -95.3694, toLat: 29.7590, distance: "15.3 mi", eta: "35 min", traffic: "Heavy" },
];

const overlays = ALL_OVERLAY_KEYS;

// ---------- helpers for traffic layer ----------

function addTrafficLayer(map: mapboxgl.Map) {
  if (map.getSource("mapbox-traffic")) return;
  map.addSource("mapbox-traffic", { type: "vector", url: "mapbox://mapbox.mapbox-traffic-v1" });
  map.addLayer({
    id: "traffic-layer",
    type: "line",
    source: "mapbox-traffic",
    "source-layer": "traffic",
    paint: {
      "line-color": [
        "match", ["get", "congestion"],
        "low", "#69D294",
        "moderate", "#FCC757",
        "heavy", "#FF8C42",
        "severe", "#D94D48",
        "#69D294",
      ],
      "line-width": 2,
      "line-opacity": 0.7,
    },
  });
}

function removeTrafficLayer(map: mapboxgl.Map) {
  if (map.getLayer("traffic-layer")) map.removeLayer("traffic-layer");
  if (map.getSource("mapbox-traffic")) map.removeSource("mapbox-traffic");
}

// ---------- type for mapboxgl (dynamic import) ----------
type MapboxGL = typeof import("mapbox-gl");
let _mapboxgl: MapboxGL | null = null;

export default function MapsPage() {
  const mapContainer = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const [mapLoaded, setMapLoaded] = useState(false);
  const [mapStyle, setMapStyle] = useState("satellite");
  const [activeOverlays, setActiveOverlays] = useState<Set<MapOverlayKey>>(() => {
    if (typeof window === "undefined") return new Set(DEFAULT_ACTIVE_OVERLAYS);
    const saved = localStorage.getItem(MAP_STORAGE_KEYS.overlays);
    return saved ? new Set(JSON.parse(saved) as MapOverlayKey[]) : new Set(DEFAULT_ACTIVE_OVERLAYS);
  });
  // Phase 21 Plan 07 Task 1: coerce empty-string + whitespace-only to null at both
  // token-read sites so the "Maps Unavailable" fallback renders deterministically
  // when NEXT_PUBLIC_MAPBOX_TOKEN is unset. Mirrors the portal /map server-boundary
  // contract so both pages fail the same visible way instead of half-initializing.
  const token = (process.env.NEXT_PUBLIC_MAPBOX_TOKEN ?? "").trim() || null;

  // Data state
  const [equipmentPositions, setEquipmentPositions] = useState<EquipmentWithPosition[]>([]);
  const [gpsPhotos, setGpsPhotos] = useState<GpsPhoto[]>([]);
  const [mapSites, setMapSites] = useState<MapSiteRow[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [equipmentFilter, setEquipmentFilter] = useState<string>("all");
  const [routeDirections, setRouteDirections] = useState<Record<string, { duration: string; distance: string; error?: string }>>({});
  // Phase 21 Plan 08 Task 1: gate the "NO EQUIPMENT TRACKED YET" empty-state chip
  // on first-response completion so a loading tick does not flash the chip.
  const [isLoadingData, setIsLoadingData] = useState(true);

  // Marker refs
  const equipmentMarkersRef = useRef<mapboxgl.Marker[]>([]);
  const photoMarkersRef = useRef<mapboxgl.Marker[]>([]);
  const siteMarkersRef = useRef<mapboxgl.Marker[]>([]);

  // Persist overlay changes
  useEffect(() => {
    localStorage.setItem(MAP_STORAGE_KEYS.overlays, JSON.stringify([...activeOverlays]));
  }, [activeOverlays]);

  const toggleOverlay = (name: MapOverlayKey) => {
    setActiveOverlays(prev => {
      const next = new Set(prev);
      if (next.has(name)) next.delete(name); else next.add(name);
      return next;
    });
  };

  // ---------- data loading ----------

  const loadMapData = useCallback(async () => {
    try {
      const results = await Promise.allSettled([
        fetch("/api/maps/equipment").then(r => r.json()),
        fetch("/api/maps/photos").then(r => r.json()),
        fetch("/api/maps/sites").then(r => r.json()),
      ]);
      if (results[0].status === "fulfilled") setEquipmentPositions(results[0].value.data ?? []);
      if (results[1].status === "fulfilled") setGpsPhotos(results[1].value.data ?? []);
      if (results[2].status === "fulfilled") setMapSites(results[2].value.data ?? []);
    } finally {
      // Phase 21 Plan 08 Task 1: flip loading flag regardless of outcome so the
      // empty-state chip can render if every fetch legitimately returned [].
      setIsLoadingData(false);
    }
  }, []);

  // ---------- rebuild marker functions ----------

  const rebuildSiteMarkers = useCallback((map: mapboxgl.Map) => {
    siteMarkersRef.current.forEach(m => m.remove());
    siteMarkersRef.current = [];
    if (!_mapboxgl) return;

    const siteData = mapSites.length > 0 ? mapSites : sites;
    siteData.forEach(site => {
      if (site.lat == null || site.lng == null) return;
      const color = site.status === "ACTIVE" ? "#69D294" : site.status === "DELAYED" ? "#D94D48" : "#FCC757";
      const el = document.createElement("div");
      el.style.cssText = `width:16px;height:16px;border-radius:50%;background:${color};border:2px solid white;box-shadow:0 0 10px ${color};cursor:pointer;`;

      const marker = new _mapboxgl!.Marker({ element: el })
        .setLngLat([site.lng!, site.lat!])
        .addTo(map);

      el.addEventListener("click", () => {
        if (!marker.getPopup()) {
          const popup = new _mapboxgl!.Popup({ offset: 25, closeButton: false }).setHTML(`
            <div style="background:#0F1C24;color:#F0F8F8;padding:10px;border-radius:8px;min-width:160px;font-family:system-ui;">
              <div style="font-size:12px;font-weight:800;margin-bottom:4px;">${escapeHtml(site.name)}</div>
              <div style="font-size:9px;color:${escapeHtml(color)};font-weight:900;margin-bottom:6px;">${escapeHtml(site.status)}</div>
              <div style="font-size:10px;color:#9EBDC2;">
                ${escapeHtml(String("crews" in site ? (site as { crews: number }).crews : 0))} crews &bull;
                ${escapeHtml(String("deliveries" in site ? (site as { deliveries: number }).deliveries : 0))} deliveries &bull;
                ${escapeHtml(String("alerts" in site ? (site as { alerts: number }).alerts : 0))} alerts
              </div>
            </div>
          `);
          marker.setPopup(popup);
        }
        marker.togglePopup();
      });

      siteMarkersRef.current.push(marker);
    });
  }, [mapSites]);

  const rebuildEquipmentMarkers = useCallback((map: mapboxgl.Map) => {
    equipmentMarkersRef.current.forEach(m => m.remove());
    equipmentMarkersRef.current = [];
    if (!_mapboxgl) return;

    equipmentPositions.forEach(item => {
      const iconInfo = EQUIPMENT_ICONS[item.type] ?? EQUIPMENT_ICONS.equipment;
      const statusColor = STATUS_COLORS[item.status] ?? STATUS_COLORS.active;

      const el = document.createElement("div");
      let borderRadius = "50%";
      let transform = "";
      if (iconInfo.shape === "rounded-square") {
        borderRadius = "4px";
      } else if (iconInfo.shape === "diamond") {
        borderRadius = "2px";
        transform = "transform:rotate(45deg);";
      }
      el.style.cssText = `width:16px;height:16px;border-radius:${borderRadius};background:${statusColor};border:2px solid white;box-shadow:0 0 10px ${statusColor};cursor:pointer;${transform}`;

      const marker = new _mapboxgl!.Marker({ element: el })
        .setLngLat([item.latest_lng, item.latest_lat])
        .addTo(map);

      el.addEventListener("click", () => {
        if (!marker.getPopup()) {
          const popup = new _mapboxgl!.Popup({ offset: 25, closeButton: false }).setHTML(`
            <div style="background:#0F1C24;color:#F0F8F8;padding:10px;border-radius:8px;min-width:160px;font-family:system-ui;">
              <div style="font-size:12px;font-weight:800;margin-bottom:4px;">${escapeHtml(item.name)}</div>
              <div style="font-size:9px;font-weight:900;margin-bottom:4px;">
                <span style="color:${escapeHtml(statusColor)}">${escapeHtml(item.status)}</span>
                <span style="color:#9EBDC2;margin-left:6px">${escapeHtml(item.type)}</span>
              </div>
              <div style="font-size:10px;color:#9EBDC2;">
                Last: ${escapeHtml(item.latest_recorded_at ? new Date(item.latest_recorded_at).toLocaleString() : "N/A")}
              </div>
            </div>
          `);
          marker.setPopup(popup);
        }
        marker.togglePopup();
      });

      equipmentMarkersRef.current.push(marker);
    });
  }, [equipmentPositions]);

  const rebuildPhotoMarkers = useCallback((map: mapboxgl.Map) => {
    photoMarkersRef.current.forEach(m => m.remove());
    photoMarkersRef.current = [];
    if (!_mapboxgl || !activeOverlays.has("PHOTOS")) return;

    gpsPhotos.forEach(photo => {
      const el = document.createElement("div");
      el.style.cssText = "width:14px;height:14px;border-radius:50%;background:#8A8FCC;border:2px solid white;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:8px;color:white;";
      el.textContent = "\u{1F4F7}";

      const marker = new _mapboxgl!.Marker({ element: el })
        .setLngLat([photo.gps_lng, photo.gps_lat])
        .addTo(map);

      el.addEventListener("click", () => {
        if (!marker.getPopup()) {
          const popup = new _mapboxgl!.Popup({ offset: 25, closeButton: false }).setHTML(`
            <div style="background:#0F1C24;color:#F0F8F8;padding:10px;border-radius:8px;min-width:140px;font-family:system-ui;">
              <div style="font-size:11px;font-weight:800;margin-bottom:4px;">${escapeHtml(photo.filename)}</div>
              <div style="font-size:10px;color:#9EBDC2;">${escapeHtml(new Date(photo.created_at).toLocaleDateString())}</div>
            </div>
          `);
          marker.setPopup(popup);
        }
        marker.togglePopup();
      });

      photoMarkersRef.current.push(marker);
    });
  }, [gpsPhotos, activeOverlays]);

  // ---------- map initialization ----------

  useEffect(() => {
    // Phase 21 Plan 07 Task 1: second-site coercion (see component-top comment).
    // The !token guard already handles empty string (falsy), but the explicit
    // .trim() || null documents intent and matches the portal boundary exactly.
    const token = (process.env.NEXT_PUBLIC_MAPBOX_TOKEN ?? "").trim() || null;
    if (!token || !mapContainer.current || mapRef.current) return;

    const loadMap = async () => {
      const mapboxgl = (await import("mapbox-gl")).default;
      await import("mapbox-gl/dist/mapbox-gl.css");
      _mapboxgl = await import("mapbox-gl");

      (mapboxgl as unknown as { accessToken: string }).accessToken = token;

      const map = new mapboxgl.Map({
        container: mapContainer.current!,
        style: "mapbox://styles/mapbox/satellite-streets-v12",
        center: [-95.3698, 29.7604],
        zoom: 12,
        pitch: 45,
        bearing: -17,
      });

      map.addControl(new mapboxgl.NavigationControl(), "top-right");

      map.on("load", () => {
        setMapLoaded(true);

        // Restore saved camera position (D-12)
        const savedCamera = localStorage.getItem(MAP_STORAGE_KEYS.cameraPrefix + "default");
        if (savedCamera) {
          try {
            const { center, zoom } = JSON.parse(savedCamera);
            map.setCenter(center);
            map.setZoom(zoom);
          } catch {
            // ignore invalid saved camera
          }
        }

        // Save camera position on move
        map.on("moveend", () => {
          const center = [map.getCenter().lng, map.getCenter().lat];
          localStorage.setItem(MAP_STORAGE_KEYS.cameraPrefix + "default", JSON.stringify({ center, zoom: map.getZoom() }));
        });

        // Site markers from hardcoded data (will be rebuilt when Supabase data loads)
        rebuildSiteMarkers(map);

        // Load map data from APIs
        loadMapData();

        // Geolocation fly-to (DYN-03)
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (pos) => {
              map.flyTo({ center: [pos.coords.longitude, pos.coords.latitude], zoom: 12 });
            },
            () => { /* keep Houston default */ },
            { timeout: 3000 }
          );
        }
      });

      mapRef.current = map;
    };

    loadMap();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ---------- SATELLITE style toggle ----------

  useEffect(() => {
    if (!mapRef.current) return;
    const map = mapRef.current;
    const style = activeOverlays.has("SATELLITE")
      ? "mapbox://styles/mapbox/satellite-streets-v12"
      : "mapbox://styles/mapbox/dark-v11";
    if (mapStyle !== (activeOverlays.has("SATELLITE") ? "satellite" : "dark")) {
      map.setStyle(style);
      setMapStyle(activeOverlays.has("SATELLITE") ? "satellite" : "dark");

      // Re-add all layers after style reload (Pitfall 1 + 6)
      map.once("style.load", () => {
        if (activeOverlays.has("TRAFFIC")) addTrafficLayer(map);
        rebuildSiteMarkers(map);
        rebuildEquipmentMarkers(map);
        rebuildPhotoMarkers(map);
      });
    }
  }, [activeOverlays, mapStyle, rebuildSiteMarkers, rebuildEquipmentMarkers, rebuildPhotoMarkers]);

  // ---------- TRAFFIC toggle ----------

  useEffect(() => {
    if (!mapRef.current) return;
    const map = mapRef.current;
    if (activeOverlays.has("TRAFFIC")) addTrafficLayer(map);
    else removeTrafficLayer(map);
  }, [activeOverlays]);

  // ---------- Rebuild equipment markers on data change ----------

  useEffect(() => {
    if (!mapRef.current) return;
    rebuildEquipmentMarkers(mapRef.current);
  }, [equipmentPositions, rebuildEquipmentMarkers]);

  // ---------- Rebuild photo markers on PHOTOS toggle or data change ----------

  useEffect(() => {
    if (!mapRef.current) return;
    rebuildPhotoMarkers(mapRef.current);
  }, [gpsPhotos, activeOverlays, rebuildPhotoMarkers]);

  // ---------- Rebuild site markers when Supabase sites load ----------

  useEffect(() => {
    if (!mapRef.current || mapSites.length === 0) return;
    rebuildSiteMarkers(mapRef.current);
  }, [mapSites, rebuildSiteMarkers]);

  // ---------- Delivery route directions ----------

  const fetchRouteDirections = async (routeKey: string, fromLng: number, fromLat: number, toLng: number, toLat: number) => {
    const mapboxToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
    if (!mapboxToken) return;

    try {
      const resp = await fetch(
        `https://api.mapbox.com/directions/v5/mapbox/driving/${fromLng},${fromLat};${toLng},${toLat}?geometries=geojson&overview=full&access_token=${mapboxToken}`
      );
      const json = await resp.json();

      if (!json.routes || json.routes.length === 0) {
        setRouteDirections(prev => ({ ...prev, [routeKey]: { duration: "", distance: "", error: "Route unavailable. Showing straight-line connection." } }));
        return;
      }

      const route = json.routes[0];
      const durationMin = Math.round(route.duration / 60);
      const distanceMi = (route.distance / 1609.34).toFixed(1);

      setRouteDirections(prev => ({ ...prev, [routeKey]: { duration: `${durationMin} min`, distance: `${distanceMi} mi` } }));

      // Draw route on map
      const map = mapRef.current;
      if (map) {
        const sourceId = `route-${routeKey}`;
        const layerId = `route-line-${routeKey}`;
        if (map.getLayer(layerId)) map.removeLayer(layerId);
        if (map.getSource(sourceId)) map.removeSource(sourceId);

        map.addSource(sourceId, {
          type: "geojson",
          data: { type: "Feature", properties: {}, geometry: route.geometry },
        });
        map.addLayer({
          id: layerId,
          type: "line",
          source: sourceId,
          paint: {
            "line-color": "#4AC4CC",
            "line-width": 3,
            "line-opacity": 0.8,
          },
        });
      }
    } catch {
      setRouteDirections(prev => ({ ...prev, [routeKey]: { duration: "", distance: "", error: "Route unavailable. Showing straight-line connection." } }));
    }
  };

  // ---------- Equipment filtering ----------

  const filteredEquipment = equipmentFilter === "all"
    ? equipmentPositions
    : equipmentPositions.filter(e => e.type === equipmentFilter);

  // ---------- Site data ----------

  const displaySites = mapSites.length > 0 ? mapSites : sites;

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 900, letterSpacing: 2, color: "var(--cyan)" }}>LIVE MAPS</div>
            <p style={{ fontSize: 11, fontWeight: 600, color: "var(--muted)", margin: "4px 0 0" }}>Satellite-backed site awareness with live overlays and rapid field routing.</p>
          </div>
          <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
            <button
              onClick={() => { setIsRefreshing(true); loadMapData().finally(() => setIsRefreshing(false)); }}
              style={{ background: "none", border: "none", cursor: "pointer", color: "var(--muted)", fontSize: 16 }}
              title="Refresh positions"
              aria-label="Refresh equipment positions"
            >
              <span style={{ display: "inline-block", transition: "transform 0.5s", transform: isRefreshing ? "rotate(360deg)" : "none" }}>&#x21BB;</span>
            </button>
            {mapLoaded && <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#69D294" }} />}
            <span style={{ fontSize: 9, fontWeight: 900, color: "var(--bg)", background: mapLoaded ? "var(--green)" : "var(--gold)", padding: "4px 10px", borderRadius: 6 }}>{mapLoaded ? "LIVE" : "LOADING..."}</span>
          </div>
        </div>
      </div>

      {/* Overlay Toggles */}
      <div style={{ display: "flex", gap: 6, marginBottom: 12, flexWrap: "wrap" }}>
        {overlays.map(o => (
          <button key={o} onClick={() => toggleOverlay(o)} aria-label={`Toggle ${o.toLowerCase()} overlay`} aria-pressed={activeOverlays.has(o)} style={{ fontSize: 9, fontWeight: 800, padding: "5px 10px", borderRadius: 6, background: activeOverlays.has(o) ? "var(--cyan)" : "var(--surface)", color: activeOverlays.has(o) ? "var(--bg)" : "var(--muted)", cursor: "pointer", border: "none" }}>{o}</button>
        ))}
      </div>

      {/* Mapbox Map */}
      {!token ? (
        <div style={{ borderRadius: 16, padding: 32, textAlign: "center", background: "var(--surface)", border: "1px solid rgba(51,84,94,0.2)", marginBottom: 16 }}>
          <div style={{ fontSize: 48, marginBottom: 8 }}>&#x1F5FA;</div>
          <div style={{ fontSize: 20, fontWeight: 900, marginBottom: 8 }}>Maps Unavailable</div>
          <div style={{ fontSize: 13, color: "var(--muted)" }}>Configure MAPBOX_TOKEN to enable interactive maps.</div>
        </div>
      ) : (
        <div style={{ position: "relative", marginBottom: 16 }}>
          <div ref={mapContainer} style={{ width: "100%", height: 400, borderRadius: 14, overflow: "hidden", border: "1px solid rgba(74,196,204,0.1)" }} />
          {/* Phase 21 Plan 08 Task 1: empty-state chip for Test 3 closure. Renders only after
              the first /api/maps/equipment response resolves AND the pre-filter array is empty
              (so the client-side equipment-type filter turning rows invisible does NOT show this). */}
          {!isLoadingData && equipmentPositions.length === 0 && (
            <div
              style={{
                position: "absolute",
                top: 12,
                right: 12,
                background: "rgba(0,0,0,0.75)",
                color: "var(--muted)",
                fontSize: 10,
                fontWeight: 700,
                letterSpacing: 1,
                padding: "6px 10px",
                borderRadius: 6,
                pointerEvents: "none",
                zIndex: 5,
              }}
              role="status"
              aria-live="polite"
            >
              NO EQUIPMENT TRACKED YET
            </div>
          )}
          {activeOverlays.has("TRAFFIC") && (
            <div style={{ position: "absolute", bottom: 8, left: 8, background: "var(--surface)", borderRadius: 8, padding: "8px 12px", fontSize: 9, fontWeight: 800, color: "var(--muted)", zIndex: 1 }}>
              Traffic: <span style={{ color: "#69D294" }}>Green</span> = flowing, <span style={{ color: "#FCC757" }}>Yellow</span> = slow, <span style={{ color: "#D94D48" }}>Red</span> = congested
            </div>
          )}
        </div>
      )}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        {/* Site Cards */}
        <div>
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>ACTIVE SITES</h3>
          {displaySites.map(s => (
            <div key={s.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                <span style={{ fontSize: 12, fontWeight: 800 }}>{s.name}</span>
                <span role="status" aria-label={`Status: ${s.status}`} style={{ fontSize: 8, fontWeight: 900, color: s.status === "ACTIVE" ? "var(--green)" : s.status === "DELAYED" ? "var(--red)" : "var(--gold)" }}>{s.status}</span>
              </div>
              <div style={{ display: "flex", gap: 12, fontSize: 10, color: "var(--muted)" }}>
                {"crews" in s && <span>{(s as { crews: number }).crews} crews</span>}
                {"deliveries" in s && <span>{(s as { deliveries: number }).deliveries} deliveries</span>}
                {"alerts" in s && <span style={{ color: (s as { alerts: number }).alerts > 0 ? "var(--red)" : "var(--green)" }}>{(s as { alerts: number }).alerts} alerts</span>}
                {"zone" in s && <span>{(s as { zone: string }).zone}</span>}
              </div>
            </div>
          ))}

          {/* Equipment Cards Section */}
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 10, marginTop: 16 }}>EQUIPMENT</h3>
          <div style={{ display: "flex", gap: 4, marginBottom: 10, flexWrap: "wrap" }}>
            {["all", "equipment", "vehicle", "material"].map(f => (
              <button key={f} onClick={() => setEquipmentFilter(f)} style={{ fontSize: 9, fontWeight: 800, padding: "4px 8px", borderRadius: 6, background: equipmentFilter === f ? "var(--cyan)" : "var(--surface)", color: equipmentFilter === f ? "var(--bg)" : "var(--muted)", cursor: "pointer", border: "none", textTransform: "capitalize" }}>{f === "all" ? "All" : f.charAt(0).toUpperCase() + f.slice(1) + "s"}</button>
            ))}
          </div>
          {filteredEquipment.length === 0 ? (
            <div style={{ background: "var(--surface)", borderRadius: 10, padding: 20, textAlign: "center" }}>
              <div style={{ fontSize: 14, fontWeight: 800, marginBottom: 4 }}>No Equipment Tracked</div>
              <div style={{ fontSize: 11, color: "var(--muted)" }}>Equipment with GPS check-ins will appear here.</div>
            </div>
          ) : (
            filteredEquipment.map(e => (
              <div key={e.id} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                  <span style={{ fontSize: 12, fontWeight: 800 }}>{e.name}</span>
                  <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
                    <span style={{ fontSize: 8, fontWeight: 900, color: "var(--bg)", background: "var(--cyan)", padding: "2px 6px", borderRadius: 4 }}>{e.type.toUpperCase()}</span>
                    <span style={{ fontSize: 8, fontWeight: 900, color: STATUS_COLORS[e.status], padding: "2px 6px", borderRadius: 4, border: `1px solid ${STATUS_COLORS[e.status]}` }}>{e.status.toUpperCase().replace("_", " ")}</span>
                  </div>
                </div>
                <div style={{ fontSize: 10, color: "var(--muted)" }}>
                  Last: {e.latest_recorded_at ? new Date(e.latest_recorded_at).toLocaleString() : "N/A"}
                </div>
              </div>
            ))
          )}
        </div>

        <div>
          {/* Satellite Passes */}
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>SATELLITE PASSES</h3>
          {satellites.map(s => (
            <div key={s.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <span style={{ fontSize: 12, fontWeight: 800 }}>{s.name}</span>
                <span style={{ fontSize: 10, color: "var(--muted)", marginLeft: 8 }}>{s.coverage}</span>
              </div>
              <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                <span style={{ fontSize: 11, fontWeight: 900, color: s.color }}>{s.confidence}%</span>
                <span style={{ fontSize: 10, color: "#FCC757" }}>ETA {s.eta}</span>
              </div>
            </div>
          ))}

          {/* Routes */}
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10, marginTop: 16 }}>DELIVERY ROUTES</h3>
          {routes.map(r => {
            const key = `${r.from}-${r.to}`;
            const dir = routeDirections[key];
            return (
              <div key={r.to} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div style={{ fontSize: 11, fontWeight: 800 }}>{r.from} &rarr; {r.to}</div>
                  <button
                    onClick={() => fetchRouteDirections(key, r.fromLng, r.fromLat, r.toLng, r.toLat)}
                    style={{ fontSize: 8, fontWeight: 800, padding: "3px 8px", borderRadius: 4, background: "var(--cyan)", color: "var(--bg)", cursor: "pointer", border: "none" }}
                  >
                    Get Directions
                  </button>
                </div>
                <div style={{ display: "flex", gap: 12, fontSize: 10, color: "var(--muted)", marginTop: 4 }}>
                  <span>{dir?.distance || r.distance}</span>
                  <span>ETA: {dir?.duration || r.eta}</span>
                  <span style={{ color: r.traffic === "Heavy" ? "var(--red)" : r.traffic === "Moderate" ? "var(--gold)" : "var(--green)" }}>{r.traffic}</span>
                </div>
                {dir?.error && (
                  <div style={{ fontSize: 9, color: "var(--gold)", marginTop: 4 }}>{dir.error}</div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
