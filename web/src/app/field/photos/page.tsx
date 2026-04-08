// Phase 16 FIELD-02: Photo browser Server Component.
// Uses Next 15 async searchParams pattern. Signed URLs are resolved in a
// single batched createSignedUrls call inside listFieldPhotos.

import type { Metadata } from "next";
import Link from "next/link";
import { listFieldPhotos } from "@/lib/field/photoQueries";
import { AttachPhotoControl } from "./AttachPhotoControl";

export const metadata: Metadata = {
  title: "Field Photos · ConstructionOS",
  description:
    "Browse field photos and attach them to punch items, daily logs, and safety incidents.",
};

type SearchParams = Promise<{ projectId?: string }>;

export default async function FieldPhotosPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const { projectId } = await searchParams;
  const result = await listFieldPhotos({ projectId });

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 14,
          padding: 20,
          marginBottom: 16,
          border: "1px solid rgba(74,196,204,0.08)",
        }}
      >
        <div
          style={{
            fontSize: 11,
            fontWeight: 800,
            letterSpacing: 3,
            color: "var(--cyan)",
          }}
        >
          FIELD · PHOTOS
        </div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>
          Photo Browser
        </h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>
          Review field photos and attach them to punch items, daily logs, and
          safety incidents.
          {projectId ? ` Filter: project ${projectId.slice(0, 8)}…` : ""}
        </p>
        <div style={{ marginTop: 8 }}>
          <Link
            href="/field"
            style={{ fontSize: 10, color: "var(--accent)", marginRight: 12 }}
          >
            ← Back to Field Ops
          </Link>
          {projectId && (
            <Link
              href="/field/photos"
              style={{ fontSize: 10, color: "var(--muted)" }}
            >
              Clear filter
            </Link>
          )}
        </div>
      </div>

      {!result.ok && (
        <div
          role="alert"
          style={{
            background: "rgba(220,60,60,0.08)",
            border: "1px solid var(--red)",
            color: "var(--red)",
            padding: 12,
            borderRadius: 8,
            marginBottom: 16,
            fontSize: 12,
          }}
        >
          Failed to load photos ({result.status}): {result.error}
        </div>
      )}

      {result.photos.length === 0 ? (
        <div
          style={{
            padding: 40,
            textAlign: "center",
            color: "var(--muted)",
            fontSize: 12,
            background: "var(--surface)",
            borderRadius: 10,
          }}
        >
          No photos yet. Capture photos from the iOS app to see them here.
        </div>
      ) : (
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))",
            gap: 12,
          }}
        >
          {result.photos.map((photo) => {
            const url = result.signedUrls.get(photo.id);
            const isStale = photo.gps_source === "stale_last_known";
            const hasGps = photo.gps_lat != null && photo.gps_lng != null;
            return (
              <div
                key={photo.id}
                style={{
                  background: "var(--surface)",
                  borderRadius: 10,
                  overflow: "hidden",
                  border: "1px solid rgba(51,84,94,0.2)",
                }}
              >
                <div
                  style={{
                    width: "100%",
                    aspectRatio: "4 / 3",
                    background: "var(--bg)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: "var(--muted)",
                    fontSize: 10,
                    overflow: "hidden",
                  }}
                >
                  {url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={url}
                      alt={photo.filename}
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                    />
                  ) : (
                    <span>No preview</span>
                  )}
                </div>
                <div style={{ padding: 10 }}>
                  <div
                    style={{
                      fontSize: 11,
                      fontWeight: 700,
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}
                    title={photo.filename}
                  >
                    {photo.filename}
                  </div>
                  <div
                    style={{
                      fontSize: 9,
                      color: "var(--muted)",
                      marginTop: 2,
                      display: "flex",
                      gap: 8,
                      flexWrap: "wrap",
                      alignItems: "center",
                    }}
                  >
                    <span>
                      {photo.captured_at
                        ? new Date(photo.captured_at).toLocaleString()
                        : "No capture time"}
                    </span>
                    {hasGps && (
                      <span
                        style={{
                          color: isStale ? "var(--gold)" : "var(--green)",
                          fontWeight: 700,
                        }}
                      >
                        {isStale ? "STALE GPS" : "GPS"}
                      </span>
                    )}
                  </div>
                  <AttachPhotoControl documentId={photo.id} />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
