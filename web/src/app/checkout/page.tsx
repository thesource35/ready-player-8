"use client";
import Image from "next/image";
import Link from "next/link";
import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  getPlan,
  isBillingInterval,
  isPaymentMethodId,
  isPlanId,
  paymentMethods,
  plans,
  type BillingInterval,
  type PaymentMethodId,
  type PlanId,
} from "@/lib/billing/plans";

export default function CheckoutPage() {
  return (
    <Suspense fallback={<div style={{ minHeight: "60vh", display: "flex", alignItems: "center", justifyContent: "center" }}><p style={{ color: "#9EBDC2" }}>Loading checkout...</p></div>}>
      <CheckoutContent />
    </Suspense>
  );
}

function CheckoutContent() {
  const searchParams = useSearchParams();
  const [selectedPlan, setSelectedPlan] = useState<PlanId>("pm");
  const [billing, setBilling] = useState<BillingInterval>("monthly");
  const [payMethod, setPayMethod] = useState<PaymentMethodId>("card");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const plan = getPlan(selectedPlan);
  const price = billing === "monthly" ? plan.price : plan.annual;

  useEffect(() => {
    const requestedPlan = searchParams.get("plan");
    const requestedBilling = searchParams.get("billing");
    const requestedPayMethod = searchParams.get("payMethod");

    if (requestedPlan && isPlanId(requestedPlan)) {
      setSelectedPlan(requestedPlan);
    }

    if (requestedBilling && isBillingInterval(requestedBilling)) {
      setBilling(requestedBilling);
    }

    if (requestedPayMethod && isPaymentMethodId(requestedPayMethod)) {
      setPayMethod(requestedPayMethod);
    }
  }, [searchParams]);

  async function startCheckout() {
    setError("");
    setLoading(true);

    try {
      const response = await fetch("/api/billing/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          planId: selectedPlan,
          billing,
          payMethod,
        }),
      });

      const data = await response.json();
      if (!response.ok || !data.url) {
        throw new Error(data.error || "Checkout is unavailable right now.");
      }

      window.location.assign(data.url);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Checkout is unavailable right now.");
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen px-4 py-10" style={{ background: "#080E12" }}>
      <div className="max-w-lg mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <Image src="/logo.png" alt="ConstructionOS" width={56} height={56} className="rounded-xl mx-auto mb-3" />
          <h1 className="text-xl font-black">Get Started with ConstructionOS</h1>
          <p className="text-xs text-[#9EBDC2] mt-1">Choose your plan. Secure checkout powered by Square.</p>
        </div>

        {/* Plan Selection */}
        <div className="mb-6">
          <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">1. CHOOSE YOUR PLAN</div>
          <div className="flex gap-2 mb-3">
            {plans.map(p => (
              <button key={p.id} onClick={() => setSelectedPlan(p.id)} className="flex-1 rounded-xl p-3 text-center transition-all" style={{ background: selectedPlan === p.id ? "#0F1C24" : "transparent", border: selectedPlan === p.id ? `2px solid ${p.color}` : "1px solid rgba(51,84,94,0.3)", cursor: "pointer" }}>
                {"popular" in p && p.popular && <div className="text-[7px] font-black mb-1" style={{ color: p.color }}>POPULAR</div>}
                <div className="text-xs font-bold" style={{ color: selectedPlan === p.id ? p.color : "#9EBDC2" }}>{p.name}</div>
                <div className="text-lg font-black" style={{ color: selectedPlan === p.id ? "#F0F8F8" : "#9EBDC2" }}>{p.price}<span className="text-[9px]">/mo</span></div>
              </button>
            ))}
          </div>

          {/* Billing Toggle */}
          <div className="flex gap-2 rounded-lg overflow-hidden" style={{ background: "#0F1C24" }}>
            <button onClick={() => setBilling("monthly")} className="flex-1 py-2 text-xs font-bold text-center" style={{ background: billing === "monthly" ? "var(--accent)" : "transparent", color: billing === "monthly" ? "#080E12" : "#9EBDC2", cursor: "pointer", border: "none" }}>MONTHLY</button>
            <button onClick={() => setBilling("annual")} className="flex-1 py-2 text-xs font-bold text-center" style={{ background: billing === "annual" ? "var(--accent)" : "transparent", color: billing === "annual" ? "#080E12" : "#9EBDC2", cursor: "pointer", border: "none" }}>ANNUAL <span style={{ color: billing === "annual" ? "#080E12" : "#69D294" }}>SAVE 17%</span></button>
          </div>
        </div>

        {/* Payment Method */}
        <div className="mb-6">
          <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">2. PAYMENT METHOD</div>
          <div className="grid grid-cols-3 gap-2 mb-4">
            {paymentMethods.map(m => (
              <button key={m.id} onClick={() => setPayMethod(m.id)} className="rounded-lg p-3 text-center transition-all" style={{ background: payMethod === m.id ? "#0F1C24" : "transparent", border: payMethod === m.id ? "2px solid var(--accent)" : "1px solid rgba(51,84,94,0.3)", cursor: "pointer" }}>
                <div className="text-lg mb-1">{m.icon}</div>
                <div className="text-[9px] font-bold" style={{ color: payMethod === m.id ? "#F0F8F8" : "#9EBDC2" }}>{m.label}</div>
              </button>
            ))}
          </div>

          <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
            <div className="text-xs font-black tracking-[0.15em] text-[#4AC4CC] mb-2">SQUARE CHECKOUT</div>
            <p className="text-sm text-[#F0F8F8] mb-2">
              {payMethod === "card" && "You’ll finish checkout on Square with card entry and any supported wallet buttons."}
              {payMethod === "apple" && "You’ll continue to Square checkout. Apple Pay will appear there when supported by your device and browser."}
              {payMethod === "google" && "You’ll continue to Square checkout. Google Pay will appear there when supported by your browser and device."}
            </p>
            <p className="text-[11px] text-[#9EBDC2]">
              Plan selected: <b className="text-[#F0F8F8]">{plan.name}</b> · Billing: <b className="text-[#F0F8F8]">{billing}</b>
            </p>
          </div>
        </div>

        {/* Order Summary */}
        <div className="rounded-xl p-4 mb-6" style={{ background: "#0F1C24", border: "1px solid rgba(242,158,61,0.15)" }}>
          <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">ORDER SUMMARY</div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm">{plan.name} — {billing === "monthly" ? "Monthly" : "Annual"}</span>
            <span className="text-sm font-black" style={{ color: plan.color }}>{price}<span className="text-[9px] text-[#9EBDC2]">/{billing === "monthly" ? "mo" : "yr"}</span></span>
          </div>
          <div className="flex justify-between items-center mb-2 text-xs text-[#9EBDC2]" style={{ borderTop: "1px solid rgba(51,84,94,0.2)", paddingTop: 8 }}>
            <span>First month discount</span>
            <span className="font-bold text-[#69D294]">Included</span>
          </div>
          <div className="flex justify-between items-center pt-2 text-sm font-black" style={{ borderTop: "1px solid rgba(51,84,94,0.2)" }}>
            <span>Due today</span>
            <span className="text-[#69D294]">$0.00</span>
          </div>
          <div className="text-[11px] text-[#9EBDC2] mt-1" style={{ textAlign: "right" }}>
            7-day free trial — no charge until trial ends
          </div>
        </div>

        {error && (
          <div className="rounded-xl p-3 mb-4 text-sm font-bold" style={{ background: "rgba(217,77,72,0.1)", color: "#D94D48", border: "1px solid rgba(217,77,72,0.2)" }}>
            {error}
          </div>
        )}

        {/* Submit */}
        <button onClick={startCheckout} disabled={loading} className="w-full py-4 rounded-xl text-base font-bold text-black cursor-pointer mb-3" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", border: "none", opacity: loading ? 0.8 : 1 }}>
          {loading ? "OPENING SQUARE CHECKOUT..." : "CONTINUE TO SECURE CHECKOUT"}
        </button>
        <p className="text-center text-[9px] text-[#9EBDC2] mb-2">By continuing, you agree to our <Link href="/terms" className="text-[#F29E3D]">Terms</Link> and <Link href="/privacy" className="text-[#F29E3D]">Privacy Policy</Link></p>
        <div className="flex justify-center gap-4 mt-2">
          {["🔒 256-bit SSL", "🛡 PCI DSS", "✅ SOC 2", "📜 GDPR"].map(b => (
            <span key={b} className="text-[9px] text-[#9EBDC2]" style={{ opacity: 0.5 }}>{b}</span>
          ))}
        </div>
      </div>
    </div>
  );
}
