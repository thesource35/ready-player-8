"use client";

// Portal photo timeline (D-47, D-54, D-55)
// Vertical chronological photo timeline with date grouping, lazy loading,
// photo count summary, and density bar.

import { useState, useCallback } from "react";
import type { PortalPhoto } from "@/lib/portal/photoHelpers";
import {
  groupPhotosByDate,
  formatPhotoDate,
  getDateRangeSummary,
} from "@/lib/portal/photoHelpers";
import PhotoCard from "./PhotoCard";
import PhotoLightbox from "./PhotoLightbox";
import DateFilter from "./DateFilter";

type PhotoTimelineProps = {
  initialPhotos: PortalPhoto[];
  totalCount: number;
  portalToken: string;
  dateRange?: { start: string; end: string };
  watermarkEnabled?: boolean;
  companyName?: string;
};

const BATCH_SIZE = 20;

export default function PhotoTimeline({
  initialPhotos,
  totalCount,
  portalToken,
  dateRange,
  watermarkEnabled,
  companyName,
}: PhotoTimelineProps) {
  const [photos, setPhotos] = useState<PortalPhoto[]>(initialPhotos);
  const [loading, setLoading] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [activeDateRange, setActiveDateRange] = useState<{
    start: string;
    end: string;
  } | null>(dateRange ?? null);
  const [filteredTotal, setFilteredTotal] = useState(totalCount);

  const hasMore = photos.length < filteredTotal;

  // D-55: Load more photos via API
  const loadMore = useCallback(async () => {
    if (loading || !hasMore) return;
    setLoading(true);
    try {
      const params = new URLSearchParams({
        token: portalToken,
        offset: String(photos.length),
        limit: String(BATCH_SIZE),
      });
      if (activeDateRange) {
        params.set("date_start", activeDateRange.start);
        params.set("date_end", activeDateRange.end);
      }
      const res = await fetch(`/api/portal/photos?${params.toString()}`);
      if (res.ok) {
        const data = await res.json();
        setPhotos((prev) => [...prev, ...data.photos]);
        setFilteredTotal(data.total);
      }
    } catch (err) {
      console.error("[PhotoTimeline] loadMore failed:", err);
    } finally {
      setLoading(false);
    }
  }, [loading, hasMore, photos.length, portalToken, activeDateRange]);

  // D-51: Date filter handler — reloads photos from API with date range
  const handleDateFilter = useCallback(
    async (range: { start: string; end: string } | null) => {
      setActiveDateRange(range);
      setLoading(true);
      try {
        const params = new URLSearchParams({
          token: portalToken,
          offset: "0",
          limit: String(BATCH_SIZE),
        });
        if (range) {
          params.set("date_start", range.start);
          params.set("date_end", range.end);
        }
        const res = await fetch(`/api/portal/photos?${params.toString()}`);
        if (res.ok) {
          const data = await res.json();
          setPhotos(data.photos);
          setFilteredTotal(data.total);
        }
      } catch (err) {
        console.error("[PhotoTimeline] filter failed:", err);
      } finally {
        setLoading(false);
      }
    },
    [portalToken],
  );

  // Build flat list for lightbox and grouped view
  const grouped = groupPhotosByDate(photos);
  const flatPhotos = photos; // maintain order for lightbox indexing
  const dateRangeSummary = getDateRangeSummary(photos);

  // D-54: Density bar — shows relative photo counts per date bucket
  const dateEntries = [...grouped.entries()];
  const maxInGroup = Math.max(1, ...dateEntries.map(([, p]) => p.length));

  // Track flat index for lightbox
  let flatIndex = 0;

  return (
    <div>
      {/* D-54: Photo count summary */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: 12,
          marginBottom: 16,
        }}
      >
        <div>
          <span style={{ fontSize: 16, fontWeight: 600, color: "#1F2937" }}>
            {filteredTotal} photo{filteredTotal !== 1 ? "s" : ""}
          </span>
          {dateRangeSummary && (
            <span
              style={{ fontSize: 13, color: "#6B7280", marginLeft: 8 }}
            >
              {" \u2014 "}
              {dateRangeSummary}
            </span>
          )}
        </div>
        <DateFilter onFilter={handleDateFilter} />
      </div>

      {/* D-54: Mini timeline density bar */}
      {dateEntries.length > 1 && (
        <div
          style={{
            display: "flex",
            gap: 2,
            height: 20,
            alignItems: "flex-end",
            marginBottom: 20,
            padding: "0 4px",
          }}
          aria-hidden="true"
        >
          {dateEntries.map(([date, group]) => (
            <div
              key={date}
              style={{
                flex: 1,
                height: `${Math.max(20, (group.length / maxInGroup) * 100)}%`,
                background: "var(--portal-primary, #2563EB)",
                opacity: 0.3,
                borderRadius: "2px 2px 0 0",
                minWidth: 3,
                maxWidth: 20,
              }}
              title={`${formatPhotoDate(date)}: ${group.length} photo${group.length !== 1 ? "s" : ""}`}
            />
          ))}
        </div>
      )}

      {/* D-47: Vertical chronological timeline with date markers */}
      {dateEntries.map(([date, group]) => {
        const startIndex = flatIndex;
        flatIndex += group.length;

        return (
          <div key={date} style={{ marginBottom: 28 }}>
            {/* Date marker header with horizontal line */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 12,
                marginBottom: 12,
              }}
            >
              <span
                style={{
                  fontSize: 13,
                  fontWeight: 600,
                  color: "#374151",
                  whiteSpace: "nowrap",
                }}
              >
                {date === "unknown" ? "Unknown date" : formatPhotoDate(date)}
              </span>
              <div
                style={{
                  flex: 1,
                  height: 1,
                  background: "#E2E5E9",
                }}
              />
              <span style={{ fontSize: 11, color: "#9CA3AF", whiteSpace: "nowrap" }}>
                {group.length} photo{group.length !== 1 ? "s" : ""}
              </span>
            </div>

            {/* D-14: 3 columns desktop, 2 columns mobile */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))",
                gap: 12,
              }}
            >
              {group.map((photo, i) => (
                <PhotoCard
                  key={photo.id}
                  photo={photo}
                  onClick={() => setLightboxIndex(startIndex + i)}
                  showWatermark={watermarkEnabled}
                  companyName={companyName}
                />
              ))}
            </div>
          </div>
        );
      })}

      {/* D-55: Load more button */}
      {hasMore && (
        <div style={{ textAlign: "center", padding: "20px 0" }}>
          <button
            onClick={loadMore}
            disabled={loading}
            style={{
              padding: "10px 24px",
              fontSize: 14,
              fontWeight: 600,
              color: "#FFFFFF",
              background: loading
                ? "#9CA3AF"
                : "var(--portal-primary, #2563EB)",
              border: "none",
              borderRadius: 8,
              cursor: loading ? "default" : "pointer",
              transition: "background 200ms",
            }}
          >
            {loading ? "Loading..." : "Load more photos"}
          </button>
          <p style={{ fontSize: 12, color: "#9CA3AF", marginTop: 6 }}>
            Showing {photos.length} of {filteredTotal}
          </p>
        </div>
      )}

      {/* Empty state */}
      {photos.length === 0 && !loading && (
        <div
          style={{
            textAlign: "center",
            padding: 40,
            color: "#9CA3AF",
            fontSize: 14,
          }}
        >
          No photos available
          {activeDateRange ? " for the selected date range" : ""}.
        </div>
      )}

      {/* D-49: Fullscreen lightbox */}
      {lightboxIndex !== null && (
        <PhotoLightbox
          photos={flatPhotos}
          initialIndex={lightboxIndex}
          onClose={() => setLightboxIndex(null)}
        />
      )}
    </div>
  );
}
