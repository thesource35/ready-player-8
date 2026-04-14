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
    const type = url.searchParams.get("type");
    const status = url.searchParams.get("status");

    let query = supabase
      .from("cs_equipment_latest_positions")
      .select("*")
      .order("recorded_at", { ascending: false });

    if (projectId) {
      query = query.eq("assigned_project", projectId);
    }
    if (type) {
      query = query.eq("type", type);
    }
    if (status) {
      query = query.eq("status", status);
    }

    const { data, error } = await query;

    if (error) {
      console.error("[maps/equipment] query error:", error);
      return NextResponse.json(
        { error: "Failed to fetch equipment" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data: data ?? [] });
  } catch (err) {
    console.error("[maps/equipment] unexpected error:", err);
    return NextResponse.json(
      { error: "Failed to fetch equipment" },
      { status: 500 }
    );
  }
}
