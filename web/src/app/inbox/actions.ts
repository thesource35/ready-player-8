"use server";

// Phase 30 — Server Actions for /inbox per-row READ and MARK ALL READ (D-01, D-02).
// Replaces the legacy POST -> ?_method=PATCH kludge that silently 404'd against the
// REST route (14-03-SUMMARY.md Known Limitation #1). The REST PATCH/DELETE handlers
// at /api/notifications/[id] stay in place for iOS + programmatic callers (D-03).

import { revalidatePath } from "next/cache";
import { markRead, markAllRead } from "@/lib/notifications/server";

export async function markReadAction(formData: FormData): Promise<void> {
  const raw = formData.get("id");
  const id = typeof raw === "string" ? raw.trim() : "";
  if (!id) return;
  await markRead(id);
  revalidatePath("/inbox");
}

export async function markAllReadAction(formData: FormData): Promise<void> {
  const raw = formData.get("project_id");
  const projectId = typeof raw === "string" && raw.length > 0 ? raw : null;
  await markAllRead(projectId);
  revalidatePath("/inbox");
}
