import { NextResponse } from "next/server";
import { fetchTable, fetchTablePaginated, insertRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import type { FeedPost } from "@/lib/supabase/types";
import { MOCK_FEED_POSTS } from "@/lib/mock-data";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const page = Math.max(0, parseInt(searchParams.get("page") || "0", 10) || 0);

  const result = await fetchTablePaginated<FeedPost>("cs_feed_posts", {
    order: { column: "created_at", ascending: false },
    page,
  });

  // 999.5 (d) Tier 2: distinguish unconfigured / error / ok. Mock only on dev.
  if (result.state === "unconfigured" && page === 0) {
    return NextResponse.json({ data: MOCK_FEED_POSTS, hasMore: false, total: MOCK_FEED_POSTS.length, demoMode: true });
  }
  if (result.state === "error") {
    return NextResponse.json({ error: "Failed to load feed", data: [], hasMore: false, total: 0 }, { status: 500 });
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
  const content = typeof body.content === "string" ? body.content.trim() : "";
  if (!content) {
    return NextResponse.json({ error: "Post content is required" }, { status: 400 });
  }

  const post = await insertRow<FeedPost>("cs_feed_posts", {
    user_id: user.id,
    author_name: typeof body.author_name === "string" ? body.author_name.trim() : "",
    author_title: typeof body.author_title === "string" ? body.author_title.trim() : "",
    author_company: typeof body.author_company === "string" ? body.author_company.trim() : "",
    content,
    post_type: typeof body.post_type === "string" ? body.post_type.trim() : "update",
    tags: Array.isArray(body.tags) ? body.tags.filter((t: unknown) => typeof t === "string") : [],
    likes: 0,
    comments: 0,
    shares: 0,
    photo_count: typeof body.photo_count === "number" ? body.photo_count : 0,
  });

  if (!post) {
    return NextResponse.json({ error: "Failed to create post" }, { status: 500 });
  }

  return NextResponse.json(post, { status: 201 });
}
