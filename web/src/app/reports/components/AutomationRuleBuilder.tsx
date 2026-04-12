"use client";

import { useState, useCallback } from "react";
import type {
  AutomationRule,
  RuleCondition,
  RuleAction,
  RuleOperator,
  ActionType,
} from "@/lib/reports/automation-rules";
import {
  AVAILABLE_METRICS,
  ACTION_TYPES,
  BUILT_IN_TEMPLATES,
  createRule,
  cloneTemplate,
} from "@/lib/reports/automation-rules";

// ---------------------------------------------------------------------------
// Automation Rule Builder (D-103)
// Visual if-then rule builder with templates, condition/action pickers,
// and active/inactive toggle per rule.
// ---------------------------------------------------------------------------

const OPERATOR_LABELS: Record<RuleOperator, string> = {
  ">": "greater than",
  "<": "less than",
  ">=": "at least",
  "<=": "at most",
  "=": "equals",
  changes_by: "changes by %",
};

const STORAGE_KEY = "ConstructOS.Reports.AutomationRules";

function loadRules(): AutomationRule[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as AutomationRule[];
  } catch {
    // Ignore parse errors
  }
  return [];
}

function saveRules(rules: AutomationRule[]): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(rules));
  } catch {
    // Storage unavailable
  }
}

// ---------------------------------------------------------------------------
// Condition editor sub-component
// ---------------------------------------------------------------------------

