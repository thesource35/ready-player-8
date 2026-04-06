import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { buildJobTags, getFallbackJobs, parseJobListing } from "@/lib/jobs";
import { hasFeatureAccess } from "@/lib/subscription/featureAccess";
import { verifyCsrfOrigin } from "@/lib/csrf";

const MAX_TEXT = 2000;

type UserProfileSummary = {
  id?: string | null;
  user_id?: string | null;
  subscription_tier?: string | null;
  full_name?: string | null;
  company?: string | null;
  title?: string | null;
};

function cleanString(value: unknown, maxLength = 160) {
  if (typeof value !== "string") return "";
  return value.trim().replace(/\s+/g, " ").slice(0, maxLength);
}

function parseRequirements(value: unknown) {
  if (Array.isArray(value)) {
    return value
      .map((item) => cleanString(item, 120))
      .filter(Boolean)
      .slice(0, 8);
  }

  if (typeof value === "string") {
    return value
      .split(",")
      .map((item) => cleanString(item, 120))
      .filter(Boolean)
      .slice(0, 8);
  }

  return [];
}

async function loadUserProfile() {
  const serverSupabase = await createServerSupabase();
  if (!serverSupabase) return { serverSupabase: null, user: null, profile: null };

  const {
    data: { user },
  } = await serverSupabase.auth.getUser();

  if (!user) {
    return { serverSupabase, user: null, profile: null };
  }

  const select = "id, user_id, subscription_tier, full_name, company, title";
  const primary = await serverSupabase
    .from("cs_user_profiles")
    .select(select)
    .eq("user_id", user.id)
    .maybeSingle();

  if (primary.data) {
    return { serverSupabase, user, profile: primary.data as UserProfileSummary };
  }

  const fallback = await serverSupabase
    .from("cs_user_profiles")
    .select(select)
    .eq("id", user.id)
    .maybeSingle();

  return { serverSupabase, user, profile: (fallback.data as UserProfileSummary | null) ?? null };
}

export async function GET() {
  // Use auth-aware client instead of service role key (RLS-07)
  // cs_feed_posts has public SELECT RLS policy, so this works for all users
  try {
    let canRevealContactEmail = false;
    const serverSupabase = await createServerSupabase();

    if (!serverSupabase) {
      return NextResponse.json({ jobs: getFallbackJobs(), source: "sample" });
    }

    try {
      const { data: { user } } = await serverSupabase.auth.getUser();
      canRevealContactEmail = Boolean(user);
    } catch {
      canRevealContactEmail = false;
    }

    const { data, error } = await serverSupabase
      .from("cs_feed_posts")
      .select("*")
      .eq("post_type", "hiring")
      .order("created_at", { ascending: false })
      .limit(50);

    if (error) {
      console.error("Jobs fetch error:", error);
      return NextResponse.json({ jobs: getFallbackJobs(), source: "sample" });
    }

    if (!Array.isArray(data)) {
      console.error("Jobs: unexpected response shape — expected array, got:", typeof data);
      return NextResponse.json({ jobs: getFallbackJobs(), source: "sample" });
    }

    const liveJobs = data
      .map(parseJobListing)
      .map((job) => (canRevealContactEmail ? job : { ...job, contactEmail: "" }));
    return NextResponse.json({
      jobs: liveJobs.length > 0 ? liveJobs : getFallbackJobs(),
      source: liveJobs.length > 0 ? "live" : "sample",
    });
  } catch (error) {
    console.error("Jobs API error:", error);
    return NextResponse.json({ jobs: getFallbackJobs(), source: "sample" });
  }
}

export async function POST(request: Request) {
  if (!verifyCsrfOrigin(request)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const contentType = request.headers.get("content-type") || "";
  if (!contentType.includes("application/json")) {
    return NextResponse.json({ error: "Expected application/json" }, { status: 415 });
  }

  const { serverSupabase, user, profile } = await loadUserProfile();

  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  if (!serverSupabase) {
    return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  }

  const tier = profile?.subscription_tier || "free";
  if (!hasFeatureAccess(tier, "jobs")) {
    return NextResponse.json({ error: "Paid subscriber access required to post jobs" }, { status: 403 });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON payload" }, { status: 400 });
  }

  const title = cleanString(body.title, 120);
  const company = cleanString(body.company, 120) || cleanString(profile?.company, 120);
  const location = cleanString(body.location, 120);
  const pay = cleanString(body.pay, 120);
  const trade = cleanString(body.trade, 80);
  const employmentType = cleanString(body.employmentType, 80);
  const startLabel = cleanString(body.startLabel, 80) || "Immediate";
  const duration = cleanString(body.duration, 80) || "Open";
  const description = cleanString(body.description, MAX_TEXT);
  const contactEmail = cleanString(body.contactEmail, 160);
  const urgent = body.urgent === true;
  const requirements = parseRequirements(body.requirements);

  if (!title || !company || !location || !pay || !trade || !employmentType || !description) {
    return NextResponse.json({ error: "Title, company, location, pay, trade, employment type, and description are required" }, { status: 400 });
  }

  try {
    // Use auth-aware client instead of service role key (RLS-07)
    const authorName =
      cleanString(profile?.full_name, 120) ||
      cleanString((user.user_metadata?.full_name as string | undefined) ?? "", 120) ||
      cleanString(user.email?.split("@")[0] ?? "", 120) ||
      "ConstructionOS Member";
    const authorTitle =
      cleanString(profile?.title, 120) ||
      cleanString((user.user_metadata?.title as string | undefined) ?? "", 120) ||
      "Hiring Manager";

    const { data, error } = await serverSupabase
      .from("cs_feed_posts")
      .insert({
        author_name: authorName,
        author_title: authorTitle,
        author_company: company,
        content: description,
        post_type: "hiring",
        tags: buildJobTags({
          title,
          company,
          location,
          pay,
          trade,
          employmentType,
          startLabel,
          duration,
          description,
          requirements,
          urgent,
          contactEmail,
        }),
        likes: 0,
        comments: 0,
        shares: 0,
        photo_count: 0,
        user_id: user.id,
      })
      .select("*")
      .single();

    if (error) {
      console.error("Job insert error:", error);
      return NextResponse.json({ error: "Failed to post job" }, { status: 500 });
    }

    return NextResponse.json({ success: true, job: parseJobListing(data) }, { status: 201 });
  } catch (error) {
    console.error("Job POST error:", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
