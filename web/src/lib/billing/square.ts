import "server-only";

import type { BillingInterval, PaymentMethodId, PlanId } from "./plans";

const squarePaymentLinkMap: Record<PlanId, Record<BillingInterval, string[]>> = {
  field: {
    monthly: [
      "SQUARE_FIELD_MONTHLY_PAYMENT_LINK",
      "NEXT_PUBLIC_SQUARE_FIELD_MONTHLY_PAYMENT_LINK",
    ],
    annual: [
      "SQUARE_FIELD_ANNUAL_PAYMENT_LINK",
      "NEXT_PUBLIC_SQUARE_FIELD_ANNUAL_PAYMENT_LINK",
    ],
  },
  pm: {
    monthly: [
      "SQUARE_PM_MONTHLY_PAYMENT_LINK",
      "NEXT_PUBLIC_SQUARE_PM_MONTHLY_PAYMENT_LINK",
    ],
    annual: [
      "SQUARE_PM_ANNUAL_PAYMENT_LINK",
      "NEXT_PUBLIC_SQUARE_PM_ANNUAL_PAYMENT_LINK",
    ],
  },
  owner: {
    monthly: [
      "SQUARE_OWNER_MONTHLY_PAYMENT_LINK",
      "NEXT_PUBLIC_SQUARE_OWNER_MONTHLY_PAYMENT_LINK",
    ],
    annual: [
      "SQUARE_OWNER_ANNUAL_PAYMENT_LINK",
      "NEXT_PUBLIC_SQUARE_OWNER_ANNUAL_PAYMENT_LINK",
    ],
  },
};

function getFirstEnvValue(keys: string[]) {
  for (const key of keys) {
    const value = process.env[key];
    if (value) return value;
  }
  return "";
}

export function getSquarePaymentLink(
  planId: PlanId,
  billing: BillingInterval,
  payMethod?: PaymentMethodId,
): string {
  const baseUrl = getFirstEnvValue(squarePaymentLinkMap[planId][billing]);
  if (!baseUrl) return "";
  // card is the default payment method on Square — no need to append
  if (!payMethod || payMethod === "card") return baseUrl;
  // Append preferred payment method as URL param for Square to pre-select
  const separator = baseUrl.includes("?") ? "&" : "?";
  return `${baseUrl}${separator}preferred_payment_method=${payMethod}`;
}
