"use client";

import type { CSSProperties } from "react";
import type { PlanId } from "@/lib/billing/plans";
import { useSubscriptionTier } from "@/lib/subscription/useSubscriptionTier";
import { getFeatureUpgradeHref } from "@/lib/subscription/featureAccess";

type SubscriberActionButtonProps = {
  label: string;
  checkoutPlan?: PlanId;
  feature?: string;
  paidHref?: string;
  onPaidClick?: () => void;
  className?: string;
  style?: CSSProperties;
  title?: string;
};

export default function SubscriberActionButton({
  label,
  checkoutPlan = "pm",
  feature,
  paidHref,
  onPaidClick,
  className,
  style,
  title,
}: SubscriberActionButtonProps) {
  const { tier, hasPaidAccess } = useSubscriptionTier();

  function goToCheckout() {
    const routeFeature = feature ?? paidHref?.replace(/^\//, "") ?? "feed";
    const href = getFeatureUpgradeHref(routeFeature, paidHref);
    const params = new URL(href, window.location.origin);

    if (checkoutPlan) {
      params.searchParams.set("plan", checkoutPlan);
    }

    window.location.assign(params.pathname + params.search);
  }

  function handleClick() {
    if (hasPaidAccess || tier === "owner" || tier === "pm" || tier === "field") {
      if (onPaidClick) {
        onPaidClick();
        return;
      }

      if (paidHref) {
        window.location.assign(paidHref);
        return;
      }
    }

    goToCheckout();
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      className={className}
      style={style}
      title={hasPaidAccess ? title : "Paid subscriber feature"}
    >
      {label}
    </button>
  );
}
