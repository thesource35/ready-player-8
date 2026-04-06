"use client";
import Link from "next/link";
import { useState } from "react";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function ProfilePage() {
  const [form, setForm] = useState({
    fullName: "Donovan Fagan", email: "admin@constructionos.world", phone: "(713) 555-0100",
    company: "ConstructionOS", title: "Founder & CEO", trade: "General",
    location: "Houston, TX", bio: "Building the operating system for the $13 trillion construction industry.",
    experience: "15", licenseNumber: "", licenseState: "TX",
  });
  const [saved, setSaved] = useState(false);

  const update = (key: string, value: string) => { setForm(prev => ({ ...prev, [key]: value })); setSaved(false); };

  const [validationError, setValidationError] = useState<string | null>(null);

  const handleSave = () => {
    // Validate required fields
    if (!form.fullName.trim()) { setValidationError("Full name is required"); return; }
    if (!form.email.trim() || !EMAIL_REGEX.test(form.email.trim())) { setValidationError("Please enter a valid email address"); return; }
    if (!form.trade.trim()) { setValidationError("Trade is required"); return; }
    setValidationError(null);
    // In production: save to Supabase cs_user_profiles
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div style={{ padding: 20, maxWidth: 600, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 20, textAlign: "center" }}>
        <div style={{ width: 80, height: 80, borderRadius: "50%", background: "linear-gradient(135deg, var(--accent), var(--gold))", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 32, fontWeight: 900, color: "var(--bg)", margin: "0 auto 12px" }}>
          {form.fullName.split(" ").map(n => n[0]).join("").toUpperCase()}
        </div>
        <h1 style={{ fontSize: 20, fontWeight: 900, margin: "0 0 4px" }}>{form.fullName}</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>{form.title} at {form.company}</p>
        <p style={{ fontSize: 11, color: "var(--cyan)" }}>{form.trade} &bull; {form.location} &bull; {form.experience} yrs</p>
      </div>

      {saved && (
        <div style={{ background: "rgba(105,210,148,0.1)", border: "1px solid rgba(105,210,148,0.2)", borderRadius: 10, padding: 12, marginBottom: 16, textAlign: "center", fontSize: 12, fontWeight: 700, color: "var(--green)" }}>Profile saved successfully</div>
      )}

      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16 }}>
        <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 12 }}>PERSONAL INFO</div>
        <label htmlFor="profile-fullname" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Full name</label>
        <input id="profile-fullname" placeholder="Full name" value={form.fullName} onChange={e => update("fullName", e.target.value)} maxLength={200} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-email" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Email</label>
        <input id="profile-email" placeholder="Email" type="email" value={form.email} onChange={e => update("email", e.target.value)} maxLength={254} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-phone" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Phone</label>
        <input id="profile-phone" placeholder="Phone" value={form.phone} onChange={e => update("phone", e.target.value)} maxLength={20} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-location" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Location</label>
        <input id="profile-location" placeholder="Location" value={form.location} onChange={e => update("location", e.target.value)} maxLength={200} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-bio" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Bio</label>
        <textarea id="profile-bio" placeholder="Bio" value={form.bio} onChange={e => update("bio", e.target.value)} maxLength={1000} style={{ marginBottom: 10, minHeight: 60 }} />
      </div>

      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16 }}>
        <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 12 }}>PROFESSIONAL INFO</div>
        <label htmlFor="profile-company" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Company name</label>
        <input id="profile-company" placeholder="Company name" value={form.company} onChange={e => update("company", e.target.value)} maxLength={200} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-title" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Job title</label>
        <input id="profile-title" placeholder="Job title" value={form.title} onChange={e => update("title", e.target.value)} maxLength={100} style={{ marginBottom: 10 }} />
        <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 10 }}>
          {["General","Electrical","Concrete","Steel","Plumbing","HVAC","Roofing","Solar","Fiber","Crane"].map(t => (
            <span key={t} onClick={() => update("trade", t)} style={{ fontSize: 10, fontWeight: 700, padding: "5px 10px", borderRadius: 6, background: form.trade === t ? "var(--accent)" : "var(--panel)", color: form.trade === t ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{t}</span>
          ))}
        </div>
        <label htmlFor="profile-experience" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Years of experience</label>
        <input id="profile-experience" placeholder="Years of experience" value={form.experience} onChange={e => update("experience", e.target.value)} maxLength={3} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-license" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>License number</label>
        <input id="profile-license" placeholder="License number (optional)" value={form.licenseNumber} onChange={e => update("licenseNumber", e.target.value)} maxLength={50} style={{ marginBottom: 10 }} />
        <label htmlFor="profile-license-state" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>License state</label>
        <input id="profile-license-state" placeholder="License state" value={form.licenseState} onChange={e => update("licenseState", e.target.value)} maxLength={10} />
      </div>

      <button onClick={handleSave} style={{ width: "100%", padding: "14px 0", borderRadius: 12, fontSize: 14, fontWeight: 800, color: "var(--bg)", background: "linear-gradient(90deg, var(--accent), var(--gold))", border: "none", cursor: "pointer" }}>SAVE PROFILE</button>

      <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
        <Link href="/verify" style={{ flex: 1, textAlign: "center", padding: 12, borderRadius: 10, fontSize: 11, fontWeight: 700, color: "var(--gold)", border: "1px solid var(--gold)", textDecoration: "none" }}>Get Verified</Link>
        <Link href="/settings" style={{ flex: 1, textAlign: "center", padding: 12, borderRadius: 10, fontSize: 11, fontWeight: 700, color: "var(--muted)", border: "1px solid var(--border)", textDecoration: "none" }}>Settings</Link>
      </div>
    </div>
  );
}
