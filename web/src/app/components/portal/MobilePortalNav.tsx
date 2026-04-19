"use client";

/**
 * MobilePortalNav: Fixed bottom navigation bar for mobile portal viewing (D-2).
 * Visible only below 640px (md:hidden). Supports smooth scrolling and swipe gestures.
 * Section icons: Calendar, DollarSign, Camera, FileEdit, File (Lucide-style inline SVGs).
 */

import { useState, useEffect, useCallback, useRef } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { PortalSectionKey } from "@/lib/portal/types";

type MobilePortalNavProps = {
  sections: { key: PortalSectionKey; label: string; enabled: boolean }[];
  showMapLink: boolean;  // Phase 27 D-19 — when true, renders the 6th MapPin icon
};

// D-25 (Phase 27): MapPin Lucide-style inline SVG, 20×20 stroke-2, matches SECTION_ICONS pattern.
const MAP_PIN_ICON: React.ReactNode = (
  <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
    <circle cx={12} cy={10} r={3} />
  </svg>
);

// Section icon SVGs (Lucide-style, inline to avoid dependency)
const SECTION_ICONS: Record<PortalSectionKey, React.ReactNode> = {
  schedule: (
    <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
      <rect x={3} y={4} width={18} height={18} rx={2} ry={2} />
      <line x1={16} y1={2} x2={16} y2={6} />
      <line x1={8} y1={2} x2={8} y2={6} />
      <line x1={3} y1={10} x2={21} y2={10} />
    </svg>
  ),
  budget: (
    <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
      <line x1={12} y1={1} x2={12} y2={23} />
      <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
    </svg>
  ),
  photos: (
    <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
      <circle cx={12} cy={13} r={4} />
    </svg>
  ),
  change_orders: (
    <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 20h9" />
      <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
    </svg>
  ),
  documents: (
    <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1={16} y1={13} x2={8} y2={13} />
      <line x1={16} y1={17} x2={8} y2={17} />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  ),
};

export default function MobilePortalNav({ sections, showMapLink }: MobilePortalNavProps) {
  const pathname = usePathname() ?? "";
  const isOnMap = pathname.endsWith("/map");
  const enabledSections = sections.filter((s) => s.enabled);
  const [activeSection, setActiveSection] = useState<PortalSectionKey | null>(
    enabledSections[0]?.key ?? null,
  );
  const touchStartRef = useRef<{ x: number; y: number } | null>(null);

  // Smooth scroll to section anchor
  const scrollToSection = useCallback((key: PortalSectionKey) => {
    const el = document.getElementById(`section-${key}`);
    if (el) {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
      setActiveSection(key);
    }
  }, []);

  // Track active section on scroll via IntersectionObserver
  useEffect(() => {
    if (enabledSections.length === 0) return;

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            const key = entry.target.id.replace("section-", "") as PortalSectionKey;
            setActiveSection(key);
          }
        }
      },
      { rootMargin: "-40% 0px -40% 0px", threshold: 0 },
    );

    for (const section of enabledSections) {
      const el = document.getElementById(`section-${section.key}`);
      if (el) observer.observe(el);
    }

    return () => observer.disconnect();
  }, [enabledSections]);

  // Swipe detection: navigate to prev/next section
  useEffect(() => {
    const handleTouchStart = (e: TouchEvent) => {
      const touch = e.touches[0];
      touchStartRef.current = { x: touch.clientX, y: touch.clientY };
    };

    const handleTouchEnd = (e: TouchEvent) => {
      if (!touchStartRef.current) return;
      const touch = e.changedTouches[0];
      const dx = touch.clientX - touchStartRef.current.x;
      const dy = touch.clientY - touchStartRef.current.y;
      touchStartRef.current = null;

      // Only trigger on horizontal swipes (|dx| > 60 and |dx| > |dy|)
      if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy)) return;

      const currentIdx = enabledSections.findIndex(
        (s) => s.key === activeSection,
      );
      if (currentIdx === -1) return;

      if (dx < 0 && currentIdx < enabledSections.length - 1) {
        // Swipe left -> next section
        scrollToSection(enabledSections[currentIdx + 1].key);
      } else if (dx > 0 && currentIdx > 0) {
        // Swipe right -> previous section
        scrollToSection(enabledSections[currentIdx - 1].key);
      }
    };

    document.addEventListener("touchstart", handleTouchStart, { passive: true });
    document.addEventListener("touchend", handleTouchEnd, { passive: true });

    return () => {
      document.removeEventListener("touchstart", handleTouchStart);
      document.removeEventListener("touchend", handleTouchEnd);
    };
  }, [activeSection, enabledSections, scrollToSection]);

  if (enabledSections.length === 0 && !showMapLink) return null;

  return (
    <nav
      aria-label="Portal section navigation"
      className="md:hidden"
      style={{
        position: "fixed",
        bottom: 0,
        left: 0,
        right: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-around",
        height: 56,
        background: "var(--portal-card-bg, #FFFFFF)",
        borderTop: "1px solid #E2E5E9",
        zIndex: 50,
        paddingBottom: "env(safe-area-inset-bottom, 0px)",
      }}
    >
      {enabledSections.map((section) => {
        const isActive = activeSection === section.key;
        return (
          <button
            key={section.key}
            onClick={() => scrollToSection(section.key)}
            aria-label={`Navigate to ${section.label}`}
            aria-current={isActive ? "true" : undefined}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 2,
              padding: "6px 8px",
              minWidth: 56,
              background: "transparent",
              border: "none",
              cursor: "pointer",
              color: isActive
                ? "var(--portal-primary, #2563EB)"
                : "#9CA3AF",
              transition: "color 200ms ease-in-out",
            }}
          >
            {SECTION_ICONS[section.key]}
            <span
              style={{
                fontSize: 10,
                fontWeight: isActive ? 600 : 400,
                lineHeight: 1,
              }}
            >
              {section.label}
            </span>
          </button>
        );
      })}
      {/* D-16, D-17, D-25 (Phase 27): 6th MapPin entry — Link, not scroll button.
          Active state when on /map per D-17. */}
      {showMapLink && (
        <Link
          key="map"
          href="./map"
          prefetch={true}
          aria-label="Navigate to Map"
          aria-current={isOnMap ? "page" : undefined}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 2,
            padding: "6px 8px",
            minWidth: 56,
            background: "transparent",
            border: "none",
            textDecoration: "none",
            color: isOnMap
              ? "var(--portal-primary, #2563EB)"
              : "#9CA3AF",
            transition: "color 200ms ease-in-out",
          }}
        >
          {MAP_PIN_ICON}
          <span
            style={{
              fontSize: 10,
              fontWeight: isOnMap ? 600 : 400,
              lineHeight: 1,
            }}
          >
            Map
          </span>
        </Link>
      )}
    </nav>
  );
}
