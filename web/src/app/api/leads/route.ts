import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { checkRateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

export async function POST(req: Request) {
  // Rate limit: 5 lead submissions per minute per IP (AUTH-11)
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
    || req.headers.get("x-real-ip")
    || "unknown";
  if (!checkRateLimit(ip, 5, 60_000)) {
    return NextResponse.json(
      { error: "Too many submissions. Please wait a minute before trying again." },
      { status: 429, headers: getRateLimitHeaders(ip, 5) }
    );
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  }

  try {
    const body = await req.json();
    const supabase = createClient(url, key);

    const { data, error } = await supabase.from("cs_rental_leads").insert({
      full_name: body.fullName,
      email: body.email,
      phone: body.phone,
      company: body.company,
      equipment_type: body.equipmentType,
      category: body.category,
      project_name: body.projectName,
      project_location: body.projectLocation,
      rental_start: body.rentalStart,
      rental_duration: body.rentalDuration,
      budget_range: body.budgetRange,
      quantity: body.quantity || 1,
      delivery_needed: body.deliveryNeeded ?? true,
      notes: body.notes,
    }).select().single();

    if (error) {
      console.error("Lead insert error:", error);
      return NextResponse.json({ error: "Failed to submit lead" }, { status: 500 });
    }

    // Send email notification about new lead
    console.log(`[NEW LEAD] ${body.fullName} (${body.email}) wants ${body.equipmentType} in ${body.projectLocation} — Budget: ${body.budgetRange}`);

    // If you want email notifications, set up a webhook in Supabase:
    // Database → Webhooks → New Webhook → Table: cs_rental_leads → Event: INSERT
    // URL: your email service (e.g., Resend, SendGrid, or Zapier webhook)

    return NextResponse.json(
      { success: true, id: data.id },
      { headers: getRateLimitHeaders(ip, 5) }
    );
  } catch (err) {
    console.error("Lead API error:", err);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
