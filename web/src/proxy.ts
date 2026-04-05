// DEPRECATED: This file is replaced by middleware.ts (Phase 2, AUTH-05)
// It is no longer imported anywhere. Safe to delete in a future cleanup.
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Public routes that don't require auth
const publicRoutes = ["/", "/login", "/pricing", "/terms", "/privacy", "/checkout", "/verify", "/profile", "/auth/callback"];

export default async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public routes, API routes, and static files
  if (
    publicRoutes.some(route => pathname === route) ||
    pathname.startsWith("/api/") ||
    pathname.startsWith("/_next/") ||
    pathname.includes(".")
  ) {
    return NextResponse.next();
  }

  // If Supabase is not configured, allow all routes (demo mode)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) {
    return NextResponse.next();
  }

  // Check for Supabase auth cookie
  const hasAuthCookie = request.cookies.getAll().some(c => c.name.includes("auth-token") || c.name.includes("sb-"));

  if (!hasAuthCookie) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}
