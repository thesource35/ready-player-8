import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";

export async function POST(req: Request) {
  try {
    const { supabase, user } = await getAuthenticatedClient();
    if (!supabase || !user) {
      return NextResponse.json(
        { error: "Authentication required" },
        { status: 401 }
      );
    }

    const body = await req.json();
    const { equipment_id, lat, lng, accuracy_m, notes } = body;

    // Validate equipment_id
    if (!equipment_id || typeof equipment_id !== "string" || !equipment_id.trim()) {
      return NextResponse.json(
        { error: "equipment_id is required" },
        { status: 400 }
      );
    }

    // Validate lat
    if (typeof lat !== "number" || isNaN(lat)) {
      return NextResponse.json(
        { error: "lat must be a valid number" },
        { status: 400 }
      );
    }
    if (lat < -90 || lat > 90) {
      return NextResponse.json(
        { error: "lat must be between -90 and 90" },
        { status: 400 }
      );
    }

    // Validate lng
    if (typeof lng !== "number" || isNaN(lng)) {
      return NextResponse.json(
        { error: "lng must be a valid number" },
        { status: 400 }
      );
    }
    if (lng < -180 || lng > 180) {
      return NextResponse.json(
        { error: "lng must be between -180 and 180" },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("cs_equipment_locations")
      .insert({
        equipment_id: equipment_id.trim(),
        lat,
        lng,
        accuracy_m: accuracy_m ?? null,
        source: "manual",
        recorded_by: user.id,
        notes: notes ?? null,
      })
      .select()
      .single();

    if (error) {
      console.error("[maps/check-in] insert error:", error);
      return NextResponse.json(
        { error: "Failed to record check-in" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data }, { status: 201 });
  } catch (err) {
    console.error("[maps/check-in] unexpected error:", err);
    return NextResponse.json(
      { error: "Failed to record check-in" },
      { status: 500 }
    );
  }
}
