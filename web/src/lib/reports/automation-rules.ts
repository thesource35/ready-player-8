// Phase 19 — Automation rule engine for reports (D-103)
// Provides built-in templates and a custom if-then rule builder.
// Rules evaluate conditions against current metrics and return triggered actions.
// Per T-19-37: Rules can only trigger predefined actions — no arbitrary code execution.

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type RuleOperator = ">" | "<" | ">=" | "<=" | "=" | "changes_by";

export type RuleCondition = {
  metric: string;
  operator: RuleOperator;
  threshold: number;
};

export type ActionType =
  | "send_report"
  | "send_notification"
  | "pause_schedule"
  | "create_task";

export type RuleAction = {
  type: ActionType;
  params: Record<string, string | number | boolean>;
};

export type AutomationRule = {
  id: string;
  name: string;
  description: string;
  condition: RuleCondition;
  action: RuleAction;
  isActive: boolean;
  isBuiltIn: boolean;
  createdAt: string;
};

export type TriggeredAction = {
  ruleId: string;
  ruleName: string;
  action: RuleAction;
  triggerValue: number;
  threshold: number;
};

// ---------------------------------------------------------------------------
// Predefined action types (T-19-37: whitelist — no arbitrary execution)
// ---------------------------------------------------------------------------

export const ACTION_TYPES: Record<
  ActionType,
  { label: string; description: string; paramSchema: string[] }
> = {
  send_report: {
    label: "Send Report",
    description: "Generate and email report to specified recipients",
    paramSchema: ["recipients", "reportType"],
  },
  send_notification: {
    label: "Send Notification",
    description: "Push a notification to specified users",
    paramSchema: ["message", "severity"],
  },
  pause_schedule: {
    label: "Pause Schedule",
    description: "Temporarily pause a scheduled report delivery",
    paramSchema: ["scheduleId"],
  },
  create_task: {
    label: "Create Task",
    description: "Create a new task linked to the triggering project",
    paramSchema: ["taskName", "assignee"],
  },
};

// ---------------------------------------------------------------------------
// Available metrics for rule conditions
// ---------------------------------------------------------------------------

export const AVAILABLE_METRICS: Array<{
  key: string;
  label: string;
  unit: string;
}> = [
  { key: "budget_percent", label: "Budget Used (%)", unit: "%" },
  { key: "schedule_percent", label: "Schedule Progress (%)", unit: "%" },
  { key: "health_score", label: "Health Score", unit: "pts" },
  { key: "open_issues", label: "Open Issues", unit: "count" },
  { key: "safety_incidents", label: "Safety Incidents", unit: "count" },
  { key: "days_since_last_incident", label: "Days Since Last Incident", unit: "days" },
  { key: "change_order_net", label: "Change Order Net ($)", unit: "$" },
  { key: "overdue_tasks", label: "Overdue Tasks", unit: "count" },
];

// ---------------------------------------------------------------------------
// Built-in templates (D-103)
// ---------------------------------------------------------------------------

export const BUILT_IN_TEMPLATES: AutomationRule[] = [
  {
    id: "template-health-red",
    name: "Send report when health drops to red",
    description: "Automatically send a report to stakeholders when project health reaches critical",
    condition: { metric: "health_score", operator: "<", threshold: 40 },
    action: {
      type: "send_report",
      params: { recipients: "stakeholders", reportType: "project" },
    },
    isActive: false,
    isBuiltIn: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: "template-budget-85",
    name: "Alert team when budget exceeds 85%",
    description: "Notify team members when budget utilization passes 85% threshold",
    condition: { metric: "budget_percent", operator: ">", threshold: 85 },
    action: {
      type: "send_notification",
      params: { message: "Budget utilization has exceeded 85%", severity: "warning" },
    },
    isActive: false,
    isBuiltIn: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: "template-weekly-pdf",
    name: "Auto-export PDF weekly",
    description: "Generate and distribute PDF report every week",
    condition: { metric: "schedule_percent", operator: ">=", threshold: 0 },
    action: {
      type: "send_report",
      params: { recipients: "all", reportType: "rollup" },
    },
    isActive: false,
    isBuiltIn: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: "template-safety-alert",
    name: "Alert on new safety incident",
    description: "Send notification when a new safety incident is logged",
    condition: { metric: "safety_incidents", operator: ">", threshold: 0 },
    action: {
      type: "send_notification",
      params: { message: "New safety incident recorded", severity: "critical" },
    },
    isActive: false,
    isBuiltIn: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: "template-overdue-tasks",
    name: "Pause schedule when tasks overdue",
    description: "Pause scheduled reports when too many tasks are overdue",
    condition: { metric: "overdue_tasks", operator: ">", threshold: 10 },
    action: {
      type: "pause_schedule",
      params: { scheduleId: "" },
    },
    isActive: false,
    isBuiltIn: true,
    createdAt: new Date().toISOString(),
  },
];