function ConditionEditor({
  condition,
  onChange,
}: {
  condition: RuleCondition;
  onChange: (c: RuleCondition) => void;
}) {
  return (
    <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
      <label style={{ fontSize: 13, color: "var(--muted, #888)" }}>IF</label>
      <select
        value={condition.metric}
        onChange={(e) => onChange({ ...condition, metric: e.target.value })}
        aria-label="Select metric"
        style={{
          padding: "6px 10px",
          borderRadius: 8,
          border: "1px solid var(--border, #333)",
          background: "var(--surface, #1a1a2e)",
          color: "var(--text, #fff)",
          fontSize: 13,
        }}
      >
        {AVAILABLE_METRICS.map((m) => (
          <option key={m.key} value={m.key}>
            {m.label}
          </option>
        ))}
      </select>
      <select
        value={condition.operator}
        onChange={(e) =>
          onChange({ ...condition, operator: e.target.value as RuleOperator })
        }
        aria-label="Select operator"
        style={{
          padding: "6px 10px",
          borderRadius: 8,
          border: "1px solid var(--border, #333)",
          background: "var(--surface, #1a1a2e)",
          color: "var(--text, #fff)",
          fontSize: 13,
        }}
      >
        {Object.entries(OPERATOR_LABELS).map(([op, label]) => (
          <option key={op} value={op}>
            {label}
          </option>
        ))}
      </select>
      <input
        type="number"
        value={condition.threshold}
        onChange={(e) =>
          onChange({ ...condition, threshold: parseFloat(e.target.value) || 0 })
        }
        aria-label="Threshold value"
        style={{
          width: 80,
          padding: "6px 10px",
          borderRadius: 8,
          border: "1px solid var(--border, #333)",
          background: "var(--surface, #1a1a2e)",
          color: "var(--text, #fff)",
          fontSize: 13,
        }}
      />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Action editor sub-component
// ---------------------------------------------------------------------------

function ActionEditor({
  action,
  onChange,
}: {
  action: RuleAction;
  onChange: (a: RuleAction) => void;
}) {
  return (
    <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
      <label style={{ fontSize: 13, color: "var(--muted, #888)" }}>THEN</label>
      <select
        value={action.type}
        onChange={(e) =>
          onChange({ ...action, type: e.target.value as ActionType })
        }
        aria-label="Select action type"
        style={{
          padding: "6px 10px",
          borderRadius: 8,
          border: "1px solid var(--border, #333)",
          background: "var(--surface, #1a1a2e)",
          color: "var(--text, #fff)",
          fontSize: 13,
        }}
      >
        {Object.entries(ACTION_TYPES).map(([key, val]) => (
          <option key={key} value={key}>
            {val.label}
          </option>
        ))}
      </select>
      <span style={{ fontSize: 12, color: "var(--muted, #888)" }}>
        {ACTION_TYPES[action.type]?.description ?? ""}
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------

export default function AutomationRuleBuilder() {
  const [rules, setRules] = useState<AutomationRule[]>(() => loadRules());
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState("");
  const [newDescription, setNewDescription] = useState("");
  const [newCondition, setNewCondition] = useState<RuleCondition>({
    metric: "budget_percent",
    operator: ">",
    threshold: 85,
  });
  const [newAction, setNewAction] = useState<RuleAction>({
    type: "send_notification",
    params: { message: "", severity: "warning" },
  });

  const updateRules = useCallback((updated: AutomationRule[]) => {
    setRules(updated);
    saveRules(updated);
  }, []);

  const handleCreateRule = () => {
    if (!newName.trim()) return;
    const rule = createRule(newName.trim(), newDescription.trim(), newCondition, newAction);
    updateRules([...rules, rule]);
    setNewName("");
    setNewDescription("");
    setShowCreate(false);
  };

  const handleUseTemplate = (template: AutomationRule) => {
    const rule = cloneTemplate(template);
    updateRules([...rules, rule]);
  };

  const toggleRule = (id: string) => {
    updateRules(
      rules.map((r) => (r.id === id ? { ...r, isActive: !r.isActive } : r))
    );
  };

  const deleteRule = (id: string) => {
    updateRules(rules.filter((r) => r.id !== id));
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
      {/* Header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div>
          <h3
            style={{
              margin: 0,
              fontSize: 18,
              fontWeight: 700,
              color: "var(--text, #fff)",
            }}
          >
            Automation Rules
          </h3>
          <p
            style={{
              margin: "4px 0 0",
              fontSize: 13,
              color: "var(--muted, #888)",
            }}
          >
            Set up if-then rules to automate report actions
          </p>
        </div>
        <button
          onClick={() => setShowCreate(!showCreate)}
          style={{
            padding: "8px 16px",
            borderRadius: 8,
            border: "none",
            background: "var(--accent, #f59e0b)",
            color: "#000",
            fontWeight: 600,
            fontSize: 13,
            cursor: "pointer",
          }}
        >
          {showCreate ? "Cancel" : "+ New Rule"}
        </button>
      </div>

      {/* Create new rule form */}
      {showCreate && (
        <div
          style={{
            background: "var(--surface, #1a1a2e)",
            borderRadius: 12,
            padding: 20,
            display: "flex",
            flexDirection: "column",
            gap: 16,
            border: "1px solid var(--accent, #f59e0b)",
          }}
        >
          <input
            type="text"
            placeholder="Rule name"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            aria-label="Rule name"
            style={{
              padding: "8px 12px",
              borderRadius: 8,
              border: "1px solid var(--border, #333)",
              background: "var(--panel, #111)",
              color: "var(--text, #fff)",
              fontSize: 14,
            }}
          />
          <input
            type="text"
            placeholder="Description (optional)"
            value={newDescription}
            onChange={(e) => setNewDescription(e.target.value)}
            aria-label="Rule description"
            style={{
              padding: "8px 12px",
              borderRadius: 8,
              border: "1px solid var(--border, #333)",
              background: "var(--panel, #111)",
              color: "var(--text, #fff)",
              fontSize: 14,
            }}
          />
          <ConditionEditor
            condition={newCondition}
            onChange={setNewCondition}
          />
          <ActionEditor action={newAction} onChange={setNewAction} />
          <button
            onClick={handleCreateRule}
            disabled={!newName.trim()}
            style={{
              alignSelf: "flex-end",
              padding: "8px 20px",
              borderRadius: 8,
              border: "none",
              background: newName.trim()
                ? "var(--green, #22c55e)"
                : "var(--muted, #888)",
              color: "#000",
              fontWeight: 600,
              fontSize: 13,
              cursor: newName.trim() ? "pointer" : "not-allowed",
            }}
          >
            Create Rule
          </button>
        </div>
      )}

      {/* Built-in templates (D-103) */}
      <section>
        <h4
          style={{
            fontSize: 14,
            fontWeight: 600,
            color: "var(--muted, #888)",
            textTransform: "uppercase",
            letterSpacing: 1,
            margin: "0 0 12px",
          }}
        >
          Quick Templates
        </h4>
        <div
          style={{
            display: "flex",
            gap: 8,
            flexWrap: "wrap",
          }}
        >
          {BUILT_IN_TEMPLATES.map((tpl) => (
            <button
              key={tpl.id}
              onClick={() => handleUseTemplate(tpl)}
              style={{
                padding: "8px 14px",
                borderRadius: 8,
                border: "1px solid var(--border, #333)",
                background: "var(--surface, #1a1a2e)",
                color: "var(--text, #fff)",
                fontSize: 12,
                cursor: "pointer",
              }}
              title={tpl.description}
            >
              + {tpl.name}
            </button>
          ))}
        </div>
      </section>

      {/* Active rules list */}
      <section>
        <h4
          style={{
            fontSize: 14,
            fontWeight: 600,
            color: "var(--muted, #888)",
            textTransform: "uppercase",
            letterSpacing: 1,
            margin: "0 0 12px",
          }}
        >
          Active Rules ({rules.filter((r) => r.isActive).length} of{" "}
          {rules.length})
        </h4>
        {rules.length === 0 ? (
          <p
            style={{
              fontSize: 13,
              color: "var(--muted, #888)",
              fontStyle: "italic",
            }}
          >
            No rules configured. Use a template above or create a custom rule.
          </p>
        ) : (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: 8,
            }}
          >
            {rules.map((rule) => (
              <div
                key={rule.id}
                style={{
                  background: "var(--surface, #1a1a2e)",
                  borderRadius: 12,
                  padding: 16,
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  opacity: rule.isActive ? 1 : 0.5,
                  border: `1px solid ${
                    rule.isActive
                      ? "var(--border, #333)"
                      : "var(--border, #222)"
                  }`,
                }}
              >
                <div style={{ flex: 1 }}>
                  <div
                    style={{
                      fontSize: 14,
                      fontWeight: 600,
                      color: "var(--text, #fff)",
                    }}
                  >
                    {rule.name}
                  </div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--muted, #888)",
                      marginTop: 4,
                    }}
                  >
                    IF{" "}
                    {
                      AVAILABLE_METRICS.find(
                        (m) => m.key === rule.condition.metric
                      )?.label ?? rule.condition.metric
                    }{" "}
                    {OPERATOR_LABELS[rule.condition.operator]}{" "}
                    {rule.condition.threshold} THEN{" "}
                    {ACTION_TYPES[rule.action.type]?.label ?? rule.action.type}
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  <label
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 4,
                      cursor: "pointer",
                    }}
                  >
                    <input
                      type="checkbox"
                      checked={rule.isActive}
                      onChange={() => toggleRule(rule.id)}
                      aria-label={`${rule.isActive ? "Disable" : "Enable"} ${rule.name}`}
                      style={{ cursor: "pointer" }}
                    />
                    <span
                      style={{
                        fontSize: 12,
                        color: rule.isActive
                          ? "var(--green, #22c55e)"
                          : "var(--muted, #888)",
                      }}
                    >
                      {rule.isActive ? "On" : "Off"}
                    </span>
                  </label>
                  <button
                    onClick={() => deleteRule(rule.id)}
                    aria-label={`Delete rule ${rule.name}`}
                    style={{
                      padding: "4px 8px",
                      borderRadius: 6,
                      border: "1px solid var(--red, #ef4444)",
                      background: "transparent",
                      color: "var(--red, #ef4444)",
                      fontSize: 12,
                      cursor: "pointer",
                    }}
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
