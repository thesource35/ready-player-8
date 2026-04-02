import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export async function GET() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    // Return demo export data
    return NextResponse.json({
      exported_at: new Date().toISOString(),
      platform: "ConstructionOS",
      tables: { projects: 5, contracts: 7, daily_logs: 3, timecards: 4, punch_items: 8 },
      message: "Demo export — connect Supabase for real data export",
    });
  }

  const supabase = createClient(url, key);
  const tables = ["cs_projects", "cs_contracts", "cs_market_data", "cs_daily_logs", "cs_timecards", "cs_ops_alerts", "cs_rfis", "cs_change_orders", "cs_punch_pro", "cs_feed_posts", "cs_transactions", "cs_tax_expenses", "cs_rental_leads"];

  const exportData: Record<string, unknown[]> = {};
  for (const table of tables) {
    const { data } = await supabase.from(table).select("*").limit(1000);
    exportData[table] = data || [];
  }

  return new NextResponse(JSON.stringify({
    exported_at: new Date().toISOString(),
    platform: "ConstructionOS",
    version: "2.0",
    data: exportData,
  }, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Content-Disposition": `attachment; filename="constructionos-export-${new Date().toISOString().split("T")[0]}.json"`,
    },
  });
}
