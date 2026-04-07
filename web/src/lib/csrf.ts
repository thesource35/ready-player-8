/**
 * CSRF origin-checking utility.
 * Compares the Origin header to the Host header to block cross-origin
 * state-changing requests (POST, PATCH, DELETE).
 */
export function verifyCsrfOrigin(req: Request): boolean {
  const origin = req.headers.get("origin");

  // Same-origin browser requests (e.g. form submissions) omit Origin header
  if (!origin) return true;

  const host =
    req.headers.get("x-forwarded-host") || req.headers.get("host");

  if (!host) {
    console.warn("[CSRF] No Host header found");
    return false;
  }

  try {
    const originHost = new URL(origin).host;
    if (originHost === host) return true;

    console.warn("[CSRF] Origin mismatch:", origin, "vs", host);
    return false;
  } catch {
    console.warn("[CSRF] Malformed Origin header:", origin);
    return false;
  }
}
