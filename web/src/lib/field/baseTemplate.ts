// Phase 16 FIELD-04: canonical base daily-log template (D-14).
//
// This is the V1 immutable shape consumed by templateResolver.ts. Project
// customization layers and role filters compose on top of this constant.

export type SectionVisibility = "required" | "optional" | "hidden";

export type TemplateSection = {
  id: string;
  label: string;
  kind:
    | "weather"
    | "crew_on_site"
    | "open_rfis"
    | "open_punch_items"
    | "yesterday_carryover"
    | "work_performed"
    | "delays"
    | "visitors"
    | "safety_notes"
    | "custom";
  visibility: SectionVisibility;
};

export type Template = {
  version: string;
  sections: TemplateSection[];
};

export type ProjectTemplateLayer = {
  addedSections?: TemplateSection[];
  hiddenSectionIds?: string[];
  requiredSectionIds?: string[];
  copyOverrides?: Record<string, string>; // sectionId → label override
};

export type RoleVisibilityFilter = Partial<Record<string, SectionVisibility>>;

export type ResolvedTemplate = Template & { resolvedFor: string };

export const BASE_TEMPLATE_V1: Template = {
  version: "v1",
  sections: [
    { id: "weather", label: "Weather", kind: "weather", visibility: "required" },
    { id: "crew_on_site", label: "Crew On Site", kind: "crew_on_site", visibility: "required" },
    { id: "open_rfis", label: "Open RFIs", kind: "open_rfis", visibility: "optional" },
    { id: "open_punch_items", label: "Open Punch Items", kind: "open_punch_items", visibility: "optional" },
    { id: "yesterday_carryover", label: "Yesterday's Carryover", kind: "yesterday_carryover", visibility: "optional" },
    { id: "work_performed", label: "Work Performed", kind: "work_performed", visibility: "required" },
    { id: "delays", label: "Delays", kind: "delays", visibility: "optional" },
    { id: "visitors", label: "Visitors", kind: "visitors", visibility: "optional" },
    { id: "safety_notes", label: "Safety Notes", kind: "safety_notes", visibility: "required" },
  ],
};
