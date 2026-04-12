// Phase 19 — Performance metrics endpoint (D-62c, D-105)
// Returns p50/p95/avg response times per API section.
// Admin-only access (T-19-38). In-memory buffer bounded to 100 entries.
// Also tracks Vercel Analytics events and references PostHog integration.

import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// ---------------------------------------------------------------------------
// In-memory timing store (T-19-38: bounded to 100 entries per endpoint)
// ---------------------------------------------------------------------------

const MAX_ENTRIES_PER_ENDPOINT = 100;

type TimingEntry = {
  durationMs: number;
  timestamp: number;
};

// Global in-memory map — survives across requests in same process
const timingStore = new Map<string, TimingEntry[]>();

/**
 * Record a timing entry for an endpoint.
 * Called from other API routes to track response times.
 */
export function recordTiming(endpoint: string, durationMs: number): void {
  let entries = timingStore.get(endpoint);
  if (!entries) {
    entries = [];
    timingStore.set(endpoint, entries);
  }

  entries.push({ durationMs, timestamp: Date.now() });

  // Bounded to MAX_ENTRIES_PER_ENDPOINT (T-19-38)
  if (entries.length > MAX_ENTRIES_PER_ENDPOINT) {
    entries.shift();
  }
}

// ---------------------------------------------------------------------------
// Percentile calculation
// ---------------------------------------------------------------------------

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, idx)];
}

function computeStats(entries: TimingEntry[]): {
  p50: number;
  p95: number;
  avg: number;
  count: number;
} {
  if (entries.length === 0) {
    return { p50: 0, p95: 0, avg: 0, count: 0 };
  }

  const durations = entries.map((e) => e.durationMs).sort((a, b) => a - b);
  const sum = durations.reduce((acc, d) => acc + d, 0);

  return {
    p50: Math.round(percentile(durations, 50)),
    p95: Math.round(percentile(durations, 95)),
    avg: Math.round(sum / durations.length),
    count: durations.length,
  };
}

// ---------------------------------------------------------------------------
// Vercel Analytics event types (D-105)
// These events are tracked client-side via @vercel/analytics track() calls.
// PostHog events sent server-side for detailed behavioral analytics.
// ---------------------------------------------------------------------------

export const ANALYTICS_EVENTS = {
  report_viewed: "report_viewed",
  report_exported: "report_exported",
  schedule_created: "schedule_created",
  embed_generated: "embed_generated",
  shared_link_created: "shared_link_created",
} as const;

/**
 * PostHog integration helper (D-105).
 * In production, initialize posthog-node and call posthog.capture().
 * This helper provides the interface; actual PostHog client initialization
 * requires POSTHOG_API_KEY environment variable.
 */
export function trackPostHogEvent(
  distinctId: string,
  event: string,
  properties?: Record<string, unknown>
): void {
  // PostHog server-side tracking (posthog-node)
  // In production: const posthog = new PostHog(process.env.POSTHOG_API_KEY);
  // posthog.capture({ distinctId, event, properties });
  if (process.env.NODE_ENV === "development") {
    console.log(`[PostHog] ${event}`, { distinctId, ...properties });
  }
}

// ---------------------------------------------------------------------------
// GET /api/reports/metrics — admin-only performance metrics
// ---------------------------------------------------------------------------

export async function GET(req: Request): Promise<Response> {
  // Rate limit (T-19-38)
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded" },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  // Auth check — admin only (T-19-38)
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  // Check admin role (query user metadata or org roles table)
  const { data: userOrg } = await supabase
    .from("user_orgs")
    .select("role")
    .eq("user_id", user.id)
    .single();

  const isAdmin =
    userOrg?.role === "admin" ||
    userOrg?.role === "owner" ||
    user.app_metadata?.role === "admin";

  if (!isAdmin) {
    return NextResponse.json(
      { error: "Admin access required" },
      { status: 403 }
    );
  }

  // Compute metrics per endpoint
  const endpoints = [
    "/api/reports/project",
    "/api/reports/rollup",
    "/api/reports/health",
    "/api/reports/schedules",
    "/api/reports/shared-links",
    "/api/reports/embed",
    "/api/reports/export",
  ];

  const metrics: Record<
    string,
    { p50: number; p95: number; avg: number; count: number }
  > = {};

  for (const endpoint of endpoints) {
    const entries = timingStore.get(endpoint) ?? [];
    metrics[endpoint] = computeStats(entries);
  }

  // Aggregate across all endpoints
  const allEntries = Array.from(timingStore.values()).flat();
  const aggregate = computeStats(allEntries);

  return NextResponse.json(
    {
      generated_at: new Date().toISOString(),
      aggregate,
      endpoints: metrics,
      buffer_size: MAX_ENTRIES_PER_ENDPOINT,
      analytics_events: Object.keys(ANALYTICS_EVENTS),
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
        "X-Report-Debug": `metrics:${allEntries.length}`,
      },
    }
  );
}

// ---------------------------------------------------------------------------
// POST /api/reports/metrics — record timing data from other routes
// ---------------------------------------------------------------------------

export async function POST(req: Request): Promise<Response> {
  try {
    const body = (await req.json()) as {
      endpoint?: string;
      durationMs?: number;
    };

    if (
      !body.endpoint ||
      typeof body.endpoint !== "string" ||
      typeof body.durationMs !== "number" ||
      body.durationMs < 0
    ) {
      return NextResponse.json(
        { error: "Invalid payload: endpoint (string) and durationMs (number >= 0) required" },
        { status: 400 }
      );
    }

    // Sanitize endpoint name
    const endpoint = body.endpoint.replace(/[^a-zA-Z0-9/\-_]/g, "").slice(0, 100);
    recordTiming(endpoint, body.durationMs);

    return NextResponse.json({ recorded: true });
  } catch {
    return NextResponse.json(
      { error: "Invalid JSON body" },
      { status: 400 }
    );
  }
}
