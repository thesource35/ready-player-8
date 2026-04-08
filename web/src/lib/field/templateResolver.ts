// Phase 16 FIELD-04: pure template resolver.
//
// resolveTemplate(base, projectLayer, role) composes:
//   1. Start from base.sections
//   2. Drop sections in projectLayer.hiddenSectionIds
//   3. Mark sections in projectLayer.requiredSectionIds as required
//   4. Apply projectLayer.copyOverrides (label rewrites)
//   5. Append projectLayer.addedSections
//   6. Apply role visibility filter (per-section override; "hidden" drops)
//
// Pure: same input → same output. No I/O, no Date.now, no globals.

import {
  BASE_TEMPLATE_V1,
  type Template,
  type ProjectTemplateLayer,
  type ResolvedTemplate,
  type TemplateSection,
} from "./baseTemplate";

export type RoleKey = "superintendent" | "projectManager" | "executive";

// Default role filters: superintendent sees everything; PM hides nothing but
// keeps optional optional; executive hides crew/visitors. These are fallbacks
// — projects can supply their own layer.
const ROLE_FILTERS: Record<RoleKey, Partial<Record<string, "required" | "optional" | "hidden">>> = {
  superintendent: {},
  projectManager: {},
  executive: {
    crew_on_site: "hidden",
    visitors: "hidden",
  },
};

export function resolveTemplate(
  base: Template,
  projectLayer: ProjectTemplateLayer | null,
  role: RoleKey,
): ResolvedTemplate {
  const layer: ProjectTemplateLayer = projectLayer ?? {};
  const hidden = new Set(layer.hiddenSectionIds ?? []);
  const required = new Set(layer.requiredSectionIds ?? []);
  const overrides = layer.copyOverrides ?? {};

  let sections: TemplateSection[] = base.sections
    .filter((s) => !hidden.has(s.id))
    .map((s) => ({
      ...s,
      visibility: required.has(s.id) ? ("required" as const) : s.visibility,
      label: overrides[s.id] ?? s.label,
    }));

  if (layer.addedSections && layer.addedSections.length > 0) {
    for (const added of layer.addedSections) {
      // Don't append duplicate ids; project-added wins.
      sections = sections.filter((s) => s.id !== added.id);
      sections.push({ ...added });
    }
  }

  const roleFilter = ROLE_FILTERS[role] ?? {};
  sections = sections
    .map((s) => {
      const override = roleFilter[s.id];
      if (!override) return s;
      return { ...s, visibility: override };
    })
    .filter((s) => s.visibility !== "hidden");

  return {
    version: base.version,
    sections,
    resolvedFor: role,
  };
}

export { BASE_TEMPLATE_V1 };
