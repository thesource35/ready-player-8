/**
 * TZ-safe ISO date-only helpers for Phase 17 Calendar.
 *
 * All functions operate on `YYYY-MM-DD` strings. Never call `new Date(isoString)`
 * on a date-only string — that parses as UTC midnight and drifts in negative
 * timezones (Pitfall #1). Use `parseDateOnly` which constructs a local Date.
 */

const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** True if `s` is a strict `YYYY-MM-DD` date string. */
export function isIsoDate(s: unknown): s is string {
  return typeof s === "string" && ISO_DATE_RE.test(s);
}

/**
 * Parse a `YYYY-MM-DD` string into a local-time Date (midnight local).
 * Throws on invalid input.
 */
export function parseDateOnly(s: string): Date {
  if (!isIsoDate(s)) throw new Error(`parseDateOnly: not an ISO date: ${s}`);
  const y = Number(s.slice(0, 4));
  const m = Number(s.slice(5, 7));
  const d = Number(s.slice(8, 10));
  // Local-time construction — never `new Date(s)` on date-only strings.
  return new Date(y, m - 1, d);
}

/** Inclusive day count between two ISO dates. daysBetween(a,a) === 0. */
export function daysBetween(a: string, b: string): number {
  const da = parseDateOnly(a);
  const db = parseDateOnly(b);
  const MS = 24 * 60 * 60 * 1000;
  return Math.round((db.getTime() - da.getTime()) / MS);
}

/** Add `n` days to an ISO date, returning a `YYYY-MM-DD` string. */
export function addDays(s: string, n: number): string {
  const d = parseDateOnly(s);
  d.setDate(d.getDate() + n);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}
