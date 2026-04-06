// Per-page SEO metadata — single source of truth.
// Server pages import directly; client pages use via layout.tsx.

import type { Metadata } from "next";

const base = {
  siteName: "ConstructionOS",
  url: "https://constructionos.world",
};

export const pageMetadata: Record<string, Metadata> = {
  projects: {
    title: "Projects — ConstructionOS",
    description: "Full project lifecycle management with real-time sync, scoring, status tracking, and CRUD operations.",
    openGraph: { ...base, title: "Projects — ConstructionOS" },
  },
  contracts: {
    title: "Bid Pipeline — ConstructionOS",
    description: "Track, score, and manage all bid opportunities with a 7-stage workflow.",
    openGraph: { ...base, title: "Bid Pipeline — ConstructionOS" },
  },
  market: {
    title: "Market Intelligence — ConstructionOS",
    description: "8 metro markets with vacancy rates, permits, PSF data, and trend insights.",
    openGraph: { ...base, title: "Market Intelligence — ConstructionOS" },
  },
  maps: {
    title: "Live Maps — ConstructionOS",
    description: "Satellite-backed site awareness with thermal, crew, and weather overlays.",
    openGraph: { ...base, title: "Live Maps — ConstructionOS" },
  },
  feed: {
    title: "Construction Network — ConstructionOS",
    description: "Social feed, job board, equipment marketplace, DMs, and company pages for construction professionals.",
    openGraph: { ...base, title: "Construction Network — ConstructionOS" },
  },
  jobs: {
    title: "Jobs Board — ConstructionOS",
    description: "Find and post construction jobs. Live hiring board for trades, PMs, and superintendents.",
    openGraph: { ...base, title: "Jobs Board — ConstructionOS" },
  },
  ops: {
    title: "Operations Command Center — ConstructionOS",
    description: "Change orders, safety incidents, RFIs, priority alerts, and action queue.",
    openGraph: { ...base, title: "Ops Command Center — ConstructionOS" },
  },
  hub: {
    title: "Integration Hub — ConstructionOS",
    description: "Connect Supabase, QuickBooks, Microsoft 365, Procore, PlanGrid, DocuSign, and webhooks.",
    openGraph: { ...base, title: "Integration Hub — ConstructionOS" },
  },
  security: {
    title: "Security & Access — ConstructionOS",
    description: "Face ID, 2FA, AES-256 encryption, session management, and audit logging.",
    openGraph: { ...base, title: "Security — ConstructionOS" },
  },
  pricing: {
    title: "Pricing — ConstructionOS",
    description: "3 plans starting at $9.99/mo. Field Worker, Project Manager, and Company Owner tiers.",
    openGraph: { ...base, title: "Pricing — ConstructionOS" },
  },
  ai: {
    title: "Angelic AI — ConstructionOS",
    description: "Claude-powered AI assistant with 56 construction tools, live data access, and streaming responses.",
    openGraph: { ...base, title: "Angelic AI — ConstructionOS" },
  },
  field: {
    title: "Field Operations — ConstructionOS",
    description: "Daily logs, timecards with OT calc, equipment tracker, and permit management.",
    openGraph: { ...base, title: "Field Operations — ConstructionOS" },
  },
  finance: {
    title: "Finance Hub — ConstructionOS",
    description: "AIA pay apps, lien waiver management, cash flow forecasting, and financial workflows.",
    openGraph: { ...base, title: "Finance Hub — ConstructionOS" },
  },
  compliance: {
    title: "Compliance — ConstructionOS",
    description: "Toolbox talks, certified payroll, SWPPP, and environmental compliance tracking.",
    openGraph: { ...base, title: "Compliance — ConstructionOS" },
  },
  clients: {
    title: "Client Portal — ConstructionOS",
    description: "Owner dashboard with progress tracking, material selections, and OAC meeting minutes.",
    openGraph: { ...base, title: "Client Portal — ConstructionOS" },
  },
  analytics: {
    title: "Analytics & AI Risk — ConstructionOS",
    description: "Bid win/loss analysis, labor productivity benchmarks, and ML-based project risk scoring.",
    openGraph: { ...base, title: "Analytics — ConstructionOS" },
  },
  schedule: {
    title: "Schedule & Gantt — ConstructionOS",
    description: "26-week Gantt chart with critical path, milestones, and 3-week lookahead.",
    openGraph: { ...base, title: "Schedule — ConstructionOS" },
  },
  training: {
    title: "Training & Certs — ConstructionOS",
    description: "OSHA 30, CPR/AED, confined space, PMP — course catalog with progress tracking.",
    openGraph: { ...base, title: "Training — ConstructionOS" },
  },
  scanner: {
    title: "QR & Barcode Scanner — ConstructionOS",
    description: "Crew badge sign-in, material PO verification, equipment tags, and document scanning.",
    openGraph: { ...base, title: "Scanner — ConstructionOS" },
  },
  electrical: {
    title: "Electrical & Fiber — ConstructionOS",
    description: "Verified electrical contractors with ratings, job leads, and fiber FTTH projects.",
    openGraph: { ...base, title: "Electrical — ConstructionOS" },
  },
  tax: {
    title: "Tax Accountant — ConstructionOS",
    description: "12 IRS categories, deduction tracker, quarterly estimates, 1099 filing, and CPA directory.",
    openGraph: { ...base, title: "Tax — ConstructionOS" },
  },
  punch: {
    title: "Punch List Pro — ConstructionOS",
    description: "Track, assign, and close out punch items with photo documentation and status workflow.",
    openGraph: { ...base, title: "Punch List — ConstructionOS" },
  },
  roofing: {
    title: "Satellite Roofing — ConstructionOS",
    description: "AI roof estimator with 9 materials, pitch calculator, and full cost breakdown.",
    openGraph: { ...base, title: "Roofing — ConstructionOS" },
  },
  "smart-build": {
    title: "Smart Build Hub — ConstructionOS",
    description: "Concrete AI, BIM clash detection, net zero design, and modular construction tools.",
    openGraph: { ...base, title: "Smart Build — ConstructionOS" },
  },
  contractors: {
    title: "Contractor Directory — ConstructionOS",
    description: "12+ verified contractors across 25 trades and 6 countries with ratings and specialties.",
    openGraph: { ...base, title: "Directory — ConstructionOS" },
  },
  tech: {
    title: "Tech 2026 — ConstructionOS",
    description: "Digital twins, construction robotics, 3D scanning, sustainability, wearables, 5G/IoT, AI/ML.",
    openGraph: { ...base, title: "Tech 2026 — ConstructionOS" },
  },
  wealth: {
    title: "Wealth Intelligence — ConstructionOS",
    description: "Money Lens, Psychology Decoder, Power Thinking, Leverage System, and Opportunity Filter.",
    openGraph: { ...base, title: "Wealth — ConstructionOS" },
  },
  "cos-network": {
    title: "COS Network — ConstructionOS",
    description: "The construction professional network with verified profiles and trust scoring.",
    openGraph: { ...base, title: "COS Network — ConstructionOS" },
  },
  rentals: {
    title: "Equipment Rentals — ConstructionOS",
    description: "97 items across 6 providers with AI recommendations, bundles, and quote requests.",
    openGraph: { ...base, title: "Rentals — ConstructionOS" },
  },
  empire: {
    title: "Financial Empire — ConstructionOS",
    description: "Pay, Capital, Insurance, Workforce, Supply Chain, Bonds, and Intelligence products.",
    openGraph: { ...base, title: "Empire — ConstructionOS" },
  },
  settings: {
    title: "Settings — ConstructionOS",
    description: "Role presets, security toggles, subscription management, and data export.",
    openGraph: { ...base, title: "Settings — ConstructionOS" },
  },
  tasks: {
    title: "Task Center — ConstructionOS",
    description: "AI task manager with todos, schedule, reminders, and priority suggestions.",
    openGraph: { ...base, title: "Tasks — ConstructionOS" },
  },
  trust: {
    title: "Trust & Reputation — ConstructionOS",
    description: "Credentials, peer endorsements, client reviews, and combined trust scoring.",
    openGraph: { ...base, title: "Trust — ConstructionOS" },
  },
  verify: {
    title: "Verification — ConstructionOS",
    description: "3-tier verification: Identity, Licensed Professional, and Verified Company.",
    openGraph: { ...base, title: "Verify — ConstructionOS" },
  },
  profile: {
    title: "Profile — ConstructionOS",
    description: "Manage your construction professional profile, trade, company, and credentials.",
    openGraph: { ...base, title: "Profile — ConstructionOS" },
  },
  login: {
    title: "Sign In — ConstructionOS",
    description: "Sign in or create your ConstructionOS account.",
    openGraph: { ...base, title: "Sign In — ConstructionOS" },
  },
  checkout: {
    title: "Checkout — ConstructionOS",
    description: "Subscribe to ConstructionOS and unlock the full platform.",
    openGraph: { ...base, title: "Checkout — ConstructionOS" },
  },
  terms: {
    title: "Terms & Conditions — ConstructionOS",
    description: "ConstructionOS terms of service and usage agreement.",
  },
  privacy: {
    title: "Privacy Policy — ConstructionOS",
    description: "ConstructionOS privacy policy and data handling practices.",
  },
  support: {
    title: "Support — ConstructionOS",
    description: "Get help with ConstructionOS. Contact support, FAQs, and documentation.",
  },
};

export function getPageMetadata(slug: string): Metadata {
  return pageMetadata[slug] ?? {
    title: `${slug.charAt(0).toUpperCase() + slug.slice(1)} — ConstructionOS`,
    description: "ConstructionOS — The Construction Command Center",
  };
}
