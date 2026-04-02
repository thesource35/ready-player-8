"use client";
import { useState } from "react";

const plans = [
  { id: "field", name: "Field Worker", price: "$9.99", annual: "$99.99", color: "#4AC4CC" },
  { id: "pm", name: "Project Manager", price: "$27.99", annual: "$279.99", color: "#FCC757", popular: true },
  { id: "owner", name: "Company Owner", price: "$49.99", annual: "$499.99", color: "#F29E3D" },
];

const paymentMethods = [
  { id: "card", label: "Credit / Debit Card", icon: "💳", fields: ["card"] },
  { id: "apple", label: "Apple Pay", icon: "🍎", fields: [] },
  { id: "google", label: "Google Pay", icon: "G", fields: [] },
  { id: "paypal", label: "PayPal", icon: "📱", fields: [] },
  { id: "bank", label: "Bank Transfer / ACH", icon: "🏦", fields: ["bank"] },
];

export default function CheckoutPage() {
  const [selectedPlan, setSelectedPlan] = useState("pm");
  const [billing, setBilling] = useState<"monthly"|"annual">("monthly");
  const [payMethod, setPayMethod] = useState("card");
  const [submitted, setSubmitted] = useState(false);

  const plan = plans.find(p => p.id === selectedPlan)!;
  const price = billing === "monthly" ? plan.price : plan.annual;

  if (submitted) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4" style={{ background: "#080E12" }}>
        <div className="text-center max-w-md">
          <div className="text-6xl mb-4">✅</div>
          <h1 className="text-2xl font-black mb-2">Welcome to ConstructionOS!</h1>
          <p className="text-sm text-[#9EBDC2] mb-2">Your <b style={{ color: plan.color }}>{plan.name}</b> plan is now active.</p>
          <p className="text-xs text-[#9EBDC2] mb-6">7-day free trial started. You won&apos;t be charged until the trial ends.</p>
          <div className="rounded-xl p-4 mb-6" style={{ background: "#0F1C24" }}>
            <div className="text-sm font-bold mb-1">Your plan: {plan.name}</div>
            <div className="text-2xl font-black" style={{ color: plan.color }}>{price}<span className="text-xs text-[#9EBDC2]">/{billing === "monthly" ? "mo" : "yr"}</span></div>
            <div className="text-xs text-[#69D294] mt-1">First charge: {billing === "monthly" ? "7 days from now" : "7 days from now"}</div>
          </div>
          <a href="/feed" className="block w-full py-3 rounded-xl text-sm font-bold text-black mb-3" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>Enter ConstructionOS →</a>
          <a href="/" className="text-xs text-[#9EBDC2]">Return to homepage</a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen px-4 py-10" style={{ background: "#080E12" }}>
      <div className="max-w-lg mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <img src="/logo.png" alt="ConstructionOS" className="w-14 h-14 rounded-xl mx-auto mb-3" />
          <h1 className="text-xl font-black">Start Your Free Trial</h1>
          <p className="text-xs text-[#9EBDC2] mt-1">7 days free. Cancel anytime. No commitment.</p>
        </div>

        {/* Plan Selection */}
        <div className="mb-6">
          <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">1. CHOOSE YOUR PLAN</div>
          <div className="flex gap-2 mb-3">
            {plans.map(p => (
              <button key={p.id} onClick={() => setSelectedPlan(p.id)} className="flex-1 rounded-xl p-3 text-center transition-all" style={{ background: selectedPlan === p.id ? "#0F1C24" : "transparent", border: selectedPlan === p.id ? `2px solid ${p.color}` : "1px solid rgba(51,84,94,0.3)", cursor: "pointer" }}>
                {p.popular && <div className="text-[7px] font-black mb-1" style={{ color: p.color }}>POPULAR</div>}
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

          {/* Card Fields */}
          {payMethod === "card" && (
            <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
              <input placeholder="Card number" className="mb-3" />
              <div className="flex gap-3">
                <input placeholder="MM / YY" className="mb-3" />
                <input placeholder="CVC" className="mb-3" />
              </div>
              <input placeholder="Name on card" className="mb-3" />
              <input placeholder="Billing ZIP code" />
            </div>
          )}

          {/* Apple/Google Pay */}
          {(payMethod === "apple" || payMethod === "google") && (
            <div className="rounded-xl p-6 text-center" style={{ background: "#0F1C24" }}>
              <div className="text-3xl mb-3">{payMethod === "apple" ? "🍎" : "G"}</div>
              <p className="text-sm text-[#9EBDC2]">Click &quot;Start Trial&quot; below to complete payment with {payMethod === "apple" ? "Apple Pay" : "Google Pay"}</p>
            </div>
          )}

          {/* PayPal */}
          {payMethod === "paypal" && (
            <div className="rounded-xl p-6 text-center" style={{ background: "#0F1C24" }}>
              <div className="text-3xl mb-3">📱</div>
              <p className="text-sm text-[#9EBDC2]">You&apos;ll be redirected to PayPal to complete your payment</p>
            </div>
          )}

          {/* Bank / ACH */}
          {payMethod === "bank" && (
            <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
              <input placeholder="Account holder name" className="mb-3" />
              <input placeholder="Routing number" className="mb-3" />
              <input placeholder="Account number" />
              <p className="text-[9px] text-[#9EBDC2] mt-3">ACH Direct Debit. Funds typically clear in 2-3 business days.</p>
            </div>
          )}

        </div>

        {/* Order Summary */}
        <div className="rounded-xl p-4 mb-6" style={{ background: "#0F1C24", border: "1px solid rgba(242,158,61,0.15)" }}>
          <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">ORDER SUMMARY</div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm">{plan.name} — {billing === "monthly" ? "Monthly" : "Annual"}</span>
            <span className="text-sm font-black" style={{ color: plan.color }}>{price}<span className="text-[9px] text-[#9EBDC2]">/{billing === "monthly" ? "mo" : "yr"}</span></span>
          </div>
          <div className="flex justify-between items-center mb-2 text-xs text-[#9EBDC2]" style={{ borderTop: "1px solid rgba(51,84,94,0.2)", paddingTop: 8 }}>
            <span>7-day free trial</span>
            <span className="font-bold text-[#69D294]">-{price}</span>
          </div>
          <div className="flex justify-between items-center pt-2 text-sm font-black" style={{ borderTop: "1px solid rgba(51,84,94,0.2)" }}>
            <span>Due today</span>
            <span className="text-[#69D294]">$0.00</span>
          </div>
        </div>

        {/* Submit */}
        <button onClick={() => setSubmitted(true)} className="w-full py-4 rounded-xl text-base font-bold text-black cursor-pointer mb-3" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", border: "none" }}>START FREE TRIAL — $0.00 TODAY</button>
        <p className="text-center text-[9px] text-[#9EBDC2] mb-2">By continuing, you agree to our <a href="/terms" className="text-[#F29E3D]">Terms</a> and <a href="/privacy" className="text-[#F29E3D]">Privacy Policy</a></p>
        <div className="flex justify-center gap-4 mt-2">
          {["🔒 256-bit SSL", "🛡 PCI DSS", "✅ SOC 2", "📜 GDPR"].map(b => (
            <span key={b} className="text-[9px] text-[#9EBDC2]" style={{ opacity: 0.5 }}>{b}</span>
          ))}
        </div>
      </div>
    </div>
  );
}
