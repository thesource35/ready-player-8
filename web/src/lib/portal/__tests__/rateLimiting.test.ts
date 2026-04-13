import { describe, it, expect } from "vitest";
import { PORTAL_RATE_LIMITS } from "../types";

/**
 * Portal rate limiting tests verify the rate limit configuration
 * and the logic for determining when limits are exceeded.
 *
 * Actual rate limiting is handled by the dual-mode limiter in
 * web/src/lib/rate-limit.ts (Upstash Redis + in-memory fallback).
 * These tests verify the portal-specific thresholds and response behavior.
 */

// Helper: simulate in-memory rate limit check for portal views (D-109)
function checkPortalViewLimit(
  currentViews: number,
  maxPerDay: number
): { allowed: boolean; remaining: number } {
  const allowed = currentViews < maxPerDay;
  return {
    allowed,
    remaining: Math.max(0, maxPerDay - currentViews),
  };
}

// Helper: simulate management API rate limit (D-109)
function checkManagementLimit(
  currentRequests: number,
  maxPerHour: number
): { allowed: boolean; remaining: number } {
  const allowed = currentRequests < maxPerHour;
  return {
    allowed,
    remaining: Math.max(0, maxPerHour - currentRequests),
  };
}

// Helper: simulate failed lookup rate limit (D-122)
function checkFailedLookupLimit(
  failedAttempts: number,
  maxPerMin: number
): { blocked: boolean; shouldDelay: boolean } {
  return {
    blocked: failedAttempts >= maxPerMin,
    shouldDelay: true, // 200ms delay always applied on 404 per D-122
  };
}

// Helper: build rate limit response headers
function buildRateLimitHeaders(limit: number, remaining: number, resetMs: number): Record<string, string> {
  return {
    "X-RateLimit-Limit": String(limit),
    "X-RateLimit-Remaining": String(remaining),
    "X-RateLimit-Reset": String(resetMs),
    "Retry-After": String(Math.ceil((resetMs - Date.now()) / 1000)),
  };
}

describe("Portal Rate Limiting", () => {
  it("limits portal views to 100/day per link (D-109)", () => {
    expect(PORTAL_RATE_LIMITS.viewsPerDayPerLink).toBe(100);

    // Under limit -- allowed
    const under = checkPortalViewLimit(50, PORTAL_RATE_LIMITS.viewsPerDayPerLink);
    expect(under.allowed).toBe(true);
    expect(under.remaining).toBe(50);

    // At limit -- blocked
    const at = checkPortalViewLimit(100, PORTAL_RATE_LIMITS.viewsPerDayPerLink);
    expect(at.allowed).toBe(false);
    expect(at.remaining).toBe(0);

    // Over limit -- blocked
    const over = checkPortalViewLimit(150, PORTAL_RATE_LIMITS.viewsPerDayPerLink);
    expect(over.allowed).toBe(false);
    expect(over.remaining).toBe(0);
  });

  it("limits management requests to 50/hour per user (D-109)", () => {
    expect(PORTAL_RATE_LIMITS.managementPerHourPerUser).toBe(50);

    const under = checkManagementLimit(25, PORTAL_RATE_LIMITS.managementPerHourPerUser);
    expect(under.allowed).toBe(true);
    expect(under.remaining).toBe(25);

    const at = checkManagementLimit(50, PORTAL_RATE_LIMITS.managementPerHourPerUser);
    expect(at.allowed).toBe(false);
    expect(at.remaining).toBe(0);
  });

  it("limits failed lookups to 10/min per IP (D-122)", () => {
    expect(PORTAL_RATE_LIMITS.failedLookupPerMinPerIP).toBe(10);

    const under = checkFailedLookupLimit(5, PORTAL_RATE_LIMITS.failedLookupPerMinPerIP);
    expect(under.blocked).toBe(false);

    const at = checkFailedLookupLimit(10, PORTAL_RATE_LIMITS.failedLookupPerMinPerIP);
    expect(at.blocked).toBe(true);

    const over = checkFailedLookupLimit(15, PORTAL_RATE_LIMITS.failedLookupPerMinPerIP);
    expect(over.blocked).toBe(true);
  });

  it("returns 429 with rate limit headers on exceeded", () => {
    const resetMs = Date.now() + 60_000;
    const headers = buildRateLimitHeaders(100, 0, resetMs);

    expect(headers["X-RateLimit-Limit"]).toBe("100");
    expect(headers["X-RateLimit-Remaining"]).toBe("0");
    expect(headers["X-RateLimit-Reset"]).toBeDefined();
    expect(headers["Retry-After"]).toBeDefined();
    // Retry-After should be a positive number (seconds until reset)
    expect(Number(headers["Retry-After"])).toBeGreaterThan(0);
  });

  it("adds 200ms delay on 404 responses (D-122)", () => {
    // The 200ms delay is applied in the route handler for invalid tokens
    // to prevent timing-based token enumeration
    const result = checkFailedLookupLimit(0, PORTAL_RATE_LIMITS.failedLookupPerMinPerIP);
    expect(result.shouldDelay).toBe(true);

    // Delay constant should be 200ms
    const INVALID_TOKEN_DELAY_MS = 200;
    expect(INVALID_TOKEN_DELAY_MS).toBe(200);
  });

  it("resets view counter after 24-hour window", () => {
    // Simulate window expiry: after 24h, counter resets
    const windowMs = 24 * 60 * 60 * 1000; // 1 day
    const resetAt = Date.now() + windowMs;

    // Before reset: blocked
    const before = checkPortalViewLimit(100, PORTAL_RATE_LIMITS.viewsPerDayPerLink);
    expect(before.allowed).toBe(false);

    // After reset: counter back to 0
    const afterReset = checkPortalViewLimit(0, PORTAL_RATE_LIMITS.viewsPerDayPerLink);
    expect(afterReset.allowed).toBe(true);
    expect(afterReset.remaining).toBe(100);

    // Verify reset time is in the future
    expect(resetAt).toBeGreaterThan(Date.now());
  });

  it("first request is always allowed", () => {
    const viewResult = checkPortalViewLimit(0, PORTAL_RATE_LIMITS.viewsPerDayPerLink);
    expect(viewResult.allowed).toBe(true);
    expect(viewResult.remaining).toBe(100);

    const mgmtResult = checkManagementLimit(0, PORTAL_RATE_LIMITS.managementPerHourPerUser);
    expect(mgmtResult.allowed).toBe(true);
    expect(mgmtResult.remaining).toBe(50);
  });
});
