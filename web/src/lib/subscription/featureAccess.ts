import type { PlanId } from "@/lib/billing/plans";

const tierRank: Record<string, number> = {
  free: 0,
  field: 1,
  pm: 2,
  owner: 3,
};

const featurePlanMap: Record<string, PlanId> = {
  feed: "field",
  jobs: "field",
  rentals: "field",
  compliance: "field",
  field: "field",
  projects: "pm",
  contracts: "pm",
  market: "pm",
  maps: "pm",
  ops: "pm",
  ai: "pm",
  analytics: "pm",
  clients: "pm",
  schedule: "pm",
  training: "pm",
  scanner: "pm",
  electrical: "pm",
  tax: "pm",
  punch: "pm",
  "punch-list": "pm",
  roofing: "pm",
  "smart-build": "pm",
  contractors: "pm",
  tech: "pm",
  "trust-score": "pm",
  wealth: "pm",
  finance: "owner",
  hub: "owner",
  empire: "owner",
};

function normalizeTier(tier: string) {
  const value = tier.toLowerCase();

  if (value === "field_worker" || value === "fieldworker") return "field";
  if (value === "project_manager" || value === "projectmanager") return "pm";
  if (value === "company_owner" || value === "companyowner") return "owner";

  return value;
}

export function getFeatureRequiredPlan(feature: string): PlanId {
  return featurePlanMap[feature] ?? "pm";
}

export function hasFeatureAccess(tier: string, feature: string) {
  const normalizedTier = normalizeTier(tier);
  const requiredPlan = getFeatureRequiredPlan(feature);

  return (tierRank[normalizedTier] ?? 0) >= tierRank[requiredPlan];
}

export function getFeatureUpgradeHref(feature: string, paidHref?: string) {
  const requiredPlan = getFeatureRequiredPlan(feature);
  const liveHref = paidHref ?? `/${feature}`;

  return `/checkout?plan=${requiredPlan}&redirect=${encodeURIComponent(liveHref)}`;
}

export function resolveFeatureAccess(feature: string, tier: string, paidHref?: string) {
  const liveHref = paidHref ?? `/${feature}`;
  const previewHref = `/preview/${feature}`;
  const requiredPlan = getFeatureRequiredPlan(feature);
  const hasAccess = hasFeatureAccess(tier, feature);

  return {
    feature,
    requiredPlan,
    hasAccess,
    liveHref,
    previewHref,
    upgradeHref: getFeatureUpgradeHref(feature, liveHref),
  };
}
