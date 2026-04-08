"use client";

import { useEffect, useState } from "react";
import { createBrowserClient } from "@supabase/ssr";

export default function SettingsPage() {
  const [userEmail, setUserEmail] = useState("");
  const [userName, setUserName] = useState("");

  useEffect(() => {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!url || !key) {
      setUserName("Demo User");
      setUserEmail("demo@constructionos.local");
      return;
    }
    const supabase = createBrowserClient(url, key);
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) {
        setUserEmail(user.email || "");
        setUserName(user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split("@")[0] || "User");
      } else {
        setUserName("Demo User");
        setUserEmail("demo@constructionos.local");
      }
    });
  }, []);

  const displayName = userName || "Loading...";
  const displayEmail = userEmail || "Loading...";
  const avatarInitial = (userName || "U")[0].toUpperCase();

  const roles = [
    { id: "SUPER", name: "Superintendent", icon: "\u{1F3D7}", desc: "Field-focused dashboards, daily logs, crew management" },
    { id: "PM", name: "Project Manager", icon: "\u{1F4CB}", desc: "RFIs, submittals, change orders, schedules, budgets" },
    { id: "EXEC", name: "Executive", icon: "\u{1F4CA}", desc: "P&L dashboards, pipeline analytics, risk scoring" },
  ];

  const subscriptionTiers = [
    { name: "Field Worker", price: "$9.99/mo", features: ["Daily logs", "Timecards", "Safety reports", "Basic AI"], current: false },
    { name: "Project Manager", price: "$27.99/mo", features: ["All Field features", "RFIs & Submittals", "Scheduling", "Full AI access", "Analytics"], current: true },
    { name: "Company Owner", price: "$49.99/mo", features: ["All PM features", "Financial Empire", "Multi-project", "API access", "Priority support", "Custom branding"], current: false },
  ];

  const integrations = [
    { name: "Supabase", status: "CONNECTED", desc: "Database & real-time sync" },
    { name: "Anthropic AI", status: "CONFIGURED", desc: "Claude AI for Angelic AI" },
    { name: "Mapbox", status: "NOT SET", desc: "Maps & satellite imagery" },
    { name: "Stripe", status: "NOT SET", desc: "Payment processing" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      {/* Profile Header */}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, display: "flex", gap: 16, alignItems: "center", border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg, var(--accent), var(--gold))", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24, fontWeight: 900, color: "var(--bg)" }}>{avatarInitial}</div>
        <div>
          <h1 style={{ fontSize: 18, fontWeight: 800, margin: 0 }}>{displayName}</h1>
          <p style={{ fontSize: 11, color: "var(--muted)", margin: "2px 0" }}>{displayEmail}</p>
          <div style={{ display: "flex", gap: 6, marginTop: 4 }}>
            <span style={{ fontSize: 8, fontWeight: 900, color: "var(--bg)", background: "var(--accent)", padding: "2px 8px", borderRadius: 3 }}>PROJECT MANAGER</span>
            <span style={{ fontSize: 8, fontWeight: 800, color: "var(--green)" }}>SUPABASE LINKED</span>
          </div>
        </div>
      </div>

      {/* Role Preset */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>ROLE PRESET</h2>
      <p style={{ fontSize: 10, color: "var(--muted)", marginBottom: 10 }}>Changes how dashboards, reports, and risk scores are presented</p>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 20 }}>
        {roles.map(r => (
          <div key={r.id} style={{ background: r.id === "PM" ? "var(--cyan)" : "var(--surface)", borderRadius: 10, padding: 14, textAlign: "center", cursor: "pointer" }}>
            <div style={{ fontSize: 28, marginBottom: 4 }}>{r.icon}</div>
            <div style={{ fontSize: 12, fontWeight: 800, color: r.id === "PM" ? "var(--bg)" : "var(--text)" }}>{r.name}</div>
            <div style={{ fontSize: 9, color: r.id === "PM" ? "rgba(0,0,0,0.6)" : "var(--muted)", marginTop: 4 }}>{r.desc}</div>
          </div>
        ))}
      </div>

      {/* Security */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>SECURITY</h2>
      <div style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <div style={{ fontSize: 12, fontWeight: 700 }}>Require Face ID / Touch ID</div>
          <div style={{ fontSize: 9, color: "var(--muted)" }}>Biometric lock when app opens</div>
        </div>
        <div style={{ width: 40, height: 22, borderRadius: 11, background: "var(--green)", position: "relative", cursor: "pointer" }}>
          <div style={{ width: 18, height: 18, borderRadius: "50%", background: "white", position: "absolute", top: 2, right: 2 }} />
        </div>
      </div>
      <div style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <div style={{ fontSize: 12, fontWeight: 700 }}>Two-Factor Authentication</div>
          <div style={{ fontSize: 9, color: "var(--muted)" }}>Authenticator app as primary</div>
        </div>
        <div style={{ width: 40, height: 22, borderRadius: 11, background: "var(--green)", position: "relative", cursor: "pointer" }}>
          <div style={{ width: 18, height: 18, borderRadius: "50%", background: "white", position: "absolute", top: 2, right: 2 }} />
        </div>
      </div>

      {/* Subscription */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10, marginTop: 20 }}>SUBSCRIPTION</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 20 }}>
        {subscriptionTiers.map(t => (
          <div key={t.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: t.current ? "2px solid var(--accent)" : "1px solid rgba(51,84,94,0.2)" }}>
            {t.current && <div style={{ fontSize: 8, fontWeight: 900, color: "var(--accent)", marginBottom: 6 }}>CURRENT PLAN</div>}
            <h3 style={{ fontSize: 14, fontWeight: 800, margin: "0 0 4px" }}>{t.name}</h3>
            <div style={{ fontSize: 18, fontWeight: 900, color: "var(--accent)", marginBottom: 10 }}>{t.price}</div>
            {t.features.map(f => (
              <div key={f} style={{ fontSize: 9, color: "var(--muted)", padding: "2px 0" }}>{"\u2713"} {f}</div>
            ))}
          </div>
        ))}
      </div>

      {/* Integrations Summary */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--purple)", marginBottom: 10 }}>INTEGRATIONS</h2>
      {integrations.map(i => (
        <div key={i.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <span style={{ fontSize: 11, fontWeight: 800 }}>{i.name}</span>
            <span style={{ fontSize: 9, color: "var(--muted)", marginLeft: 8 }}>{i.desc}</span>
          </div>
          <span role="status" aria-label={`Status: ${i.status}`} style={{ fontSize: 8, fontWeight: 900, color: i.status === "CONNECTED" || i.status === "CONFIGURED" ? "var(--green)" : "var(--muted)" }}>{i.status}</span>
        </div>
      ))}

      {/* Danger Zone */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--red)", marginBottom: 10, marginTop: 20 }}>DANGER ZONE</h2>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
        <a href="/api/export" style={{ background: "var(--surface)", color: "var(--gold)", border: "1px solid var(--gold)", borderRadius: 8, padding: "8px 16px", fontSize: 10, fontWeight: 800, cursor: "pointer", textDecoration: "none" }}>Export All Data</a>
        <a href="/profile" style={{ background: "var(--surface)", color: "var(--cyan)", border: "1px solid var(--cyan)", borderRadius: 8, padding: "8px 16px", fontSize: 10, fontWeight: 800, cursor: "pointer", textDecoration: "none" }}>Edit Profile</a>
        <a href="/login" style={{ background: "var(--surface)", color: "var(--red)", border: "1px solid var(--red)", borderRadius: 8, padding: "8px 16px", fontSize: 10, fontWeight: 800, cursor: "pointer", textDecoration: "none" }}>Sign Out</a>
      </div>
    </div>
  );
}
