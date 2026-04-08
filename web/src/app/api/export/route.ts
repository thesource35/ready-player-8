import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export async function GET() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    return NextResponse.json(
      { error: "Export unavailable — Supabase is not configured" },
      { status: 503 }
    );
  }

  const supabase = createClient(url, key);
  const tables = ["cs_projects", "cs_contracts", "cs_market_data", "cs_daily_logs", "cs_timecards", "cs_ops_alerts", "cs_rfis", "cs_change_orders", "cs_punch_pro", "cs_feed_posts", "cs_transactions", "cs_tax_expenses", "cs_rental_leads"];

  // Check row counts before fetching — reject if any table exceeds 1000 rows (T-09-06)
  const MAX_EXPORT_ROWS = 1000;
  for (const table of tables) {
    const { count, error } = await supabase
      .from(table)
      .select("id", { count: "exact", head: true });
    if (!error && (count ?? 0) > MAX_EXPORT_ROWS) {
      return NextResponse.json(
        { error: "Export too large. One or more tables exceed 1000 rows. Use the API with pagination for large datasets." },
        { status: 413 }
      );
    }
  }

  const exportData: Record<string, unknown[]> = {};
  for (const table of tables) {
    const { data } = await supabase.from(table).select("*").limit(MAX_EXPORT_ROWS);
    exportData[table] = data || [];
  }

  // Read version from package.json at build time (DYN-07)
  const appVersion = process.env.npm_package_version || "unknown";

  return new NextResponse(JSON.stringify({
    exported_at: new Date().toISOString(),
    platform: "ConstructionOS",
    version: appVersion,
    data: exportData,
  }, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Content-Disposition": `attachment; filename="constructionos-export-${new Date().toISOString().split("T")[0]}.json"`,
    },
  });
}
