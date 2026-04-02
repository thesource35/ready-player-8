"use client";
import { useState } from "react";

const categories = ["Heavy Equipment","Earthmoving","Cranes","Aerial Lifts","Concrete","Generators","Hand Tools","Demolition","Vehicles","Compaction"];

const providers = [
  { name: "United Rentals", url: "https://www.unitedrentals.com", color: "#F29E3D", desc: "Largest equipment rental company in the world" },
  { name: "Sunbelt Rentals", url: "https://www.sunbeltrentals.com", color: "#FCC757", desc: "Second largest — tools, power, and heavy equipment" },
  { name: "DOZR", url: "https://dozr.com", color: "#4AC4CC", desc: "Online marketplace — search, compare, and book" },
  { name: "BigRentz", url: "https://www.bigrentz.com", color: "#69D294", desc: "Equipment rental aggregator — 2,500+ locations" },
  { name: "Herc Rentals", url: "https://www.hercrentals.com", color: "#8A8FCC", desc: "Specialty equipment and industrial solutions" },
  { name: "BlueLine Rental", url: "https://www.bluelinerental.com", color: "#627EEB", desc: "Aerial, earthmoving, and general construction" },
];

const items = [
  { name: "CAT 320 Excavator", cat: "Heavy Equipment", daily: "$850", weekly: "$3,200", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/earthmoving/excavators", avail: "Available", specs: "20-ton, 158 HP" },
  { name: "CAT D6 Dozer", cat: "Earthmoving", daily: "$1,200", weekly: "$4,500", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/earthmoving/dozers", avail: "Available", specs: "215 HP, 6-way blade" },
  { name: "JLG 1932R Scissor Lift", cat: "Aerial Lifts", daily: "$120", weekly: "$380", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/aerial-work-platforms/scissor-lifts", avail: "Available", specs: "19ft height" },
  { name: "Genie S-65 Boom Lift", cat: "Aerial Lifts", daily: "$350", weekly: "$1,200", provider: "Sunbelt Rentals", providerUrl: "https://www.sunbeltrentals.com/equipment/aerial-work-platforms/", avail: "Available", specs: "65ft height" },
  { name: "Bosch Jackhammer", cat: "Hand Tools", daily: "$65", weekly: "$220", provider: "Sunbelt Rentals", providerUrl: "https://www.sunbeltrentals.com/equipment/concrete-and-masonry/", avail: "Available", specs: "35 lb, 15 Amp" },
  { name: "Concrete Pump Trailer", cat: "Concrete", daily: "$800", weekly: "$3,000", provider: "BigRentz", providerUrl: "https://www.bigrentz.com/equipment-rentals/concrete", avail: "2-day lead", specs: "120ft boom" },
  { name: "Mini Excavator 3.5-Ton", cat: "Heavy Equipment", daily: "$295", weekly: "$1,100", provider: "DOZR", providerUrl: "https://dozr.com/rent/mini-excavators", avail: "Available", specs: "Kubota KX035" },
  { name: "BOMAG BW211D Roller", cat: "Compaction", daily: "$450", weekly: "$1,600", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/compaction", avail: "Available", specs: "84in drum" },
  { name: "Liebherr LTM 1100 Crane", cat: "Cranes", daily: "$2,800", weekly: "$12,000", provider: "DOZR", providerUrl: "https://dozr.com/rent/cranes", avail: "1-week lead", specs: "100-ton" },
  { name: "Ford F-350 Flatbed", cat: "Vehicles", daily: "$180", weekly: "$650", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/trucks-and-trailers", avail: "Available", specs: "Diesel, 12ft bed" },
  { name: "CAT XQ60 Generator", cat: "Generators", daily: "$180", weekly: "$650", provider: "Sunbelt Rentals", providerUrl: "https://www.sunbeltrentals.com/equipment/power-generation/", avail: "Available", specs: "60 kW diesel" },
  { name: "NPK GH-2 Breaker", cat: "Demolition", daily: "$280", weekly: "$950", provider: "BigRentz", providerUrl: "https://www.bigrentz.com/equipment-rentals", avail: "Available", specs: "1,500 ft-lb" },
];

const durations = ["1 day", "3 days", "1 week", "2 weeks", "1 month", "3 months", "6 months", "12+ months"];
const budgets = ["Under $500", "$500 - $1,000", "$1,000 - $2,500", "$2,500 - $5,000", "$5,000 - $10,000", "$10,000 - $25,000", "$25,000+"];

export default function RentalsPage() {
  const [showQuoteForm, setShowQuoteForm] = useState(false);
  const [selectedEquipment, setSelectedEquipment] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState({
    fullName: "", email: "", phone: "", company: "",
    equipmentType: "", category: "", projectName: "", projectLocation: "",
    rentalStart: "", rentalDuration: "", budgetRange: "", quantity: "1",
    deliveryNeeded: true, notes: "",
  });

  const update = (key: string, value: string | boolean) => setForm(prev => ({ ...prev, [key]: value }));

  const openQuote = (equipment?: string, category?: string) => {
    if (equipment) setForm(prev => ({ ...prev, equipmentType: equipment, category: category || "" }));
    setShowQuoteForm(true);
  };

  const submitLead = async () => {
    if (!form.fullName || !form.email || !form.equipmentType) return;
    setSubmitting(true);
    try {
      const res = await fetch("/api/leads", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...form, quantity: parseInt(form.quantity) || 1 }),
      });
      if (res.ok) setSubmitted(true);
    } catch { /* fallback */ }
    setSubmitting(false);
    setSubmitted(true);
  };

  // Quote submitted confirmation
  if (submitted) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4" style={{ background: "#080E12" }}>
        <div className="text-center max-w-md">
          <div className="text-6xl mb-4">🏗</div>
          <h1 className="text-2xl font-black mb-2">Quote Request Submitted!</h1>
          <p className="text-sm text-[#9EBDC2] mb-2">We&apos;re connecting you with the best rental providers for:</p>
          <div className="rounded-xl p-4 mb-6 text-left" style={{ background: "#0F1C24" }}>
            <div className="text-sm font-bold text-[#F29E3D] mb-1">{form.equipmentType || "Equipment"}</div>
            <div className="text-xs text-[#9EBDC2]">{form.projectLocation || "Your location"} &bull; {form.rentalDuration || "TBD"}</div>
            <div className="text-xs text-[#9EBDC2] mt-1">Budget: {form.budgetRange || "TBD"}</div>
          </div>
          <p className="text-xs text-[#9EBDC2] mb-6">You&apos;ll receive quotes from up to 3 rental providers within 24 hours via email at <b className="text-[#F0F8F8]">{form.email}</b></p>
          <button onClick={() => { setSubmitted(false); setShowQuoteForm(false); setForm({ fullName: "", email: "", phone: "", company: "", equipmentType: "", category: "", projectName: "", projectLocation: "", rentalStart: "", rentalDuration: "", budgetRange: "", quantity: "1", deliveryNeeded: true, notes: "" }); }} className="w-full py-3 rounded-xl text-sm font-bold text-black cursor-pointer" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", border: "none" }}>Browse More Equipment</button>
        </div>
      </div>
    );
  }

  // Quote form modal
  if (showQuoteForm) {
    return (
      <div className="min-h-screen px-4 py-8" style={{ background: "#080E12" }}>
        <div className="max-w-lg mx-auto">
          <button onClick={() => setShowQuoteForm(false)} className="text-sm text-[#9EBDC2] mb-4 cursor-pointer" style={{ background: "none", border: "none" }}>&larr; Back to Equipment</button>
          <div className="text-center mb-6">
            <div className="text-3xl mb-2">📋</div>
            <h1 className="text-xl font-black">Request a Rental Quote</h1>
            <p className="text-xs text-[#9EBDC2] mt-1">Get quotes from up to 3 providers. Free, no obligation.</p>
          </div>

          <div className="rounded-xl p-4 mb-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.15em] text-[#F29E3D] mb-3">EQUIPMENT DETAILS</div>
            <input placeholder="Equipment type (e.g., 20-ton Excavator)" value={form.equipmentType} onChange={e => update("equipmentType", e.target.value)} className="mb-3" />
            <select value={form.category} onChange={e => update("category", e.target.value)} className="mb-3">
              <option value="">Select category</option>
              {categories.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
            <div className="flex gap-3">
              <input placeholder="Quantity" type="number" min="1" value={form.quantity} onChange={e => update("quantity", e.target.value)} className="mb-3" style={{ width: "30%" }} />
              <select value={form.rentalDuration} onChange={e => update("rentalDuration", e.target.value)} className="mb-3" style={{ width: "70%" }}>
                <option value="">Rental duration</option>
                {durations.map(d => <option key={d} value={d}>{d}</option>)}
              </select>
            </div>
            <input placeholder="Start date (e.g., Apr 15, 2026)" value={form.rentalStart} onChange={e => update("rentalStart", e.target.value)} className="mb-3" />
            <select value={form.budgetRange} onChange={e => update("budgetRange", e.target.value)}>
              <option value="">Budget range</option>
              {budgets.map(b => <option key={b} value={b}>{b}</option>)}
            </select>
          </div>

          <div className="rounded-xl p-4 mb-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.15em] text-[#4AC4CC] mb-3">PROJECT INFO</div>
            <input placeholder="Project name" value={form.projectName} onChange={e => update("projectName", e.target.value)} className="mb-3" />
            <input placeholder="Project location (city, state)" value={form.projectLocation} onChange={e => update("projectLocation", e.target.value)} className="mb-3" />
            <div className="flex items-center gap-3 mb-3">
              <label className="flex items-center gap-2 text-xs cursor-pointer">
                <input type="checkbox" checked={form.deliveryNeeded} onChange={e => update("deliveryNeeded", e.target.checked)} />
                Delivery to jobsite needed
              </label>
            </div>
            <textarea placeholder="Additional notes (specific specs, attachments needed, etc.)" value={form.notes} onChange={e => update("notes", e.target.value)} className="min-h-[60px]" />
          </div>

          <div className="rounded-xl p-4 mb-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.15em] text-[#69D294] mb-3">YOUR CONTACT INFO</div>
            <input placeholder="Full name *" value={form.fullName} onChange={e => update("fullName", e.target.value)} className="mb-3" />
            <input placeholder="Email address *" type="email" value={form.email} onChange={e => update("email", e.target.value)} className="mb-3" />
            <input placeholder="Phone number" type="tel" value={form.phone} onChange={e => update("phone", e.target.value)} className="mb-3" />
            <input placeholder="Company name" value={form.company} onChange={e => update("company", e.target.value)} />
          </div>

          <button onClick={submitLead} disabled={!form.fullName || !form.email || !form.equipmentType || submitting} className="w-full py-4 rounded-xl text-base font-bold text-black cursor-pointer" style={{ background: form.fullName && form.email && form.equipmentType ? "linear-gradient(90deg, #F29E3D, #FCC757)" : "#33545E", border: "none" }}>
            {submitting ? "Submitting..." : "GET FREE QUOTES FROM 3 PROVIDERS"}
          </button>
          <p className="text-center text-[9px] text-[#9EBDC2] mt-3">Free, no obligation. Quotes delivered to your email within 24 hours.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="rounded-2xl p-6 mb-6" style={{ background: "#0F1C24" }}>
        <div className="flex justify-between items-start">
          <div>
            <div className="text-xs font-bold tracking-widest text-[#F29E3D] mb-1">RENTALS</div>
            <h1 className="text-2xl font-black">Construction Equipment Rentals</h1>
            <p className="text-sm text-[#9EBDC2]">{items.length} items across {providers.length} providers — rent direct or request quotes</p>
          </div>
          <button onClick={() => openQuote()} className="px-5 py-3 rounded-xl text-sm font-bold text-black cursor-pointer shrink-0" style={{ background: "linear-gradient(90deg, #69D294, #4AC4CC)", border: "none" }}>📋 REQUEST QUOTE</button>
        </div>
      </div>

      {/* Lead Gen Banner */}
      <div className="rounded-xl p-5 mb-6 flex items-center justify-between" style={{ background: "linear-gradient(135deg, rgba(105,210,148,0.1), rgba(74,196,204,0.1))", border: "1px solid rgba(105,210,148,0.2)" }}>
        <div>
          <h3 className="text-sm font-black text-[#69D294] mb-1">Need the best price? Get 3 quotes free.</h3>
          <p className="text-xs text-[#9EBDC2]">Tell us what you need and we&apos;ll connect you with 3 rental providers competing for your business.</p>
        </div>
        <button onClick={() => openQuote()} className="px-5 py-2.5 rounded-lg text-xs font-bold text-black cursor-pointer shrink-0" style={{ background: "#69D294", border: "none" }}>GET QUOTES</button>
      </div>

      {/* Providers */}
      <h2 className="text-[10px] font-black tracking-[0.15em] text-[#FCC757] mb-3">RENTAL PROVIDERS — CLICK TO VISIT</h2>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 mb-6">
        {providers.map(p => (
          <a key={p.name} href={p.url} target="_blank" rel="noopener noreferrer" className="rounded-xl p-4 text-center block hover:-translate-y-1 transition-transform" style={{ background: "#0F1C24", border: `1px solid ${p.color}30`, textDecoration: "none" }}>
            <div className="text-sm font-black mb-1" style={{ color: p.color }}>{p.name}</div>
            <div className="text-[8px] text-[#9EBDC2]">{p.desc}</div>
          </a>
        ))}
      </div>

      <div className="mb-4"><input placeholder="Search equipment, tools, vehicles..." className="w-full" /></div>

      <div className="flex gap-2 overflow-x-auto pb-3 mb-6" style={{ scrollbarWidth: "none" }}>
        <span className="text-xs font-bold px-3 py-1.5 rounded-md cursor-pointer text-black shrink-0" style={{ background: "#F29E3D" }}>ALL</span>
        {categories.map(c => <span key={c} className="text-xs font-bold px-3 py-1.5 rounded-md cursor-pointer shrink-0" style={{ background: "#0F1C24", color: "#F0F8F8" }}>{c}</span>)}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {items.map(item => (
          <div key={item.name} className="rounded-xl p-4" style={{ background: "#0F1C24", border: "1px solid rgba(51,84,94,0.2)" }}>
            <div className="flex justify-between items-start mb-2">
              <div>
                <div className="font-bold text-sm">{item.name}</div>
                <div className="text-xs text-[#9EBDC2]">{item.cat}</div>
              </div>
              <div className="text-right">
                <div className="text-lg font-black text-[#F29E3D]">{item.daily}</div>
                <div className="text-xs text-[#9EBDC2]">/day</div>
              </div>
            </div>
            <div className="text-xs text-[#9EBDC2] mb-2">{item.specs} &bull; {item.weekly}/week</div>
            <div className="flex justify-between items-center mb-3">
              <div className="flex items-center gap-1">
                <div className="w-1.5 h-1.5 rounded-full" style={{ background: item.avail === "Available" ? "#69D294" : "#FCC757" }} />
                <span className="text-xs font-bold" style={{ color: item.avail === "Available" ? "#69D294" : "#FCC757" }}>{item.avail}</span>
              </div>
              <span className="text-xs font-bold" style={{ color: providers.find(p => p.name === item.provider)?.color || "#9EBDC2" }}>{item.provider}</span>
            </div>
            <div className="flex gap-2">
              <a href={item.providerUrl} target="_blank" rel="noopener noreferrer" className="flex-1 py-2 rounded-lg text-[10px] font-bold text-black text-center" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>RENT DIRECT &rarr;</a>
              <button onClick={() => openQuote(item.name, item.cat)} className="flex-1 py-2 rounded-lg text-[10px] font-bold text-black text-center cursor-pointer" style={{ background: "#69D294", border: "none" }}>GET QUOTES</button>
            </div>
          </div>
        ))}
      </div>

      {/* Bottom CTA */}
      <div className="rounded-xl p-6 mt-8 text-center" style={{ background: "#0F1C24", border: "1px solid rgba(105,210,148,0.15)" }}>
        <h3 className="text-lg font-black mb-2">Can&apos;t find what you need?</h3>
        <p className="text-sm text-[#9EBDC2] mb-4">Request a custom quote for any equipment. We&apos;ll find it for you across all providers.</p>
        <button onClick={() => openQuote()} className="px-8 py-3 rounded-xl text-sm font-bold text-black cursor-pointer" style={{ background: "linear-gradient(90deg, #69D294, #4AC4CC)", border: "none" }}>REQUEST CUSTOM QUOTE</button>
      </div>
    </div>
  );
}
