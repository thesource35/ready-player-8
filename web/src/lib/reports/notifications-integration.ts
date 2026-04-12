// Phase 19 — Report notification integration (D-100, D-101, D-102, D-50d)
// Emits notifications for report-related events: health changes, delivery,
// shared link access, batch export, and metric threshold alerts.
// Integrates with Phase 14 notification system via cs_notifications table.

import type { HealthColor, HealthScore } from "./types";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type HealthChangeEvent = {
  projectId: string;
  projectName: string;
  oldHealth: HealthScore;
  newHealth: HealthScore;
};

export type DeliveryEvent = {
  scheduleId: string;
  status: "sent" | "failed" | "partial";
  recipients: string[];
  errorMessage?: string;
};

export type SharedLinkAccessEvent = {
  linkId: string;
  viewerIp: string;
  viewerUserAgent?: string;
  reportType: "project" | "rollup";
};

export type BatchExportEvent = {
  userId: string;
  status: "completed" | "failed";
  downloadUrl?: string;
  projectCount: number;
};

export type ThresholdAlert = {
  projectId: string;
  projectName: string;
  metric: string;
  currentValue: number;
  threshold: number;
  operator: ">" | "<" | ">=" | "<=" | "=";
};

export type MetricThreshold = {
  metric: string;
  operator: ">" | "<" | ">=" | "<=" | "=";
  threshold: number;
  label?: string;
};

export type NotificationPrefs = {
  healthChanges: boolean;
  deliveries: boolean;
  thresholdAlerts: boolean;
  sharedLinkAccess: boolean;
  batchExport: boolean;
  dailyDigest: boolean;
  projectOverrides: Record<string, { enabled: boolean }>;
};

// ---------------------------------------------------------------------------
// Default preferences (D-101)
// ---------------------------------------------------------------------------

export const DEFAULT_NOTIFICATION_PREFS: NotificationPrefs = {
  healthChanges: true,
  deliveries: true,
  thresholdAlerts: true,
  sharedLinkAccess: false,
  batchExport: true,
  dailyDigest: false,
  projectOverrides: {},
};

// ---------------------------------------------------------------------------
// Color transition detection (D-100)
// ---------------------------------------------------------------------------

const COLOR_SEVERITY: Record<HealthColor, number> = {
  green: 0,
  gold: 1,
  red: 2,
};

/** Returns true when the health color actually changed */
export function hasColorTransition(
  oldHealth: HealthScore,
  newHealth: HealthScore
): boolean {
  return oldHealth.color !== newHealth.color;
}

/** Human-readable transition direction */
function transitionDirection(from: HealthColor, to: HealthColor): string {
  const diff = COLOR_SEVERITY[to] - COLOR_SEVERITY[from];
  if (diff > 0) return "degraded";
  if (diff < 0) return "improved";
  return "unchanged";
}

// ---------------------------------------------------------------------------
// Notification insertion helper
// ---------------------------------------------------------------------------

async function insertNotification(params: {
  userId: string;
  projectId: string | null;
  category: string;
  title: string;
  body: string;
  entityType?: string;
  entityId?: string;
}): Promise<boolean> {
  try {
    const { supabase } = await getAuthenticatedClient();
    if (!supabase) {
      console.error("[notifications-integration] No Supabase client available");
      return false;
    }

    const { error } = await supabase.from("cs_notifications").insert({
      user_id: params.userId,
      project_id: params.projectId,
      category: params.category,
      title: params.title,
      body: params.body,
      entity_type: params.entityType ?? null,
      entity_id: params.entityId ?? null,
      event_id: crypto.randomUUID(),
      read_at: null,
      dismissed_at: null,
    });

    if (error) {
      console.error("[notifications-integration] Insert failed:", error.message);
      return false;
    }
    return true;
  } catch (err) {
    console.error("[notifications-integration] insertNotification error:", err);
    return false;
  }
}

// ---------------------------------------------------------------------------
// Health change notifications (D-100)
// ---------------------------------------------------------------------------

/**
 * Emit notification when health score color transitions.
 * Only emits if the color actually changed (green->gold, gold->red, etc.).
 * Per D-100: default alerts on all color transitions + user-customizable overrides.
 */
export async function emitHealthChangeNotification(
  event: HealthChangeEvent,
  userId: string
): Promise<boolean> {
  if (!hasColorTransition(event.oldHealth, event.newHealth)) {
    return false; // No color change — no notification
  }

  const direction = transitionDirection(event.oldHealth.color, event.newHealth.color);
  const title = `Health ${direction}: ${event.projectName}`;
  const body =
    `Project health ${direction} from ${event.oldHealth.label} ` +
    `(${event.oldHealth.color}) to ${event.newHealth.label} ` +
    `(${event.newHealth.color}). Score: ${event.newHealth.score}`;

  return insertNotification({
    userId,
    projectId: event.projectId,
    category: "health_change",
    title,
    body,
    entityType: "cs_projects",
    entityId: event.projectId,
  });
}

