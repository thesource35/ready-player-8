"use client";

import { TEMPLATE_DEFAULTS, SECTION_ORDER } from "@/lib/portal/types";
import type { PortalTemplate, PortalSectionKey } from "@/lib/portal/types";
import { tokens } from "@/lib/design-tokens";

// D-18: 3 preset portal templates

type TemplateInfo = {
  key: PortalTemplate;
  name: string;
  icon: string;
  description: string;
};

const TEMPLATES: TemplateInfo[] = [
  {
    key: "executive_summary",
    name: "Executive Summary",
    icon: "\u{1F4C4}", // FileText equivalent
    description: "High-level schedule and change orders",
  },
  {
    key: "full_progress",
    name: "Full Progress",
    icon: "\u{1F4CB}", // Layout equivalent
    description: "Complete project overview with all sections",
  },
  {
    key: "photo_update",
    name: "Photo Update",
    icon: "\u{1F4F7}", // Camera equivalent
    description: "Focus on visual progress documentation",
  },
];

const SECTION_LABELS: Record<PortalSectionKey, string> = {
  schedule: "Schedule",
  budget: "Budget",
  photos: "Photos",
  change_orders: "Change Orders",
  documents: "Documents",
};

type PortalTemplatesProps = {
  selected: PortalTemplate;
  onSelect: (t: PortalTemplate) => void;
};

export function PortalTemplates({ selected, onSelect }: PortalTemplatesProps) {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: tokens.spacing.sm }}>
      {TEMPLATES.map((tmpl) => {
        const isSelected = selected === tmpl.key;
        const defaults = TEMPLATE_DEFAULTS[tmpl.key];
        return (
          <button
            key={tmpl.key}
            type="button"
            onClick={() => onSelect(tmpl.key)}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "flex-start",
              gap: tokens.spacing.sm,
              padding: tokens.spacing.md,
              border: `2px solid ${isSelected ? tokens.colors.primary[600] : tokens.colors.gray[200]}`,
              borderRadius: tokens.radius.lg,
              background: isSelected ? tokens.colors.primary[50] : tokens.card.bg,
              cursor: "pointer",
              textAlign: "left",
              transition: `border-color ${tokens.motion.normal} ${tokens.motion.easing.default}`,
            }}
          >
            <div style={{ fontSize: 24 }}>{tmpl.icon}</div>
            <div
              style={{
                fontSize: tokens.typography.fontSize.md,
                fontWeight: tokens.typography.fontWeight.semibold,
                color: tokens.colors.gray[900],
              }}
            >
              {tmpl.name}
            </div>
            <div
              style={{
                fontSize: tokens.typography.fontSize.xs,
                color: tokens.colors.gray[500],
                lineHeight: tokens.typography.lineHeight.normal,
              }}
            >
              {tmpl.description}
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 4, marginTop: 4 }}>
              {SECTION_ORDER.map((key) => {
                const enabled = defaults[key]?.enabled ?? false;
                return (
                  <span
                    key={key}
                    style={{
                      fontSize: 10,
                      color: enabled ? tokens.colors.semantic.success : tokens.colors.gray[400],
                      display: "flex",
                      alignItems: "center",
                      gap: 2,
                    }}
                  >
                    {enabled ? "\u2713" : "\u2013"} {SECTION_LABELS[key]}
                  </span>
                );
              })}
            </div>
          </button>
        );
      })}
    </div>
  );
}
