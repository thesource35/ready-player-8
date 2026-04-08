"use client";

import FeatureAccessLink from "./FeatureAccessLink";
import AngelicPromptToggle from "./AngelicPromptToggle";

type AngelicFlowStripProps = {
  title?: string;
  description?: string;
  prompts: string[];
};

export default function AngelicFlowStrip({
  title = "Flow Into Angelic AI",
  description = "Move users from browsing the site into a prompt-aware AI workflow without losing context.",
  prompts,
}: AngelicFlowStripProps) {
  return (
    <div
      className="rounded-2xl p-6"
      style={{
        background: "linear-gradient(135deg, rgba(138,143,204,0.12), rgba(74,196,204,0.08))",
        border: "1px solid rgba(138,143,204,0.18)",
      }}
    >
      <div className="text-[10px] font-black tracking-[0.2em] text-[#8A8FCC] mb-2">ANGELIC FLOW</div>
      <h3 className="text-2xl font-black mb-2">{title}</h3>
      <p className="text-sm text-[#9EBDC2] mb-4 max-w-2xl">{description}</p>
      <AngelicPromptToggle />
      <div className="flex flex-wrap gap-2">
        {prompts.map((prompt) => (
          <FeatureAccessLink
            key={prompt}
            feature="ai"
            paidHref={`/ai?prompt=${encodeURIComponent(prompt)}`}
            className="px-4 py-2 rounded-xl text-sm font-bold text-black"
            style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}
          >
            {prompt}
          </FeatureAccessLink>
        ))}
      </div>
    </div>
  );
}
