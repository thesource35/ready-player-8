import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// ---------------------------------------------------------------------------
// Public routes that skip auth entirely
// ---------------------------------------------------------------------------

const publicRoutes = [
  "/",
  "/login",
  "/pricing",
  "/terms",
  "/privacy",
  "/checkout",
  "/verify",
  "/profile",
  "/auth/callback",
  "/auth/signout",
];

// ---------------------------------------------------------------------------
// JWT fast-path: decode Supabase JWT claims without a DB round-trip
// ---------------------------------------------------------------------------

function decodeSupabaseJWT(
  cookieValue: string
): { sub: string; email: string; exp: number } | null {
  try {
    const parts = cookieValue.split(".");
    if (parts.length < 2) return null;

    const payload = parts[1];
    const decoded = Buffer.from(payload, "base64url").toString();
    const claims = JSON.parse(decoded) as {
      sub?: string;
      email?: string;
      exp?: number;
    };

    if (!claims.sub || !claims.exp) return null;

    // 60-second buffer before expiry (PERF-07 pitfall avoidance)
    if (claims.exp * 1000 <= Date.now() + 60_000) return null;

    return {
      sub: claims.sub,
      email: claims.email || "",
      exp: claims.exp,
    };
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public routes
  if (publicRoutes.some((route) => pathname === route)) {
    return NextResponse.next();
  }

  // Allow static files and Next.js internals
  if (pathname.startsWith("/_next/") || pathname.includes(".")) {
    return NextResponse.next();
  }

  // -------------------------------------------------------------------------
  // A) Rate limiting for /api/* routes
  // -------------------------------------------------------------------------
  if (pathname.startsWith("/api/")) {
    const identifier =
      request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      request.headers.get("x-real-ip") ||
      "unknown";

    const result = await rateLimit(identifier, pathname);
    const headers = getRateLimitHeaders(result);

    if (!result.success) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Please wait." },
        {
          status: 429,
          headers,
        }
      );
    }

    // Rate limit passed — forward request with rate limit headers
    const response = NextResponse.next();
    Object.entries(headers).forEach(([k, v]) => response.headers.set(k, v));
    return response;
  }

  // -------------------------------------------------------------------------
  // B) Session validation for protected pages
  // -------------------------------------------------------------------------

  // If Supabase is not configured, allow all routes (demo mode)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) {
    return NextResponse.next();
  }

  // JWT fast-path: try to decode the auth cookie without a DB round-trip
  // Supabase stores the access token in a cookie named sb-<project-ref>-auth-token
  const authCookie = request.cookies
    .getAll()
    .find((c) => c.name.match(/^sb-.*-auth-token$/));

  if (authCookie) {
    // The cookie value may be a JSON array where the first element is the access token,
    // or it may be the raw JWT string
    let tokenValue = authCookie.value;
    try {
      const parsed = JSON.parse(tokenValue);
      if (Array.isArray(parsed) && typeof parsed[0] === "string") {
        tokenValue = parsed[0];
      } else if (
        typeof parsed === "object" &&
        parsed !== null &&
        typeof parsed.access_token === "string"
      ) {
        tokenValue = parsed.access_token;
      }
    } catch {
      // Not JSON — use raw value (could be the JWT directly)
    }

    const claims = decodeSupabaseJWT(tokenValue);
    if (claims) {
      // Valid, non-expired JWT — skip getUser() call
      return NextResponse.next();
    }
  }

  // Fallback: create Supabase server client and call getUser()
  // This handles token refresh and expired/invalid tokens
  let response = NextResponse.next({
    request: { headers: request.headers },
  });

  const supabase = createServerClient(url, key, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value)
        );
        response = NextResponse.next({
          request: { headers: request.headers },
        });
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options)
        );
      },
    },
  });

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt).*)",
  ],
};
