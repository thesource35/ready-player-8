// Portal types per D-97 through D-112

export type PortalLinkType = "report" | "portal";

export type PortalTemplate =
  | "executive_summary"
  | "full_progress"
  | "photo_update";

export type PortalSectionKey =
  | "schedule"
  | "budget"
  | "photos"
  | "change_orders"
  | "documents";

export type PortalSectionsConfig = {
  schedule: { enabled: boolean; date_range?: { start: string; end: string } };
  budget: { enabled: boolean; date_range?: { start: string; end: string } };
  photos: { enabled: boolean; date_range?: { start: string; end: string } };
  change_orders: {
    enabled: boolean;
    date_range?: { start: string; end: string };
  };
  documents: { enabled: boolean; allowed_document_ids?: string[] };
  // D-13: Portal map overlay configuration. Optional for backward compatibility
  // with portal links created before Phase 21.
  map_overlays?: {
    show_map: boolean;
    satellite: boolean;
    traffic: boolean;
    equipment: boolean;
    photos: boolean;
  };
};

// D-13: Default map overlay configuration. Used when a portal link has no
// map_overlays field (backward compatibility) or as the initial state in the
// portal creation dialog.
export const DEFAULT_MAP_OVERLAYS = {
  show_map: true,
  satellite: true,
  traffic: false,
  equipment: false,
  photos: true,
} as const;

export type PortalConfig = {
  id: string;
  link_id: string;
  project_id: string;
  user_id: string;
  org_id: string | null;
  slug: string;
  company_slug: string;
  template: PortalTemplate;
  sections_config: PortalSectionsConfig;
  show_exact_amounts: boolean;
  welcome_message: string | null;
  section_notes: Record<string, string>;
  pinned_items: Record<string, string[]>;
  date_ranges: Record<string, { start: string; end: string }>;
  watermark_enabled: boolean;
  powered_by_enabled: boolean;
  client_email: string | null;
  created_at: string;
  updated_at: string;
};

export type PortalThemeConfig = {
  primary: string;
  secondary: string;
  background: string;
  text: string;
  cardBg: string;
  fontFamily: "Inter" | "Roboto" | "Source Sans 3" | "DM Sans";
  borderRadius: number;
  customCSS: string | null;
};

export type CompanyBranding = {
  id: string;
  org_id: string;
  user_id: string;
  company_name: string;
  logo_light_path: string | null;
  logo_dark_path: string | null;
  favicon_path: string | null;
  cover_image_path: string | null;
  theme_config: PortalThemeConfig;
  font_family: string;
  custom_css: string | null;
  contact_info: {
    email?: string;
    phone?: string;
    website?: string;
    address?: string;
  };
  created_at: string;
  updated_at: string;
};

export type PortalAnalyticsEvent = {
  id: string;
  portal_config_id: string;
  link_id: string;
  section_viewed: string | null;
  time_spent_ms: number | null;
  scroll_depth_pct: number | null;
  ip_hash: string | null;
  user_agent: string | null;
  created_at: string;
};

export type PortalAuditAction =
  | "link_created"
  | "link_revoked"
  | "link_deleted"
  | "config_updated"
  | "branding_updated"
  | "portal_viewed"
  | "portal_expired"
  | "ip_blocked";

export type PortalAuditLog = {
  id: string;
  user_id: string | null;
  action: PortalAuditAction;
  portal_config_id: string | null;
  link_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
};

// Default section configs per template (D-18, D-33)
// D-13: Each template also seeds map_overlays with template-appropriate defaults.
export const TEMPLATE_DEFAULTS: Record<PortalTemplate, PortalSectionsConfig> = {
  executive_summary: {
    schedule: { enabled: true },
    budget: { enabled: false }, // D-33: budget always defaults hidden
    photos: { enabled: false },
    change_orders: { enabled: true },
    documents: { enabled: false },
    map_overlays: {
      show_map: true,
      satellite: true,
      traffic: false,
      equipment: false,
      photos: true,
    },
  },
  full_progress: {
    schedule: { enabled: true },
    budget: { enabled: false },
    photos: { enabled: true },
    change_orders: { enabled: true },
    documents: { enabled: true },
    map_overlays: {
      show_map: true,
      satellite: true,
      traffic: false,
      equipment: true,
      photos: true,
    },
  },
  photo_update: {
    schedule: { enabled: false },
    budget: { enabled: false },
    photos: { enabled: true },
    change_orders: { enabled: false },
    documents: { enabled: false },
    map_overlays: {
      show_map: true,
      satellite: true,
      traffic: false,
      equipment: false,
      photos: true,
    },
  },
};

// D-32: Fixed section display order
export const SECTION_ORDER: PortalSectionKey[] = [
  "schedule",
  "budget",
  "photos",
  "change_orders",
  "documents",
];

// D-109: Rate limits
export const PORTAL_RATE_LIMITS = {
  viewsPerDayPerLink: 100,
  managementPerHourPerUser: 50,
  failedLookupPerMinPerIP: 10,
};

// D-04: Expiry options
export const EXPIRY_OPTIONS = [
  { label: "7 days", days: 7 },
  { label: "30 days", days: 30 },
  { label: "90 days", days: 90 },
  { label: "Never expires", days: null },
] as const;
