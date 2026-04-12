// next-intl configuration for App Router (D-86)
// Default locale: 'en', extensible to additional locales.
// Per RESEARCH.md pitfall 8: keep config minimal, English-only to start.

import { getRequestConfig } from "next-intl/server";

export const defaultLocale = "en";
export const locales = ["en"] as const;
export type Locale = (typeof locales)[number];

export default getRequestConfig(async () => {
  // For now, always return English messages.
  // When adding locales, resolve from request headers or URL segment.
  const messages = (await import("@/lib/reports/i18n-messages/en.json")).default;

  return {
    locale: defaultLocale,
    messages,
  };
});
