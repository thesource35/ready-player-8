import { NextResponse } from "next/server";
import { fetchTable } from "@/lib/supabase/fetch";
import type { OpsAlert, Rfi, ChangeOrder } from "@/lib/supabase/types";
import { checkRateLimit } from "@/lib/rate-limit";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });
  const [alerts, rfis, changeOrders] = await Promise.all([
    fetchTable<OpsAlert>("cs_ops_alerts", { order: { column: "severity", ascending: false } }),
    fetchTable<Rfi>("cs_rfis", { order: { column: "created_at", ascending: false } }),
    fetchTable<ChangeOrder>("cs_change_orders", { order: { column: "created_at", ascending: false } }),
  ]);

  return NextResponse.json({ alerts, rfis, changeOrders });
}
