"use client";

import { useState, useEffect, useCallback } from "react";
import { tokens } from "@/lib/design-tokens";
import {
  TEMPLATE_DEFAULTS,
  EXPIRY_OPTIONS,
  SECTION_ORDER,
  DEFAULT_MAP_OVERLAYS,
} from "@/lib/portal/types";
import type {
  PortalTemplate,
  PortalSectionsConfig,
  PortalConfig,
} from "@/lib/portal/types";
import { PortalTemplates } from "./PortalTemplates";
import { SectionVisibilityEditor } from "./SectionVisibilityEditor";
import { LivePreviewPanel } from "./LivePreviewPanel";

type ProjectOption = { id: string; name: string };

type PortalCreateDialogProps = {
  open: boolean;
  onClose: () => void;
  onCreated: (config: PortalConfig, url: string) => void;
};

export function PortalCreateDialog({
  open,
  onClose,
  onCreated,
}: PortalCreateDialogProps) {
  // Form state
  const [projectId, setProjectId] = useState("");
  const [template, setTemplate] = useState<PortalTemplate>("executive_summary");
  const [expiryDays, setExpiryDays] = useState<number | null>(30);
  const [slug, setSlug] = useState("");
  const [clientEmail, setClientEmail] = useState("");
  const [sectionsConfig, setSectionsConfig] = useState<PortalSectionsConfig>(
    () => ({ ...TEMPLATE_DEFAULTS.executive_summary })
  );
  // D-13: Portal map overlay configuration
  const [mapOverlays, setMapOverlays] = useState<{
    show_map: boolean;
    satellite: boolean;
    traffic: boolean;
    equipment: boolean;
    photos: boolean;
  }>(() => ({ ...DEFAULT_MAP_OVERLAYS }));
  const [showExactAmounts, setShowExactAmounts] = useState(false);
  const [sectionNotes, setSectionNotes] = useState<Record<string, string>>({});
  const [pinnedItems, setPinnedItems] = useState<Record<string, string[]>>({});
  const [dateRanges, setDateRanges] = useState<
    Record<string, { start: string; end: string }>
  >({});

  // UI state
  const [projects, setProjects] = useState<ProjectOption[]>([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [slugError, setSlugError] = useState("");
  const [error, setError] = useState("");

  // Fetch projects on mount
  useEffect(() => {
    if (!open) return;
    let cancelled = false;

    async function loadProjects() {
      setLoading(true);
      try {
        const res = await fetch("/api/reports/rollup");
        if (!res.ok) throw new Error("Failed to load projects");
        const data = await res.json();
        if (!cancelled && data.projects) {
          setProjects(
            data.projects.map(
              (p: { id: string; name: string }) => ({
                id: p.id,
                name: p.name,
              })
            )
          );
        }
      } catch {
        // Fallback: no projects available
        if (!cancelled) setProjects([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    loadProjects();
    return () => {
      cancelled = true;
    };
  }, [open]);

  // When template changes, update sections config (D-33: budget always hidden)
  const handleTemplateChange = useCallback((t: PortalTemplate) => {
    setTemplate(t);
    const defaults = { ...TEMPLATE_DEFAULTS[t] };
    // D-33: budget always defaults to hidden regardless of template
    defaults.budget = { ...defaults.budget, enabled: false };
    setSectionsConfig(defaults);
    setShowExactAmounts(false);
    // D-13: Reset map overlay config to the template-specific default
    if (defaults.map_overlays) {
      setMapOverlays({ ...defaults.map_overlays });
    } else {
      setMapOverlays({ ...DEFAULT_MAP_OVERLAYS });
    }
  }, []);

  // Validate slug format
  function validateSlug(value: string): boolean {
    if (!value) return true; // optional
    const valid = /^[a-z0-9]+(-[a-z0-9]+)*$/.test(value);
    if (!valid) {
      setSlugError(
        "Slug must be lowercase letters, numbers, and hyphens only"
      );
    } else {
      setSlugError("");
    }
    return valid;
  }

  async function handleSubmit() {
    if (!projectId) {
      setError("Please select a project");
      return;
    }
    if (slug && !validateSlug(slug)) return;

    setSubmitting(true);
    setError("");

    try {
      const res = await fetch("/api/portal/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          project_id: projectId,
          slug: slug || undefined,
          template,
          expiry_days: expiryDays,
          client_email: clientEmail || undefined,
          // D-13: Portal-specific map overlay configuration
          map_overlays: mapOverlays,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        if (res.status === 409 || data.error?.includes("slug")) {
          setSlugError(
            `This slug is already in use. Try: ${slug}-2`
          );
        } else {
          setError(data.error || "Failed to create portal link");
        }
        return;
      }

      // Copy URL to clipboard
      const portalUrl = data.link?.url ?? "";
      if (portalUrl) {
        try {
          await navigator.clipboard.writeText(portalUrl);
        } catch {
          // Clipboard may not be available in all contexts
        }
      }

      onCreated(data.config as PortalConfig, portalUrl);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to create portal link"
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (!open) return null;

  const previewConfig: Partial<PortalConfig> = {
    template,
    sections_config: sectionsConfig,
    show_exact_amounts: showExactAmounts,
    section_notes: sectionNotes,
    pinned_items: pinnedItems,
    date_ranges: dateRanges,
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.5)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1000,
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: tokens.card.bg,
          borderRadius: tokens.radius.xl,
          maxWidth: 960,
          width: "95%",
          maxHeight: "90vh",
          overflow: "auto",
          boxShadow: "0 16px 48px rgba(0,0,0,0.15)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          style={{
            padding: `${tokens.spacing.lg}px ${tokens.spacing.lg}px ${tokens.spacing.md}px`,
            borderBottom: `1px solid ${tokens.colors.gray[200]}`,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <h2
            style={{
              margin: 0,
              fontSize: tokens.typography.fontSize["2xl"],
              fontWeight: tokens.typography.fontWeight.semibold,
              color: tokens.colors.gray[900],
            }}
          >
            Create Portal Link
          </h2>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: "none",
              border: "none",
              fontSize: 20,
              color: tokens.colors.gray[400],
              cursor: "pointer",
              padding: 4,
            }}
            aria-label="Close dialog"
          >
            \u2715
          </button>
        </div>

        {/* Body — two-column layout */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 320px",
            gap: tokens.spacing.lg,
            padding: tokens.spacing.lg,
          }}
        >
          {/* Left column: form */}
          <div style={{ display: "flex", flexDirection: "column", gap: tokens.spacing.md }}>
            {/* Project selector */}
            <div>
              <label
                style={{
                  display: "block",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: tokens.colors.gray[700],
                  marginBottom: 4,
                }}
              >
                Project <span style={{ color: tokens.colors.semantic.error }}>*</span>
              </label>
              <select
                value={projectId}
                onChange={(e) => setProjectId(e.target.value)}
                disabled={loading}
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.sm,
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.md,
                  background: tokens.card.bg,
                  color: tokens.colors.gray[900],
                  outline: "none",
                }}
              >
                <option value="">
                  {loading ? "Loading projects..." : "Select a project"}
                </option>
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Template selector */}
            <div>
              <label
                style={{
                  display: "block",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: tokens.colors.gray[700],
                  marginBottom: 4,
                }}
              >
                Template
              </label>
              <PortalTemplates
                selected={template}
                onSelect={handleTemplateChange}
              />
            </div>

            {/* Expiry */}
            <div>
              <label
                style={{
                  display: "block",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: tokens.colors.gray[700],
                  marginBottom: 4,
                }}
              >
                Link Expiry
              </label>
              <select
                value={expiryDays === null ? "null" : String(expiryDays)}
                onChange={(e) =>
                  setExpiryDays(
                    e.target.value === "null" ? null : Number(e.target.value)
                  )
                }
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.sm,
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.md,
                  background: tokens.card.bg,
                  color: tokens.colors.gray[900],
                  outline: "none",
                }}
              >
                {EXPIRY_OPTIONS.map((opt) => (
                  <option
                    key={opt.label}
                    value={opt.days === null ? "null" : String(opt.days)}
                  >
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Custom slug (D-24) */}
            <div>
              <label
                style={{
                  display: "block",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: tokens.colors.gray[700],
                  marginBottom: 4,
                }}
              >
                Custom Slug{" "}
                <span style={{ color: tokens.colors.gray[400], fontWeight: 400 }}>
                  (optional)
                </span>
              </label>
              <input
                type="text"
                value={slug}
                onChange={(e) => {
                  const val = e.target.value
                    .toLowerCase()
                    .replace(/\s+/g, "-")
                    .replace(/[^a-z0-9-]/g, "");
                  setSlug(val);
                  if (slugError) validateSlug(val);
                }}
                placeholder="auto-generated from project name"
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.sm,
                  border: `1px solid ${slugError ? tokens.colors.semantic.error : tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.md,
                  background: tokens.card.bg,
                  color: tokens.colors.gray[900],
                  outline: "none",
                  boxSizing: "border-box",
                }}
              />
              {slugError && (
                <div
                  style={{
                    fontSize: tokens.typography.fontSize.xs,
                    color: tokens.colors.semantic.error,
                    marginTop: 4,
                  }}
                >
                  {slugError}
                </div>
              )}
            </div>

            {/* Client email (D-09) */}
            <div>
              <label
                style={{
                  display: "block",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: tokens.colors.gray[700],
                  marginBottom: 4,
                }}
              >
                Client Email{" "}
                <span style={{ color: tokens.colors.gray[400], fontWeight: 400 }}>
                  (optional)
                </span>
              </label>
              <input
                type="email"
                value={clientEmail}
                onChange={(e) => setClientEmail(e.target.value)}
                placeholder="client@example.com"
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.sm,
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.md,
                  background: tokens.card.bg,
                  color: tokens.colors.gray[900],
                  outline: "none",
                  boxSizing: "border-box",
                }}
              />
            </div>

            {/* Section visibility (D-28 through D-46) */}
            <div>
              <label
                style={{
                  display: "block",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: tokens.colors.gray[700],
                  marginBottom: 4,
                }}
              >
                Section Visibility
              </label>
              <SectionVisibilityEditor
                config={sectionsConfig}
                showExactAmounts={showExactAmounts}
                sectionNotes={sectionNotes}
                pinnedItems={pinnedItems}
                dateRanges={dateRanges}
                onChange={(updates) => {
                  if (updates.config) setSectionsConfig(updates.config);
                  if (updates.showExactAmounts !== undefined)
                    setShowExactAmounts(updates.showExactAmounts);
                  if (updates.sectionNotes)
                    setSectionNotes(updates.sectionNotes);
                  if (updates.pinnedItems) setPinnedItems(updates.pinnedItems);
                  if (updates.dateRanges) setDateRanges(updates.dateRanges);
                }}
              />
            </div>

            {/* Map Overlay Configuration (D-13) */}
            <div style={{ marginTop: 16 }}>
              <h4
                style={{
                  fontSize: 11,
                  fontWeight: 800,
                  letterSpacing: 1,
                  color: tokens.colors.gray[600],
                  margin: 0,
                  marginBottom: 8,
                  textTransform: "uppercase",
                }}
              >
                Map Settings
              </h4>
              <div
                style={{
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.lg,
                  padding: tokens.spacing.md,
                }}
              >
                <label
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    cursor: "pointer",
                    fontSize: tokens.typography.fontSize.sm,
                    fontWeight: tokens.typography.fontWeight.medium,
                    color: tokens.colors.gray[900],
                  }}
                >
                  <input
                    type="checkbox"
                    checked={mapOverlays.show_map}
                    onChange={(e) =>
                      setMapOverlays((prev) => ({
                        ...prev,
                        show_map: e.target.checked,
                      }))
                    }
                    aria-label="Show map on portal"
                  />
                  <span>Show Map</span>
                </label>
                {/* D-15 (Phase 27): Admin helper copy — explains what enabling Show Map does for client viewer */}
                <p
                  style={{
                    fontSize: tokens.typography.fontSize.xs,
                    color: tokens.colors.gray[500],
                    margin: "4px 0 0 24px",
                    lineHeight: 1.4,
                  }}
                >
                  Clients see a Map link in the portal navigation when enabled.
                </p>
                {mapOverlays.show_map && (
                  <div
                    style={{
                      paddingLeft: 24,
                      marginTop: 8,
                      display: "flex",
                      flexDirection: "column",
                      gap: 6,
                    }}
                  >
                    <label
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 8,
                        cursor: "pointer",
                        fontSize: tokens.typography.fontSize.xs,
                        color: tokens.colors.gray[700],
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={mapOverlays.satellite}
                        onChange={(e) =>
                          setMapOverlays((prev) => ({
                            ...prev,
                            satellite: e.target.checked,
                          }))
                        }
                        aria-label="Satellite imagery"
                      />
                      <span>Satellite imagery</span>
                    </label>
                    <label
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 8,
                        cursor: "pointer",
                        fontSize: tokens.typography.fontSize.xs,
                        color: tokens.colors.gray[700],
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={mapOverlays.traffic}
                        onChange={(e) =>
                          setMapOverlays((prev) => ({
                            ...prev,
                            traffic: e.target.checked,
                          }))
                        }
                        aria-label="Traffic overlay"
                      />
                      <span>Traffic overlay</span>
                    </label>
                    <label
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 8,
                        cursor: "pointer",
                        fontSize: tokens.typography.fontSize.xs,
                        color: tokens.colors.gray[700],
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={mapOverlays.equipment}
                        onChange={(e) =>
                          setMapOverlays((prev) => ({
                            ...prev,
                            equipment: e.target.checked,
                          }))
                        }
                        aria-label="Equipment locations"
                      />
                      <span>Equipment locations</span>
                    </label>
                    <label
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 8,
                        cursor: "pointer",
                        fontSize: tokens.typography.fontSize.xs,
                        color: tokens.colors.gray[700],
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={mapOverlays.photos}
                        onChange={(e) =>
                          setMapOverlays((prev) => ({
                            ...prev,
                            photos: e.target.checked,
                          }))
                        }
                        aria-label="GPS photos"
                      />
                      <span>GPS photos</span>
                    </label>
                  </div>
                )}
              </div>
            </div>

            {/* Error */}
            {error && (
              <div
                style={{
                  padding: "8px 12px",
                  background: tokens.colors.toast.error.bg,
                  border: `1px solid ${tokens.colors.toast.error.border}`,
                  borderRadius: tokens.radius.md,
                  fontSize: tokens.typography.fontSize.sm,
                  color: tokens.colors.semantic.error,
                }}
              >
                {error}
              </div>
            )}

            {/* Submit */}
            <div style={{ display: "flex", gap: tokens.spacing.sm, justifyContent: "flex-end" }}>
              <button
                type="button"
                onClick={onClose}
                style={{
                  padding: "10px 20px",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.md,
                  background: tokens.card.bg,
                  color: tokens.colors.gray[700],
                  cursor: "pointer",
                }}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSubmit}
                disabled={submitting || !projectId}
                style={{
                  padding: "10px 20px",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.bold,
                  border: "none",
                  borderRadius: tokens.radius.md,
                  background:
                    submitting || !projectId
                      ? tokens.colors.gray[300]
                      : tokens.colors.primary[600],
                  color: "#fff",
                  cursor:
                    submitting || !projectId ? "not-allowed" : "pointer",
                }}
              >
                {submitting ? "Creating..." : "Create Portal Link"}
              </button>
            </div>
          </div>

          {/* Right column: live preview (D-27) */}
          <div
            style={{
              borderLeft: `1px solid ${tokens.colors.gray[200]}`,
              paddingLeft: tokens.spacing.lg,
            }}
          >
            <div
              style={{
                fontSize: tokens.typography.fontSize.sm,
                fontWeight: tokens.typography.fontWeight.medium,
                color: tokens.colors.gray[700],
                marginBottom: tokens.spacing.sm,
              }}
            >
              Preview
            </div>
            <LivePreviewPanel previewConfig={previewConfig} />
          </div>
        </div>
      </div>
    </div>
  );
}
