import { z } from "zod";

// Shared zod schemas for Phase 15 Team & Crew API routes.
// Imported by route handlers and by vitest tests to keep validation rules
// in one place (see web/src/lib/team/__tests__/team.test.ts).

export const memberSchema = z.object({
  kind: z.enum(["internal", "subcontractor", "vendor"]),
  name: z.string().trim().min(1, "name required").max(200),
  role: z.string().max(100).optional().nullable(),
  trade: z.string().max(100).optional().nullable(),
  email: z.string().email().optional().nullable(),
  phone: z.string().max(40).optional().nullable(),
  company: z.string().max(200).optional().nullable(),
  notes: z.string().max(2000).optional().nullable(),
  user_id: z.string().uuid().optional().nullable(),
});

export const assignmentSchema = z.object({
  project_id: z.string().uuid(),
  member_id: z.string().uuid(),
  role_on_project: z.string().max(100).optional().nullable(),
  start_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .nullable(),
  end_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .nullable(),
  status: z.enum(["active", "paused", "ended"]).default("active"),
});

export const certSchema = z.object({
  member_id: z.string().uuid(),
  name: z.string().min(1).max(200),
  issuer: z.string().max(200).optional().nullable(),
  number: z.string().max(100).optional().nullable(),
  issued_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .nullable(),
  expires_at: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .nullable(),
  document_id: z.string().uuid().optional().nullable(),
  status: z.enum(["active", "expired", "revoked"]).default("active"),
});

export const dailyCrewSchema = z.object({
  assignment_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  member_ids: z.array(z.string().uuid()).default([]),
  notes: z.string().max(2000).optional().nullable(),
});
