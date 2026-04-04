// Shared rate limiter for API routes
const rateLimit = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(
  ip: string,
  limit: number = 30,
  windowMs: number = 60_000
): boolean {
  const now = Date.now();
  const entry = rateLimit.get(ip);
  if (!entry || now > entry.resetAt) {
    rateLimit.set(ip, { count: 1, resetAt: now + windowMs });
    if (rateLimit.size > 10_000) {
      for (const [key, val] of rateLimit) {
        if (now > val.resetAt) rateLimit.delete(key);
      }
    }
    return true;
  }
  if (entry.count >= limit) return false;
  entry.count++;
  return true;
}

export function getRateLimitHeaders(ip: string, limit: number = 30): Record<string, string> {
  const entry = rateLimit.get(ip);
  const remaining = entry ? Math.max(0, limit - entry.count) : limit;
  return {
    "X-RateLimit-Limit": String(limit),
    "X-RateLimit-Remaining": String(remaining),
  };
}
