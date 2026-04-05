import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import type { PlanId } from "@/lib/billing/plans";
import { PLAN_IDS } from "@/lib/billing/plans";

export const dynamic = "force-dynamic";

// Set this in your environment after configuring the webhook in Square Dashboard.
// Square Dashboard → Webhooks → your endpoint → Signature Key
const SQUARE_WEBHOOK_SIGNATURE_KEY = process.env.SQUARE_WEBHOOK_SIGNATURE_KEY || "";

// The full URL Square sends the webhook to — needed for signature computation.
// Example: https://constructionos.world/api/billing/webhook
const SQUARE_WEBHOOK_URL = process.env.SQUARE_WEBHOOK_URL || "";

// ─── Signature verification ────────────────────────────────────────────
// Square signs every webhook with HMAC-SHA256(signatureKey, requestUrl + rawBody).
// The signature is sent in the x-square-hmacsha256-signature header as base64.
// Docs: https://developer.squareup.com/docs/webhooks/step3validate

async function verifySquareSignature(
  rawBody: string,
  signatureHeader: string,
  webhookUrl: string,
  signatureKey: string,
): Promise<boolean> {
  const encoder = new TextEncoder();

  // Import the signature key
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(signatureKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Square hashes: webhookUrl + rawBody
  const payload = webhookUrl + rawBody;
  const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));

  // Convert to base64
  const expectedSignature = btoa(
    String.fromCharCode(...new Uint8Array(signatureBuffer)),
  );

  // Constant-time comparison to prevent timing attacks
  if (expectedSignature.length !== signatureHeader.length) return false;

  let mismatch = 0;
  for (let i = 0; i < expectedSignature.length; i++) {
    mismatch |= expectedSignature.charCodeAt(i) ^ signatureHeader.charCodeAt(i);
  }
  return mismatch === 0;
}

// ─── Plan extraction ───────────────────────────────────────────────────

function isPlanId(value: string): value is PlanId {
  return PLAN_IDS.includes(value as PlanId);
}

function extractPlanFromPayment(data: Record<string, unknown>): PlanId | null {
  // 1. Check order note for "plan:field", "plan:pm", or "plan:owner"
  const note = (data.note as string) || (data.description as string) || "";
  const noteMatch = note.match(/plan[:\s-]+(field|pm|owner)/i);
  if (noteMatch && isPlanId(noteMatch[1].toLowerCase())) {
    return noteMatch[1].toLowerCase() as PlanId;
  }

  // 2. Check line item names
  const lineItems = (data.line_items as Array<Record<string, unknown>>) || [];
  for (const item of lineItems) {
    const itemName = ((item.name as string) || "").toLowerCase();
    if (itemName.includes("owner") || itemName.includes("company")) return "owner";
    if (itemName.includes("project manager") || itemName.includes("pm")) return "pm";
    if (itemName.includes("field")) return "field";
  }

  // 3. Infer from amount (cents)
  const totalMoney = data.total_money as Record<string, unknown> | undefined;
  const amount = totalMoney ? Number(totalMoney.amount) : 0;
  if (amount >= 4999) return "owner";
  if (amount >= 2799) return "pm";
  if (amount >= 999) return "field";

  return null;
}

// ─── Email extraction ──────────────────────────────────────────────────

function extractEmail(data: Record<string, unknown>): string {
  const buyerEmail =
    (data.buyer_email_address as string) ||
    (data.receipt_email as string) ||
    "";

  if (buyerEmail) return buyerEmail.toLowerCase().trim();

  const tenders = (data.tenders as Array<Record<string, unknown>>) || [];
  for (const tender of tenders) {
    const cardDetails = tender.card_details as Record<string, unknown> | undefined;
    if (cardDetails?.buyer_email_address) {
      return (cardDetails.buyer_email_address as string).toLowerCase().trim();
    }
  }

  return "";
}

// ─── Webhook handler ───────────────────────────────────────────────────

export async function POST(req: Request) {
  // Read raw body BEFORE parsing — needed for signature verification
  const rawBody = await req.text();

  // Verify HMAC signature when configured
  if (SQUARE_WEBHOOK_SIGNATURE_KEY) {
    const signature = req.headers.get("x-square-hmacsha256-signature");
    if (!signature) {
      console.error("[Webhook] Missing x-square-hmacsha256-signature header");
      return NextResponse.json({ error: "Missing signature" }, { status: 401 });
    }

    const webhookUrl = SQUARE_WEBHOOK_URL || req.url;
    const isValid = await verifySquareSignature(rawBody, signature, webhookUrl, SQUARE_WEBHOOK_SIGNATURE_KEY);

    if (!isValid) {
      console.error("[Webhook] Invalid signature — request rejected");
      return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
    }
  }

  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) {
    return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  }

  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawBody);
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const eventType = (body.type as string) || "";

  // Only process payment completed events
  if (
    eventType !== "payment.completed" &&
    eventType !== "payment.updated" &&
    eventType !== "order.fulfillment.updated"
  ) {
    return NextResponse.json({ received: true });
  }

  const data =
    ((body.data as Record<string, unknown>)?.object as Record<string, unknown>) ||
    (body.data as Record<string, unknown>) ||
    {};

  const payment =
    (data.payment as Record<string, unknown>) ||
    (data.order as Record<string, unknown>) ||
    data;

  const email = extractEmail(payment);
  const plan = extractPlanFromPayment(payment);

  if (!email || !plan) {
    console.error("[Webhook] Could not extract email or plan:", {
      email: email || "(missing)",
      plan: plan || "(missing)",
      eventType,
    });
    return NextResponse.json({ received: true, warning: "Could not match payment to user" });
  }

  try {
    const supabase = createClient(url, key);

    // Find user by email
    const { data: users, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error("[Webhook] Failed to list users:", listError);
      return NextResponse.json({ error: "User lookup failed" }, { status: 500 });
    }

    const matchedUser = users.users.find((u) => u.email?.toLowerCase() === email);
    if (!matchedUser) {
      console.error(`[Webhook] No user found for email: ${email}`);
      return NextResponse.json({ received: true, warning: "No matching user" });
    }

    // Upsert subscription tier
    const { error: upsertError } = await supabase
      .from("cs_user_profiles")
      .upsert(
        {
          user_id: matchedUser.id,
          subscription_tier: plan,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );

    if (upsertError) {
      console.error("[Webhook] Failed to update subscription:", upsertError);
      return NextResponse.json({ error: "Subscription update failed" }, { status: 500 });
    }

    console.info(`[Webhook] Updated ${email} to tier: ${plan}`);
    return NextResponse.json({ success: true, email, plan });
  } catch (err) {
    console.error("[Webhook] Unexpected error:", err);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
