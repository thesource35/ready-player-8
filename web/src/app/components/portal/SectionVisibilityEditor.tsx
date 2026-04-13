"use client";

import { SECTION_ORDER } from "@/lib/portal/types";
import type { PortalSectionsConfig, PortalSectionKey } from "@/lib/portal/types";
import { tokens } from "@/lib/design-tokens";

// D-28 through D-46: Section visibility controls

type SectionVisibilityEditorProps = {
  config: PortalSectionsConfig;
  showExactAmounts: boolean;
  sectionNotes: Record<string, string>;
  pinnedItems: Record<string, string[]>;
  dateRanges: Record<string, { start: string; end: string }>;
  onChange: (updates: {
    config?: PortalSectionsConfig;
    showExactAmounts?: boolean;
    sectionNotes?: Record<string, string>;
    pinnedItems?: Record<string, string[]>;
    dateRanges?: Record<string, { start: string; end: string }>;
  }) => void;
};

const SECTION_META: Record<
  PortalSectionKey,
  { label: string; icon: string }
> = {
  schedule: { label: "Schedule", icon: "\uD83D\uDCC5" }, // Calendar
  budget: { label: "Budget", icon: "\uD83D\uDCB0" }, // DollarSign
  photos: { label: "Photos", icon: "\uD83D\uDCF7" }, // Camera
  change_orders: { label: "Change Orders", icon: "\uD83D\uDCDD" }, // FileEdit
  documents: { label: "Documents", icon: "\uD83D\uDCC1" }, // File
};

