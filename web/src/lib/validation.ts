import { z } from "zod";

export const emailSchema = z
  .string()
  .trim()
  .email("Invalid email address")
  .transform((v) => v.toLowerCase());

export const phoneSchema = z
  .string()
  .regex(/^\+?[\d\s\-().]{7,20}$/, "Invalid phone number");

export const leadSchema = z.object({
  fullName: z.string().min(1, "Full name is required").max(200),
  email: emailSchema,
  equipmentType: z.string().min(1, "Equipment type is required").max(200),
  phone: phoneSchema.optional(),
  company: z.string().max(200).optional(),
  projectName: z.string().max(300).optional(),
  projectLocation: z.string().max(300).optional(),
  rentalStart: z.string().optional(),
  rentalDuration: z.string().optional(),
  budgetRange: z.string().optional(),
  quantity: z.number().int().min(1).max(999).default(1),
  deliveryNeeded: z.boolean().default(true),
  notes: z.string().max(2000).optional(),
  category: z.string().max(100).optional(),
});

export type LeadInput = z.infer<typeof leadSchema>;
