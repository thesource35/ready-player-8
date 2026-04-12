"use client";

import { useState, useCallback } from "react";
import type { ReportTemplate } from "@/lib/reports/types";

// ---------- Built-in Templates (D-93) ----------

const REPORT_SECTIONS = [
  "budget",
  "schedule",
  "safety",
  "team",
  "issues",
  "ai_insights",
  "documents",
  "photos",
] as const;

type SectionId = (typeof REPORT_SECTIONS)[number];

const SECTION_LABELS: Record<SectionId, string> = {
  budget: "Budget & Financial",
  schedule: "Schedule & Milestones",
  safety: "Safety & Incidents",
  team: "Team & Activity",
  issues: "Issues & Risks",
  ai_insights: "AI Insights",
  documents: "Documents",
  photos: "Photos",
};

const BUILTIN_TEMPLATES: ReportTemplate[] = [
  {
    id: "builtin-standard",
    name: "Standard",
    description: "Complete report with all sections in default order.",
    template_config: {
      sections: [...REPORT_SECTIONS],
      ordering: [...REPORT_SECTIONS],
      visibility: Object.fromEntries(REPORT_SECTIONS.map((s) => [s, true])),
    },
  },
  {
    id: "builtin-executive",
    name: "Executive Summary",
    description: "High-level overview: budget, schedule, and AI insights only.",
    template_config: {
      sections: ["budget", "schedule", "ai_insights"],
      ordering: ["budget", "schedule", "ai_insights"],
      visibility: Object.fromEntries(
        REPORT_SECTIONS.map((s) => [s, ["budget", "schedule", "ai_insights"].includes(s)])
      ),
    },
  },
  {
    id: "builtin-safety",
    name: "Safety Focus",
    description: "Safety-first report for field safety officers and inspectors.",
    template_config: {
      sections: ["safety", "team", "issues"],
      ordering: ["safety", "team", "issues"],
      visibility: Object.fromEntries(
        REPORT_SECTIONS.map((s) => [s, ["safety", "team", "issues"].includes(s)])
      ),
    },
  },
  {
    id: "builtin-financial",
    name: "Financial Detail",
    description: "Detailed financial report with budget, issues, and change orders.",
    template_config: {
      sections: ["budget", "issues", "schedule"],
      ordering: ["budget", "issues", "schedule"],
      visibility: Object.fromEntries(
        REPORT_SECTIONS.map((s) => [s, ["budget", "issues", "schedule"].includes(s)])
      ),
    },
  },
  {
    id: "builtin-minimal",
    name: "Minimal",
    description: "Budget and schedule only. Quick status check.",
    template_config: {
      sections: ["budget", "schedule"],
      ordering: ["budget", "schedule"],
      visibility: Object.fromEntries(
        REPORT_SECTIONS.map((s) => [s, ["budget", "schedule"].includes(s)])
      ),
    },
  },
];

// ---------- Customization Tiers (D-94) ----------

type CustomizationTier = "basic" | "advanced" | "power";

const TIER_LABELS: Record<CustomizationTier, string> = {
  basic: "Basic",
  advanced: "Advanced",
  power: "Power User",
};

const TIER_DESCRIPTIONS: Record<CustomizationTier, string> = {
  basic: "Toggle sections on/off and reorder them.",
  advanced: "Full visual editor with section layout and chart configuration.",
  power: "JSON/code-based template editing for maximum control.",
};

// ---------- Validation (T-19-40) ----------

const MAX_TEMPLATE_JSON_SIZE = 50_000; // 50KB limit for template config

function validateTemplateConfig(config: unknown): { valid: boolean; error?: string } {
  if (typeof config !== "object" || config === null) {
    return { valid: false, error: "Template config must be an object." };
  }

  const json = JSON.stringify(config);
  if (json.length > MAX_TEMPLATE_JSON_SIZE) {
    return { valid: false, error: `Template config exceeds ${MAX_TEMPLATE_JSON_SIZE / 1000}KB limit.` };
  }

  const c = config as Record<string, unknown>;
  if (!Array.isArray(c.sections)) {
    return { valid: false, error: "Template config must have a 'sections' array." };
  }

  // Sanitize custom CSS: strip script tags and event handlers
  if (typeof c.customCSS === "string") {
    const css = c.customCSS as string;
    if (/<script|javascript:|on\w+\s*=/i.test(css)) {
      return { valid: false, error: "Custom CSS contains forbidden content." };
    }
  }

  return { valid: true };
}

// ---------- Component ----------

type TemplateManagerProps = {
  onApply?: (template: ReportTemplate) => void;
};

