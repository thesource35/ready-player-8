"use client";
import { useEffect, useRef, useState } from "react";

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
  { from: "Yard / Staging", to: "Riverside Lofts", distance: "4.2 mi", eta: "12 min", traffic: "Light" },
  { from: "Concrete Batch Plant", to: "Harbor Crossing", distance: "8.7 mi", eta: "22 min", traffic: "Moderate" },
  { from: "Steel Fabricator", to: "Skyline Tower", distance: "15.3 mi", eta: "35 min", traffic: "Heavy" },
];

const overlays = ["SATELLITE", "THERMAL", "CREWS", "WEATHER", "AUTO TRACK"];

export default function MapsPage() {
  const mapContainer = useRef<HTMLDivElement>(null);
  const mapRef = useRef<unknown>(null);
  const [mapLoaded, setMapLoaded] = useState(false);
  const [mapStyle, setMapStyle] = useState("satellite");
  const [activeOverlays, setActiveOverlays] = useState<Set<string>>(new Set(["SATELLITE", "CREWS"]));
  const token = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;

  const toggleOverlay = (name: string) => {
    setActiveOverlays(prev => {
      const next = new Set(prev);
      if (next.has(name)) next.delete(name); else next.add(name);
      return next;
    });
  };

  useEffect(() => {
    const token = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
    if (!token || !mapContainer.current || mapRef.current) return;

    const loadMap = async () => {
      const mapboxgl = (await import("mapbox-gl")).default;
      await import("mapbox-gl/dist/mapbox-gl.css");

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

        sites.forEach(site => {
          const color = site.status === "ACTIVE" ? "#69D294" : site.status === "DELAYED" ? "#D94D48" : "#FCC757";

          const el = document.createElement("div");
          el.style.cssText = `width:16px;height:16px;border-radius:50%;background:${color};border:2px solid white;box-shadow:0 0 10px ${color};cursor:pointer;`;

          const marker = new mapboxgl.Marker({ element: el })
            .setLngLat([site.lng, site.lat])
            .addTo(map);

          // Lazy popup creation — only build DOM on first click (PERF-04)
          el.addEventListener("click", () => {
            if (!marker.getPopup()) {
              const popup = new mapboxgl.Popup({ offset: 25, closeButton: false }).setHTML(`
                <div style="background:#0F1C24;color:#F0F8F8;padding:10px;border-radius:8px;min-width:160px;font-family:system-ui;">
                  <div style="font-size:12px;font-weight:800;margin-bottom:4px;">${escapeHtml(site.name)}</div>
                  <div style="font-size:9px;color:${escapeHtml(color)};font-weight:900;margin-bottom:6px;">${escapeHtml(site.status)}</div>
                  <div style="font-size:10px;color:#9EBDC2;">
                    ${escapeHtml(String(site.crews))} crews &bull; ${escapeHtml(String(site.deliveries))} deliveries &bull; ${escapeHtml(String(site.alerts))} alerts<br/>
                    ${escapeHtml(site.zone)}
                  </div>
                </div>
              `);
              marker.setPopup(popup);
            }
            marker.togglePopup();
          });
        });

        // Fly to user location if geolocation is available (DYN-03)
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
  }, []);

  useEffect(() => {
    if (!mapRef.current) return;
    const map = mapRef.current as { setStyle: (s: string) => void };
    const style = activeOverlays.has("SATELLITE")
      ? "mapbox://styles/mapbox/satellite-streets-v12"
      : "mapbox://styles/mapbox/dark-v11";
    if (mapStyle !== (activeOverlays.has("SATELLITE") ? "satellite" : "dark")) {
      map.setStyle(style);
      setMapStyle(activeOverlays.has("SATELLITE") ? "satellite" : "dark");
    }
  }, [activeOverlays, mapStyle]);

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 900, letterSpacing: 2, color: "var(--cyan)" }}>LIVE MAPS</div>
            <p style={{ fontSize: 11, fontWeight: 600, color: "var(--muted)", margin: "4px 0 0" }}>Satellite-backed site awareness with live overlays and rapid field routing.</p>
          </div>
          <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
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
        <div ref={mapContainer} style={{ width: "100%", height: 400, borderRadius: 14, marginBottom: 16, overflow: "hidden", border: "1px solid rgba(74,196,204,0.1)" }} />
      )}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        {/* Site Cards */}
        <div>
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>ACTIVE SITES</h3>
          {sites.map(s => (
            <div key={s.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                <span style={{ fontSize: 12, fontWeight: 800 }}>{s.name}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: s.status === "ACTIVE" ? "var(--green)" : s.status === "DELAYED" ? "var(--red)" : "var(--gold)" }}>{s.status}</span>
              </div>
              <div style={{ display: "flex", gap: 12, fontSize: 10, color: "var(--muted)" }}>
                <span>{s.crews} crews</span>
                <span>{s.deliveries} deliveries</span>
                <span style={{ color: s.alerts > 0 ? "var(--red)" : "var(--green)" }}>{s.alerts} alerts</span>
                <span>{s.zone}</span>
              </div>
            </div>
          ))}
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
          {routes.map(r => (
            <div key={r.to} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
              <div style={{ fontSize: 11, fontWeight: 800 }}>{r.from} &rarr; {r.to}</div>
              <div style={{ display: "flex", gap: 12, fontSize: 10, color: "var(--muted)", marginTop: 4 }}>
                <span>{r.distance}</span>
                <span>ETA: {r.eta}</span>
                <span style={{ color: r.traffic === "Heavy" ? "var(--red)" : r.traffic === "Moderate" ? "var(--gold)" : "var(--green)" }}>{r.traffic}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