// ---------------------------------------------------------------------------
// Rule evaluation (D-103)
// ---------------------------------------------------------------------------

/**
 * Evaluate a single condition against current metrics.
 * For "changes_by" operator, previousMetrics must be provided.
 */
function evaluateCondition(
  condition: RuleCondition,
  currentMetrics: Record<string, number>,
  previousMetrics?: Record<string, number>
): { triggered: boolean; value: number } {
  const currentValue = currentMetrics[condition.metric];
  if (currentValue === undefined) {
    return { triggered: false, value: 0 };
  }

  if (condition.operator === "changes_by") {
    if (!previousMetrics) return { triggered: false, value: currentValue };
    const prev = previousMetrics[condition.metric];
    if (prev === undefined || prev === 0) return { triggered: false, value: currentValue };
    const changePercent = Math.abs(((currentValue - prev) / prev) * 100);
    return {
      triggered: changePercent >= condition.threshold,
      value: changePercent,
    };
  }

  let triggered: boolean;
  switch (condition.operator) {
    case ">":
      triggered = currentValue > condition.threshold;
      break;
    case "<":
      triggered = currentValue < condition.threshold;
      break;
    case ">=":
      triggered = currentValue >= condition.threshold;
      break;
    case "<=":
      triggered = currentValue <= condition.threshold;
      break;
    case "=":
      triggered = currentValue === condition.threshold;
      break;
    default:
      triggered = false;
  }

  return { triggered, value: currentValue };
}

/**
 * Evaluate all active rules against current (and optionally previous) metrics.
 * Returns an array of triggered actions to execute.
 * Per T-19-37: only returns predefined action types — no arbitrary code.
 */
export function evaluateRules(
  rules: AutomationRule[],
  currentMetrics: Record<string, number>,
  previousMetrics?: Record<string, number>
): TriggeredAction[] {
  const triggered: TriggeredAction[] = [];

  for (const rule of rules) {
    if (!rule.isActive) continue;

    // Validate action type is in the whitelist (T-19-37)
    if (!(rule.action.type in ACTION_TYPES)) continue;

    const result = evaluateCondition(rule.condition, currentMetrics, previousMetrics);
    if (result.triggered) {
      triggered.push({
        ruleId: rule.id,
        ruleName: rule.name,
        action: rule.action,
        triggerValue: result.value,
        threshold: rule.condition.threshold,
      });
    }
  }

  return triggered;
}

// ---------------------------------------------------------------------------
// Rule creation helpers
// ---------------------------------------------------------------------------

/** Create a new custom rule with a unique ID */
export function createRule(
  name: string,
  description: string,
  condition: RuleCondition,
  action: RuleAction
): AutomationRule {
  return {
    id: `rule-${crypto.randomUUID()}`,
    name,
    description,
    condition,
    action,
    isActive: true,
    isBuiltIn: false,
    createdAt: new Date().toISOString(),
  };
}

/** Clone a built-in template into a user-editable rule */
export function cloneTemplate(template: AutomationRule): AutomationRule {
  return {
    ...template,
    id: `rule-${crypto.randomUUID()}`,
    isBuiltIn: false,
    isActive: true,
    createdAt: new Date().toISOString(),
  };
}
