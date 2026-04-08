"use client";

import { useEffect, useState } from "react";
import { ANGELIC_BUBBLE_ENABLED_KEY, ANGELIC_BUBBLE_EVENT } from "@/lib/angelic/preferences";

type AngelicPromptToggleProps = {
  compact?: boolean;
};

export default function AngelicPromptToggle({ compact = false }: AngelicPromptToggleProps) {
  const [enabled, setEnabled] = useState(() => {
    if (typeof window === "undefined") return true;
    try {
      const storedValue = window.localStorage.getItem(ANGELIC_BUBBLE_ENABLED_KEY);
      return storedValue === null ? true : storedValue === "true";
    } catch {
      return true;
    }
  });

  useEffect(() => {
    try {
      const storedValue = window.localStorage.getItem(ANGELIC_BUBBLE_ENABLED_KEY);
      if (storedValue === null) {
        window.localStorage.setItem(ANGELIC_BUBBLE_ENABLED_KEY, "true");
      }
    } catch {
      // ignore
    }
  }, []);

  function setPromptPreference(nextEnabled: boolean) {
    try {
      window.localStorage.setItem(ANGELIC_BUBBLE_ENABLED_KEY, String(nextEnabled));
      window.dispatchEvent(new Event(ANGELIC_BUBBLE_EVENT));
    } catch {}

    setEnabled(nextEnabled);
  }

  return (
    <div
      className={compact ? "mt-4 flex flex-wrap items-center gap-3" : "rounded-xl p-4 flex flex-wrap items-center justify-between gap-4"}
      style={
        compact
          ? undefined
          : {
              background: "rgba(8,14,18,0.35)",
              border: "1px solid rgba(74,196,204,0.14)",
            }
      }
    >
      <div>
        <div className="text-xs font-black tracking-[0.2em] text-[#4AC4CC] mb-1">ANGELIC PROMPTS</div>
        <div className="text-sm font-bold text-[#F0F8F8]">
          Tips, reminders, suggestions, to-dos, and construction finance insights
        </div>
        <div className="text-xs text-[#9EBDC2] mt-1">
          Status: {enabled ? "ON" : "OFF"}
        </div>
      </div>
      <button
        onClick={() => setPromptPreference(!enabled)}
        className="px-4 py-2 rounded-xl text-xs font-bold cursor-pointer"
        style={{
          background: enabled ? "#162832" : "linear-gradient(90deg, #F29E3D, #FCC757)",
          color: enabled ? "#F0F8F8" : "#080E12",
          border: enabled ? "1px solid rgba(51,84,94,0.35)" : "none",
        }}
      >
        {enabled ? "Turn Prompts Off" : "Turn Prompts On"}
      </button>
    </div>
  );
}
