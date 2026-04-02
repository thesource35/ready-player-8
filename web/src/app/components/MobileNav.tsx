"use client";
import { useState } from "react";
import { usePathname } from "next/navigation";

const navGroups = [
  { label: "CORE", color: "#F29E3D", links: [
    { href: "/projects", label: "Projects", icon: "🏗" }, { href: "/contracts", label: "Contracts", icon: "📋" },
    { href: "/market", label: "Market", icon: "📊" }, { href: "/maps", label: "Maps", icon: "🗺" },
    { href: "/feed", label: "Network", icon: "👥" },
  ]},
  { label: "INTEL", color: "#4AC4CC", links: [
    { href: "/ops", label: "Ops Center", icon: "⚙️" }, { href: "/hub", label: "Hub", icon: "🔌" },
    { href: "/security", label: "Security", icon: "🔐" }, { href: "/pricing", label: "Pricing", icon: "💲" },
    { href: "/ai", label: "Angelic AI", icon: "👼" },
  ]},
  { label: "FIELD", color: "#69D294", links: [
    { href: "/field", label: "Field Ops", icon: "📱" }, { href: "/finance", label: "Finance", icon: "💵" },
    { href: "/compliance", label: "Compliance", icon: "🛡" }, { href: "/clients", label: "Clients", icon: "👤" },
    { href: "/analytics", label: "Analytics", icon: "📈" },
  ]},
  { label: "PLAN", color: "#8A8FCC", links: [
    { href: "/schedule", label: "Schedule", icon: "📅" }, { href: "/training", label: "Training", icon: "🎓" },
    { href: "/scanner", label: "Scanner", icon: "📷" },
  ]},
  { label: "TRADE", color: "#FCC757", links: [
    { href: "/electrical", label: "Electrical", icon: "⚡" }, { href: "/tax", label: "Tax", icon: "💰" },
  ]},
  { label: "BUILD", color: "#D94D48", links: [
    { href: "/punch", label: "Punch List", icon: "✅" }, { href: "/roofing", label: "Roofing", icon: "🏠" },
    { href: "/smart-build", label: "Smart Build", icon: "🧪" }, { href: "/contractors", label: "Directory", icon: "📖" },
    { href: "/tech", label: "Tech 2026", icon: "🤖" },
  ]},
  { label: "WEALTH", color: "#FCC757", links: [
    { href: "/wealth", label: "Wealth", icon: "💎" }, { href: "/cos-network", label: "COS Net", icon: "🌐" },
    { href: "/rentals", label: "Rentals", icon: "🛠" },
  ]},
  { label: "EMPIRE", color: "#F29E3D", links: [
    { href: "/empire", label: "Empire", icon: "🏦" },
    { href: "/settings", label: "Settings", icon: "⚙️" },
  ]},
];

export default function MobileNav() {
  const [isOpen, setIsOpen] = useState(false);
  const pathname = usePathname();

  return (
    <>
      {/* Hamburger button — only visible on mobile */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="lg:hidden flex flex-col gap-1.5 p-2"
        style={{ background: "none", border: "none", cursor: "pointer" }}
        aria-label="Menu"
      >
        <span style={{ width: 20, height: 2, background: isOpen ? "#F29E3D" : "#9EBDC2", borderRadius: 1, transition: "0.2s", transform: isOpen ? "rotate(45deg) translate(4px, 4px)" : "none" }} />
        <span style={{ width: 20, height: 2, background: "#9EBDC2", borderRadius: 1, transition: "0.2s", opacity: isOpen ? 0 : 1 }} />
        <span style={{ width: 20, height: 2, background: isOpen ? "#F29E3D" : "#9EBDC2", borderRadius: 1, transition: "0.2s", transform: isOpen ? "rotate(-45deg) translate(4px, -4px)" : "none" }} />
      </button>

      {/* Mobile menu overlay */}
      {isOpen && (
        <div
          style={{
            position: "fixed", top: 52, left: 0, right: 0, bottom: 0, zIndex: 49,
            background: "rgba(8,14,18,0.98)", backdropFilter: "blur(20px)",
            overflowY: "auto", padding: "16px 20px",
          }}
        >
          {/* Quick links */}
          <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
            <a href="/login" onClick={() => setIsOpen(false)} style={{ flex: 1, padding: "10px 0", borderRadius: 10, textAlign: "center", fontSize: 12, fontWeight: 800, color: "#F29E3D", border: "1px solid rgba(242,158,61,0.3)", textDecoration: "none" }}>Sign In</a>
            <a href="/login" onClick={() => setIsOpen(false)} style={{ flex: 1, padding: "10px 0", borderRadius: 10, textAlign: "center", fontSize: 12, fontWeight: 800, color: "#080E12", background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>Get Started</a>
          </div>

          {/* Nav groups */}
          {navGroups.map(g => (
            <div key={g.label} style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 9, fontWeight: 900, letterSpacing: 3, color: g.color, marginBottom: 8, paddingLeft: 4 }}>{g.label}</div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
                {g.links.map(l => (
                  <a
                    key={l.href}
                    href={l.href}
                    onClick={() => setIsOpen(false)}
                    style={{
                      display: "flex", alignItems: "center", gap: 8,
                      padding: "10px 12px", borderRadius: 10,
                      background: pathname === l.href ? "rgba(242,158,61,0.1)" : "#0F1C24",
                      border: pathname === l.href ? "1px solid rgba(242,158,61,0.3)" : "1px solid rgba(51,84,94,0.15)",
                      textDecoration: "none", color: pathname === l.href ? "#F29E3D" : "#F0F8F8",
                    }}
                  >
                    <span style={{ fontSize: 16 }}>{l.icon}</span>
                    <span style={{ fontSize: 11, fontWeight: 700 }}>{l.label}</span>
                  </a>
                ))}
              </div>
            </div>
          ))}

          {/* Bottom links */}
          <div style={{ display: "flex", gap: 12, justifyContent: "center", paddingTop: 12, borderTop: "1px solid rgba(51,84,94,0.2)" }}>
            {[
              { href: "/verify", label: "Get Verified" },
              { href: "/terms", label: "Terms" },
              { href: "/privacy", label: "Privacy" },
            ].map(l => (
              <a key={l.href} href={l.href} onClick={() => setIsOpen(false)} style={{ fontSize: 10, color: "#9EBDC2", textDecoration: "none" }}>{l.label}</a>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
