export const PLAN_IDS = ["field", "pm", "owner"] as const;
export const BILLING_INTERVALS = ["monthly", "annual"] as const;
export const PAYMENT_METHOD_IDS = ["card", "apple", "google"] as const;

export type PlanId = (typeof PLAN_IDS)[number];
export type BillingInterval = (typeof BILLING_INTERVALS)[number];
export type PaymentMethodId = (typeof PAYMENT_METHOD_IDS)[number];

export const plans = [
  { id: "field", name: "Field Worker", price: "$9.99", annual: "$99.99", color: "#4AC4CC" },
  { id: "pm", name: "Project Manager", price: "$27.99", annual: "$279.99", color: "#FCC757", popular: true },
  { id: "owner", name: "Company Owner", price: "$49.99", annual: "$499.99", color: "#F29E3D" },
] as const;

export const paymentMethods = [
  { id: "card", label: "Card Checkout", icon: "💳", description: "Pay securely on Square checkout." },
  { id: "apple", label: "Apple Pay", icon: "🍎", description: "Available on Square checkout when your device supports Apple Pay." },
  { id: "google", label: "Google Pay", icon: "G", description: "Available on Square checkout when your browser supports Google Pay." },
] as const;

export function isPlanId(value: string): value is PlanId {
  return PLAN_IDS.includes(value as PlanId);
}

export function isBillingInterval(value: string): value is BillingInterval {
  return BILLING_INTERVALS.includes(value as BillingInterval);
}

export function isPaymentMethodId(value: string): value is PaymentMethodId {
  return PAYMENT_METHOD_IDS.includes(value as PaymentMethodId);
}

export function getPlan(planId: PlanId) {
  return plans.find((plan) => plan.id === planId) ?? plans[1];
}
