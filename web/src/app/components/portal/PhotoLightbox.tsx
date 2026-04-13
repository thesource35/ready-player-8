"use client";

// Portal photo lightbox (D-49)
// Fullscreen overlay with swipe navigation, zoom, keyboard controls

import { useState, useEffect, useCallback, useRef } from "react";
import type { PortalPhoto } from "@/lib/portal/photoHelpers";
import { formatPhotoDate } from "@/lib/portal/photoHelpers";

type PhotoLightboxProps = {
  photos: PortalPhoto[];
  initialIndex: number;
  onClose: () => void;
};

export default function PhotoLightbox({
  photos,
  initialIndex,
  onClose,
}: PhotoLightboxProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [scale, setScale] = useState(1);
  const touchStartRef = useRef<{ x: number; y: number } | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const photo = photos[currentIndex];
  const totalCount = photos.length;

  // Navigate to previous photo
  const goToPrev = useCallback(() => {
    setScale(1);
    setCurrentIndex((prev) => (prev > 0 ? prev - 1 : prev));
  }, []);

  // Navigate to next photo
  const goToNext = useCallback(() => {
    setScale(1);
    setCurrentIndex((prev) => (prev < photos.length - 1 ? prev + 1 : prev));
  }, [photos.length]);

  // Keyboard navigation: Escape to close, Left/Right arrows (D-49)
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      switch (e.key) {
        case "Escape":
          onClose();
          break;
        case "ArrowLeft":
          goToPrev();
          break;
        case "ArrowRight":
          goToNext();
          break;
      }
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onClose, goToPrev, goToNext]);

  // Prevent body scroll when lightbox is open
  useEffect(() => {
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = originalOverflow;
    };
  }, []);

  // Focus container on mount for keyboard accessibility
  useEffect(() => {
    containerRef.current?.focus();
  }, []);

  // Touch handlers for swipe navigation on mobile (D-49)
  function handleTouchStart(e: React.TouchEvent) {
    if (e.touches.length === 1) {
      touchStartRef.current = {
        x: e.touches[0].clientX,
        y: e.touches[0].clientY,
      };
    }
  }

  function handleTouchEnd(e: React.TouchEvent) {
    if (!touchStartRef.current || e.changedTouches.length === 0) return;
    const deltaX =
      e.changedTouches[0].clientX - touchStartRef.current.x;
    const deltaY =
      e.changedTouches[0].clientY - touchStartRef.current.y;

    // Only trigger swipe if horizontal movement > 50px and dominant
    if (Math.abs(deltaX) > 50 && Math.abs(deltaX) > Math.abs(deltaY)) {
      if (deltaX > 0) {
        goToPrev();
      } else {
        goToNext();
      }
    }
    touchStartRef.current = null;
  }

  // Scroll-to-zoom on desktop (D-49)
  function handleWheel(e: React.WheelEvent) {
    e.preventDefault();
    setScale((prev) => {
      const next = prev - e.deltaY * 0.001;
      return Math.min(Math.max(next, 0.5), 4);
    });
  }

  if (!photo) return null;

  return (
    <div
      ref={containerRef}
      role="dialog"
      aria-modal="true"
      aria-label={`Photo lightbox: ${photo.caption || "Project photo"}`}
      tabIndex={-1}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      onWheel={handleWheel}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 10000,
        background: "rgba(0, 0, 0, 0.92)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        outline: "none",
      }}
    >
      {/* Close button (X) top-left */}
      <button
        onClick={onClose}
        aria-label="Close lightbox"
        style={{
          position: "absolute",
          top: 16,
          left: 16,
          width: 40,
          height: 40,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "rgba(255, 255, 255, 0.15)",
          border: "none",
          borderRadius: 8,
          cursor: "pointer",
          color: "#FFFFFF",
          fontSize: 20,
          zIndex: 10001,
        }}
      >
        <svg
          width="20"
          height="20"
          viewBox="0 0 16 16"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        >
          <path d="M4 4l8 8M12 4l-8 8" />
        </svg>
      </button>

      {/* Download button top-right */}
      <a
        href={photo.signedUrl || photo.url}
        download
        aria-label="Download photo"
        style={{
          position: "absolute",
          top: 16,
          right: 16,
          width: 40,
          height: 40,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "rgba(255, 255, 255, 0.15)",
          border: "none",
          borderRadius: 8,
          color: "#FFFFFF",
          textDecoration: "none",
          zIndex: 10001,
        }}
      >
        <svg
          width="18"
          height="18"
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

      {/* Previous arrow */}
      {currentIndex > 0 && (
        <button
          onClick={goToPrev}
          aria-label="Previous photo"
          style={{
            position: "absolute",
            left: 16,
            top: "50%",
            transform: "translateY(-50%)",
            width: 44,
            height: 44,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "rgba(255, 255, 255, 0.12)",
            border: "none",
            borderRadius: 22,
            cursor: "pointer",
            color: "#FFFFFF",
            zIndex: 10001,
          }}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 16 16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M10 4l-4 4 4 4" />
          </svg>
        </button>
      )}

      {/* Next arrow */}
      {currentIndex < totalCount - 1 && (
        <button
          onClick={goToNext}
          aria-label="Next photo"
          style={{
            position: "absolute",
            right: 16,
            top: "50%",
            transform: "translateY(-50%)",
            width: 44,
            height: 44,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "rgba(255, 255, 255, 0.12)",
            border: "none",
            borderRadius: 22,
            cursor: "pointer",
            color: "#FFFFFF",
            zIndex: 10001,
          }}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 16 16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M6 4l4 4-4 4" />
          </svg>
        </button>
      )}

      {/* Main photo (centered, zoomable) */}
      <div
        style={{
          flex: 1,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          width: "100%",
          padding: "60px 60px 100px",
          overflow: "hidden",
        }}
      >
        <img
          src={photo.signedUrl || photo.url}
          alt={
            photo.caption ||
            `Project photo from ${formatPhotoDate(photo.date_taken)}`
          }
          style={{
            maxWidth: "100%",
            maxHeight: "100%",
            objectFit: "contain",
            transform: `scale(${scale})`,
            transition: "transform 150ms ease-out",
            borderRadius: 4,
          }}
          draggable={false}
        />
      </div>

      {/* Bottom info bar: counter + caption + date + location */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          padding: "12px 20px 20px",
          background:
            "linear-gradient(transparent, rgba(0,0,0,0.7))",
          color: "#FFFFFF",
          textAlign: "center",
        }}
      >
        {/* Photo counter */}
        <p
          style={{
            fontSize: 13,
            fontWeight: 500,
            margin: "0 0 4px 0",
            opacity: 0.8,
          }}
        >
          {currentIndex + 1} / {totalCount}
        </p>

        {/* Caption */}
        {photo.caption && (
          <p
            style={{
              fontSize: 14,
              fontWeight: 500,
              margin: "0 0 4px 0",
            }}
          >
            {photo.caption}
          </p>
        )}

        {/* Date + location */}
        <p
          style={{
            fontSize: 12,
            margin: 0,
            opacity: 0.7,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 12,
          }}
        >
          <span>{formatPhotoDate(photo.date_taken)}</span>
          {photo.location.label && (
            <span
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 3,
              }}
            >
              <svg
                width="10"
                height="10"
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
              >
                <path d="M8 1C5.24 1 3 3.24 3 6c0 4.5 5 9 5 9s5-4.5 5-9c0-2.76-2.24-5-5-5z" />
                <circle cx="8" cy="6" r="1.5" />
              </svg>
              {photo.location.label}
            </span>
          )}
        </p>
      </div>
    </div>
  );
}
