import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";

export const dynamic = "force-dynamic";

// Paddle product ID → subscription tier mapping
const PRODUCT_TIER_MAP: Record<string, string> = {
  // Configure these to match your Paddle product IDs
  pro_field: "field",
  pro_pm: "pm",
  pro_owner: "owner",
};

// Maximum age of a webhook timestamp before rejection (replay protection)
const MAX_TIMESTAMP_AGE_MS = 5 * 60 * 1000; // 5 minutes

// ─── Signature verification (WEB-04) ──────────────────────────────────
// Paddle signs every webhook with HMAC-SHA256.
// Header format: ts=TIMESTAMP;h1=HMAC_HEX
// Signed payload: ${timestamp}.${rawBody}
// Docs: https://developer.paddle.com/webhooks/signature-verification

async function verifyPaddleSignature(
  rawBody: string,
  signatureHeader: string,
  secret: string,
): Promise<boolean> {
  // Parse ts=TIMESTAMP;h1=HMAC_HEX
  const parts: Record<string, string> = {};
  for (const segment of signatureHeader.split(";")) {
    const eqIndex = segment.indexOf("=");
    if (eqIndex > 0) {
      parts[segment.slice(0, eqIndex)] = segment.slice(eqIndex + 1);
    }
  }

  const timestamp = parts.ts;
  const h1 = parts.h1;

  if (!timestamp || !h1) {
    console.warn("[Paddle] Malformed signature header:", signatureHeader);
    return false;
  }

  // Replay protection: reject timestamps older than 5 minutes
  const tsMs = parseInt(timestamp, 10) * 1000;
  if (isNaN(tsMs) || Date.now() - tsMs > MAX_TIMESTAMP_AGE_MS) {
    console.warn("[Paddle] Timestamp too old or invalid:", timestamp);
    return false;
  }

  // Compute HMAC-SHA256 of "${timestamp}.${rawBody}"
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const payload = `${timestamp}.${rawBody}`;
  const signatureBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );

  // Convert to hex for comparison with h1
  const computedHex = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Constant-time comparison to prevent timing attacks
  if (computedHex.length !== h1.length) return false;

  let mismatch = 0;
  for (let i = 0; i < computedHex.length; i++) {
    mismatch |= computedHex.charCodeAt(i) ^ h1.charCodeAt(i);
  }
  return mismatch === 0;
}

// ─── Tier extraction ──────────────────────────────────────────────────

function extractTierFromItems(items: Array<Record<string, unknown>>): string {
  for (const item of items) {
    const price = item.price as Record<string, unknown> | undefined;
    const productId = (price?.product_id as string) || (item.product_id as string) || "";

    // Check exact match in product map
    if (productId && PRODUCT_TIER_MAP[productId]) {
      return PRODUCT_TIER_MAP[productId];
    }

    // Infer from product name if no exact match
    const productName = ((price?.name as string) || (item.name as string) || "").toLowerCase();
    if (productName.includes("owner") || productName.includes("company")) return "owner";
    if (productName.includes("project manager") || productName.includes("pm")) return "pm";
    if (productName.includes("field")) return "field";
  }

  return "";
}

// ─── Webhook handler ──────────────────────────────────────────────────

export async function POST(req: Request) {
  const secret = process.env.PADDLE_WEBHOOK_SECRET;
  if (!secret) {
    console.error("[Paddle] PADDLE_WEBHOOK_SECRET is not configured");
    return NextResponse.json(
      { error: "Paddle webhook not configured" },
      { status: 503 },
    );
  }

  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) {
    return NextResponse.json(
      { error: "Database not configured" },
      { status: 503 },
    );
  }

  // Read raw body BEFORE parsing -- needed for signature verification
  const rawBody = await req.text();

  // Verify HMAC signature (WEB-04)
  const signatureHeader = req.headers.get("paddle-signature");
  if (!signatureHeader) {
    console.error("[Paddle] Missing paddle-signature header");
    return NextResponse.json({ error: "Missing signature" }, { status: 401 });
  }

  const isValid = await verifyPaddleSignature(rawBody, signatureHeader, secret);
  if (!isValid) {
    console.error("[Paddle] Invalid signature -- request rejected");
    return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
  }

  // Parse body after signature verification
  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawBody);
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const eventType = (body.event_type as string) || "";
  const data = (body.data as Record<string, unknown>) || {};

  console.info("[Paddle]", eventType, "subscription_id:", data.id, "customer_id:", data.customer_id);

  // Only process subscription events (WEB-05)
  if (
    eventType !== "subscription.created" &&
    eventType !== "subscription.updated" &&
    eventType !== "subscription.canceled"
  ) {
    return NextResponse.json({ received: true });
  }

  try {
    const supabase = createClient(url, key);

    // Extract customer email from nested customer object or custom_data
    const customer = data.customer as Record<string, unknown> | undefined;
    const customData = data.custom_data as Record<string, unknown> | undefined;
    const email = (
      (customer?.email as string) ||
      (customData?.email as string) ||
      ""
    ).toLowerCase().trim();

    const paddleCustomerId = (data.customer_id as string) || "";

    if (!email && !paddleCustomerId) {
      console.error("[Paddle] No email or customer_id in webhook data");
      return NextResponse.json({ received: true, warning: "No customer identifier" });
    }

    // Find user by email
    let userId: string | null = null;

    if (email) {
      const { data: users, error: listError } = await supabase.auth.admin.listUsers();
      if (listError) {
        console.error("[Paddle] Failed to list users:", listError);
        return NextResponse.json({ error: "User lookup failed" }, { status: 500 });
      }
      const matchedUser = users.users.find((u) => u.email?.toLowerCase() === email);
      userId = matchedUser?.id || null;
    }

    if (!userId) {
      // Try finding by paddle_customer_id in existing profiles
      const { data: profile } = await supabase
        .from("cs_user_profiles")
        .select("user_id")
        .eq("paddle_customer_id", paddleCustomerId)
        .maybeSingle();
      userId = profile?.user_id || null;
    }

    if (!userId) {
      console.error(`[Paddle] No user found for email: ${email}, customer: ${paddleCustomerId}`);
      return NextResponse.json({ received: true, warning: "No matching user" });
    }

    // Determine subscription tier
    let tier: string;
    if (eventType === "subscription.canceled") {
      tier = "free";
    } else {
      const items = (data.items as Array<Record<string, unknown>>) || [];
      tier = extractTierFromItems(items);
      if (!tier) {
        console.warn("[Paddle] Unknown product in subscription items, defaulting to field");
        tier = "field";
      }
    }

    // Upsert subscription tier
    const { error: upsertError } = await supabase
      .from("cs_user_profiles")
      .upsert(
        {
          user_id: userId,
          subscription_tier: tier,
          paddle_customer_id: paddleCustomerId,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );

    if (upsertError) {
      console.error("[Paddle] Failed to update subscription:", upsertError);
      return NextResponse.json({ error: "Subscription update failed" }, { status: 500 });
    }

    console.info(`[Paddle] Updated user ${userId} to tier: ${tier}`);
    return NextResponse.json({ success: true, tier });
  } catch (err) {
    console.error("[Paddle] Unexpected error:", err);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
