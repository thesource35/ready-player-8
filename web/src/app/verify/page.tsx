"use client";
import Image from "next/image";
import Link from "next/link";
import { useState } from "react";

const trades = [
  "General Contractor", "Electrician", "Plumber", "HVAC", "Concrete", "Steel/Ironwork",
  "Crane Operator", "Welder", "Roofing Contractor", "Structural Engineer", "Architect",
  "Fire Protection", "Solar Installer", "Low Voltage", "Demolition",
];

const tiers = [
  { id: "identity", name: "Identity Verified", price: "FREE", icon: "✅", color: "#69D294", desc: "Email, phone, and basic profile verification" },
  { id: "licensed", name: "Licensed Professional", price: "$27.99/mo", icon: "🏆", color: "#FCC757", desc: "State license verification + gold badge" },
  { id: "company", name: "Verified Company", price: "$49.99/mo", icon: "🏢", color: "#4AC4CC", desc: "Business license + insurance + bonding verification" },
];

export default function VerifyPage() {
  const [selectedTier, setSelectedTier] = useState("licensed");
  const [step, setStep] = useState(1);
  const [submitted, setSubmitted] = useState(false);
  const [form, setForm] = useState({
    fullName: "", email: "", phone: "", trade: "",
    licenseType: "", licenseNumber: "", licenseState: "", licenseExpiry: "", oshaLevel: "",
    companyName: "", ein: "", yearsInBusiness: "",
    insuranceCarrier: "", insurancePolicyNumber: "", glCoverage: "", wcCoverage: "",
    bondingCompany: "", bondingCapacity: "",
  });

  const update = (key: string, value: string) => setForm(prev => ({ ...prev, [key]: value }));
  const tier = tiers.find(t => t.id === selectedTier)!;

  if (submitted) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4" style={{ background: "#080E12" }}>
        <div className="text-center max-w-md">
          <div className="text-6xl mb-4">{tier.icon}</div>
          <h1 className="text-2xl font-black mb-2">Verification Submitted!</h1>
          <p className="text-sm text-[#9EBDC2] mb-2">Your <b style={{ color: tier.color }}>{tier.name}</b> application is being reviewed.</p>
          <p className="text-xs text-[#9EBDC2] mb-6">We verify licenses against state databases. Typical processing: 2-5 business days. You&apos;ll receive an email when your badge is activated.</p>
          <div className="rounded-xl p-4 mb-6 text-left" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">APPLICATION SUMMARY</div>
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div><span className="text-[#9EBDC2]">Name:</span> {form.fullName}</div>
              <div><span className="text-[#9EBDC2]">Trade:</span> {form.trade}</div>
              <div><span className="text-[#9EBDC2]">License #:</span> {form.licenseNumber || "N/A"}</div>
              <div><span className="text-[#9EBDC2]">State:</span> {form.licenseState || "N/A"}</div>
              <div><span className="text-[#9EBDC2]">Status:</span> <span style={{ color: "#FCC757" }}>PENDING REVIEW</span></div>
              <div><span className="text-[#9EBDC2]">Tier:</span> <span style={{ color: tier.color }}>{tier.name}</span></div>
            </div>
          </div>
          <Link href="/feed" className="block w-full py-3 rounded-xl text-sm font-bold text-black mb-3" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>Back to Network</Link>
          <Link href="/cos-network" className="text-xs text-[#9EBDC2]">View verification tiers</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen px-4 py-10" style={{ background: "#080E12" }}>
      <div className="max-w-lg mx-auto">
        <div className="text-center mb-8">
          <Image src="/logo.png" alt="ConstructionOS" width={56} height={56} className="rounded-xl mx-auto mb-3" />
          <h1 className="text-xl font-black">Get Verified</h1>
          <p className="text-xs text-[#9EBDC2] mt-1">License verification against state databases. Stand out on the network.</p>
        </div>

        {/* Tier Selection */}
        <div className="mb-6">
          <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">1. CHOOSE VERIFICATION TIER</div>
          <div className="flex gap-2">
            {tiers.map(t => (
              <button key={t.id} onClick={() => setSelectedTier(t.id)} className="flex-1 rounded-xl p-3 text-center" style={{ background: selectedTier === t.id ? "#0F1C24" : "transparent", border: selectedTier === t.id ? `2px solid ${t.color}` : "1px solid rgba(51,84,94,0.3)", cursor: "pointer" }}>
                <div className="text-xl mb-1">{t.icon}</div>
                <div className="text-[10px] font-bold" style={{ color: selectedTier === t.id ? t.color : "#9EBDC2" }}>{t.name}</div>
                <div className="text-xs font-black mt-1">{t.price}</div>
              </button>
            ))}
          </div>
          <p className="text-[9px] text-[#9EBDC2] mt-2 text-center">{tier.desc}</p>
        </div>

        {/* Step 1: Personal Info */}
        {step >= 1 && (
          <div className="mb-6">
            <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">2. PERSONAL INFORMATION</div>
            <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
              <input placeholder="Full legal name" value={form.fullName} onChange={e => update("fullName", e.target.value)} className="mb-3" />
              <input placeholder="Email address" type="email" value={form.email} onChange={e => update("email", e.target.value)} className="mb-3" />
              <input placeholder="Phone number" value={form.phone} onChange={e => update("phone", e.target.value)} className="mb-3" />
              <select value={form.trade} onChange={e => update("trade", e.target.value)} className="mb-3">
                <option value="">Select your trade</option>
                {trades.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
              {step === 1 && form.fullName && form.email && form.trade && (
                <button onClick={() => setStep(2)} className="w-full py-2.5 rounded-xl text-sm font-bold text-black" style={{ background: tier.color, border: "none", cursor: "pointer" }}>Continue</button>
              )}
            </div>
          </div>
        )}

        {/* Step 2: License Info */}
        {step >= 2 && selectedTier !== "identity" && (
          <div className="mb-6">
            <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">3. LICENSE INFORMATION</div>
            <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
              <input placeholder="License type (e.g., Master Electrician)" value={form.licenseType} onChange={e => update("licenseType", e.target.value)} className="mb-3" />
              <input placeholder="License number" value={form.licenseNumber} onChange={e => update("licenseNumber", e.target.value)} className="mb-3" />
              <input placeholder="License state (e.g., TX)" value={form.licenseState} onChange={e => update("licenseState", e.target.value)} className="mb-3" />
              <input placeholder="License expiry date" value={form.licenseExpiry} onChange={e => update("licenseExpiry", e.target.value)} className="mb-3" />
              <select value={form.oshaLevel} onChange={e => update("oshaLevel", e.target.value)}>
                <option value="">OSHA Training Level</option>
                <option value="OSHA 10">OSHA 10-Hour</option>
                <option value="OSHA 30">OSHA 30-Hour</option>
                <option value="None">None</option>
              </select>
              {step === 2 && form.licenseNumber && (
                <button onClick={() => setStep(selectedTier === "company" ? 3 : 4)} className="w-full py-2.5 rounded-xl text-sm font-bold text-black mt-3" style={{ background: tier.color, border: "none", cursor: "pointer" }}>Continue</button>
              )}
            </div>
          </div>
        )}

        {/* Step 3: Company Info (company tier only) */}
        {step >= 3 && selectedTier === "company" && (
          <div className="mb-6">
            <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">4. COMPANY & INSURANCE</div>
            <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
              <input placeholder="Company name" value={form.companyName} onChange={e => update("companyName", e.target.value)} className="mb-3" />
              <input placeholder="EIN (Federal Tax ID)" value={form.ein} onChange={e => update("ein", e.target.value)} className="mb-3" />
              <input placeholder="Years in business" value={form.yearsInBusiness} onChange={e => update("yearsInBusiness", e.target.value)} className="mb-3" />
              <input placeholder="Insurance carrier" value={form.insuranceCarrier} onChange={e => update("insuranceCarrier", e.target.value)} className="mb-3" />
              <input placeholder="Policy number" value={form.insurancePolicyNumber} onChange={e => update("insurancePolicyNumber", e.target.value)} className="mb-3" />
              <div className="flex gap-3">
                <input placeholder="GL coverage amount" value={form.glCoverage} onChange={e => update("glCoverage", e.target.value)} className="mb-3" />
                <input placeholder="WC coverage amount" value={form.wcCoverage} onChange={e => update("wcCoverage", e.target.value)} className="mb-3" />
              </div>
              <input placeholder="Bonding company" value={form.bondingCompany} onChange={e => update("bondingCompany", e.target.value)} className="mb-3" />
              <input placeholder="Bonding capacity" value={form.bondingCapacity} onChange={e => update("bondingCapacity", e.target.value)} />
              {form.companyName && (
                <button onClick={() => setStep(4)} className="w-full py-2.5 rounded-xl text-sm font-bold text-black mt-3" style={{ background: tier.color, border: "none", cursor: "pointer" }}>Continue</button>
              )}
            </div>
          </div>
        )}

        {/* Step 4: Review & Submit */}
        {step >= 4 && (
          <div className="mb-6">
            <div className="text-[10px] font-black tracking-[0.15em] text-[#9EBDC2] mb-3">{selectedTier === "identity" ? "3" : selectedTier === "licensed" ? "4" : "5"}. REVIEW & SUBMIT</div>
            <div className="rounded-xl p-4" style={{ background: "#0F1C24" }}>
              <div className="text-xs mb-4">
                <div className="flex justify-between py-1" style={{ borderBottom: "1px solid rgba(51,84,94,0.2)" }}><span className="text-[#9EBDC2]">Tier</span><span style={{ color: tier.color }}>{tier.name} — {tier.price}</span></div>
                <div className="flex justify-between py-1" style={{ borderBottom: "1px solid rgba(51,84,94,0.2)" }}><span className="text-[#9EBDC2]">Name</span><span>{form.fullName}</span></div>
                <div className="flex justify-between py-1" style={{ borderBottom: "1px solid rgba(51,84,94,0.2)" }}><span className="text-[#9EBDC2]">Trade</span><span>{form.trade}</span></div>
                {form.licenseNumber && <div className="flex justify-between py-1" style={{ borderBottom: "1px solid rgba(51,84,94,0.2)" }}><span className="text-[#9EBDC2]">License</span><span>{form.licenseState} #{form.licenseNumber}</span></div>}
                {form.companyName && <div className="flex justify-between py-1" style={{ borderBottom: "1px solid rgba(51,84,94,0.2)" }}><span className="text-[#9EBDC2]">Company</span><span>{form.companyName}</span></div>}
              </div>
              <p className="text-[9px] text-[#9EBDC2] mb-3">By submitting, you confirm all information is accurate. We will verify your license against the appropriate state database. False information may result in permanent ban from the network.</p>
              <button onClick={() => setSubmitted(true)} className="w-full py-3 rounded-xl text-sm font-bold text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", border: "none", cursor: "pointer" }}>SUBMIT VERIFICATION REQUEST</button>
            </div>
          </div>
        )}

        {/* Identity tier skips to step 4 */}
        {step === 1 && selectedTier === "identity" && form.fullName && form.email && form.trade && (
          <div className="text-center">
            <button onClick={() => { setStep(4); }} className="px-8 py-3 rounded-xl text-sm font-bold text-black" style={{ background: tier.color, border: "none", cursor: "pointer" }}>Review & Submit</button>
          </div>
        )}
      </div>
    </div>
  );
}
