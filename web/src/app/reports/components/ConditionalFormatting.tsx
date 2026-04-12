"use client";

/**
 * ConditionalFormatting: Built-in and user-defined conditional formatting for report tables.
 * Per D-26j: Auto-applies health-based coloring; supports custom user-defined rules.
 * Rules stored in localStorage per user.
 */

import { useState, useEffect, useCallback } from "react";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ConditionalOperator = ">" | "<" | "=" | ">=" | "<=" | "!=" | "contains";

export type FormatStyle = {
  backgroundColor?: string;
  color?: string;
  fontWeight?: string;
};

export type ConditionalRule = {
  id: string;
  column: string;
  operator: ConditionalOperator;
  value: string;
  format: FormatStyle;
  enabled: boolean;
};

type ConditionalFormattingProps = {
  rules: ConditionalRule[];
  onRulesChange: (rules: ConditionalRule[]) => void;
  availableColumns?: string[];
};

// ---------------------------------------------------------------------------
// Health-Based Auto Coloring (D-26j)
// ---------------------------------------------------------------------------

const HEALTH_COLORS: Record<string, FormatStyle> = {
  green: { backgroundColor: "rgba(74, 222, 128, 0.15)", color: "#4ade80" },
  gold: { backgroundColor: "rgba(245, 166, 35, 0.15)", color: "#f5a623" },
  red: { backgroundColor: "rgba(239, 68, 68, 0.15)", color: "#ef4444" },
};

/**
 * Apply health-based formatting to a cell value.
 * Returns style object if the value matches a health status.
 */
export function getHealthStyle(healthColor: string): FormatStyle | null {
  return HEALTH_COLORS[healthColor] ?? null;
}

/**
 * Evaluate a conditional rule against a cell value.
 * Returns true if the rule matches.
 */
export function evaluateRule(rule: ConditionalRule, cellValue: string | number): boolean {
  if (!rule.enabled) return false;

  const numericValue = typeof cellValue === "number" ? cellValue : parseFloat(String(cellValue));
  const ruleNumericValue = parseFloat(rule.value);
  const stringValue = String(cellValue).toLowerCase();
  const ruleStringValue = rule.value.toLowerCase();

  switch (rule.operator) {
    case ">":
      return !isNaN(numericValue) && !isNaN(ruleNumericValue) && numericValue > ruleNumericValue;
    case "<":
      return !isNaN(numericValue) && !isNaN(ruleNumericValue) && numericValue < ruleNumericValue;
    case ">=":
      return !isNaN(numericValue) && !isNaN(ruleNumericValue) && numericValue >= ruleNumericValue;
    case "<=":
      return !isNaN(numericValue) && !isNaN(ruleNumericValue) && numericValue <= ruleNumericValue;
    case "=":
      return stringValue === ruleStringValue;
    case "!=":
      return stringValue !== ruleStringValue;
    case "contains":
      return stringValue.includes(ruleStringValue);
    default:
      return false;
  }
}

/**
 * Get the combined format style for a cell by evaluating all rules.
 * Later rules override earlier ones.
 */
export function getCellStyle(
  rules: ConditionalRule[],
  column: string,
  cellValue: string | number
): FormatStyle {
  let style: FormatStyle = {};
  for (const rule of rules) {
    if (rule.column === column && evaluateRule(rule, cellValue)) {
      style = { ...style, ...rule.format };
    }
  }
  return style;
}

// ---------------------------------------------------------------------------
// Storage Key
// ---------------------------------------------------------------------------

const STORAGE_KEY = "constructionos.reports.conditionalRules";

function loadRulesFromStorage(): ConditionalRule[] {
  if (typeof window === "undefined") return [];
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  } catch {
    return [];
  }
}

function saveRulesToStorage(rules: ConditionalRule[]): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(rules));
  } catch {
    console.error("[ConditionalFormatting] Failed to save rules to localStorage");
  }
}

// ---------------------------------------------------------------------------
// Operators List
// ---------------------------------------------------------------------------

const OPERATORS: { value: ConditionalOperator; label: string }[] = [
  { value: ">", label: "Greater than" },
  { value: "<", label: "Less than" },
  { value: ">=", label: "Greater or equal" },
  { value: "<=", label: "Less or equal" },
  { value: "=", label: "Equals" },
  { value: "!=", label: "Not equals" },
  { value: "contains", label: "Contains" },
];

const DEFAULT_COLUMNS = [
  "Health",
  "Budget",
  "Progress",
  "Open Issues",
  "Safety Incidents",
  "Schedule Status",
  "Status",
];

