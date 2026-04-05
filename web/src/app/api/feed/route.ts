import { NextResponse } from "next/server";
import { fetchTable, insertRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import type { FeedPost } from "@/lib/supabase/types";
import { MOCK_FEED_POSTS } from "@/lib/mock-data";
import { checkRateLimit } from "@/lib/rate-limit";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });
  const posts = await fetchTable<FeedPost>("cs_feed_posts", {
    order: { column: "created_at", ascending: false },
    limit: 50,
  });

  if (posts.length === 0) {
    return NextResponse.json(MOCK_FEED_POSTS);
  }

  return NextResponse.json(posts);
}

export async function POST(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const body = await req.json();
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

  return NextResponse.json(post);
}
