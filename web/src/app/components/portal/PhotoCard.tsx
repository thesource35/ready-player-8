"use client";

// Portal photo card (D-48, D-50, D-52, D-57)
// Thumbnail with caption, date, location, uploader, annotation badge, optional watermark

import type { PortalPhoto } from "@/lib/portal/photoHelpers";
import { formatPhotoDate } from "@/lib/portal/photoHelpers";

type PhotoCardProps = {
  photo: PortalPhoto;
  onClick: () => void;
  showWatermark?: boolean;
  companyName?: string;
};

export default function PhotoCard({
  photo,
  onClick,
  showWatermark,
  companyName,
}: PhotoCardProps) {
  const altText =
    photo.caption || `Project photo from ${formatPhotoDate(photo.date_taken)}`;

  return (
    <div
      style={{
        borderRadius: 8,
        overflow: "hidden",
        border: "1px solid #E2E5E9",
        background: "#FFFFFF",
        cursor: "pointer",
        transition: "box-shadow 200ms ease-in-out",
      }}
      onClick={onClick}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onClick();
        }
      }}
      role="button"
      tabIndex={0}
      aria-label={`View photo: ${altText}`}
    >
      {/* Thumbnail */}
      <div
        style={{
          width: "100%",
          paddingBottom: "75%",
          position: "relative",
          background: "#F1F3F5",
          overflow: "hidden",
        }}
      >
        <img
          src={photo.signedUrl || photo.url}
          alt={altText}
          loading="lazy"
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
            height: "100%",
            objectFit: "cover",
          }}
        />

        {/* D-48: Annotation indicator badge */}
        {photo.has_annotation && (
          <span
            style={{
              position: "absolute",
              top: 8,
              left: 8,
              background: "var(--portal-primary, #2563EB)",
              color: "#FFFFFF",
              fontSize: 10,
              fontWeight: 600,
              padding: "2px 6px",
              borderRadius: 4,
              lineHeight: 1.4,
            }}
            title="Has annotations"
          >
            Annotated
          </span>
        )}

        {/* D-57: Watermark overlay */}
        {showWatermark && companyName && (
          <div
            style={{
              position: "absolute",
              bottom: 8,
              right: 8,
              background: "rgba(0, 0, 0, 0.4)",
              color: "rgba(255, 255, 255, 0.8)",
              fontSize: 10,
              fontWeight: 500,
              padding: "2px 8px",
              borderRadius: 3,
              pointerEvents: "none",
            }}
          >
            {companyName}
          </div>
        )}

        {/* Download button */}
        <a
          href={photo.signedUrl || photo.url}
          download
          onClick={(e) => e.stopPropagation()}
          style={{
            position: "absolute",
            top: 8,
            right: 8,
            width: 28,
            height: 28,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "rgba(0, 0, 0, 0.5)",
            borderRadius: 6,
            color: "#FFFFFF",
            textDecoration: "none",
            opacity: 0.7,
            transition: "opacity 200ms",
          }}
          title="Download photo"
          aria-label={`Download ${altText}`}
        >
          <svg
            width="14"
            height="14"
            viewBox="0 0 16 16"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M8 2v9M4 8l4 4 4-4M2 14h12" />
          </svg>
        </a>
      </div>

      {/* Metadata below image (D-52) */}
      <div style={{ padding: "8px 10px" }}>
        {/* Caption */}
        {photo.caption && (
          <p
            style={{
              fontSize: 13,
              fontWeight: 500,
              color: "#1F2937",
              margin: "0 0 4px 0",
              lineHeight: 1.3,
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {photo.caption}
          </p>
        )}

        {/* Date taken */}
        <p
          style={{
            fontSize: 11,
            color: "#9CA3AF",
            margin: "0 0 2px 0",
          }}
        >
          {formatPhotoDate(photo.date_taken)}
        </p>

        {/* D-50: Location tag */}
        {photo.location.label && (
          <p
            style={{
              fontSize: 11,
              color: "#6B7280",
              margin: "0 0 2px 0",
              display: "flex",
              alignItems: "center",
              gap: 3,
            }}
          >
            <svg
              width="10"
              height="10"
              viewBox="0 0 16 16"
              fill="none"
              stroke="#6B7280"
              strokeWidth="1.5"
            >
              <path d="M8 1C5.24 1 3 3.24 3 6c0 4.5 5 9 5 9s5-4.5 5-9c0-2.76-2.24-5-5-5z" />
              <circle cx="8" cy="6" r="1.5" />
            </svg>
            {photo.location.label}
          </p>
        )}

        {/* Uploader name (D-52) */}
        <p
          style={{
            fontSize: 11,
            color: "#9CA3AF",
            margin: 0,
          }}
        >
          {photo.uploader_name}
        </p>
      </div>
    </div>
  );
}