const COLOR_PRESETS = [
  { label: "Green", bg: "rgba(74, 222, 128, 0.15)", text: "#4ade80" },
  { label: "Gold", bg: "rgba(245, 166, 35, 0.15)", text: "#f5a623" },
  { label: "Red", bg: "rgba(239, 68, 68, 0.15)", text: "#ef4444" },
  { label: "Cyan", bg: "rgba(0, 212, 255, 0.15)", text: "#00d4ff" },
  { label: "Purple", bg: "rgba(168, 85, 247, 0.15)", text: "#a855f7" },
];

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export default function ConditionalFormatting({
  rules,
  onRulesChange,
  availableColumns,
}: ConditionalFormattingProps) {
  const columns = availableColumns ?? DEFAULT_COLUMNS;
  const [isExpanded, setIsExpanded] = useState(false);

  // New rule form state
  const [newColumn, setNewColumn] = useState(columns[0] || "");
  const [newOperator, setNewOperator] = useState<ConditionalOperator>(">");
  const [newValue, setNewValue] = useState("");
  const [newColorIdx, setNewColorIdx] = useState(0);
  const [newBold, setNewBold] = useState(false);

  // Load stored rules on mount
  useEffect(() => {
    const stored = loadRulesFromStorage();
    if (stored.length > 0 && rules.length === 0) {
      onRulesChange(stored);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const handleSaveRules = useCallback(
    (updated: ConditionalRule[]) => {
      onRulesChange(updated);
      saveRulesToStorage(updated);
    },
    [onRulesChange]
  );

  const addRule = () => {
    if (!newValue.trim()) return;
    const preset = COLOR_PRESETS[newColorIdx];
    const rule: ConditionalRule = {
      id: `rule-${Date.now()}`,
      column: newColumn,
      operator: newOperator,
      value: newValue.trim(),
      format: {
        backgroundColor: preset.bg,
        color: preset.text,
        fontWeight: newBold ? "700" : undefined,
      },
      enabled: true,
    };
    handleSaveRules([...rules, rule]);
    setNewValue("");
  };

  const removeRule = (id: string) => {
    handleSaveRules(rules.filter((r) => r.id !== id));
  };

  const toggleRule = (id: string) => {
    handleSaveRules(
      rules.map((r) => (r.id === id ? { ...r, enabled: !r.enabled } : r))
    );
  };

  const inputStyle: React.CSSProperties = {
    background: "var(--surface, #111d33)",
    border: "1px solid var(--border, #1e3a5f)",
    borderRadius: 8,
    color: "var(--text, #e2e8f0)",
    padding: "6px 10px",
    fontSize: 13,
  };

  return (
    <div style={{ marginBottom: 16 }}>
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        style={{
          background: "none",
          border: "1px solid var(--border, #1e3a5f)",
          borderRadius: 8,
          color: "var(--accent, #f5a623)",
          padding: "6px 14px",
          fontSize: 13,
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          gap: 6,
        }}
        aria-expanded={isExpanded}
        aria-label="Toggle conditional formatting rules"
      >
        <span>{isExpanded ? "Hide" : "Show"} Formatting Rules</span>
        <span style={{ fontSize: 10 }}>{isExpanded ? "\u25B2" : "\u25BC"}</span>
      </button>

      {isExpanded && (
        <div
          style={{
            marginTop: 12,
            padding: 16,
            background: "var(--surface, #111d33)",
            borderRadius: 12,
            border: "1px solid var(--border, #1e3a5f)",
          }}
        >
          {/* Built-in health coloring note */}
          <p style={{ color: "var(--muted, #94a3b8)", fontSize: 12, margin: "0 0 12px" }}>
            Health-based coloring (green/gold/red) is auto-applied. Add custom rules below.
          </p>

          {/* Existing rules */}
          {rules.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              {rules.map((rule) => (
                <div
                  key={rule.id}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    padding: "6px 10px",
                    marginBottom: 4,
                    borderRadius: 8,
                    background: rule.enabled
                      ? "rgba(255,255,255,0.03)"
                      : "rgba(255,255,255,0.01)",
                    opacity: rule.enabled ? 1 : 0.5,
                  }}
                >
                  <input
                    type="checkbox"
                    checked={rule.enabled}
                    onChange={() => toggleRule(rule.id)}
                    aria-label={`Toggle rule: ${rule.column} ${rule.operator} ${rule.value}`}
                  />
                  <span
                    style={{
                      ...rule.format,
                      padding: "2px 8px",
                      borderRadius: 4,
                      fontSize: 13,
                    }}
                  >
                    {rule.column} {rule.operator} {rule.value}
                  </span>
                  <button
                    onClick={() => removeRule(rule.id)}
                    style={{
                      marginLeft: "auto",
                      background: "none",
                      border: "none",
                      color: "var(--red, #ef4444)",
                      cursor: "pointer",
                      fontSize: 14,
                    }}
                    aria-label={`Remove rule: ${rule.column} ${rule.operator} ${rule.value}`}
                  >
                    x
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Add new rule form */}
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              gap: 8,
              alignItems: "center",
            }}
          >
            <select
              value={newColumn}
              onChange={(e) => setNewColumn(e.target.value)}
              style={inputStyle}
              aria-label="Column"
            >
              {columns.map((col) => (
                <option key={col} value={col}>
                  {col}
                </option>
              ))}
            </select>

            <select
              value={newOperator}
              onChange={(e) => setNewOperator(e.target.value as ConditionalOperator)}
              style={inputStyle}
              aria-label="Condition"
            >
              {OPERATORS.map((op) => (
                <option key={op.value} value={op.value}>
                  {op.label}
                </option>
              ))}
            </select>

            <input
              type="text"
              value={newValue}
              onChange={(e) => setNewValue(e.target.value)}
              placeholder="Value"
              style={{ ...inputStyle, width: 100 }}
              aria-label="Condition value"
            />

            <select
              value={newColorIdx}
              onChange={(e) => setNewColorIdx(Number(e.target.value))}
              style={inputStyle}
              aria-label="Format color"
            >
              {COLOR_PRESETS.map((p, i) => (
                <option key={p.label} value={i}>
                  {p.label}
                </option>
              ))}
            </select>

            <label style={{ color: "var(--muted, #94a3b8)", fontSize: 13, display: "flex", alignItems: "center", gap: 4 }}>
              <input
                type="checkbox"
                checked={newBold}
                onChange={(e) => setNewBold(e.target.checked)}
              />
              Bold
            </label>

            <button
              onClick={addRule}
              style={{
                background: "var(--accent, #f5a623)",
                color: "#000",
                border: "none",
                borderRadius: 8,
                padding: "6px 14px",
                fontSize: 13,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Add Rule
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
