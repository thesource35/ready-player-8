// Phase 14 — PATCH (mark read) + DELETE (dismiss) for a single notification
// 999.5 follow-up: structured logging via [api:notifications] prefix —
// Vercel captures stdout/stderr automatically; searchable in dashboard.

import { NextResponse } from "next/server";
import { markRead, dismiss } from "@/lib/notifications/server";

export async function PATCH(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const t0 = Date.now();
  const { id } = await params;
  if (!id) {
    console.warn("[api:notifications] PATCH 400 missing id");
    return NextResponse.json({ error: "missing id" }, { status: 400 });
  }
  try {
    const ok = await markRead(id);
    if (!ok) {
      console.warn(`[api:notifications] PATCH 404 markRead id=${id} ${Date.now() - t0}ms`);
      return NextResponse.json({ error: "not found or unauthorized" }, { status: 404 });
    }
    console.log(`[api:notifications] PATCH 200 id=${id} ${Date.now() - t0}ms`);
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error(`[api:notifications] PATCH 500 id=${id} ${Date.now() - t0}ms`, e);
    return NextResponse.json({ error: "internal error" }, { status: 500 });
  }
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const t0 = Date.now();
  const { id } = await params;
  if (!id) {
    console.warn("[api:notifications] DELETE 400 missing id");
    return NextResponse.json({ error: "missing id" }, { status: 400 });
  }
  try {
    const ok = await dismiss(id);
    if (!ok) {
      console.warn(`[api:notifications] DELETE 404 dismiss id=${id} ${Date.now() - t0}ms`);
      return NextResponse.json({ error: "not found or unauthorized" }, { status: 404 });
    }
    console.log(`[api:notifications] DELETE 200 id=${id} ${Date.now() - t0}ms`);
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error(`[api:notifications] DELETE 500 id=${id} ${Date.now() - t0}ms`, e);
    return NextResponse.json({ error: "internal error" }, { status: 500 });
  }
}
