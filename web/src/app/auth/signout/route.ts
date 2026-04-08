import { NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { getSupabasePublishableKey, getSupabaseUrl } from "@/lib/supabase/env";

function isValidSameOriginRequest(request: Request) {
  const { origin } = new URL(request.url);
  const requestOrigin = request.headers.get("origin");
  if (requestOrigin && requestOrigin !== origin) return false;

  const fetchSite = request.headers.get("sec-fetch-site");
  if (fetchSite && fetchSite !== "same-origin" && fetchSite !== "same-site") return false;
  if (!fetchSite && !requestOrigin) return false;

  return true;
}

async function signOut(request: Request) {
  const { origin } = new URL(request.url);
  const url = getSupabaseUrl();
  const key = getSupabasePublishableKey();

  if (url && key) {
    const cookieStore = await cookies();
    const supabase = createServerClient(url, key, {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        },
      },
    });

    await supabase.auth.signOut();
  }

  return NextResponse.redirect(`${origin}/login`);
}

export async function POST(request: Request) {
  if (!isValidSameOriginRequest(request)) {
    return NextResponse.json({ error: "Invalid request origin" }, { status: 403 });
  }

  return signOut(request);
}

export async function GET(request: Request) {
  const { origin } = new URL(request.url);
  return NextResponse.redirect(`${origin}/settings`);
}
