import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// D-98: Threaded comments on report sections
// T-19-31: Sanitize comment content, validate length limits

const MAX_COMMENT_LENGTH = 2000;

/** Strip HTML tags to prevent XSS in stored content (T-19-31) */
function sanitizeContent(raw: string): string {
  return raw.replace(/<[^>]*>/g, "").trim();
}

export async function GET(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/comments");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  const { searchParams } = new URL(req.url);
  const reportHistoryId = searchParams.get("report_history_id");
  const section = searchParams.get("section");

  if (!reportHistoryId) {
    return NextResponse.json(
      { error: "report_history_id is required" },
      { status: 400 }
    );
  }

  // Fetch comments for the report history entry, optionally filtered by section
  let query = supabase
    .from("cs_report_comments")
    .select("*")
    .eq("report_history_id", reportHistoryId)
    .order("created_at", { ascending: true });

  if (section) {
    query = query.eq("section", section);
  }

  const { data, error } = await query;

  if (error) {
    console.error("[reports/comments] GET error:", error);
    return NextResponse.json(
      { error: "Failed to fetch comments" },
      { status: 500 }
    );
  }

  // Build threaded structure: top-level comments with nested replies
  type Comment = {
    id: string;
    user_id: string;
    report_history_id: string;
    section: string;
    content: string;
    parent_id: string | null;
    created_at: string;
    replies: Comment[];
  };

  const commentMap = new Map<string, Comment>();
  const topLevel: Comment[] = [];

  for (const row of data ?? []) {
    const comment: Comment = { ...row, replies: [] };
    commentMap.set(comment.id, comment);
  }

  for (const comment of Array.from(commentMap.values())) {
    if (comment.parent_id && commentMap.has(comment.parent_id)) {
      commentMap.get(comment.parent_id)!.replies.push(comment);
    } else {
      topLevel.push(comment);
    }
  }

  return NextResponse.json(
    { comments: topLevel, total: (data ?? []).length },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}

export async function POST(req: Request) {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports/comments");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  let body: { report_history_id?: string; section?: string; content?: string; parent_id?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { report_history_id, section, content, parent_id } = body;

  if (!report_history_id || typeof report_history_id !== "string") {
    return NextResponse.json(
      { error: "report_history_id is required" },
      { status: 400 }
    );
  }

  if (!section || typeof section !== "string") {
    return NextResponse.json(
      { error: "section is required" },
      { status: 400 }
    );
  }

  if (!content || typeof content !== "string" || content.trim().length === 0) {
    return NextResponse.json(
      { error: "content must be a non-empty string" },
      { status: 400 }
    );
  }

  // T-19-31: Sanitize and enforce length limit
  const sanitized = sanitizeContent(content);
  if (sanitized.length === 0) {
    return NextResponse.json(
      { error: "content must contain text (not just HTML tags)" },
      { status: 400 }
    );
  }

  if (sanitized.length > MAX_COMMENT_LENGTH) {
    return NextResponse.json(
      { error: `content exceeds maximum length of ${MAX_COMMENT_LENGTH} characters` },
      { status: 400 }
    );
  }

  // Verify report_history_id exists
  const { data: historyCheck, error: historyError } = await supabase
    .from("cs_report_history")
    .select("id")
    .eq("id", report_history_id)
    .limit(1);

  if (historyError || !historyCheck || historyCheck.length === 0) {
    return NextResponse.json(
      { error: "report_history_id not found" },
      { status: 404 }
    );
  }

  // If parent_id provided, verify it exists
  if (parent_id) {
    const { data: parentCheck, error: parentError } = await supabase
      .from("cs_report_comments")
      .select("id")
      .eq("id", parent_id)
      .limit(1);

    if (parentError || !parentCheck || parentCheck.length === 0) {
      return NextResponse.json(
        { error: "parent_id comment not found" },
        { status: 404 }
      );
    }
  }

  const { data, error } = await supabase
    .from("cs_report_comments")
    .insert({
      user_id: user.id,
      report_history_id,
      section,
      content: sanitized,
      parent_id: parent_id || null,
    })
    .select()
    .single();

  if (error) {
    console.error("[reports/comments] POST error:", error);
    return NextResponse.json(
      { error: "Failed to create comment" },
      { status: 500 }
    );
  }

  return NextResponse.json({ comment: data }, { status: 201 });
}
