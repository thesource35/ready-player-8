import type { PlanId } from "@/lib/billing/plans";

export type FeaturePreview = {
  slug: string;
  title: string;
  eyebrow: string;
  description: string;
  recommendedPlan: PlanId;
  paidHref: string;
  highlights: string[];
  examples: Array<{
    label: string;
    value: string;
    note: string;
  }>;
};

const previewMap: Record<string, FeaturePreview> = {
  projects: {
    slug: "projects",
    title: "Project Command",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "See how ConstructionOS tracks project health, schedules, budgets, and superintendent ownership in one command view.",
    recommendedPlan: "pm",
    paidHref: "/projects",
    highlights: [
      "Real-time project scoring and status tracking",
      "Pipeline, budget, and superintendent visibility",
      "Add and manage live projects from one dashboard",
    ],
    examples: [
      { label: "Active projects", value: "5", note: "Mixed-use, infrastructure, high-rise, and municipal jobs" },
      { label: "Pipeline value", value: "$43.9M", note: "Roll-up visibility across active work" },
      { label: "Risk signal", value: "61", note: "Delayed projects surface faster for recovery planning" },
    ],
  },
  contracts: {
    slug: "contracts",
    title: "Bid Pipeline",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview how bid opportunities are scored, staged, and watched so your team knows what to chase first.",
    recommendedPlan: "pm",
    paidHref: "/contracts",
    highlights: [
      "7-stage pursuit workflow",
      "Scored opportunities and watcher counts",
      "Deadline visibility across the full bid board",
    ],
    examples: [
      { label: "Tracked bids", value: "7", note: "Healthcare, aviation, industrial, municipal, and commercial" },
      { label: "Top score", value: "94", note: "Houston Medical Complex currently ranks highest" },
      { label: "Active bids", value: "3", note: "Open for bid or prequalifying right now" },
    ],
  },
  feed: {
    slug: "feed",
    title: "ConstructionOS Network",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Unpaid users can preview the network experience here. Paid subscribers unlock posting, applying, following, and full crew/company workflow.",
    recommendedPlan: "field",
    paidHref: "/feed",
    highlights: [
      "Project updates, hiring posts, market listings, DMs, and company pages",
      "Post to the network and follow crews once subscribed",
      "Use the marketplace and job flow from the same feed",
    ],
    examples: [
      { label: "Professionals", value: "Growing", note: "Network size grows with each signup" },
      { label: "Live online", value: "8,420", note: "Sample activity level from the network header" },
      { label: "Feed modes", value: "5", note: "Feed, Jobs, Market, DMs, and Companies" },
    ],
  },
  jobs: {
    slug: "jobs",
    title: "Construction Jobs Board",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview the live hiring board. Paid subscribers can post roles in real time, while unpaid users can see the shape of the marketplace before upgrading.",
    recommendedPlan: "field",
    paidHref: "/jobs",
    highlights: [
      "Live hiring posts written into the ConstructionOS database",
      "Paid subscribers can publish roles and manage hiring visibility",
      "Applicants can use Angelic and the network flow to move faster",
    ],
    examples: [
      { label: "Board mode", value: "Live", note: "Designed for active openings, not dead-end placeholder cards" },
      { label: "Refresh", value: "30s", note: "Board refresh cadence in the paid experience" },
      { label: "Best fit", value: "Field+", note: "Available for paying subscribers who need hiring velocity" },
    ],
  },
  ai: {
    slug: "ai",
    title: "Angelic AI",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview the AI workspace that helps with bids, rentals, planning, field ops, pricing, and construction-specific guidance.",
    recommendedPlan: "pm",
    paidHref: "/ai",
    highlights: [
      "Construction-specific AI prompts and tool suggestions",
      "Project, rental, contract, and finance guidance in one workspace",
      "Subscriber access unlocks the full interactive assistant flow",
    ],
    examples: [
      { label: "AI tools", value: "56", note: "Referenced throughout the platform experience" },
      { label: "Core use cases", value: "6+", note: "Projects, rentals, contracts, ops, pricing, and wealth" },
      { label: "Recommended plan", value: "PM", note: "Best fit for supers, PMs, and estimators" },
    ],
  },
  rentals: {
    slug: "rentals",
    title: "Equipment Rentals",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview the rental marketplace experience, then unlock live quote requests, lead capture, and provider comparison with a paid plan.",
    recommendedPlan: "field",
    paidHref: "/rentals",
    highlights: [
      "97 rental items across multiple categories",
      "Provider comparison and direct rental links",
      "Quote request flow that writes to the rental leads database",
    ],
    examples: [
      { label: "Providers", value: "6", note: "United Rentals, Sunbelt, DOZR, BigRentz, Herc, and more" },
      { label: "Inventory", value: "97 items", note: "Heavy equipment, lifts, tools, generators, vehicles" },
      { label: "Lead flow", value: "Live", note: "Quote requests post into the rental leads path" },
    ],
  },
  finance: {
    slug: "finance",
    title: "Finance Hub",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview pay apps, waivers, cash flow, and finance workflows before unlocking the full subscriber workspace.",
    recommendedPlan: "owner",
    paidHref: "/finance",
    highlights: [
      "AIA pay app and waiver workflows",
      "Cash flow visibility and finance actions",
      "Best fit for owners and teams running project finance",
    ],
    examples: [
      { label: "Finance scope", value: "4+", note: "Pay apps, waivers, forecast, and supporting actions" },
      { label: "Best fit", value: "Owner", note: "Recommended for financial controls and portfolio view" },
      { label: "Workflow type", value: "Protected", note: "Subscriber actions are intentionally gated" },
    ],
  },
  ops: {
    slug: "ops",
    title: "Operations Command Center",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview operations alerts, queue management, and multi-panel job controls before unlocking the live work surface.",
    recommendedPlan: "pm",
    paidHref: "/ops",
    highlights: [
      "Priority alerts and action queue",
      "Change orders, safety incidents, and RFI visibility",
      "Subscriber flow for handling live ops work",
    ],
    examples: [
      { label: "Critical alerts", value: "2", note: "Sample command-center priority count" },
      { label: "Panels", value: "12", note: "Ops suite positioning used throughout the product" },
      { label: "Queue items", value: "4", note: "Action queue ready for PM-level workflow" },
    ],
  },
  "punch-list": {
    slug: "punch-list",
    title: "Punch List Manager",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Track, assign, and close out punch list items across all your projects with photo documentation and trade-specific workflows.",
    recommendedPlan: "pm",
    paidHref: "/punch",
    highlights: [
      "Create and assign punch items by trade and priority",
      "Photo documentation with item tracking",
      "Filter by status, trade, and priority",
    ],
    examples: [
      { label: "Open items", value: "6", note: "Across all active projects" },
      { label: "Trades tracked", value: "8", note: "Painting, HVAC, electrical, and more" },
      { label: "Completion rate", value: "75%", note: "Items resolved within deadline" },
    ],
  },
  "trust-score": {
    slug: "trust-score",
    title: "Trust Score",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Build and display your verified contractor trust score with peer endorsements, client reviews, and credential verification.",
    recommendedPlan: "pm",
    paidHref: "/trust",
    highlights: [
      "Multi-factor trust scoring across 6 categories",
      "Peer endorsements and client reviews",
      "Credential and photo proof verification",
    ],
    examples: [
      { label: "Trust score", value: "77/100", note: "Composite score across all categories" },
      { label: "Endorsements", value: "3", note: "From verified construction professionals" },
      { label: "Reviews", value: "5 stars", note: "Average across client reviews" },
    ],
  },
  hub: {
    slug: "hub",
    title: "Integration Hub",
    eyebrow: "PAID FEATURE PREVIEW",
    description: "Preview integration categories, API setup, and webhook visibility before unlocking connected workflow management.",
    recommendedPlan: "owner",
    paidHref: "/hub",
    highlights: [
      "Supabase, Microsoft, accounting, docs, and webhook awareness",
      "Central place for API and integration visibility",
      "Owner-level plan fit for connected operations",
    ],
    examples: [
      { label: "Integrations shown", value: "8", note: "Database, notifications, mail, accounting, docs, e-sign, and more" },
      { label: "Webhooks", value: "4", note: "Project, payment, safety, and bid events" },
      { label: "API status", value: "Mixed", note: "Configured services plus upgrade-ready slots" },
    ],
  },
};

function startCase(value: string) {
  return value
    .split("-")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function getFeaturePreview(slug: string): FeaturePreview {
  const preview = previewMap[slug];

  if (preview) return preview;

  const title = startCase(slug || "feature");

  return {
    slug,
    title,
    eyebrow: "PAID FEATURE PREVIEW",
    description: `Preview what ${title} looks like before unlocking the full subscriber experience.`,
    recommendedPlan: "pm",
    paidHref: `/${slug}`,
    highlights: [
      `${title} is part of the paid ConstructionOS workspace`,
      "Subscribers unlock the live, interactive version of this feature",
      "Preview mode is designed to show the value before upgrade",
    ],
    examples: [
      { label: "Access", value: "Preview", note: "This page is intentionally visible to unpaid users" },
      { label: "Upgrade path", value: "Live", note: "Paid subscribers reach the full workflow" },
      { label: "Route", value: `/${slug}`, note: "Unlocked automatically when the user has paid access" },
    ],
  };
}
