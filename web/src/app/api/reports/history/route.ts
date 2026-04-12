import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// D-99: Every report generation creates a version snapshot
// D-34l: Store PDF in Supabase Storage, save path in pdf_storage_path

export async function GET(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/history");
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
  const projectId = searchParams.get("project_id");
  const reportType = searchParams.get("report_type");
  const limitStr = searchParams.get("limit");
  const limit = limitStr ? Math.min(parseInt(limitStr, 10) || 50, 100) : 50;

  let query = supabase
    .from("cs_report_history")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(limit);

  if (projectId) {
    query = query.eq("project_id", projectId);
  }

  if (reportType && (reportType === "project" || reportType === "rollup")) {
    query = query.eq("report_type", reportType);
  }

  const { data, error } = await query;

  if (error) {
    console.error("[reports/history] GET error:", error);
    return NextResponse.json(
      { error: "Failed to fetch report history" },
      { status: 500 }
    );
  }

  return NextResponse.json(
    { versions: data ?? [], total: (data ?? []).length },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}

export async function POST(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/history");
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

  let body: {
    project_id?: string;
    report_type?: string;
    snapshot_data?: unknown;
    pdf_storage_path?: string;
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { project_id, report_type, snapshot_data, pdf_storage_path } = body;

  if (!report_type || (report_type !== "project" && report_type !== "rollup")) {
    return NextResponse.json(
      { error: "report_type must be 'project' or 'rollup'" },
      { status: 400 }
    );
  }

  if (!snapshot_data || typeof snapshot_data !== "object") {
    return NextResponse.json(
      { error: "snapshot_data must be a non-empty JSON object" },
      { status: 400 }
    );
  }

  // Enforce snapshot_data size limit (5MB max for jsonb)
  const snapshotStr = JSON.stringify(snapshot_data);
  if (snapshotStr.length > 5_000_000) {
    return NextResponse.json(
      { error: "snapshot_data exceeds maximum size of 5MB" },
      { status: 400 }
    );
  }

  // D-34l: pdf_storage_path optional — set when PDF stored in Supabase Storage
  const insertData: Record<string, unknown> = {
    user_id: user.id,
    project_id: project_id || null,
    report_type,
    snapshot_data,
  };

  if (pdf_storage_path && typeof pdf_storage_path === "string") {
    insertData.pdf_storage_path = pdf_storage_path;
  }

  const { data, error } = await supabase
    .from("cs_report_history")
    .insert(insertData)
    .select()
    .single();

  if (error) {
    console.error("[reports/history] POST error:", error);
    return NextResponse.json(
      { error: "Failed to save report version" },
      { status: 500 }
    );
  }

  return NextResponse.json({ version: data }, { status: 201 });
}
