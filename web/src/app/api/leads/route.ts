import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { checkRateLimit, getLegacyRateLimitHeaders } from "@/lib/rate-limit";
import { leadSchema } from "@/lib/validation";
import { verifyCsrfOrigin } from "@/lib/csrf";

export async function POST(req: Request) {
  // Rate limit: 5 lead submissions per minute per IP (AUTH-11)
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
    || req.headers.get("x-real-ip")
    || "unknown";
  if (!checkRateLimit(ip, 5, 60_000)) {
    return NextResponse.json(
      { error: "Too many submissions. Please wait a minute before trying again." },
      { status: 429, headers: getLegacyRateLimitHeaders(ip, 5) }
    );
  }

  // CSRF origin check (WEB-01)
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  }

  try {
    const body = await req.json();

    // Validate input with Zod schema (WEB-01)
    const parsed = leadSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Validation failed", details: parsed.error.flatten().fieldErrors },
        { status: 400 }
      );
    }

    const supabase = createClient(url, key);

    const { data, error } = await supabase.from("cs_rental_leads").insert({
      full_name: parsed.data.fullName,
      email: parsed.data.email,
      phone: parsed.data.phone,
      company: parsed.data.company,
      equipment_type: parsed.data.equipmentType,
      category: parsed.data.category,
      project_name: parsed.data.projectName,
      project_location: parsed.data.projectLocation,
      rental_start: parsed.data.rentalStart,
      rental_duration: parsed.data.rentalDuration,
      budget_range: parsed.data.budgetRange,
      quantity: parsed.data.quantity,
      delivery_needed: parsed.data.deliveryNeeded,
      notes: parsed.data.notes,
    }).select().single();

    if (error) {
      console.error("Lead insert error:", error);
      return NextResponse.json({ error: "Failed to submit lead" }, { status: 500 });
    }

    // Send email notification about new lead
    console.log(`[NEW LEAD] ${parsed.data.fullName} (${parsed.data.email}) wants ${parsed.data.equipmentType} in ${parsed.data.projectLocation} — Budget: ${parsed.data.budgetRange}`);

    return NextResponse.json(
      { success: true, id: data.id },
      { headers: getLegacyRateLimitHeaders(ip, 5) }
    );
  } catch (err) {
    console.error("Lead API error:", err);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
