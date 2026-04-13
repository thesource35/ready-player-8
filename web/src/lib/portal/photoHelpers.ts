// Portal photo helpers (D-47, D-52, D-54)
// Groups photos by date, formats dates, defines the PortalPhoto type

export type PortalPhoto = {
  id: string;
  url: string;
  signedUrl: string;
  caption: string | null;
  date_taken: string;
  location: {
    lat?: number;
    lng?: number;
    label?: string;
  };
  uploader_name: string;
  has_annotation: boolean;
  width: number;
  height: number;
};

/**
 * Group photos by date (YYYY-MM-DD), sorted newest date first (D-47).
 * Within each date group, photos retain their original order.
 */
export function groupPhotosByDate(
  photos: PortalPhoto[]
): Map<string, PortalPhoto[]> {
  const grouped = new Map<string, PortalPhoto[]>();

  for (const photo of photos) {
    const dateKey = photo.date_taken
      ? photo.date_taken.slice(0, 10)
      : "unknown";
    const existing = grouped.get(dateKey);
    if (existing) {
      existing.push(photo);
    } else {
      grouped.set(dateKey, [photo]);
    }
  }

  // Sort by date descending (newest first)
  const sorted = new Map(
    [...grouped.entries()].sort((a, b) => {
      if (a[0] === "unknown") return 1;
      if (b[0] === "unknown") return -1;
      return b[0].localeCompare(a[0]);
    })
  );

  return sorted;
}

/**
 * Format a date string to human-readable format: "April 10, 2026" (D-52)
 */
export function formatPhotoDate(date: string): string {
  try {
    const d = new Date(date);
    if (isNaN(d.getTime())) return date;
    return d.toLocaleDateString("en-US", {
      month: "long",
      day: "numeric",
      year: "numeric",
    });
  } catch {
    return date;
  }
}

/**
 * Get the date range summary string: "March 2026 to April 2026" (D-54)
 */
export function getDateRangeSummary(photos: PortalPhoto[]): string {
  if (photos.length === 0) return "";
  const dates = photos
    .map((p) => new Date(p.date_taken))
    .filter((d) => !isNaN(d.getTime()))
    .sort((a, b) => a.getTime() - b.getTime());

  if (dates.length === 0) return "";

  const oldest = dates[0];
  const newest = dates[dates.length - 1];

  const fmt = (d: Date) =>
    d.toLocaleDateString("en-US", { month: "long", year: "numeric" });

  if (fmt(oldest) === fmt(newest)) return fmt(oldest);
  return `${fmt(oldest)} to ${fmt(newest)}`;
}
