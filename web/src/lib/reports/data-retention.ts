// Data retention policy for reports (D-96) + full data export (D-97)
// User-configurable retention periods with cleanup and expiry warnings.

// ---------------------------------------------------------------------------
// Retention period options (D-96)
// ---------------------------------------------------------------------------

export type RetentionPeriod = "6_months" | "1_year" | "2_years" | "unlimited";

export const RETENTION_OPTIONS: {
  value: RetentionPeriod;
  label: string;
  days: number | null;
}[] = [
  { value: "6_months", label: "6 months", days: 183 },
  { value: "1_year", label: "1 year", days: 365 },
  { value: "2_years", label: "2 years", days: 730 },
  { value: "unlimited", label: "Unlimited", days: null },
];

function retentionDays(period: RetentionPeriod): number | null {
  const option = RETENTION_OPTIONS.find((o) => o.value === period);
  return option?.days ?? null;
}

// ---------------------------------------------------------------------------
// User retention policy (D-96)
// ---------------------------------------------------------------------------

/**
 * Get the retention policy for a user.
 * In production, reads from user settings in Supabase.
 * Default: 1 year.
 */
export async function getRetentionPolicy(
  userId: string
): Promise<{
  period: RetentionPeriod;
  days: number | null;
  cutoffDate: Date | null;
}> {
  // Read from user preferences (Supabase user_settings table)
  // For now, use default until user settings API is wired
  let period: RetentionPeriod = "1_year";

  try {
    const res = await fetch(`/api/reports/settings?userId=${encodeURIComponent(userId)}`);
    if (res.ok) {
      const data = await res.json();
      if (data.retention_period && isValidPeriod(data.retention_period)) {
        period = data.retention_period;
      }
    }
  } catch {
    // Fall back to default on network error
  }

  const days = retentionDays(period);
  const cutoffDate = days
    ? new Date(Date.now() - days * 24 * 60 * 60 * 1000)
    : null;

  return { period, days, cutoffDate };
}

function isValidPeriod(value: string): value is RetentionPeriod {
  return ["6_months", "1_year", "2_years", "unlimited"].includes(value);
}

// ---------------------------------------------------------------------------
// Apply retention (D-96): delete expired records
// ---------------------------------------------------------------------------

/**
 * Apply data retention policy by deleting records older than the retention cutoff.
 * Targets: cs_report_history, cs_report_delivery_log.
 * Returns count of deleted records per table.
 */
export async function applyRetention(
  userId: string
): Promise<{ deletedHistory: number; deletedDelivery: number; error?: string }> {
  const policy = await getRetentionPolicy(userId);

  if (!policy.cutoffDate) {
    // Unlimited retention -- nothing to delete
    return { deletedHistory: 0, deletedDelivery: 0 };
  }

  const cutoffISO = policy.cutoffDate.toISOString();

  try {
    const res = await fetch("/api/reports/retention/apply", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId,
        cutoffDate: cutoffISO,
        tables: ["cs_report_history", "cs_report_delivery_log"],
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return { deletedHistory: 0, deletedDelivery: 0, error: errText };
    }

    const data = await res.json();
    return {
      deletedHistory: data.deletedHistory ?? 0,
      deletedDelivery: data.deletedDelivery ?? 0,
    };
  } catch (err) {
    return {
      deletedHistory: 0,
      deletedDelivery: 0,
      error: err instanceof Error ? err.message : "Unknown error",
    };
  }
}

// ---------------------------------------------------------------------------
// Expiring items warning (D-96)
// ---------------------------------------------------------------------------

/**
 * Get items within 30 days of their retention expiry.
 * Helps users decide what to export before automatic cleanup.
 */
export async function getExpiringItems(
  userId: string
): Promise<{
  items: { id: string; table: string; createdAt: string; expiresAt: string }[];
  error?: string;
}> {
  const policy = await getRetentionPolicy(userId);

  if (!policy.cutoffDate || !policy.days) {
    // Unlimited retention -- nothing expires
    return { items: [] };
  }

  // Items created before (cutoffDate + 30 days) are within 30 days of expiry
  const warningCutoff = new Date(
    policy.cutoffDate.getTime() + 30 * 24 * 60 * 60 * 1000
  );
  const warningISO = warningCutoff.toISOString();
  const cutoffISO = policy.cutoffDate.toISOString();

  try {
    const res = await fetch(
      `/api/reports/retention/expiring?userId=${encodeURIComponent(userId)}&warningDate=${encodeURIComponent(warningISO)}&cutoffDate=${encodeURIComponent(cutoffISO)}`
    );

    if (!res.ok) {
      return { items: [], error: await res.text() };
    }

    const data = await res.json();
    return { items: data.items ?? [] };
  } catch (err) {
    return {
      items: [],
      error: err instanceof Error ? err.message : "Unknown error",
    };
  }
}

// ---------------------------------------------------------------------------
// Full data export (D-97)
// ---------------------------------------------------------------------------

export type ExportManifest = {
  userId: string;
  exportedAt: string;
  contents: {
    reportHistory: number;
    deliveryLogs: number;
    schedules: number;
    templates: number;
    pdfs: number;
  };
};

/**
 * Request a full data export (D-97).
 * Server generates a ZIP containing all report data:
 * - Stored PDFs from Supabase Storage
 * - Schedule configurations as JSON
 * - Templates as JSON
 * - Delivery logs as CSV
 * - Report history snapshots as JSON
 *
 * Returns a download URL for the generated ZIP.
 * Rate limited to 1/hour per D-97 and T-19-44.
 */
export async function requestFullExport(
  userId: string
): Promise<{ downloadUrl: string; manifest: ExportManifest } | { error: string }> {
  try {
    const res = await fetch("/api/reports/export/full", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId }),
    });

    if (res.status === 429) {
      return { error: "Export rate limited. You can export once per hour." };
    }

    if (!res.ok) {
      const errText = await res.text();
      return { error: errText || "Export failed" };
    }

    const data = await res.json();
    return {
      downloadUrl: data.downloadUrl,
      manifest: data.manifest,
    };
  } catch (err) {
    return {
      error: err instanceof Error ? err.message : "Unknown error during export",
    };
  }
}
