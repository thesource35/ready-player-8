import { NextResponse } from "next/server";
import {
  isBillingInterval,
  isPaymentMethodId,
  isPlanId,
  type BillingInterval,
  type PaymentMethodId,
  type PlanId,
} from "@/lib/billing/plans";
import { getSquarePaymentLink } from "@/lib/billing/square";

const missingCheckoutMessage =
  "This plan is currently being set up. Please try again shortly or contact support.";

function validateCheckoutInput(
  planId: string | null,
  billing: string | null,
  payMethod: string | null,
): { error?: string; planId?: PlanId; billing?: BillingInterval; payMethod?: PaymentMethodId } {
  if (!planId || !isPlanId(planId)) {
    return { error: "Invalid plan selection." };
  }

  if (!billing || !isBillingInterval(billing)) {
    return { error: "Invalid billing interval." };
  }

  if (!payMethod || !isPaymentMethodId(payMethod)) {
    return { error: "Unsupported payment method." };
  }

  return { planId, billing, payMethod };
}

export async function POST(request: Request) {
  let body: { planId?: string; billing?: string; payMethod?: string };

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid checkout request." }, { status: 400 });
  }

  const validated = validateCheckoutInput(body.planId ?? null, body.billing ?? null, body.payMethod ?? null);
  if (validated.error || !validated.planId || !validated.billing || !validated.payMethod) {
    return NextResponse.json({ error: validated.error ?? "Checkout request failed." }, { status: 400 });
  }

  const checkoutUrl = getSquarePaymentLink(validated.planId, validated.billing, validated.payMethod);
  if (!checkoutUrl) {
    return NextResponse.json({ error: missingCheckoutMessage }, { status: 503 });
  }

  return NextResponse.json({
    provider: "square",
    payMethod: validated.payMethod,
    url: checkoutUrl,
  });
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const validated = validateCheckoutInput(
    searchParams.get("plan"),
    searchParams.get("billing"),
    searchParams.get("payMethod") ?? "card",
  );

  if (validated.error || !validated.planId || !validated.billing) {
    return NextResponse.json({ error: validated.error ?? "Checkout request failed." }, { status: 400 });
  }

  const checkoutUrl = getSquarePaymentLink(
    validated.planId,
    validated.billing,
    validated.payMethod,
  );
  if (!checkoutUrl) {
    return NextResponse.json({ error: missingCheckoutMessage }, { status: 503 });
  }

  return NextResponse.redirect(checkoutUrl);
}
