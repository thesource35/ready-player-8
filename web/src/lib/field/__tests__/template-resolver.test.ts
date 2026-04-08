import { describe, it, expect } from "vitest";
import { BASE_TEMPLATE_V1 } from "../baseTemplate";
import { resolveTemplate } from "../templateResolver";

describe("resolveTemplate", () => {
  it("returns base sections for superintendent with no layer", () => {
    const r = resolveTemplate(BASE_TEMPLATE_V1, null, "superintendent");
    expect(r.sections.length).toBe(BASE_TEMPLATE_V1.sections.length);
    expect(r.resolvedFor).toBe("superintendent");
  });

  it("removes hidden sections from project layer", () => {
    const r = resolveTemplate(
      BASE_TEMPLATE_V1,
      { hiddenSectionIds: ["visitors", "delays"] },
      "superintendent",
    );
    const ids = r.sections.map((s) => s.id);
    expect(ids).not.toContain("visitors");
    expect(ids).not.toContain("delays");
  });

  it("appends added sections", () => {
    const r = resolveTemplate(
      BASE_TEMPLATE_V1,
      {
        addedSections: [
          { id: "tool_inventory", label: "Tool Inventory", kind: "custom", visibility: "optional" },
        ],
      },
      "superintendent",
    );
    const last = r.sections[r.sections.length - 1];
    expect(last.id).toBe("tool_inventory");
  });

  it("promotes optional sections to required via requiredSectionIds", () => {
    const r = resolveTemplate(
      BASE_TEMPLATE_V1,
      { requiredSectionIds: ["delays"] },
      "superintendent",
    );
    const delays = r.sections.find((s) => s.id === "delays");
    expect(delays?.visibility).toBe("required");
  });

  it("applies copyOverrides to labels", () => {
    const r = resolveTemplate(
      BASE_TEMPLATE_V1,
      { copyOverrides: { weather: "Site Conditions" } },
      "superintendent",
    );
    const w = r.sections.find((s) => s.id === "weather");
    expect(w?.label).toBe("Site Conditions");
  });

  it("hides crew_on_site and visitors for executive role", () => {
    const r = resolveTemplate(BASE_TEMPLATE_V1, null, "executive");
    const ids = r.sections.map((s) => s.id);
    expect(ids).not.toContain("crew_on_site");
    expect(ids).not.toContain("visitors");
  });

  it("is pure (same input → same output)", () => {
    const a = resolveTemplate(BASE_TEMPLATE_V1, { hiddenSectionIds: ["delays"] }, "projectManager");
    const b = resolveTemplate(BASE_TEMPLATE_V1, { hiddenSectionIds: ["delays"] }, "projectManager");
    expect(a).toEqual(b);
  });
});
