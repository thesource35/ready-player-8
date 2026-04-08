import { NextResponse } from "next/server";
import { fetchTable, fetchTablePaginated, insertRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import type { Contract } from "@/lib/supabase/types";
import { MOCK_CONTRACTS } from "@/lib/mock-data";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const page = Math.max(0, parseInt(searchParams.get("page") || "0", 10) || 0);

  const result = await fetchTablePaginated<Contract>("cs_contracts", {
    order: { column: "score", ascending: false },
    page,
  });

  if (result.data.length === 0 && page === 0) {
    return NextResponse.json({ data: MOCK_CONTRACTS, hasMore: false, total: MOCK_CONTRACTS.length });
  }

  return NextResponse.json(result);
}

export async function POST(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }
  const title = typeof body.title === "string" ? body.title.trim() : "";
  if (!title) {
    return NextResponse.json({ error: "Contract title is required" }, { status: 400 });
  }

  const contract = await insertRow<Contract>("cs_contracts", {
    user_id: user.id,
    title,
    client: typeof body.client === "string" ? body.client.trim() : "",
    sector: typeof body.sector === "string" ? body.sector.trim() : "",
    stage: typeof body.stage === "string" ? body.stage.trim() : "Open For Bid",
    budget: typeof body.budget === "string" ? body.budget.trim() : "$0",
    score: typeof body.score === "number" ? body.score : 0,
    watch_count: typeof body.watch_count === "number" ? body.watch_count : 0,
    location: typeof body.location === "string" ? body.location.trim() : "",
    bid_due: typeof body.bid_due === "string" ? body.bid_due.trim() : "N/A",
  });

  if (!contract) {
    return NextResponse.json({ error: "Failed to create" }, { status: 500 });
  }
  return NextResponse.json(contract, { status: 201 });
}
