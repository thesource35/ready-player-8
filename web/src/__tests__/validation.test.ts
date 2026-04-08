import { describe, it, expect } from "vitest";
import { emailSchema, phoneSchema, leadSchema } from "@/lib/validation";
import { verifyCsrfOrigin } from "@/lib/csrf";

describe("emailSchema", () => {
  it("rejects invalid email", () => {
    const result = emailSchema.safeParse("notanemail");
    expect(result.success).toBe(false);
  });

  it("accepts valid email and lowercases it", () => {
    const result = emailSchema.safeParse("Test@Example.COM");
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data).toBe("test@example.com");
    }
  });
});

describe("phoneSchema", () => {
  it("rejects invalid phone", () => {
    const result = phoneSchema.safeParse("abc");
    expect(result.success).toBe(false);
  });

  it("accepts valid international phone", () => {
    const result = phoneSchema.safeParse("+1 (555) 123-4567");
    expect(result.success).toBe(true);
  });
});

describe("leadSchema", () => {
  const validLead = {
    fullName: "John Doe",
    email: "john@example.com",
    equipmentType: "Excavator",
  };

  it("rejects invalid email in lead", () => {
    const result = leadSchema.safeParse({ ...validLead, email: "notanemail" });
    expect(result.success).toBe(false);
    if (!result.success) {
      const fields = result.error.flatten().fieldErrors;
      expect(fields.email).toBeDefined();
    }
  });

  it("rejects empty fullName", () => {
    const result = leadSchema.safeParse({ ...validLead, fullName: "" });
    expect(result.success).toBe(false);
    if (!result.success) {
      const fields = result.error.flatten().fieldErrors;
      expect(fields.fullName).toBeDefined();
    }
  });

  it("accepts valid lead with required fields only", () => {
    const result = leadSchema.safeParse(validLead);
    expect(result.success).toBe(true);
  });

  it("applies defaults for quantity and deliveryNeeded", () => {
    const result = leadSchema.safeParse(validLead);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.quantity).toBe(1);
      expect(result.data.deliveryNeeded).toBe(true);
    }
  });
});

describe("verifyCsrfOrigin", () => {
  function makeRequest(headers: Record<string, string>): Request {
    return new Request("http://localhost:3000/api/test", {
      method: "POST",
      headers,
    });
  }

  it("returns false when Origin differs from Host", () => {
    const req = makeRequest({
      Origin: "https://evil.com",
      Host: "localhost:3000",
    });
    expect(verifyCsrfOrigin(req)).toBe(false);
  });

  it("returns true when Origin matches Host", () => {
    const req = makeRequest({
      Origin: "http://localhost:3000",
      Host: "localhost:3000",
    });
    expect(verifyCsrfOrigin(req)).toBe(true);
  });

  it("returns true when no Origin header (same-origin form)", () => {
    const req = makeRequest({
      Host: "localhost:3000",
    });
    expect(verifyCsrfOrigin(req)).toBe(true);
  });

  it("uses X-Forwarded-Host when Host is absent", () => {
    const req = makeRequest({
      Origin: "https://myapp.com",
      "X-Forwarded-Host": "myapp.com",
    });
    expect(verifyCsrfOrigin(req)).toBe(true);
  });
});
