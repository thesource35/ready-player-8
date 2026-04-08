import Link from "next/link";
import AngelicFlowStrip from "@/app/components/AngelicFlowStrip";
import { getFeaturePreview } from "@/lib/subscription/featurePreviews";

export default async function FeaturePreviewPage({
  params,
}: {
  params: Promise<{ feature: string }>;
}) {
  const { feature } = await params;
  const preview = getFeaturePreview(feature);

  return (
    <div className="min-h-screen px-4 py-12" style={{ background: "#080E12" }}>
      <div className="max-w-4xl mx-auto">
        <div
          className="rounded-3xl p-8 mb-8"
          style={{
            background: "linear-gradient(180deg, rgba(15,28,36,0.96), rgba(8,14,18,0.98))",
            border: "1px solid rgba(242,158,61,0.12)",
          }}
        >
          <div className="text-[11px] font-black tracking-[0.3em] text-[#F29E3D] mb-3">{preview.eyebrow}</div>
          <h1 className="text-4xl md:text-5xl font-black mb-3">{preview.title}</h1>
          <p className="text-sm md:text-base text-[#9EBDC2] max-w-2xl mb-6">{preview.description}</p>
          <div className="flex gap-3 flex-wrap">
            <Link
              href={`/checkout?plan=${preview.recommendedPlan}&redirect=${encodeURIComponent(preview.paidHref)}`}
              className="px-6 py-3 rounded-xl text-sm font-bold text-black"
              style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}
            >
              Unlock Full Feature
            </Link>
            <Link
              href="/pricing"
              className="px-6 py-3 rounded-xl text-sm font-bold text-[#4AC4CC] border border-[#4AC4CC]"
            >
              Compare Plans
            </Link>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
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

        <div
          className="rounded-2xl p-6 mb-8"
          style={{ background: "#0F1C24", border: "1px solid rgba(105,210,148,0.12)" }}
        >
          <div className="text-[11px] font-black tracking-[0.2em] text-[#69D294] mb-3">WHAT SUBSCRIBERS UNLOCK</div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {preview.highlights.map((highlight) => (
              <div
                key={highlight}
                className="rounded-xl p-4 text-sm text-[#F0F8F8]"
                style={{ background: "rgba(105,210,148,0.05)", border: "1px solid rgba(105,210,148,0.08)" }}
              >
                {highlight}
              </div>
            ))}
          </div>
        </div>

        <div
          className="rounded-2xl p-6 text-center"
          style={{ background: "#0F1C24", border: "1px solid rgba(242,158,61,0.12)" }}
        >
          <div className="text-[10px] font-black tracking-[0.2em] text-[#FCC757] mb-2">UPGRADE PATH</div>
          <h2 className="text-2xl font-black mb-2">Ready to use this feature? Subscribe to unlock full access.</h2>
          <p className="text-sm text-[#9EBDC2] mb-5">
            Subscribers get full access to all live features, AI tools, and real-time data across the entire platform.
          </p>
          <div className="flex gap-3 justify-center flex-wrap">
            <Link
              href={`/checkout?plan=${preview.recommendedPlan}&redirect=${encodeURIComponent(preview.paidHref)}`}
              className="px-6 py-3 rounded-xl text-sm font-bold text-black"
              style={{ background: "linear-gradient(90deg, #69D294, #4AC4CC)" }}
            >
              Start Paid Access
            </Link>
            <Link href="/" className="px-6 py-3 rounded-xl text-sm font-bold text-[#9EBDC2] border border-[#33545E]">
              Back to Homepage
            </Link>
          </div>
        </div>

        <div className="mt-8">
          <AngelicFlowStrip
            title={`Ask Angelic About ${preview.title}`}
            description="Angelic AI provides intelligent assistance across every feature of the platform."
            prompts={[
              `How would Angelic help with ${preview.title}?`,
              `What does the paid version of ${preview.title} unlock?`,
              `Which plan should I choose for ${preview.title}?`,
            ]}
          />
        </div>
      </div>
    </div>
  );
}
