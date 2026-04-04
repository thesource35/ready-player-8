"use client";
import { useState, useRef, useEffect } from "react";
import { usePathname } from "next/navigation";
import Link from "next/link";
import { navGroups } from "@/lib/nav";

export default function MobileNav() {
  const [isOpen, setIsOpen] = useState(false);
  const pathname = usePathname();
  const menuRef = useRef<HTMLDivElement>(null);
  const loginHref = `/login?redirect=${encodeURIComponent(pathname || "/")}`;

  // Close menu when clicking outside
  useEffect(() => {
    if (!isOpen) return;
    function handleClick(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [isOpen]);

  // Close on route change
  useEffect(() => { setIsOpen(false); }, [pathname]);

  return (
    <div ref={menuRef} style={{ position: "relative", flexShrink: 0 }}>
      {/* Hamburger button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        style={{ background: "none", border: "none", cursor: "pointer", padding: 8, display: "flex", flexDirection: "column", gap: 5 }}
        aria-label="Menu"
      >
        <span style={{ width: 20, height: 2, background: isOpen ? "#F29E3D" : "#9EBDC2", borderRadius: 1, transition: "0.2s", transform: isOpen ? "rotate(45deg) translate(4px, 4px)" : "none" }} />
        <span style={{ width: 20, height: 2, background: "#9EBDC2", borderRadius: 1, transition: "0.2s", opacity: isOpen ? 0 : 1 }} />
        <span style={{ width: 20, height: 2, background: isOpen ? "#F29E3D" : "#9EBDC2", borderRadius: 1, transition: "0.2s", transform: isOpen ? "rotate(-45deg) translate(4px, -4px)" : "none" }} />
      </button>

      {/* Dropdown menu — anchored to the button */}
      {isOpen && (
        <div
          style={{
            position: "absolute",
            top: 44,
            right: 0,
            width: 280,
            maxHeight: "80vh",
            overflowY: "auto",
            background: "#0F1C24",
            border: "1px solid rgba(51,84,94,0.4)",
            borderRadius: 14,
            padding: 12,
            boxShadow: "0 12px 40px rgba(0,0,0,0.6)",
            zIndex: 9999,
          }}
        >
          {/* Sign in buttons */}
          <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
            <Link href={loginHref} onClick={() => setIsOpen(false)} style={{ flex: 1, padding: "8px 0", borderRadius: 8, textAlign: "center", fontSize: 11, fontWeight: 800, color: "#F29E3D", border: "1px solid rgba(242,158,61,0.3)", textDecoration: "none" }}>Sign In</Link>
            <Link href={loginHref} onClick={() => setIsOpen(false)} style={{ flex: 1, padding: "8px 0", borderRadius: 8, textAlign: "center", fontSize: 11, fontWeight: 800, color: "#080E12", background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>Get Started</Link>
          </div>

          {/* Nav groups */}
          {navGroups.map(g => (
            <div key={g.label} style={{ marginBottom: 10 }}>
              <div style={{ fontSize: 8, fontWeight: 900, letterSpacing: 3, color: g.color, marginBottom: 6, paddingLeft: 2 }}>{g.label}</div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 4 }}>
                {g.links.map(l => (
                  <Link
                    key={l.href}
                    href={l.href}
                    onClick={() => setIsOpen(false)}
                    style={{
                      display: "flex", alignItems: "center", gap: 6,
                      padding: "7px 8px", borderRadius: 8,
                      background: pathname === l.href ? "rgba(242,158,61,0.15)" : "#162832",
                      textDecoration: "none",
                      color: pathname === l.href ? "#F29E3D" : "#F0F8F8",
                    }}
                  >
                    <span style={{ fontSize: 13 }}>{l.icon}</span>
                    <span style={{ fontSize: 10, fontWeight: 700 }}>{l.label}</span>
                  </Link>
                ))}
              </div>
            </div>
          ))}

          {/* Footer links */}
          <div style={{ display: "flex", gap: 10, justifyContent: "center", paddingTop: 8, borderTop: "1px solid rgba(51,84,94,0.2)" }}>
            {[
              { href: "/verify", label: "Verify" },
              { href: "/terms", label: "Terms" },
              { href: "/privacy", label: "Privacy" },
            ].map(l => (
              <Link key={l.href} href={l.href} onClick={() => setIsOpen(false)} style={{ fontSize: 9, color: "#9EBDC2", textDecoration: "none" }}>{l.label}</Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
