export type UrgencyLevel = "safe" | "warning" | "urgent" | "expired";

export type UrgencyInfo = {
  color: string;
  label: string;
  level: UrgencyLevel;
};

export function getUrgencyInfo(expires: string | null): UrgencyInfo {
  if (!expires) return { color: "var(--muted)", label: "No expiry", level: "safe" };
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const exp = new Date(expires);
  const diffDays = Math.ceil((exp.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  if (diffDays < 0) return { color: "var(--red)", label: "Expired", level: "expired" };
  if (diffDays === 0) return { color: "var(--red)", label: "Expires today", level: "urgent" };
  if (diffDays <= 7) return { color: "var(--red)", label: `Expires in ${diffDays}d`, level: "urgent" };
  if (diffDays <= 30) return { color: "var(--gold)", label: `Expires in ${diffDays}d`, level: "warning" };
  return { color: "var(--green)", label: `${diffDays}d remaining`, level: "safe" };
}

/** Convenience alias for Plan 06 CertComplianceWidget */
export function certUrgency(expires: string | null): UrgencyLevel {
  return getUrgencyInfo(expires).level;
}

export function urgencyColor(expires: string | null): string {
  return getUrgencyInfo(expires).color;
}

export function urgencyLabel(expires: string | null): string {
  return getUrgencyInfo(expires).label;
}
