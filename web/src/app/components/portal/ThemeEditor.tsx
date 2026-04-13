"use client";

import { useState, useCallback } from "react";
import type { CompanyBranding, PortalThemeConfig } from "@/lib/portal/types";
import { checkContrastRatio, getContrastWarning } from "@/lib/portal/contrastValidator";
import type { PortalPresetKey } from "@/lib/design-tokens";
import ThemePresetPicker from "./ThemePresetPicker";
import LogoUpload from "./LogoUpload";
import CSSOverrideEditor from "./CSSOverrideEditor";

type ThemeEditorProps = {
  branding: CompanyBranding;
  onChange: (updates: Partial<CompanyBranding>) => void;
};

const FONT_OPTIONS: PortalThemeConfig["fontFamily"][] = [
  "Inter",
  "Roboto",
  "Source Sans 3",
  "DM Sans",
];

type ColorField = {
  key: keyof Pick<PortalThemeConfig, "primary" | "secondary" | "background" | "text">;
  label: string;
  description: string;
};

const COLOR_FIELDS: ColorField[] = [
  { key: "primary", label: "Primary", description: "Accent color for buttons and links" },
  { key: "secondary", label: "Secondary", description: "Hover and active states" },
  { key: "background", label: "Background", description: "Page background" },
  { key: "text", label: "Text", description: "Body text color" },
];

