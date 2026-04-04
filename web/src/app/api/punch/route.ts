import { NextResponse } from "next/server";
import { fetchTable, insertRow, updateRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import type { PunchItem } from "@/lib/supabase/types";
import { MOCK_PUNCH_ITEMS } from "@/lib/mock-data";
import { checkRateLimit } from "@/lib/rate-limit";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });
  const items = await fetchTable<PunchItem>("cs_punch_pro", {
    order: { column: "created_at", ascending: false },
  });

  if (items.length === 0) {
    return NextResponse.json(MOCK_PUNCH_ITEMS);
  }

  return NextResponse.json(items);
}

export async function POST(req: Request) {
  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const body = await req.json();
  const description = typeof body.description === "string" ? body.description.trim() : "";
  if (!description) {
    return NextResponse.json({ error: "Description is required" }, { status: 400 });
  }

  const item = await insertRow<PunchItem>("cs_punch_pro", {
    user_id: user.id,
    description,
    location: typeof body.location === "string" ? body.location.trim() : "",
    trade: typeof body.trade === "string" ? body.trade.trim() : "",
    priority: typeof body.priority === "string" ? body.priority.trim() : "MEDIUM",
    status: typeof body.status === "string" ? body.status.trim() : "OPEN",
    assignee: typeof body.assignee === "string" ? body.assignee.trim() : "",
    due_date: typeof body.due_date === "string" ? body.due_date.trim() : "",
    photo_count: typeof body.photo_count === "number" ? body.photo_count : 0,
  });

  if (!item) return NextResponse.json({ error: "Failed to create" }, { status: 500 });
  return NextResponse.json(item);
}

export async function PATCH(req: Request) {
  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { id, ...updates } = await req.json();
  if (typeof id !== "string" || !id) {
    return NextResponse.json({ error: "Valid id is required" }, { status: 400 });
  }

  const item = await updateRow<PunchItem>("cs_punch_pro", id, updates);
  if (!item) return NextResponse.json({ error: "Failed to update" }, { status: 500 });
  return NextResponse.json(item);
}
