"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import {
  REPORT_THEMES,
  DEFAULT_THEME,
  applyThemeToElement,
  getTheme,
  type ReportTheme,
} from "@/lib/reports/report-themes";

// ---------- Types ----------

type ReportThemeSwitcherProps = {
  /** Ref to the report container element to apply theme CSS vars on */
  containerRef?: React.RefObject<HTMLElement | null>;
  /** Callback when theme changes */
  onThemeChange?: (themeKey: string, theme: ReportTheme) => void;
  /** Optional company logo URL for white-labeling (D-107) */
  logoUrl?: string;
  /** Optional company name for white-labeling (D-107) */
  companyName?: string;
};

// ---------- Constants ----------

const STORAGE_KEY = "constructos-report-theme";

const themeKeys = Object.keys(REPORT_THEMES);

// ---------- Component ----------

export function ReportThemeSwitcher({
  containerRef,
  onThemeChange,
  logoUrl,
  companyName,
}: ReportThemeSwitcherProps) {
  const [open, setOpen] = useState(false);
  const [activeTheme, setActiveTheme] = useState<string>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem(STORAGE_KEY) ?? DEFAULT_THEME;
    }
    return DEFAULT_THEME;
  });
  const [previewTheme, setPreviewTheme] = useState<string | null>(null);
  const popoverRef = useRef<HTMLDivElement>(null);

  // Apply theme on mount and change
  useEffect(() => {
    if (containerRef?.current) {
      const theme = getTheme(activeTheme);
      applyThemeToElement(containerRef.current, theme);
    }
  }, [activeTheme, containerRef]);

  // Close popover on outside click
  useEffect(() => {
    if (!open) return;
    function handleClick(e: MouseEvent) {
      if (popoverRef.current && !popoverRef.current.contains(e.target as Node)) {
        setOpen(false);
        setPreviewTheme(null);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  const selectTheme = useCallback(
    (key: string) => {
      setActiveTheme(key);
      setPreviewTheme(null);
      setOpen(false);
      localStorage.setItem(STORAGE_KEY, key);
      const theme = getTheme(key);
      if (containerRef?.current) {
        applyThemeToElement(containerRef.current, theme);
      }
      onThemeChange?.(key, theme);
    },
    [containerRef, onThemeChange]
  );

  // Preview on hover
  const handlePreview = useCallback(
    (key: string) => {
      setPreviewTheme(key);
      if (containerRef?.current) {
        applyThemeToElement(containerRef.current, getTheme(key));
      }
    },
    [containerRef]
  );

  const handlePreviewEnd = useCallback(() => {
    setPreviewTheme(null);
    if (containerRef?.current) {
      applyThemeToElement(containerRef.current, getTheme(activeTheme));
    }
  }, [containerRef, activeTheme]);

  const displayKey = previewTheme ?? activeTheme;

  return (
    <div style={{ position: "relative", display: "inline-block" }} ref={popoverRef}>
      <button
        onClick={() => setOpen(!open)}
        aria-label="Select report theme"
        aria-expanded={open}
        style={{
          display: "flex",
          alignItems: "center",
          gap: 6,
          padding: "6px 12px",
          fontSize: 11,
          fontWeight: 600,
          background: "var(--surface)",
          color: "var(--text)",
          border: "1px solid var(--border)",
          borderRadius: 6,
          cursor: "pointer",
        }}
      >
        <span
          style={{
            width: 10,
            height: 10,
            borderRadius: 2,
            background: REPORT_THEMES[displayKey]?.colors.accent ?? "var(--accent)",
          }}
        />
        {REPORT_THEMES[displayKey]?.name ?? "Theme"}
      </button>

      {open && (
        <div
          role="listbox"
          aria-label="Report themes"
          style={{
            position: "absolute",
            top: "100%",
            right: 0,
            marginTop: 4,
            minWidth: 220,
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            boxShadow: "0 8px 24px rgba(0,0,0,0.3)",
            zIndex: 100,
            padding: 4,
          }}
        >
          {themeKeys.map((key) => {
            const theme = REPORT_THEMES[key];
            const isActive = key === activeTheme;
            return (
              <button
                key={key}
                role="option"
                aria-selected={isActive}
                onClick={() => selectTheme(key)}
                onMouseEnter={() => handlePreview(key)}
                onMouseLeave={handlePreviewEnd}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  width: "100%",
                  padding: "8px 10px",
                  fontSize: 11,
                  fontWeight: isActive ? 800 : 600,
                  background: isActive ? "rgba(242,158,61,0.1)" : "transparent",
                  color: "var(--text)",
                  border: "none",
                  borderRadius: 6,
                  cursor: "pointer",
                  textAlign: "left",
                }}
              >
                {/* Color swatch preview */}
                <div
                  style={{
                    display: "flex",
                    gap: 2,
                    flexShrink: 0,
                  }}
                >
                  <span
                    style={{
                      width: 12,
                      height: 12,
                      borderRadius: 2,
                      background: theme.colors.bg,
                      border: "1px solid var(--border)",
                    }}
                  />
                  <span
                    style={{
                      width: 12,
                      height: 12,
                      borderRadius: 2,
                      background: theme.colors.accent,
                    }}
                  />
                  <span
                    style={{
                      width: 12,
                      height: 12,
                      borderRadius: 2,
                      background: theme.colors.surface,
                      border: "1px solid var(--border)",
                    }}
                  />
                </div>
                <span style={{ flex: 1 }}>{theme.name}</span>
                {isActive && (
                  <span style={{ fontSize: 10, color: "var(--accent)" }}>Active</span>
                )}
              </button>
            );
          })}

          {/* White-labeling indicator (D-107) */}
          {(logoUrl || companyName) && (
            <div
              style={{
                borderTop: "1px solid var(--border)",
                marginTop: 4,
                paddingTop: 8,
                padding: "8px 10px",
                fontSize: 10,
                color: "var(--muted)",
              }}
            >
              {logoUrl && (
                <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 4 }}>
                  <img
                    src={logoUrl}
                    alt={companyName ? `${companyName} logo` : "Company logo"}
                    style={{ width: 16, height: 16, borderRadius: 2, objectFit: "contain" }}
                  />
                  <span>Custom branding active</span>
                </div>
              )}
              {companyName && <div>Company: {companyName}</div>}
            </div>
          )}

          {/* Enterprise white-labeling upsell (D-107) */}
          <div
            style={{
              borderTop: "1px solid var(--border)",
              marginTop: 4,
              padding: "8px 10px",
              fontSize: 10,
              color: "var(--muted)",
            }}
          >
            Custom domain &amp; email branding available for Enterprise
          </div>
        </div>
      )}
    </div>
  );
}