export function SectionVisibilityEditor({
  config,
  showExactAmounts,
  sectionNotes,
  pinnedItems,
  dateRanges,
  onChange,
}: SectionVisibilityEditorProps) {
  const allEnabled = SECTION_ORDER.every((key) => config[key]?.enabled);

  function toggleAll() {
    const newEnabled = !allEnabled;
    const newConfig = { ...config };
    for (const key of SECTION_ORDER) {
      newConfig[key] = { ...newConfig[key], enabled: newEnabled };
    }
    // D-33: Budget defaults hidden — but user can explicitly enable via Select all
    onChange({ config: newConfig });
  }

  function toggleSection(key: PortalSectionKey) {
    const newConfig = { ...config };
    newConfig[key] = { ...newConfig[key], enabled: !newConfig[key].enabled };
    onChange({ config: newConfig });
  }

  function updateDateRange(
    key: string,
    field: "start" | "end",
    value: string
  ) {
    const current = dateRanges[key] ?? { start: "", end: "" };
    const updated = { ...dateRanges, [key]: { ...current, [field]: value } };
    onChange({ dateRanges: updated });
  }

  function updateNote(key: string, value: string) {
    // D-45: max 200 chars
    const trimmed = value.slice(0, 200);
    onChange({ sectionNotes: { ...sectionNotes, [key]: trimmed } });
  }

  const toggleStyle: React.CSSProperties = {
    width: 40,
    height: 22,
    borderRadius: 11,
    border: "none",
    cursor: "pointer",
    position: "relative",
    transition: `background ${tokens.motion.normal} ${tokens.motion.easing.default}`,
    flexShrink: 0,
  };

  const dotStyle: React.CSSProperties = {
    width: 16,
    height: 16,
    borderRadius: "50%",
    background: "#fff",
    position: "absolute",
    top: 3,
    transition: `left ${tokens.motion.normal} ${tokens.motion.easing.default}`,
    boxShadow: "0 1px 3px rgba(0,0,0,0.2)",
  };

  return (
    <div
      style={{
        border: `1px solid ${tokens.colors.gray[200]}`,
        borderRadius: tokens.radius.lg,
        overflow: "hidden",
      }}
    >
      {/* D-34: Select all / Deselect all */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: `${tokens.spacing.sm}px ${tokens.spacing.md}px`,
          background: tokens.colors.gray[50],
          borderBottom: `1px solid ${tokens.colors.gray[200]}`,
        }}
      >
        <span
          style={{
            fontSize: tokens.typography.fontSize.xs,
            fontWeight: tokens.typography.fontWeight.semibold,
            color: tokens.colors.gray[600],
            textTransform: "uppercase",
            letterSpacing: 0.5,
          }}
        >
          Sections
        </span>
        <button
          type="button"
          onClick={toggleAll}
          style={{
            background: "none",
            border: "none",
            fontSize: tokens.typography.fontSize.xs,
            color: tokens.colors.primary[600],
            cursor: "pointer",
            fontWeight: tokens.typography.fontWeight.medium,
          }}
        >
          {allEnabled ? "Deselect all" : "Select all"}
        </button>
      </div>

      {/* Section rows in SECTION_ORDER (D-32) */}
      {SECTION_ORDER.map((key) => {
        const meta = SECTION_META[key];
        const enabled = config[key]?.enabled ?? false;
        const isBudget = key === "budget";
        const range = dateRanges[key];
        const note = sectionNotes[key] ?? "";

        return (
          <div
            key={key}
            style={{
              borderBottom: `1px solid ${tokens.colors.gray[100]}`,
            }}
          >
            {/* Toggle row */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: tokens.spacing.sm,
                padding: `${tokens.spacing.sm}px ${tokens.spacing.md}px`,
              }}
            >
              {/* Toggle switch */}
              <button
                type="button"
                role="switch"
                aria-checked={enabled}
                aria-label={`Toggle ${meta.label}`}
                onClick={() => toggleSection(key)}
                style={{
                  ...toggleStyle,
                  background: enabled
                    ? tokens.colors.primary[600]
                    : tokens.colors.gray[300],
                }}
              >
                <span
                  style={{
                    ...dotStyle,
                    left: enabled ? 21 : 3,
                  }}
                />
              </button>

              {/* Section label */}
              <span style={{ fontSize: 16 }}>{meta.icon}</span>
              <span
                style={{
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  color: enabled
                    ? tokens.colors.gray[900]
                    : tokens.colors.gray[400],
                  flex: 1,
                }}
              >
                {meta.label}
              </span>
            </div>

            {/* Expanded options when enabled */}
            {enabled && (
              <div
                style={{
                  padding: `0 ${tokens.spacing.md}px ${tokens.spacing.sm}px ${tokens.spacing.md + 48}px`,
                  display: "flex",
                  flexDirection: "column",
                  gap: tokens.spacing.sm,
                }}
              >
                {/* Budget-specific: Show exact amounts toggle (D-30) */}
                {isBudget && (
                  <>
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: tokens.spacing.sm,
                      }}
                    >
                      <button
                        type="button"
                        role="switch"
                        aria-checked={showExactAmounts}
                        aria-label="Show exact amounts"
                        onClick={() =>
                          onChange({
                            showExactAmounts: !showExactAmounts,
                          })
                        }
                        style={{
                          ...toggleStyle,
                          width: 32,
                          height: 18,
                          borderRadius: 9,
                          background: showExactAmounts
                            ? tokens.colors.primary[600]
                            : tokens.colors.gray[300],
                        }}
                      >
                        <span
                          style={{
                            ...dotStyle,
                            width: 12,
                            height: 12,
                            top: 3,
                            left: showExactAmounts ? 17 : 3,
                          }}
                        />
                      </button>
                      <span
                        style={{
                          fontSize: tokens.typography.fontSize.xs,
                          color: tokens.colors.gray[600],
                        }}
                      >
                        Show exact amounts
                      </span>
                    </div>
                    {/* Budget warning */}
                    <div
                      style={{
                        padding: "6px 10px",
                        background: tokens.colors.toast.error.bg,
                        border: `1px solid ${tokens.colors.toast.error.border}`,
                        borderRadius: tokens.radius.sm,
                        fontSize: tokens.typography.fontSize.xs,
                        color: tokens.colors.semantic.error,
                      }}
                    >
                      Enabling budget will show financial data to viewers
                    </div>
                  </>
                )}

                {/* Date range picker (D-35) */}
                <div
                  style={{
                    display: "flex",
                    gap: tokens.spacing.sm,
                    alignItems: "center",
                    flexWrap: "wrap",
                  }}
                >
                  <span
                    style={{
                      fontSize: tokens.typography.fontSize.xs,
                      color: tokens.colors.gray[500],
                      minWidth: 60,
                    }}
                  >
                    Date range:
                  </span>
                  <input
                    type="date"
                    value={range?.start ?? ""}
                    onChange={(e) =>
                      updateDateRange(key, "start", e.target.value)
                    }
                    style={{
                      padding: "4px 8px",
                      fontSize: 11,
                      border: `1px solid ${tokens.colors.gray[200]}`,
                      borderRadius: tokens.radius.sm,
                      background: tokens.card.bg,
                      color: tokens.colors.gray[700],
                    }}
                  />
                  <span
                    style={{
                      fontSize: 11,
                      color: tokens.colors.gray[400],
                    }}
                  >
                    to
                  </span>
                  <input
                    type="date"
                    value={range?.end ?? ""}
                    onChange={(e) =>
                      updateDateRange(key, "end", e.target.value)
                    }
                    style={{
                      padding: "4px 8px",
                      fontSize: 11,
                      border: `1px solid ${tokens.colors.gray[200]}`,
                      borderRadius: tokens.radius.sm,
                      background: tokens.card.bg,
                      color: tokens.colors.gray[700],
                    }}
                  />
                </div>

                {/* Pinned items selector (D-36) */}
                <div
                  style={{
                    fontSize: tokens.typography.fontSize.xs,
                    color: tokens.colors.gray[500],
                  }}
                >
                  <span style={{ fontWeight: tokens.typography.fontWeight.medium }}>
                    Pinned items:
                  </span>{" "}
                  {(pinnedItems[key] ?? []).length > 0
                    ? `${pinnedItems[key].length} items pinned`
                    : "None — items will display in default order"}
                </div>

                {/* Section note (D-45) */}
                <div>
                  <textarea
                    value={note}
                    onChange={(e) => updateNote(key, e.target.value)}
                    placeholder="Add a note for this section (max 200 chars)"
                    maxLength={200}
                    rows={2}
                    style={{
                      width: "100%",
                      padding: "6px 8px",
                      fontSize: 11,
                      border: `1px solid ${tokens.colors.gray[200]}`,
                      borderRadius: tokens.radius.sm,
                      background: tokens.card.bg,
                      color: tokens.colors.gray[700],
                      resize: "vertical",
                      fontFamily: tokens.typography.fontFamily.sans,
                      boxSizing: "border-box",
                    }}
                  />
                  <div
                    style={{
                      fontSize: 10,
                      color: tokens.colors.gray[400],
                      textAlign: "right",
                    }}
                  >
                    {note.length}/200
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
