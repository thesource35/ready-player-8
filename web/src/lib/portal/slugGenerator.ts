// Slug generation for portal URLs (D-24)
// Converts project/company names to URL-safe slugs

/**
 * Generate a URL-safe slug from a name string.
 * Lowercase, replace spaces with hyphens, strip non-alphanumeric except hyphens, max 50 chars.
 */
export function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")           // spaces -> hyphens
    .replace(/[^a-z0-9-]/g, "")     // strip non-alphanumeric except hyphens
    .replace(/-{2,}/g, "-")         // collapse multiple hyphens
    .replace(/^-+|-+$/g, "")        // trim leading/trailing hyphens
    .slice(0, 50);
}

/**
 * Generate a URL-safe slug from a company name.
 * Same logic as generateSlug — separate function for semantic clarity.
 */
export function generateCompanySlug(companyName: string): string {
  return generateSlug(companyName);
}
