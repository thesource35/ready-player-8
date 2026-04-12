// Multi-layer caching for reports (D-59) + rate limiting for expensive ops (D-62b)
// Layers: 1) Client-side SWR-like hook, 2) Server in-memory cache, 3) Edge cache headers
// Uses Upstash Redis for rate limiting (same as web/src/lib/rate-limit.ts)

import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

// ---------------------------------------------------------------------------
// Layer 1: Client-side SWR config (used by report page components)
// Per D-59: 5-minute TTL, no revalidation on focus
// ---------------------------------------------------------------------------

/** SWR-compatible configuration for report data fetching */
export const REPORT_SWR_CONFIG = {
  revalidateOnFocus: false,
  revalidateOnReconnect: true,
  refreshInterval: 300_000, // 5 minutes
  dedupingInterval: 5_000, // 5s request dedup (D-50w)
  errorRetryCount: 2,
} as const;

/**
 * Client-side fetch wrapper with deduplication (D-50w).
 * Components call this instead of raw fetch for report endpoints.
 * Returns cached response if same key requested within 5 seconds.
 */
const clientDedup = new Map<string, { data: unknown; ts: number }>();

export async function fetchReportWithDedup<T>(
  key: string,
  fetcher: () => Promise<T>
): Promise<T> {
  const now = Date.now();
  const cached = clientDedup.get(key);
  if (cached && now - cached.ts < 5_000) {
    return cached.data as T;
  }
  const data = await fetcher();
  clientDedup.set(key, { data, ts: now });
  // Prune old entries
  if (clientDedup.size > 500) {
    for (const [k, v] of clientDedup) {
      if (now - v.ts > 10_000) clientDedup.delete(k);
    }
  }
  return data;
}

// ---------------------------------------------------------------------------
// Layer 2: Server in-memory cache (1-min TTL for DB view results)
// Per D-59: fast cache for aggregation query results
// ---------------------------------------------------------------------------

type CacheEntry<T> = { value: T; expiresAt: number };

const memCache = new Map<string, CacheEntry<unknown>>();

export const serverCache = {
  get<T>(key: string): T | null {
    const entry = memCache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      memCache.delete(key);
      return null;
    }
    return entry.value as T;
  },

  set<T>(key: string, value: T, ttlMs: number = 60_000): void {
    memCache.set(key, { value, expiresAt: Date.now() + ttlMs });
    // Prune expired entries when map gets large
    if (memCache.size > 1_000) {
      const now = Date.now();
      for (const [k, v] of memCache) {
        if (now > v.expiresAt) memCache.delete(k);
      }
    }
  },

  delete(key: string): void {
    memCache.delete(key);
  },

  /** Clear all entries matching a prefix */
  invalidatePrefix(prefix: string): void {
    for (const key of memCache.keys()) {
      if (key.startsWith(prefix)) memCache.delete(key);
    }
  },
};

// ---------------------------------------------------------------------------
// Layer 3: Vercel Edge Cache headers (D-59)
// Per D-59: s-maxage=60, stale-while-revalidate=300
// ---------------------------------------------------------------------------

/**
 * Returns Cache-Control headers for edge caching.
 * Uses projectId as cache tag for targeted invalidation.
 */
export function edgeCacheHeaders(projectId: string): Record<string, string> {
  return {
    "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300",
    "Cache-Tag": `report-${projectId}`,
    "Vary": "Accept-Encoding",
  };
}

// ---------------------------------------------------------------------------
// Cache invalidation (D-59)
// Purges all 3 layers for a given project
// ---------------------------------------------------------------------------

/**
 * Invalidate report cache for a specific project across all layers.
 * Call after data writes that affect report content.
 */
export function invalidateReportCache(projectId: string): void {
  // Layer 1: Clear client dedup cache for this project
  for (const key of clientDedup.keys()) {
    if (key.includes(projectId)) clientDedup.delete(key);
  }
  // Layer 2: Clear server cache for this project
  serverCache.invalidatePrefix(`report:${projectId}`);
  // Layer 3: Edge cache invalidated by deploying with new cache tags
  // (Vercel purges automatically on redeploy; manual purge requires Vercel API)
}

// ---------------------------------------------------------------------------
// Report rate limiting (D-62b)
// Separate limits for different report operations
// ---------------------------------------------------------------------------

type ReportRateLimitType = "general" | "pdf" | "batch_export";

const REPORT_RATE_LIMITS: Record<
  ReportRateLimitType,
  { requests: number; window: string }
> = {
  general: { requests: 60, window: "1 m" },
  pdf: { requests: 10, window: "1 m" },
  batch_export: { requests: 3, window: "1 m" },
};

// Cache Ratelimit instances
const reportLimiterCache = new Map<string, Ratelimit>();

function getReportLimiter(type: ReportRateLimitType): Ratelimit | null {
  if (
    !process.env.UPSTASH_REDIS_REST_URL ||
    !process.env.UPSTASH_REDIS_REST_TOKEN
  ) {
    return null;
  }
  const config = REPORT_RATE_LIMITS[type];
  const key = `report:${type}`;
  let limiter = reportLimiterCache.get(key);
  if (!limiter) {
    const redis = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL,
      token: process.env.UPSTASH_REDIS_REST_TOKEN,
    });
    limiter = new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(
        config.requests,
        config.window as Parameters<typeof Ratelimit.slidingWindow>[1]
      ),
      prefix: "constructionos:report",
    });
    reportLimiterCache.set(key, limiter);
  }
  return limiter;
}

// In-memory fallback for rate limiting (dev/single-instance)
const memRateStore = new Map<
  string,
  { count: number; resetAt: number }
>();

function parseWindowMs(window: string): number {
  const parts = window.trim().split(/\s+/);
  const value = parseInt(parts[0], 10);
  const unit = (parts[1] || "s").toLowerCase();
  switch (unit) {
    case "s": return value * 1_000;
    case "m": return value * 60_000;
    case "h": return value * 3_600_000;
    default: return value * 60_000;
  }
}

/**
 * Rate limit check for report operations (D-62b).
 * Returns { success, limit, remaining, reset }.
 */
export async function reportRateLimit(
  type: ReportRateLimitType,
  identifier: string
): Promise<{ success: boolean; limit: number; remaining: number; reset: number }> {
  const config = REPORT_RATE_LIMITS[type];
  const limiter = getReportLimiter(type);

  if (limiter) {
    const result = await limiter.limit(identifier);
    return {
      success: result.success,
      limit: result.limit,
      remaining: result.remaining,
      reset: result.reset,
    };
  }

  // In-memory fallback
  const now = Date.now();
  const windowMs = parseWindowMs(config.window);
  const storeKey = `${identifier}:report:${type}`;
  const entry = memRateStore.get(storeKey);

  if (!entry || now > entry.resetAt) {
    memRateStore.set(storeKey, { count: 1, resetAt: now + windowMs });
    if (memRateStore.size > 10_000) {
      for (const [k, v] of memRateStore) {
        if (now > v.resetAt) memRateStore.delete(k);
      }
    }
    return {
      success: true,
      limit: config.requests,
      remaining: config.requests - 1,
      reset: now + windowMs,
    };
  }

  if (entry.count >= config.requests) {
    return {
      success: false,
      limit: config.requests,
      remaining: 0,
      reset: entry.resetAt,
    };
  }

  entry.count++;
  return {
    success: true,
    limit: config.requests,
    remaining: config.requests - entry.count,
    reset: entry.resetAt,
  };
}
