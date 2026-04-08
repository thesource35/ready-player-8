"use client";

import type { CSSProperties, ReactNode } from "react";
import Link from "next/link";
import { useSubscriptionTier } from "@/lib/subscription/useSubscriptionTier";
import { resolveFeatureAccess } from "@/lib/subscription/featureAccess";

type FeatureAccessLinkProps = {
  feature: string;
  paidHref: string;
  previewHref?: string;
  children: ReactNode;
  className?: string;
  style?: CSSProperties;
  onClick?: () => void;
};

export default function FeatureAccessLink({
  feature,
  paidHref,
  previewHref,
  children,
  className,
  style,
  onClick,
}: FeatureAccessLinkProps) {
  const { tier } = useSubscriptionTier();
  const access = resolveFeatureAccess(feature, tier, paidHref);
  const href = access.hasAccess ? access.liveHref : previewHref ?? access.previewHref;

  return (
    <Link href={href} className={className} style={style} onClick={onClick}>
      {children}
    </Link>
  );
}
