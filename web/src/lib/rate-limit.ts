// Dual-mode rate limiter: Upstash Redis (distributed) with in-memory fallback
// Upstash is used when UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN are set;
// otherwise falls back to per-instance in-memory Map (suitable for dev/single-instance).

import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

// ---------------------------------------------------------------------------
// Per-route rate limit configuration
// ---------------------------------------------------------------------------

type RouteLimit = { requests: number; window: string };

const ROUTE_LIMITS: Record<string, RouteLimit> = {
  "/api/chat": { requests: 10, window: "1 m" },
  "/api/leads": { requests: 5, window: "1 m" },
  "/api/export": { requests: 3, window: "1 m" },
  default: { requests: 30, window: "1 m" },
};

function getRouteLimits(route: string): RouteLimit {
  for (const [prefix, limits] of Object.entries(ROUTE_LIMITS)) {
    if (prefix !== "default" && route.startsWith(prefix)) {
      return limits;
    }
  }
  return ROUTE_LIMITS["default"];
}

// ---------------------------------------------------------------------------
// Rate limit result shape (matches Upstash Ratelimit.limit() output)
// ---------------------------------------------------------------------------

type RateLimitResult = {
  success: boolean;
  limit: number;
  remaining: number;
  reset: number;
};

// ---------------------------------------------------------------------------
// Upstash Redis limiter (distributed, production)
// ---------------------------------------------------------------------------

// Cache Ratelimit instances per unique config to avoid re-creating on every call
const upstashLimiterCache = new Map<string, Ratelimit>();

function getUpstashLimiter(config: RouteLimit): Ratelimit {
  const key = `${config.requests}:${config.window}`;
  let limiter = upstashLimiterCache.get(key);
  if (!limiter) {
    const redis = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL!,
      token: process.env.UPSTASH_REDIS_REST_TOKEN!,
    });
    limiter = new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(
        config.requests,
        config.window as Parameters<typeof Ratelimit.slidingWindow>[1]
      ),
      prefix: "constructionos",
    });
    upstashLimiterCache.set(key, limiter);
  }
  return limiter;
}

// ---------------------------------------------------------------------------
// In-memory limiter (dev / single-instance fallback)
// ---------------------------------------------------------------------------

const memoryStore = new Map<string, { count: number; resetAt: number }>();

function inMemoryLimit(
  identifier: string,
  config: RouteLimit
): RateLimitResult {
  const now = Date.now();
  // Parse window string to milliseconds (e.g. "1 m" -> 60000)
  const windowMs = parseWindow(config.window);
  const storeKey = `${identifier}:${config.requests}:${config.window}`;
  const entry = memoryStore.get(storeKey);

  if (!entry || now > entry.resetAt) {
    memoryStore.set(storeKey, { count: 1, resetAt: now + windowMs });
    // Prune stale entries when map exceeds 10,000
    if (memoryStore.size > 10_000) {
      for (const [key, val] of memoryStore) {
        if (now > val.resetAt) memoryStore.delete(key);
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

function parseWindow(window: string): number {
  const parts = window.trim().split(/\s+/);
  const value = parseInt(parts[0], 10);
  const unit = (parts[1] || "s").toLowerCase();
  switch (unit) {
    case "s":
      return value * 1_000;
    case "m":
      return value * 60_000;
    case "h":
      return value * 3_600_000;
    case "d":
      return value * 86_400_000;
    default:
      return value * 60_000;
  }
}

// ---------------------------------------------------------------------------
// Exported: main rate limit function
// ---------------------------------------------------------------------------

export async function rateLimit(
  identifier: string,
  route: string
): Promise<RateLimitResult> {
  const config = getRouteLimits(route);

  if (
    process.env.UPSTASH_REDIS_REST_URL &&
    process.env.UPSTASH_REDIS_REST_TOKEN
  ) {
    const limiter = getUpstashLimiter(config);
    const result = await limiter.limit(identifier);
    return {
      success: result.success,
      limit: result.limit,
      remaining: result.remaining,
      reset: result.reset,
    };
  }

  return inMemoryLimit(identifier, config);
}

// ---------------------------------------------------------------------------
// Exported: build standard rate limit response headers
// ---------------------------------------------------------------------------

export function getRateLimitHeaders(result: {
  limit: number;
  remaining: number;
  reset: number;
}): Record<string, string> {
  return {
    "X-RateLimit-Limit": String(result.limit),
    "X-RateLimit-Remaining": String(result.remaining),
    "X-RateLimit-Reset": String(result.reset),
  };
}

// ---------------------------------------------------------------------------
// Backward-compatible exports (used by web/src/app/api/chat/route.ts)
// ---------------------------------------------------------------------------

/** @deprecated -- rate limiting now handled in middleware */
const legacyStore = new Map<string, { count: number; resetAt: number }>();

/** @deprecated -- rate limiting now handled in middleware */
export function getLegacyRateLimitHeaders(
  ip: string,
  limit: number = 30
): Record<string, string> {
  const entry = legacyStore.get(ip);
  const remaining = entry ? Math.max(0, limit - entry.count) : limit;
  return {
    "X-RateLimit-Limit": String(limit),
    "X-RateLimit-Remaining": String(remaining),
  };
}

/** @deprecated -- rate limiting now handled in middleware */
export function checkRateLimit(
  ip: string,
  limit: number = 30,
  windowMs: number = 60_000
): boolean {
  const now = Date.now();
  const entry = legacyStore.get(ip);
  if (!entry || now > entry.resetAt) {
    legacyStore.set(ip, { count: 1, resetAt: now + windowMs });
    if (legacyStore.size > 10_000) {
      for (const [key, val] of legacyStore) {
        if (now > val.resetAt) legacyStore.delete(key);
      }
    }
    return true;
  }
  if (entry.count >= limit) return false;
  entry.count++;
  return true;
}