export default function ThemeEditor({ branding, onChange }: ThemeEditorProps) {
  const theme = branding.theme_config;
  const [selectedPreset, setSelectedPreset] = useState<string | undefined>();

  // Compute contrast warning between text and background
  const contrastWarning = getContrastWarning(theme.text, theme.background);
  const contrastRatio = checkContrastRatio(theme.text, theme.background);

  const updateTheme = useCallback(
    (updates: Partial<PortalThemeConfig>) => {
      onChange({
        theme_config: { ...theme, ...updates },
      });
    },
    [theme, onChange]
  );

  const handlePresetSelect = useCallback(
    (preset: PortalPresetKey, presetTheme: { primary: string; secondary: string; background: string; text: string; cardBg: string }) => {
      setSelectedPreset(preset);
      updateTheme({
        primary: presetTheme.primary,
        secondary: presetTheme.secondary,
        background: presetTheme.background,
        text: presetTheme.text,
        cardBg: presetTheme.cardBg,
      });
    },
    [updateTheme]
  );

  const handleColorChange = useCallback(
    (key: keyof PortalThemeConfig, value: string) => {
      setSelectedPreset(undefined);
      updateTheme({ [key]: value });
    },
    [updateTheme]
  );

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 32 }}>
      {/* Section 1: Preset Themes */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Preset Themes
        </h3>
        <p style={{ fontSize: 13, color: "#6B7280", margin: "0 0 12px" }}>
          Choose a starting point, then customize further below.
        </p>
        <ThemePresetPicker selected={selectedPreset} onSelect={handlePresetSelect} />
      </section>

      {/* Section 2: Colors (D-58) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Colors
        </h3>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
          {COLOR_FIELDS.map((field) => (
            <div key={field.key}>
              <label
                style={{
                  display: "block",
                  fontSize: 13,
                  fontWeight: 600,
                  color: "#374151",
                  marginBottom: 4,
                }}
              >
                {field.label}
              </label>
              <p style={{ fontSize: 11, color: "#9CA3AF", margin: "0 0 6px" }}>
                {field.description}
              </p>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <input
                  type="color"
                  value={theme[field.key] as string}
                  onChange={(e) => handleColorChange(field.key, e.target.value)}
                  style={{
                    width: 40,
                    height: 36,
                    padding: 0,
                    border: "1px solid #E2E5E9",
                    borderRadius: 6,
                    cursor: "pointer",
                    background: "none",
                  }}
                />
                <input
                  type="text"
                  value={theme[field.key] as string}
                  onChange={(e) => {
                    const val = e.target.value;
                    if (/^#[0-9a-fA-F]{0,6}$/.test(val) || val === "") {
                      handleColorChange(field.key, val);
                    }
                  }}
                  maxLength={7}
                  style={{
                    width: 90,
                    padding: "6px 10px",
                    fontSize: 13,
                    fontFamily: "JetBrains Mono, monospace",
                    border: "1px solid #E2E5E9",
                    borderRadius: 6,
                    color: "#1F2937",
                    outline: "none",
                  }}
                />
              </div>
            </div>
          ))}
        </div>

        {/* Contrast warning (D-72) */}
        {contrastWarning && (
          <div
            style={{
              marginTop: 12,
              padding: 10,
              background: "#FFFBEB",
              border: "1px solid #F59E0B",
              borderRadius: 6,
              display: "flex",
              alignItems: "center",
              gap: 8,
            }}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#F59E0B" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
              <line x1="12" y1="9" x2="12" y2="13" />
              <line x1="12" y1="17" x2="12.01" y2="17" />
            </svg>
            <span style={{ fontSize: 13, color: "#92400E" }}>
              Low contrast -- text may be hard to read. Current ratio: {contrastRatio.toFixed(1)}:1 (minimum 4.5:1 for WCAG AA).
            </span>
          </div>
        )}
      </section>

      {/* Section 3: Typography (D-76) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Typography
        </h3>
        <label
          style={{
            display: "block",
            fontSize: 13,
            fontWeight: 600,
            color: "#374151",
            marginBottom: 6,
          }}
        >
          Font Family
        </label>
        <select
          value={theme.fontFamily}
          onChange={(e) => updateTheme({ fontFamily: e.target.value as PortalThemeConfig["fontFamily"] })}
          style={{
            padding: "8px 12px",
            fontSize: 14,
            border: "1px solid #E2E5E9",
            borderRadius: 8,
            background: "#FFFFFF",
            color: "#1F2937",
            cursor: "pointer",
            outline: "none",
            minWidth: 200,
          }}
        >
          {FONT_OPTIONS.map((font) => (
            <option key={font} value={font} style={{ fontFamily: font }}>
              {font}
            </option>
          ))}
        </select>
      </section>

      {/* Section 4: Logo (D-75) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Logo
        </h3>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
          <LogoUpload
            type="logo_light"
            currentPath={branding.logo_light_path ?? undefined}
            onUpload={(path) => onChange({ logo_light_path: path || null })}
          />
          <LogoUpload
            type="logo_dark"
            currentPath={branding.logo_dark_path ?? undefined}
            onUpload={(path) => onChange({ logo_dark_path: path || null })}
          />
        </div>
      </section>

      {/* Section 5: Favicon (D-61) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Favicon
        </h3>
        <LogoUpload
          type="favicon"
          currentPath={branding.favicon_path ?? undefined}
          onUpload={(path) => onChange({ favicon_path: path || null })}
        />
      </section>

      {/* Section 6: Cover Image (D-62) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Cover Image
        </h3>
        <p style={{ fontSize: 13, color: "#6B7280", margin: "0 0 8px" }}>
          Optional hero banner at the top of your portal. Falls back to a solid brand-color header.
        </p>
        <LogoUpload
          type="cover_image"
          currentPath={branding.cover_image_path ?? undefined}
          onUpload={(path) => onChange({ cover_image_path: path || null })}
        />
      </section>

      {/* Section 7: Footer Contact */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Footer Contact Information
        </h3>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          {(["email", "phone", "website", "address"] as const).map((field) => (
            <div key={field}>
              <label
                style={{
                  display: "block",
                  fontSize: 13,
                  fontWeight: 500,
                  color: "#374151",
                  marginBottom: 4,
                  textTransform: "capitalize",
                }}
              >
                {field}
              </label>
              <input
                type={field === "email" ? "email" : field === "website" ? "url" : "text"}
                value={branding.contact_info?.[field] ?? ""}
                onChange={(e) =>
                  onChange({
                    contact_info: {
                      ...branding.contact_info,
                      [field]: e.target.value || undefined,
                    },
                  })
                }
                placeholder={
                  field === "email"
                    ? "contact@company.com"
                    : field === "phone"
                      ? "(555) 123-4567"
                      : field === "website"
                        ? "https://company.com"
                        : "123 Main St, City, ST"
                }
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  fontSize: 14,
                  border: "1px solid #E2E5E9",
                  borderRadius: 8,
                  color: "#1F2937",
                  outline: "none",
                  boxSizing: "border-box",
                }}
              />
            </div>
          ))}
        </div>
      </section>

      {/* Section 8: Options (D-19, D-70) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Options
        </h3>

        {/* Powered by toggle (D-19: default OFF) */}
        <label
          style={{
            display: "flex",
            alignItems: "center",
            gap: 10,
            cursor: "pointer",
            marginBottom: 16,
          }}
        >
          <input
            type="checkbox"
            checked={false}
            onChange={() => {
              // This would need a separate portal config field;
              // for branding page we show the toggle but it's per-portal
            }}
            style={{ width: 18, height: 18, accentColor: "#2563EB" }}
          />
          <span style={{ fontSize: 14, color: "#374151" }}>
            Powered by ConstructionOS
          </span>
          <span style={{ fontSize: 12, color: "#9CA3AF" }}>
            (shown in portal footer)
          </span>
        </label>

        {/* Welcome message (D-70) */}
        <label
          style={{
            display: "block",
            fontSize: 13,
            fontWeight: 600,
            color: "#374151",
            marginBottom: 6,
          }}
        >
          Default Welcome Message
        </label>
        <textarea
          value={branding.theme_config.customCSS === null ? "" : ""}
          placeholder="Welcome to your project portal. Here you can view the latest updates and progress."
          rows={3}
          style={{
            width: "100%",
            padding: "8px 12px",
            fontSize: 14,
            border: "1px solid #E2E5E9",
            borderRadius: 8,
            color: "#1F2937",
            resize: "vertical",
            outline: "none",
            boxSizing: "border-box",
          }}
        />
      </section>

      {/* Section 9: Advanced -- Custom CSS (D-68) */}
      <section>
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#111827", margin: "0 0 12px" }}>
          Advanced
        </h3>
        <CSSOverrideEditor
          css={branding.custom_css}
          onChange={(css) => onChange({ custom_css: css || null })}
        />
      </section>
    </div>
  );
}
