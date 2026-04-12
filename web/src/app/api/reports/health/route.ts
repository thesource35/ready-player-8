import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// D-56b: verify all required tables exist, views exist, Resend config, schema version
// D-56d: pre-flight schema check

const REQUIRED_TABLES = [
  "cs_projects",
  "cs_contracts",
  "cs_project_tasks",
  "cs_report_schedules",
  "cs_report_shared_links",
] as const;

type TableStatus = {
  name: string;
  exists: boolean;
};

export async function GET(req: Request) {
  // Rate limiting
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  // Auth check (T-19-08)
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  const startTime = Date.now();

  // Check each required table by attempting a lightweight query
  const tableChecks = await Promise.allSettled(
    REQUIRED_TABLES.map(async (tableName): Promise<TableStatus> => {
      const { error } = await supabase
        .from(tableName)
        .select("id", { count: "exact", head: true })
        .limit(0);

      // If error code is 42P01 (undefined_table) or PGRST116, table doesn't exist
      const exists = !error || (!error.message?.includes("does not exist") && error.code !== "42P01");
      return { name: tableName, exists };
    })
  );

  const tables: TableStatus[] = tableChecks.map((result, i) => {
    if (result.status === "fulfilled") {
      return result.value;
    }
    return { name: REQUIRED_TABLES[i], exists: false };
  });

  const allTablesExist = tables.every((t) => t.exists);

  // Check RESEND_API_KEY env var exists (for scheduled reports)
  const resendConfigured = !!process.env.RESEND_API_KEY;

  // Determine overall status
  let status: "ok" | "degraded" | "error";
  if (allTablesExist && resendConfigured) {
    status = "ok";
  } else if (allTablesExist && !resendConfigured) {
    status = "degraded";
  } else {
    const coreTablesExist = tables
      .filter((t) => ["cs_projects", "cs_contracts", "cs_project_tasks"].includes(t.name))
      .every((t) => t.exists);
    status = coreTablesExist ? "degraded" : "error";
  }

  const totalMs = Date.now() - startTime;

  const responseBody = {
    status,
    tables,
    resend_configured: resendConfigured,
    version: "19.04",
    _meta: {
      generated_at: new Date().toISOString(),
      total_ms: totalMs,
    },
  };

  const debugHeader = JSON.stringify({ total_ms: totalMs, status });

  return NextResponse.json(responseBody, {
    status: 200,
    headers: {
      "X-Report-Debug": debugHeader,
      ...getRateLimitHeaders(rl),
    },
  });
}