// ---------------------------------------------------------------------------
// Delivery notifications (D-50d)
// ---------------------------------------------------------------------------

/**
 * Emit notification on scheduled report delivery or failure.
 */
export async function emitDeliveryNotification(
  event: DeliveryEvent,
  userId: string
): Promise<boolean> {
  const statusLabel =
    event.status === "sent" ? "delivered" : event.status === "partial" ? "partially delivered" : "failed";
  const title = `Report ${statusLabel}`;
  const body =
    event.status === "failed"
      ? `Scheduled report delivery failed: ${event.errorMessage ?? "Unknown error"}`
      : `Scheduled report ${statusLabel} to ${event.recipients.length} recipient(s)`;

  return insertNotification({
    userId,
    projectId: null,
    category: "report_delivery",
    title,
    body,
    entityType: "cs_report_schedules",
    entityId: event.scheduleId,
  });
}

// ---------------------------------------------------------------------------
// Shared link access notifications (D-50d)
// ---------------------------------------------------------------------------

/**
 * Emit notification when someone views a shared report link.
 */
export async function emitSharedLinkAccessNotification(
  event: SharedLinkAccessEvent,
  userId: string
): Promise<boolean> {
  const title = "Shared report viewed";
  const body = `A ${event.reportType} report was viewed via shared link. Viewer IP: ${event.viewerIp}`;

  return insertNotification({
    userId,
    projectId: null,
    category: "shared_link_access",
    title,
    body,
    entityType: "cs_report_shared_links",
    entityId: event.linkId,
  });
}

// ---------------------------------------------------------------------------
// Batch export notifications (D-50d)
// ---------------------------------------------------------------------------

/**
 * Emit notification when batch export completes or fails.
 */
export async function emitBatchExportNotification(
  event: BatchExportEvent
): Promise<boolean> {
  const title =
    event.status === "completed"
      ? "Batch export ready"
      : "Batch export failed";
  const body =
    event.status === "completed"
      ? `${event.projectCount} report(s) exported and ready for download`
      : `Batch export of ${event.projectCount} report(s) failed. Please try again.`;

  return insertNotification({
    userId: event.userId,
    projectId: null,
    category: "batch_export",
    title,
    body,
  });
}

// ---------------------------------------------------------------------------
// Metric threshold checking (D-102)
// ---------------------------------------------------------------------------

/**
 * Compare operator evaluation for threshold checks.
 */
function evaluateOperator(
  value: number,
  operator: MetricThreshold["operator"],
  threshold: number
): boolean {
  switch (operator) {
    case ">":
      return value > threshold;
    case "<":
      return value < threshold;
    case ">=":
      return value >= threshold;
    case "<=":
      return value <= threshold;
    case "=":
      return value === threshold;
    default:
      return false;
  }
}

/**
 * Check project metrics against user-defined thresholds.
 * Returns alerts for any thresholds that are exceeded.
 * Per D-102: custom thresholds per project per metric.
 */
export function checkThresholds(
  projectId: string,
  projectName: string,
  metrics: Record<string, number>,
  userThresholds: MetricThreshold[]
): ThresholdAlert[] {
  const alerts: ThresholdAlert[] = [];

  for (const t of userThresholds) {
    const value = metrics[t.metric];
    if (value === undefined) continue;

    if (evaluateOperator(value, t.operator, t.threshold)) {
      alerts.push({
        projectId,
        projectName,
        metric: t.label ?? t.metric,
        currentValue: value,
        threshold: t.threshold,
        operator: t.operator,
      });
    }
  }

  return alerts;
}

/**
 * Detect unexpected movements: flag metrics that changed by more than
 * the given percentage in a single reporting period.
 * Per D-102: change detection for unexpected movements.
 */
export function detectUnexpectedChanges(
  previousMetrics: Record<string, number>,
  currentMetrics: Record<string, number>,
  changeThresholdPercent: number = 20
): Array<{
  metric: string;
  previousValue: number;
  currentValue: number;
  changePercent: number;
}> {
  const changes: Array<{
    metric: string;
    previousValue: number;
    currentValue: number;
    changePercent: number;
  }> = [];

  for (const [metric, current] of Object.entries(currentMetrics)) {
    const previous = previousMetrics[metric];
    if (previous === undefined || previous === 0) continue;

    const changePercent = Math.abs(((current - previous) / previous) * 100);
    if (changePercent > changeThresholdPercent) {
      changes.push({
        metric,
        previousValue: previous,
        currentValue: current,
        changePercent: Math.round(changePercent * 10) / 10,
      });
    }
  }

  return changes;
}
