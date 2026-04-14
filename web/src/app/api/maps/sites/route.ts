import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";

export async function GET() {
  try {
    const { supabase, user } = await getAuthenticatedClient();
    if (!supabase || !user) {
      return NextResponse.json(
        { error: "Authentication required" },
        { status: 401 }
      );
    }

    const { data, error } = await supabase
      .from("cs_projects")
      .select("id, name, lat, lng, status, type, client")
      .not("lat", "is", null)
      .not("lng", "is", null);

    if (error) {
      console.error("[maps/sites] query error:", error);
      return NextResponse.json(
        { error: "Failed to fetch map sites" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data: data ?? [] });
  } catch (err) {
    console.error("[maps/sites] unexpected error:", err);
    return NextResponse.json(
      { error: "Failed to fetch map sites" },
      { status: 500 }
    );
  }
}
