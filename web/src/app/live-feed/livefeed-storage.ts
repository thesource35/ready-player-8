// Phase 29 LIVE-04 — shared localStorage keys mirroring iOS AppStorage namespace (CLAUDE.md).

export const LIVE_FEED_KEYS = {
  lastSelectedProjectId: "ConstructOS.LiveFeed.LastSelectedProjectId",
  lastFleetSelection: "ConstructOS.LiveFeed.LastFleetSelection",
  suggestionModel: "ConstructOS.LiveFeed.SuggestionModel",
} as const;

export function perProjectLastAnalyzedKey(projectId: string): string {
  return `ConstructOS.LiveFeed.LastAnalyzedAt.${projectId}`;
}

export function perProjectScrubKey(projectId: string): string {
  return `ConstructOS.LiveFeed.LastScrubTimestamp.${projectId}`;
}

export function readBool(key: string, fallback = false): boolean {
  if (typeof window === "undefined") return fallback;
  const v = window.localStorage.getItem(key);
  if (v === null) return fallback;
  return v === "true";
}

export function writeBool(key: string, value: boolean): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(key, value ? "true" : "false");
}

export function readString(key: string, fallback = ""): string {
  if (typeof window === "undefined") return fallback;
  return window.localStorage.getItem(key) ?? fallback;
}

export function writeString(key: string, value: string): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(key, value);
}