export function TemplateManager({ onApply }: TemplateManagerProps) {
  const [templates, setTemplates] = useState<ReportTemplate[]>(BUILTIN_TEMPLATES);
  const [selected, setSelected] = useState<ReportTemplate | null>(null);
  const [tier, setTier] = useState<CustomizationTier>("basic");
  const [showCreate, setShowCreate] = useState(false);

  // Create form state
  const [newName, setNewName] = useState("");
  const [newDescription, setNewDescription] = useState("");
  const [newVisibility, setNewVisibility] = useState<Record<string, boolean>>(
    Object.fromEntries(REPORT_SECTIONS.map((s) => [s, true]))
  );
  const [newOrdering, setNewOrdering] = useState<string[]>([...REPORT_SECTIONS]);
  const [jsonEditor, setJsonEditor] = useState("");
  const [error, setError] = useState("");
  const [defaultTemplateId, setDefaultTemplateId] = useState<string | null>(null);

  // ---------- Handlers ----------

  const handleApply = useCallback(
    (template: ReportTemplate) => {
      setSelected(template);
      onApply?.(template);
    },
    [onApply]
  );

  const handleCreate = useCallback(() => {
    setError("");

    const name = newName.trim();
    if (!name) {
      setError("Template name is required.");
      return;
    }

    let config: ReportTemplate["template_config"];

    if (tier === "power") {
      // Parse JSON editor
      try {
        config = JSON.parse(jsonEditor);
      } catch {
        setError("Invalid JSON in template editor.");
        return;
      }
    } else {
      const activeSections = newOrdering.filter((s) => newVisibility[s]);
      config = {
        sections: activeSections,
        ordering: newOrdering,
        visibility: { ...newVisibility },
      };
    }

    // T-19-40: validate template config
    const validation = validateTemplateConfig(config);
    if (!validation.valid) {
      setError(validation.error ?? "Invalid template config.");
      return;
    }

    const newTemplate: ReportTemplate = {
      id: `user-${Date.now()}`,
      name,
      description: newDescription.trim(),
      template_config: config,
    };

    setTemplates((prev) => [...prev, newTemplate]);
    setShowCreate(false);
    setNewName("");
    setNewDescription("");
    setNewVisibility(Object.fromEntries(REPORT_SECTIONS.map((s) => [s, true])));
    setNewOrdering([...REPORT_SECTIONS]);
    setJsonEditor("");

    // Auto-save to Supabase (best-effort)
    fetch("/api/reports/templates", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: newTemplate.name,
        description: newTemplate.description,
        template_config: newTemplate.template_config,
      }),
    }).catch(() => {
      // Template saved locally even if remote fails
    });
  }, [newName, newDescription, newVisibility, newOrdering, jsonEditor, tier]);

  const handleSetDefault = useCallback(
    (templateId: string) => {
      setDefaultTemplateId(templateId === defaultTemplateId ? null : templateId);
    },
    [defaultTemplateId]
  );

  const moveSection = useCallback(
    (index: number, direction: "up" | "down") => {
      setNewOrdering((prev) => {
        const arr = [...prev];
        const swapIdx = direction === "up" ? index - 1 : index + 1;
        if (swapIdx < 0 || swapIdx >= arr.length) return prev;
        [arr[index], arr[swapIdx]] = [arr[swapIdx], arr[index]];
        return arr;
      });
    },
    []
  );

  // ---------- Render ----------

  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 16,
        }}
      >
        <div style={{ fontSize: 14, fontWeight: 800, color: "var(--text)" }}>
          Report Templates
        </div>
        <button
          onClick={() => setShowCreate(!showCreate)}
          style={{
            background: "var(--accent)",
            color: "#000",
            border: "none",
            borderRadius: 6,
            padding: "6px 14px",
            fontSize: 11,
            fontWeight: 700,
            cursor: "pointer",
          }}
        >
          {showCreate ? "Cancel" : "+ New Template"}
        </button>
      </div>

      {/* Template list */}
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 16 }}>
        {templates.map((tpl) => {
          const isBuiltin = tpl.id.startsWith("builtin-");
          const isSelected = selected?.id === tpl.id;
          const isDefault = defaultTemplateId === tpl.id;

          return (
            <div
              key={tpl.id}
              style={{
                background: isSelected ? "rgba(242,158,61,0.08)" : "var(--panel)",
                border: `1px solid ${isSelected ? "var(--accent)" : "var(--border)"}`,
                borderRadius: 8,
                padding: 12,
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: "var(--text)" }}>
                    {tpl.name}
                    {isBuiltin && (
                      <span
                        style={{
                          fontSize: 9,
                          color: "var(--muted)",
                          background: "var(--surface)",
                          padding: "1px 6px",
                          borderRadius: 3,
                          marginLeft: 6,
                        }}
                      >
                        Built-in
                      </span>
                    )}
                    {isDefault && (
                      <span
                        style={{
                          fontSize: 9,
                          color: "var(--green)",
                          background: "rgba(0,200,83,0.1)",
                          padding: "1px 6px",
                          borderRadius: 3,
                          marginLeft: 6,
                        }}
                      >
                        Default
                      </span>
                    )}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 2 }}>
                    {tpl.description}
                  </div>
                  <div style={{ fontSize: 10, color: "var(--muted)", marginTop: 4 }}>
                    Sections: {tpl.template_config.sections.length} of {REPORT_SECTIONS.length}
                  </div>
                </div>
                <div style={{ display: "flex", gap: 4 }}>
                  <button
                    onClick={() => handleSetDefault(tpl.id)}
                    title={isDefault ? "Remove default" : "Set as default"}
                    style={{
                      background: "none",
                      border: "1px solid var(--border)",
                      borderRadius: 4,
                      padding: "4px 8px",
                      fontSize: 10,
                      color: isDefault ? "var(--green)" : "var(--muted)",
                      cursor: "pointer",
                    }}
                  >
                    {isDefault ? "★" : "☆"}
                  </button>
                  <button
                    onClick={() => handleApply(tpl)}
                    style={{
                      background: isSelected ? "var(--accent)" : "var(--surface)",
                      color: isSelected ? "#000" : "var(--text)",
                      border: "1px solid var(--border)",
                      borderRadius: 4,
                      padding: "4px 10px",
                      fontSize: 10,
                      fontWeight: 600,
                      cursor: "pointer",
                    }}
                  >
                    Apply
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create form */}
      {showCreate && (
        <div
          style={{
            background: "var(--panel)",
            border: "1px solid var(--border)",
            borderRadius: 10,
            padding: 16,
          }}
        >
          <div style={{ fontSize: 12, fontWeight: 700, color: "var(--text)", marginBottom: 12 }}>
            Create Template
          </div>

          {/* Name / Description */}
          <input
            type="text"
            placeholder="Template name"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            aria-label="Template name"
            style={{
              width: "100%",
              padding: "8px 10px",
              fontSize: 12,
              background: "var(--surface)",
              color: "var(--text)",
              border: "1px solid var(--border)",
              borderRadius: 6,
              outline: "none",
              marginBottom: 8,
              boxSizing: "border-box",
            }}
          />
          <input
            type="text"
            placeholder="Description (optional)"
            value={newDescription}
            onChange={(e) => setNewDescription(e.target.value)}
            aria-label="Template description"
            style={{
              width: "100%",
              padding: "8px 10px",
              fontSize: 12,
              background: "var(--surface)",
              color: "var(--text)",
              border: "1px solid var(--border)",
              borderRadius: 6,
              outline: "none",
              marginBottom: 12,
              boxSizing: "border-box",
            }}
          />

          {/* D-94: Tier selector */}
          <div
            style={{
              display: "flex",
              gap: 4,
              marginBottom: 12,
            }}
          >
            {(["basic", "advanced", "power"] as const).map((t) => (
              <button
                key={t}
                onClick={() => setTier(t)}
                style={{
                  flex: 1,
                  padding: "6px 8px",
                  fontSize: 10,
                  fontWeight: tier === t ? 700 : 500,
                  color: tier === t ? "#000" : "var(--text)",
                  background: tier === t ? "var(--accent)" : "var(--surface)",
                  border: "1px solid var(--border)",
                  borderRadius: 6,
                  cursor: "pointer",
                }}
              >
                {TIER_LABELS[t]}
              </button>
            ))}
          </div>
          <div style={{ fontSize: 10, color: "var(--muted)", marginBottom: 12 }}>
            {TIER_DESCRIPTIONS[tier]}
          </div>

          {/* Basic tier: section toggle + reorder */}
          {tier === "basic" && (
            <div>
              {newOrdering.map((sectionId, idx) => (
                <div
                  key={sectionId}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    padding: "4px 0",
                    borderBottom: "1px solid var(--border)",
                  }}
                >
                  <input
                    type="checkbox"
                    checked={newVisibility[sectionId] ?? true}
                    onChange={(e) =>
                      setNewVisibility((prev) => ({
                        ...prev,
                        [sectionId]: e.target.checked,
                      }))
                    }
                    aria-label={`Toggle ${SECTION_LABELS[sectionId as SectionId] ?? sectionId}`}
                  />
                  <span style={{ fontSize: 12, color: "var(--text)", flex: 1 }}>
                    {SECTION_LABELS[sectionId as SectionId] ?? sectionId}
                  </span>
                  <button
                    onClick={() => moveSection(idx, "up")}
                    disabled={idx === 0}
                    style={{
                      background: "none",
                      border: "none",
                      color: idx === 0 ? "var(--border)" : "var(--muted)",
                      cursor: idx === 0 ? "default" : "pointer",
                      fontSize: 12,
                    }}
                    aria-label={`Move ${sectionId} up`}
                  >
                    ▲
                  </button>
                  <button
                    onClick={() => moveSection(idx, "down")}
                    disabled={idx === newOrdering.length - 1}
                    style={{
                      background: "none",
                      border: "none",
                      color: idx === newOrdering.length - 1 ? "var(--border)" : "var(--muted)",
                      cursor: idx === newOrdering.length - 1 ? "default" : "pointer",
                      fontSize: 12,
                    }}
                    aria-label={`Move ${sectionId} down`}
                  >
                    ▼
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Advanced tier: section layout + chart config */}
          {tier === "advanced" && (
            <div>
              <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 8 }}>
                Drag sections to reorder. Toggle visibility and configure chart types per section.
              </div>
              {newOrdering.map((sectionId, idx) => (
                <div
                  key={sectionId}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    padding: "6px 0",
                    borderBottom: "1px solid var(--border)",
                  }}
                >
                  <input
                    type="checkbox"
                    checked={newVisibility[sectionId] ?? true}
                    onChange={(e) =>
                      setNewVisibility((prev) => ({
                        ...prev,
                        [sectionId]: e.target.checked,
                      }))
                    }
                    aria-label={`Toggle ${SECTION_LABELS[sectionId as SectionId] ?? sectionId}`}
                  />
                  <span style={{ fontSize: 12, color: "var(--text)", flex: 1 }}>
                    {SECTION_LABELS[sectionId as SectionId] ?? sectionId}
                  </span>
                  <select
                    defaultValue="default"
                    aria-label={`Chart type for ${sectionId}`}
                    style={{
                      fontSize: 10,
                      background: "var(--surface)",
                      color: "var(--text)",
                      border: "1px solid var(--border)",
                      borderRadius: 4,
                      padding: "2px 4px",
                    }}
                  >
                    <option value="default">Default chart</option>
                    <option value="bar">Bar chart</option>
                    <option value="line">Line chart</option>
                    <option value="pie">Pie chart</option>
                    <option value="table">Table only</option>
                  </select>
                  <button
                    onClick={() => moveSection(idx, "up")}
                    disabled={idx === 0}
                    style={{
                      background: "none",
                      border: "none",
                      color: idx === 0 ? "var(--border)" : "var(--muted)",
                      cursor: idx === 0 ? "default" : "pointer",
                      fontSize: 12,
                    }}
                    aria-label={`Move ${sectionId} up`}
                  >
                    ▲
                  </button>
                  <button
                    onClick={() => moveSection(idx, "down")}
                    disabled={idx === newOrdering.length - 1}
                    style={{
                      background: "none",
                      border: "none",
                      color: idx === newOrdering.length - 1 ? "var(--border)" : "var(--muted)",
                      cursor: idx === newOrdering.length - 1 ? "default" : "pointer",
                      fontSize: 12,
                    }}
                    aria-label={`Move ${sectionId} down`}
                  >
                    ▼
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Power user tier: JSON editor */}
          {tier === "power" && (
            <div>
              <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 6 }}>
                Edit template configuration as JSON. Must include <code>sections</code> array.
              </div>
              <textarea
                value={jsonEditor}
                onChange={(e) => setJsonEditor(e.target.value)}
                placeholder={JSON.stringify(
                  {
                    sections: ["budget", "schedule"],
                    ordering: ["budget", "schedule"],
                    visibility: { budget: true, schedule: true },
                  },
                  null,
                  2
                )}
                aria-label="Template JSON editor"
                spellCheck={false}
                style={{
                  width: "100%",
                  minHeight: 160,
                  padding: 10,
                  fontSize: 11,
                  fontFamily: "monospace",
                  background: "var(--surface)",
                  color: "var(--text)",
                  border: "1px solid var(--border)",
                  borderRadius: 6,
                  outline: "none",
                  resize: "vertical",
                  boxSizing: "border-box",
                }}
              />
            </div>
          )}

          {/* Error */}
          {error && (
            <div
              style={{
                fontSize: 11,
                color: "var(--red)",
                marginTop: 8,
                padding: "4px 8px",
                background: "rgba(255,0,0,0.05)",
                borderRadius: 4,
              }}
            >
              {error}
            </div>
          )}

          {/* Submit */}
          <button
            onClick={handleCreate}
            style={{
              marginTop: 12,
              width: "100%",
              background: "var(--accent)",
              color: "#000",
              border: "none",
              borderRadius: 6,
              padding: "8px 14px",
              fontSize: 12,
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            Create Template
          </button>
        </div>
      )}
    </div>
  );
}
