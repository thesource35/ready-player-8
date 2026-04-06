import { NextResponse } from "next/server";
import { fetchTable, fetchTablePaginated } from "@/lib/supabase/fetch";
import type { OpsAlert, Rfi, ChangeOrder } from "@/lib/supabase/types";
import { checkRateLimit } from "@/lib/rate-limit";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });

  const { searchParams } = new URL(req.url);
  const page = Math.max(0, parseInt(searchParams.get("page") || "0", 10) || 0);

  const [alertsResult, rfis, changeOrders] = await Promise.all([
    fetchTablePaginated<OpsAlert>("cs_ops_alerts", { order: { column: "severity", ascending: false }, page }),
    fetchTable<Rfi>("cs_rfis", { order: { column: "created_at", ascending: false } }),
    fetchTable<ChangeOrder>("cs_change_orders", { order: { column: "created_at", ascending: false } }),
  ]);

  return NextResponse.json({
    alerts: alertsResult.data,
    rfis,
    changeOrders,
    hasMore: alertsResult.hasMore,
    total: alertsResult.total,
  });
}
