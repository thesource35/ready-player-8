// Phase 14 — PATCH (mark read) + DELETE (dismiss) for a single notification

import { NextResponse } from "next/server";
import { markRead, dismiss } from "@/lib/notifications";

export async function PATCH(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!id) return NextResponse.json({ error: "missing id" }, { status: 400 });

  const ok = await markRead(id);
  if (!ok) return NextResponse.json({ error: "not found or unauthorized" }, { status: 404 });
  return NextResponse.json({ ok: true });
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!id) return NextResponse.json({ error: "missing id" }, { status: 400 });

  const ok = await dismiss(id);
  if (!ok) return NextResponse.json({ error: "not found or unauthorized" }, { status: 404 });
  return NextResponse.json({ ok: true });
}
