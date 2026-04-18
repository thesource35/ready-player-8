"use client";

import { useEffect } from "react";

export function CertHighlightScroller({ certId }: { certId: string | null }) {
  useEffect(() => {
    if (certId) {
      const el = document.getElementById(`cert-${certId}`);
      el?.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }, [certId]);
  return null;
}
