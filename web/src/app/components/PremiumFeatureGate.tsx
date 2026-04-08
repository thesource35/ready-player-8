"use client";

import type { ReactNode } from "react";
import Link from "next/link";
import { getFeaturePreview } from "@/lib/subscription/featurePreviews";
import { useSubscriptionTier } from "@/lib/subscription/useSubscriptionTier";
import { resolveFeatureAccess } from "@/lib/subscription/featureAccess";

type PremiumFeatureGateProps = {
  feature: string;
  children: ReactNode;
};

export default function PremiumFeatureGate({
  feature,
  children,
}: PremiumFeatureGateProps) {
  const { tier, loading } = useSubscriptionTier();
  const preview = getFeaturePreview(feature);
  const access = resolveFeatureAccess(feature, tier, preview.paidHref);

  if (loading) {
    return (
      <div className="min-h-[50vh] flex items-center justify-center px-4 py-12">
        <div
          className="rounded-2xl p-6 text-center max-w-md"
          style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.08)" }}
        >
          <div className="text-[10px] font-black tracking-[0.2em] text-[#4AC4CC] mb-2">CHECKING ACCESS</div>
          <h2 className="text-xl font-black mb-2">Loading your feature access...</h2>
          <p className="text-sm text-[#9EBDC2]">We&apos;re checking your subscription tier before opening the full workspace.</p>
        </div>
      </div>
    );
  }

  if (access.hasAccess) {
    return <>{children}</>;
  }

  return (
    <div className="min-h-[60vh] px-4 py-10">
      <div className="max-w-4xl mx-auto">
        <div
          className="rounded-3xl p-8 mb-8"
          style={{
            background: "linear-gradient(180deg, rgba(15,28,36,0.96), rgba(8,14,18,0.98))",
            border: "1px solid rgba(242,158,61,0.12)",
          }}
        >
          <div className="text-[11px] font-black tracking-[0.3em] text-[#F29E3D] mb-3">{preview.eyebrow}</div>
          <h1 className="text-4xl font-black mb-3">{preview.title}</h1>
          <p className="text-sm text-[#9EBDC2] max-w-2xl mb-6">{preview.description}</p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            {preview.examples.map((example) => (
              <div
                key={example.label}
                className="rounded-2xl p-5"
                style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.08)" }}
              >
                <div className="text-[10px] font-black tracking-[0.18em] text-[#9EBDC2] mb-2">{example.label}</div>
                <div className="text-2xl font-black text-[#F29E3D] mb-2">{example.value}</div>
                <p className="text-xs text-[#9EBDC2]">{example.note}</p>
              </div>
            ))}
          </div>
          <div className="flex gap-3 flex-wrap">
            <Link
              href={access.upgradeHref}
              className="px-6 py-3 rounded-xl text-sm font-bold text-black"
              style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}
            >
              Unlock Full Feature
            </Link>
            <Link href={access.previewHref} className="px-6 py-3 rounded-xl text-sm font-bold text-[#4AC4CC] border border-[#4AC4CC]">
              Explore Feature
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
