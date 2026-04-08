import { validateRequiredEnvVars } from "@/lib/supabase/env";

export function register() {
  validateRequiredEnvVars();
}
