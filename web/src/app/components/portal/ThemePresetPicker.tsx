"use client";

import { portalPresetThemes, type PortalPresetKey } from "@/lib/design-tokens";

type PresetTheme = (typeof portalPresetThemes)[PortalPresetKey];

type ThemePresetPickerProps = {
  selected?: string;
  onSelect: (preset: PortalPresetKey, theme: PresetTheme) => void;
};

const presetKeys = Object.keys(portalPresetThemes) as PortalPresetKey[];

export default function ThemePresetPicker({ selected, onSelect }: ThemePresetPickerProps) {
  return (
    <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
      {presetKeys.map((key) => {
        const theme = portalPresetThemes[key];
        const isSelected = selected === key;

        return (
          <button
            key={key}
            type="button"
            onClick={() => onSelect(key, theme)}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 6,
              padding: 8,
              border: isSelected ? "2px solid #2563EB" : "2px solid #E2E5E9",
              borderRadius: 8,
              background: "#FFFFFF",
              cursor: "pointer",
              transition: "border-color 200ms ease-in-out",
            }}
          >
            {/* Color swatch: 80x60px with primary + bg gradient */}
            <div
              style={{
                width: 80,
                height: 60,
                borderRadius: 4,
                background: `linear-gradient(135deg, ${theme.primary} 50%, ${theme.background} 50%)`,
              }}
            />
            <span
              style={{
                fontSize: 12,
                fontWeight: isSelected ? 600 : 400,
                color: "#374151",
              }}
            >
              {theme.name}
            </span>
          </button>
        );
      })}
    </div>
  );
}
