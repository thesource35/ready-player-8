import { NextResponse } from "next/server";
import {
  fetchTable,
  insertRow,
  deleteOwnedRow,
  getAuthenticatedClient,
} from "@/lib/supabase/fetch";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

type Dep = {
  id: string;
  predecessor_task_id: string;
  successor_task_id: string;
  dep_type?: string;
  lag_days?: number;
};

/**
 * Would adding edge (newPred → newSucc) create a cycle?
 *
 * Edge direction: A→B means A is a predecessor of B. A cycle exists if
 * newPred is already (transitively) reachable FROM newSucc via predecessor
 * links — i.e. BFS upward from newSucc along predecessor edges can reach
 * newPred.
 */
export function wouldCreateCycle(
  deps: Array<{ predecessor_task_id: string; successor_task_id: string }>,
  newPred: string,
  newSucc: string
): boolean {
  if (newPred === newSucc) return true;

  // successor -> [predecessors]
  const predsOf = new Map<string, string[]>();
  for (const d of deps) {
    const arr = predsOf.get(d.successor_task_id) ?? [];
    arr.push(d.predecessor_task_id);
    predsOf.set(d.successor_task_id, arr);
  }

  // BFS upward from newPred following predecessor links.
  // If we reach newSucc, then newSucc is already an ancestor of newPred,
  // so adding newPred→newSucc closes a cycle.
  const visited = new Set<string>();
  const queue: string[] = [newPred];
  while (queue.length) {
    const node = queue.shift()!;
    if (node === newSucc) return true;
    if (visited.has(node)) continue;
    visited.add(node);
    const preds = predsOf.get(node) ?? [];
    for (const p of preds) queue.push(p);
  }
  return false;
}

export async function GET(req: Request) {
  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const projectId = searchParams.get("project_id");

  const allDeps = await fetchTable<Dep>("cs_task_dependencies");

  if (!projectId) {
    return NextResponse.json(allDeps);
  }

  // Filter to deps whose predecessor belongs to this project.
  const tasks = await fetchTable<{ id: string }>("cs_project_tasks", {
    eq: { column: "project_id", value: projectId },
  });
  const taskIds = new Set(tasks.map((t) => t.id));
  const filtered = allDeps.filter(
    (d) => taskIds.has(d.predecessor_task_id) || taskIds.has(d.successor_task_id)
  );
  return NextResponse.json(filtered);
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

  const { predecessor_task_id, successor_task_id, dep_type, lag_days } = body as {
    predecessor_task_id?: unknown;
    successor_task_id?: unknown;
    dep_type?: unknown;
    lag_days?: unknown;
  };

  if (typeof predecessor_task_id !== "string" || !predecessor_task_id) {
    return NextResponse.json({ error: "predecessor_task_id required" }, { status: 400 });
  }
  if (typeof successor_task_id !== "string" || !successor_task_id) {
    return NextResponse.json({ error: "successor_task_id required" }, { status: 400 });
  }
  if (predecessor_task_id === successor_task_id) {
    return NextResponse.json({ error: "Self-loop not allowed" }, { status: 409 });
  }

  const existing = await fetchTable<Dep>("cs_task_dependencies");
  if (wouldCreateCycle(existing, predecessor_task_id, successor_task_id)) {
    return NextResponse.json({ error: "Cycle detected" }, { status: 409 });
  }

  const row = await insertRow<Dep>("cs_task_dependencies", {
    predecessor_task_id,
    successor_task_id,
    dep_type: typeof dep_type === "string" ? dep_type : "FS",
    lag_days: typeof lag_days === "number" ? lag_days : 0,
  });
  if (!row) {
    return NextResponse.json({ error: "Failed to create dependency" }, { status: 500 });
  }
  return NextResponse.json(row, { status: 201 });
}

export async function DELETE(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const id = searchParams.get("id");
  if (!id) {
    return NextResponse.json({ error: "id is required" }, { status: 400 });
  }

  const ok = await deleteOwnedRow("cs_task_dependencies", id, user.id);
  if (!ok) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  return new NextResponse(null, { status: 204 });
}
