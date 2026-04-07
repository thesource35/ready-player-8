// ─── Environment variable access with validation ──────────────────────

const warned = new Set<string>();

function warnOnce(key: string) {
  if (warned.has(key)) return;
  warned.add(key);
  console.error(`[ConstructionOS] Missing required env var: ${key} — running in demo mode`);
}

export function getSupabaseUrl(): string {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
  if (!url) warnOnce("NEXT_PUBLIC_SUPABASE_URL");
  return url;
}

export function getSupabasePublishableKey(): string {
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
    "";
  if (!key) warnOnce("NEXT_PUBLIC_SUPABASE_ANON_KEY");
  return key;
}

export function getSupabaseServerKey(): string {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  if (!key) warnOnce("SUPABASE_SERVICE_ROLE_KEY");
  return key;
}

export function isSupabaseConfigured(): boolean {
  return !!(getSupabaseUrl() && getSupabasePublishableKey());
}

// ─── Startup validation ───────────────────────────────────────────────

export function validateRequiredEnvVars() {
  const required: Record<string, string | undefined> = {
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY:
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  };
  const optional: Record<string, string | undefined> = {
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
    SQUARE_WEBHOOK_SIGNATURE_KEY: process.env.SQUARE_WEBHOOK_SIGNATURE_KEY,
  };

  const missingRequired = Object.entries(required)
    .filter(([, v]) => !v)
    .map(([k]) => k);
  const missingOptional = Object.entries(optional)
    .filter(([, v]) => !v)
    .map(([k]) => k);

  if (missingRequired.length > 0) {
    console.error(
      `[ConstructionOS] MISSING REQUIRED env vars: ${missingRequired.join(", ")} — app will run in demo mode`,
    );
  }
  if (missingOptional.length > 0) {
    console.warn(
      `[ConstructionOS] Missing optional env vars: ${missingOptional.join(", ")} — some features disabled`,
    );
  }
}

// Validate on startup
validateRequiredEnvVars();
