import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";

export async function GET(req: Request) {
  try {
    const { supabase, user } = await getAuthenticatedClient();
    if (!supabase || !user) {
      return NextResponse.json(
        { error: "Authentication required" },
        { status: 401 }
      );
    }

    const url = new URL(req.url);
    const projectId = url.searchParams.get("project_id");

    let query = supabase
      .from("cs_documents")
      .select("id, filename, gps_lat, gps_lng, created_at, entity_type, entity_id")
      .not("gps_lat", "is", null)
      .not("gps_lng", "is", null);

    if (projectId) {
      query = query.eq("entity_id", projectId).eq("entity_type", "project");
    }

    const { data, error } = await query;

    if (error) {
      console.error("[maps/photos] query error:", error);
      return NextResponse.json(
        { error: "Failed to fetch GPS photos" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data: data ?? [] });
  } catch (err) {
    console.error("[maps/photos] unexpected error:", err);
    return NextResponse.json(
      { error: "Failed to fetch GPS photos" },
      { status: 500 }
    );
  }
}
