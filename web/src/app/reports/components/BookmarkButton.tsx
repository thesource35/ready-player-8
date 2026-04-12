"use client";

import { useState, useEffect, useCallback } from "react";

// ---------- Types ----------

type BookmarkButtonProps = {
  reportId: string;
  reportType: string;
  /** Optional label shown in dashboard view */
  label?: string;
  /** Size of the button icon */
  size?: number;
};

type BookmarkEntry = {
  reportId: string;
  reportType: string;
  label: string;
  addedAt: string;
};

// ---------- Storage ----------

const STORAGE_KEY = "constructos-report-bookmarks";
const MAX_BOOKMARKS = 50;

function getBookmarks(): BookmarkEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveBookmarks(bookmarks: BookmarkEntry[]): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(bookmarks));
  } catch {
    // localStorage full or unavailable — silently fail
  }
}

// ---------- BookmarkButton Component ----------

export function BookmarkButton({
  reportId,
  reportType,
  label,
  size = 16,
}: BookmarkButtonProps) {
  const [isBookmarked, setIsBookmarked] = useState(false);

  useEffect(() => {
    const bookmarks = getBookmarks();
    setIsBookmarked(bookmarks.some((b) => b.reportId === reportId));
  }, [reportId]);

  const toggle = useCallback(() => {
    const bookmarks = getBookmarks();
    const idx = bookmarks.findIndex((b) => b.reportId === reportId);

    if (idx >= 0) {
      // Remove bookmark
      bookmarks.splice(idx, 1);
      saveBookmarks(bookmarks);
      setIsBookmarked(false);
    } else {
      // Add bookmark (D-111: pin favorite reports)
      if (bookmarks.length >= MAX_BOOKMARKS) {
        // Limit to prevent unbounded growth
        bookmarks.shift();
      }
      bookmarks.push({
        reportId,
        reportType,
        label: label ?? reportId,
        addedAt: new Date().toISOString(),
      });
      saveBookmarks(bookmarks);
      setIsBookmarked(true);
    }
  }, [reportId, reportType, label]);

  return (
    <button
      onClick={toggle}
      aria-label={isBookmarked ? "Remove bookmark" : "Bookmark report"}
      aria-pressed={isBookmarked}
      title={isBookmarked ? "Remove bookmark" : "Bookmark report"}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        width: size + 12,
        height: size + 12,
        padding: 0,
        background: "none",
        border: "none",
        cursor: "pointer",
        borderRadius: 4,
        transition: "background 0.15s",
      }}
    >
      {isBookmarked ? (
        // Filled star
        <svg
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill="var(--accent, #F29E3D)"
          stroke="var(--accent, #F29E3D)"
          strokeWidth={2}
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      ) : (
        // Outline star
        <svg
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill="none"
          stroke="var(--muted, #6B7B8D)"
          strokeWidth={2}
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </svg>
      )}
    </button>
  );
}

// ---------- BookmarkDashboard Component (D-111) ----------

type BookmarkDashboardProps = {
  /** Render function for each bookmarked item (e.g., mini chart widget) */
  renderWidget?: (entry: BookmarkEntry) => React.ReactNode;
};

export function BookmarkDashboard({ renderWidget }: BookmarkDashboardProps) {
  const [bookmarks, setBookmarks] = useState<BookmarkEntry[]>([]);
  const [dragIdx, setDragIdx] = useState<number | null>(null);

  useEffect(() => {
    setBookmarks(getBookmarks());
  }, []);

  const removeBookmark = useCallback((reportId: string) => {
    setBookmarks((prev) => {
      const next = prev.filter((b) => b.reportId !== reportId);
      saveBookmarks(next);
      return next;
    });
  }, []);

  // Simple drag-and-drop reorder using CSS grid (D-111)
  const handleDragStart = useCallback((idx: number) => {
    setDragIdx(idx);
  }, []);

  const handleDrop = useCallback(
    (targetIdx: number) => {
      if (dragIdx === null || dragIdx === targetIdx) {
        setDragIdx(null);
        return;
      }
      setBookmarks((prev) => {
        const next = [...prev];
        const [moved] = next.splice(dragIdx, 1);
        next.splice(targetIdx, 0, moved);
        saveBookmarks(next);
        return next;
      });
      setDragIdx(null);
    },
    [dragIdx]
  );

  if (bookmarks.length === 0) {
    return (
      <div
        style={{
          textAlign: "center",
          padding: 32,
          color: "var(--muted, #6B7B8D)",
          fontSize: 12,
        }}
      >
        No bookmarked reports yet. Star a report to pin it here.
      </div>
    );
  }

  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
        gap: 12,
      }}
    >
      {bookmarks.map((entry, idx) => (
        <div
          key={entry.reportId}
          draggable
          onDragStart={() => handleDragStart(idx)}
          onDragOver={(e) => e.preventDefault()}
          onDrop={() => handleDrop(idx)}
          style={{
            background: "var(--surface, #1A2332)",
            border: `1px solid ${dragIdx === idx ? "var(--accent, #F29E3D)" : "var(--border, #2A3544)"}`,
            borderRadius: 8,
            padding: 12,
            cursor: "grab",
            opacity: dragIdx === idx ? 0.5 : 1,
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: 8,
            }}
          >
            <span
              style={{
                fontSize: 11,
                fontWeight: 800,
                color: "var(--text, #E8ECF0)",
              }}
            >
              {entry.label}
            </span>
            <button
              onClick={() => removeBookmark(entry.reportId)}
              aria-label={`Remove ${entry.label} bookmark`}
              style={{
                background: "none",
                border: "none",
                color: "var(--muted, #6B7B8D)",
                fontSize: 12,
                cursor: "pointer",
                padding: 2,
              }}
            >
              x
            </button>
          </div>
          <div
            style={{
              fontSize: 9,
              color: "var(--muted, #6B7B8D)",
              marginBottom: renderWidget ? 8 : 0,
            }}
          >
            {entry.reportType}
          </div>
          {renderWidget?.(entry)}
        </div>
      ))}
    </div>
  );
}
