import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// D-98: Visual annotations on charts stored as Fabric.js JSON
// T-19-32: Validate JSON structure before storage; limit size

const MAX_FABRIC_JSON_SIZE = 500_000; // 500KB limit for annotation data

/** Basic validation that fabric_json looks like a Fabric.js canvas export */
function isValidFabricJson(obj: unknown): boolean {
  if (typeof obj !== "object" || obj === null) return false;
  const candidate = obj as Record<string, unknown>;
  // Fabric.js toJSON() produces { version, objects } at minimum
  if (!Array.isArray(candidate.objects)) return false;
  return true;
}

export async function GET(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/annotations");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  const { searchParams } = new URL(req.url);
  const reportHistoryId = searchParams.get("report_history_id");

  if (!reportHistoryId) {
    return NextResponse.json(
      { error: "report_history_id is required" },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from("cs_report_annotations")
    .select("*")
    .eq("report_history_id", reportHistoryId)
    .order("created_at", { ascending: true });

  if (error) {
    console.error("[reports/annotations] GET error:", error);
    return NextResponse.json(
      { error: "Failed to fetch annotations" },
      { status: 500 }
    );
  }

  return NextResponse.json(
    { annotations: data ?? [] },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}

export async function POST(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/annotations");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  let body: { report_history_id?: string; chart_id?: string; fabric_json?: unknown };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { report_history_id, chart_id, fabric_json } = body;

  if (!report_history_id || typeof report_history_id !== "string") {
    return NextResponse.json(
      { error: "report_history_id is required" },
      { status: 400 }
    );
  }

  if (!chart_id || typeof chart_id !== "string") {
    return NextResponse.json(
      { error: "chart_id is required" },
      { status: 400 }
    );
  }

  // T-19-32: Validate fabric_json structure
  if (!fabric_json || !isValidFabricJson(fabric_json)) {
    return NextResponse.json(
      { error: "fabric_json must be a valid Fabric.js canvas export with an objects array" },
      { status: 400 }
    );
  }

  // T-19-32: Enforce size limit
  const jsonStr = JSON.stringify(fabric_json);
  if (jsonStr.length > MAX_FABRIC_JSON_SIZE) {
    return NextResponse.json(
      { error: `fabric_json exceeds maximum size of ${MAX_FABRIC_JSON_SIZE} bytes` },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from("cs_report_annotations")
    .insert({
      user_id: user.id,
      report_history_id,
      chart_id,
      fabric_json,
    })
    .select()
    .single();

  if (error) {
    console.error("[reports/annotations] POST error:", error);
    return NextResponse.json(
      { error: "Failed to create annotation" },
      { status: 500 }
    );
  }

  return NextResponse.json({ annotation: data }, { status: 201 });
}

export async function PUT(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/annotations");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  let body: { id?: string; fabric_json?: unknown };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { id, fabric_json } = body;

  if (!id || typeof id !== "string") {
    return NextResponse.json(
      { error: "id is required" },
      { status: 400 }
    );
  }

  // T-19-32: Validate fabric_json structure
  if (!fabric_json || !isValidFabricJson(fabric_json)) {
    return NextResponse.json(
      { error: "fabric_json must be a valid Fabric.js canvas export with an objects array" },
      { status: 400 }
    );
  }

  // T-19-32: Enforce size limit
  const jsonStr = JSON.stringify(fabric_json);
  if (jsonStr.length > MAX_FABRIC_JSON_SIZE) {
    return NextResponse.json(
      { error: `fabric_json exceeds maximum size of ${MAX_FABRIC_JSON_SIZE} bytes` },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from("cs_report_annotations")
    .update({ fabric_json })
    .eq("id", id)
    .eq("user_id", user.id)
    .select()
    .single();

  if (error) {
    console.error("[reports/annotations] PUT error:", error);
    return NextResponse.json(
      { error: "Failed to update annotation" },
      { status: 500 }
    );
  }

  if (!data) {
    return NextResponse.json(
      { error: "Annotation not found or not owned by user" },
      { status: 404 }
    );
  }

  return NextResponse.json({ annotation: data }, { status: 200 });
}
