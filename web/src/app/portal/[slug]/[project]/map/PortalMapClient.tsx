"use client";

// D-13: Portal map client component -- renders Mapbox with LOCKED overlays.
// No toggle strip, no refresh, no sidebar. Pure embed.

import { useEffect, useRef, useState } from "react";
import type { PortalMapOverlays } from "@/lib/maps/types";

type EquipmentMarker = {
  id: string;
  name: string;
  type: string;
  status: string;
  lat: number;
  lng: number;
  recorded_at: string;
};

type PhotoMarker = {
  id: string;
  filename: string;
  lat: number;
  lng: number;
  created_at: string;
};

type PortalMapData = {
  overlays: PortalMapOverlays;
  site: {
    project_id: string;
    name: string;
    lat: number | null;
    lng: number | null;
  };
  equipment: EquipmentMarker[];
  photos: PhotoMarker[];
};

type PortalMapClientProps = {
  token: string;
  mapboxToken: string | null;
};

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

export default function PortalMapClient({
  token,
  mapboxToken,
}: PortalMapClientProps) {
  const mapContainer = useRef<HTMLDivElement>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const mapRef = useRef<any>(null);
  const [loadState, setLoadState] = useState<
    "idle" | "loading" | "ready" | "error" | "disabled"
  >("loading");
  const [errorMsg, setErrorMsg] = useState<string>("");
  const [mapData, setMapData] = useState<PortalMapData | null>(null);

  // ---------- Fetch portal map data on mount ----------
  useEffect(() => {
    let cancelled = false;

    async function loadData() {
      try {
        const res = await fetch(
          `/api/portal/map?token=${encodeURIComponent(token)}`,
        );
        if (!res.ok) {
          if (!cancelled) {
            setLoadState("error");
            setErrorMsg("Map failed to load. Check your internet connection.");
          }
          return;
        }
        const json = (await res.json()) as {
          data: PortalMapData | null;
          message?: string;
        };
        if (cancelled) return;
        if (!json.data) {
          setLoadState("disabled");
          setErrorMsg(json.message ?? "Map not available for this portal");
          return;
        }
        setMapData(json.data);
      } catch (err) {
        console.error("[portal-map-client] fetch failed:", err);
        if (!cancelled) {
          setLoadState("error");
          setErrorMsg("Map failed to load. Check your internet connection.");
        }
      }
    }

    loadData();
    return () => {
      cancelled = true;
    };
  }, [token]);

  // ---------- Initialize Mapbox once data is loaded ----------
  useEffect(() => {
    if (!mapData || !mapboxToken || !mapContainer.current) return;
    if (mapRef.current) return;

    const overlays = mapData.overlays;

    const initMap = async () => {
      try {
        const mapboxgl = (await import("mapbox-gl")).default;
        await import("mapbox-gl/dist/mapbox-gl.css");

        (mapboxgl as unknown as { accessToken: string }).accessToken =
          mapboxToken;

        const centerLng = mapData.site.lng ?? -95.3698;
        const centerLat = mapData.site.lat ?? 29.7604;

        const style = overlays.satellite
          ? "mapbox://styles/mapbox/satellite-streets-v12"
          : "mapbox://styles/mapbox/dark-v11";

        const map = new mapboxgl.Map({
          container: mapContainer.current!,
          style,
          center: [centerLng, centerLat],
          zoom: 13,
          pitch: 30,
          // NO interactive controls for portal view -- locked view
          interactive: true,
        });

        map.addControl(new mapboxgl.NavigationControl(), "top-right");

        map.on("load", () => {
          // Site marker (map center)
          if (mapData.site.lat != null && mapData.site.lng != null) {
            const siteEl = document.createElement("div");
            siteEl.style.cssText =
              "width:18px;height:18px;border-radius:50%;background:#4AC4CC;border:3px solid white;box-shadow:0 0 12px #4AC4CC;";
            new mapboxgl.Marker({ element: siteEl })
              .setLngLat([mapData.site.lng, mapData.site.lat])
              .setPopup(
                new mapboxgl.Popup({ offset: 25, closeButton: false })
                  .setHTML(
                    `<div style="padding:8px;font-family:system-ui;">
                       <div style="font-size:12px;font-weight:800;">${escapeHtml(
                         mapData.site.name,
                       )}</div>
                     </div>`,
                  ),
              )
              .addTo(map);
          }

          // Traffic overlay (D-13: traffic)
          if (overlays.traffic) {
            map.addSource("mapbox-traffic", {
              type: "vector",
              url: "mapbox://mapbox.mapbox-traffic-v1",
            });
            map.addLayer({
              id: "traffic-layer",
              type: "line",
              source: "mapbox-traffic",
              "source-layer": "traffic",
              paint: {
                "line-color": [
                  "match",
                  ["get", "congestion"],
                  "low",
                  "#69D294",
                  "moderate",
                  "#FCC757",
                  "heavy",
                  "#FF8C42",
                  "severe",
                  "#D94D48",
                  "#69D294",
                ],
                "line-width": 2,
                "line-opacity": 0.7,
              },
            });
          }

          // Equipment markers (D-13: equipment)
          if (overlays.equipment) {
            for (const item of mapData.equipment) {
              const statusColor =
                item.status === "active"
                  ? "#69D294"
                  : item.status === "needs_attention"
                    ? "#D94D48"
                    : "#FCC757";

              let borderRadius = "50%";
              if (item.type === "vehicle") borderRadius = "4px";
              else if (item.type === "material") borderRadius = "2px";

              const el = document.createElement("div");
              el.style.cssText = `width:14px;height:14px;border-radius:${borderRadius};background:${statusColor};border:2px solid white;box-shadow:0 0 8px ${statusColor};`;

              new mapboxgl.Marker({ element: el })
                .setLngLat([item.lng, item.lat])
                .setPopup(
                  new mapboxgl.Popup({ offset: 20, closeButton: false }).setHTML(
                    `<div style="padding:6px;font-family:system-ui;">
                       <div style="font-size:11px;font-weight:800;">${escapeHtml(
                         item.name,
                       )}</div>
                       <div style="font-size:9px;color:#666;">${escapeHtml(
                         item.type,
                       )} &bull; ${escapeHtml(item.status)}</div>
                     </div>`,
                  ),
                )
                .addTo(map);
            }
          }

          // Photo markers (D-13: photos)
          if (overlays.photos) {
            for (const photo of mapData.photos) {
              const el = document.createElement("div");
              el.style.cssText =
                "width:12px;height:12px;border-radius:50%;background:#8A8FCC;border:2px solid white;cursor:pointer;";

              new mapboxgl.Marker({ element: el })
                .setLngLat([photo.lng, photo.lat])
                .setPopup(
                  new mapboxgl.Popup({ offset: 20, closeButton: false }).setHTML(
                    `<div style="padding:6px;font-family:system-ui;">
                       <div style="font-size:10px;font-weight:800;">${escapeHtml(
                         photo.filename,
                       )}</div>
                       <div style="font-size:9px;color:#666;">${escapeHtml(
                         new Date(photo.created_at).toLocaleDateString(),
                       )}</div>
                     </div>`,
                  ),
                )
                .addTo(map);
            }
          }

          setLoadState("ready");
        });

        map.on("error", (e) => {
          console.error("[portal-map-client] mapbox error:", e);
          setLoadState("error");
          setErrorMsg("Map failed to load. Check your internet connection.");
        });

        mapRef.current = map;
      } catch (err) {
        console.error("[portal-map-client] init failed:", err);
        setLoadState("error");
        setErrorMsg("Map failed to load. Check your internet connection.");
      }
    };

    initMap();

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [mapData, mapboxToken]);

  // ---------- Render ----------

  if (loadState === "disabled") {
    return (
      <div
        style={{
          width: "100%",
          height: 500,
          borderRadius: 14,
          background: "var(--surface, #F5F7F8)",
          border: "1px solid rgba(51,84,94,0.12)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "var(--muted, #6B7C80)",
          fontSize: 13,
          fontWeight: 600,
        }}
      >
        {errorMsg || "Map not available for this portal"}
      </div>
    );
  }

  if (!mapboxToken) {
    return (
      <div
        style={{
          width: "100%",
          height: 500,
          borderRadius: 14,
          background: "var(--surface, #F5F7F8)",
          border: "1px solid rgba(51,84,94,0.12)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
          gap: 8,
          color: "var(--muted, #6B7C80)",
          fontSize: 13,
          fontWeight: 600,
        }}
      >
        <div>Maps Unavailable</div>
        <div style={{ fontSize: 11, opacity: 0.75 }}>
          Mapbox not configured for this portal.
        </div>
      </div>
    );
  }

  return (
    <div style={{ position: "relative" }}>
      <div
        ref={mapContainer}
        style={{
          width: "100%",
          height: 500,
          borderRadius: 14,
          overflow: "hidden",
          border: "1px solid rgba(74,196,204,0.12)",
        }}
      />
      {loadState === "loading" && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            background: "rgba(15,28,36,0.6)",
            borderRadius: 14,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#F0F8F8",
            fontSize: 13,
            fontWeight: 700,
          }}
        >
          Loading map...
        </div>
      )}
      {loadState === "error" && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            background: "var(--surface, #F5F7F8)",
            borderRadius: 14,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "var(--red, #D94D48)",
            fontSize: 13,
            fontWeight: 700,
            padding: 16,
            textAlign: "center",
          }}
        >
          {errorMsg}
        </div>
      )}
    </div>
  );
}
