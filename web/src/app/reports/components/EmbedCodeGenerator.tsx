"use client";

import { useState, useCallback } from "react";

// ---------------------------------------------------------------------------
// Embed Code Generator (D-104)
// Generates iframe HTML for embedding reports on external sites.
// Auth via share token included in iframe src URL.
// ---------------------------------------------------------------------------

type EmbedTarget = "full_report" | "health_badge" | "budget_chart" | "schedule_chart";

type EmbedSize = {
  label: string;
  width: string;
  height: string;
};

const EMBED_SIZES: Record<string, EmbedSize> = {
  small: { label: "Small", width: "400", height: "300" },
  medium: { label: "Medium", width: "600", height: "400" },
  large: { label: "Large", width: "800", height: "600" },
  responsive: { label: "Responsive", width: "100%", height: "500" },
};

const EMBED_TARGETS: Array<{ key: EmbedTarget; label: string }> = [
  { key: "full_report", label: "Full Report" },
  { key: "health_badge", label: "Health Badge" },
  { key: "budget_chart", label: "Budget Chart" },
  { key: "schedule_chart", label: "Schedule Chart" },
];

type EmbedCodeGeneratorProps = {
  /** Share token for authentication */
  shareToken: string;
  /** Base URL for the embed endpoint */
  baseUrl?: string;
};

export default function EmbedCodeGenerator({
  shareToken,
  baseUrl,
}: EmbedCodeGeneratorProps) {
  const [target, setTarget] = useState<EmbedTarget>("full_report");
  const [sizeKey, setSizeKey] = useState("medium");
  const [copied, setCopied] = useState(false);

  const size = EMBED_SIZES[sizeKey];

  const origin =
    baseUrl ?? (typeof window !== "undefined" ? window.location.origin : "");

  const embedUrl = `${origin}/api/reports/embed?token=${encodeURIComponent(shareToken)}&view=${target}`;

  const isResponsive = sizeKey === "responsive";
  const iframeCode = isResponsive
    ? `<div style="position:relative;width:100%;padding-bottom:62.5%;overflow:hidden">\n  <iframe\n    src="${embedUrl}"\n    style="position:absolute;top:0;left:0;width:100%;height:100%;border:none"\n    title="ConstructionOS Report"\n    loading="lazy"\n    sandbox="allow-scripts allow-same-origin"\n  ></iframe>\n</div>`
    : `<iframe\n  src="${embedUrl}"\n  width="${size.width}"\n  height="${size.height}"\n  style="border:none;border-radius:8px"\n  title="ConstructionOS Report"\n  loading="lazy"\n  sandbox="allow-scripts allow-same-origin"\n></iframe>`;

  const handleCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(iframeCode);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback: select textarea content
      const textarea = document.querySelector(
        "[data-embed-code]"
      ) as HTMLTextAreaElement | null;
      if (textarea) {
        textarea.select();
        document.execCommand("copy");
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      }
    }
  }, [iframeCode]);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      {/* Header */}
      <div>
        <h3
          style={{
            margin: 0,
            fontSize: 18,
            fontWeight: 700,
            color: "var(--text, #fff)",
          }}
        >
          Embed Code
        </h3>
        <p
          style={{
            margin: "4px 0 0",
            fontSize: 13,
            color: "var(--muted, #888)",
          }}
        >
          Generate an iframe to embed this report on external sites
        </p>
      </div>

      {/* Target selector */}
      <div>
        <label
          style={{
            fontSize: 13,
            fontWeight: 600,
            color: "var(--muted, #888)",
            display: "block",
            marginBottom: 8,
          }}
        >
          What to embed
        </label>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {EMBED_TARGETS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTarget(t.key)}
              style={{
                padding: "6px 14px",
                borderRadius: 8,
                border:
                  target === t.key
                    ? "2px solid var(--accent, #f59e0b)"
                    : "1px solid var(--border, #333)",
                background:
                  target === t.key
                    ? "var(--accent, #f59e0b)"
                    : "var(--surface, #1a1a2e)",
                color: target === t.key ? "#000" : "var(--text, #fff)",
                fontSize: 13,
                fontWeight: target === t.key ? 700 : 400,
                cursor: "pointer",
              }}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* Size selector */}
      <div>
        <label
          style={{
            fontSize: 13,
            fontWeight: 600,
            color: "var(--muted, #888)",
            display: "block",
            marginBottom: 8,
          }}
        >
          Size
        </label>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {Object.entries(EMBED_SIZES).map(([key, s]) => (
            <button
              key={key}
              onClick={() => setSizeKey(key)}
              style={{
                padding: "6px 14px",
                borderRadius: 8,
                border:
                  sizeKey === key
                    ? "2px solid var(--accent, #f59e0b)"
                    : "1px solid var(--border, #333)",
                background:
                  sizeKey === key
                    ? "var(--accent, #f59e0b)"
                    : "var(--surface, #1a1a2e)",
                color: sizeKey === key ? "#000" : "var(--text, #fff)",
                fontSize: 13,
                fontWeight: sizeKey === key ? 700 : 400,
                cursor: "pointer",
              }}
            >
              {s.label} ({s.width}x{s.height})
            </button>
          ))}
        </div>
      </div>

      {/* Code output */}
      <div>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 8,
          }}
        >
          <label
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: "var(--muted, #888)",
            }}
          >
            Embed code
          </label>
          <button
            onClick={handleCopy}
            style={{
              padding: "6px 16px",
              borderRadius: 8,
              border: "none",
              background: copied
                ? "var(--green, #22c55e)"
                : "var(--accent, #f59e0b)",
              color: "#000",
              fontWeight: 600,
              fontSize: 13,
              cursor: "pointer",
              minWidth: 80,
            }}
          >
            {copied ? "Copied!" : "Copy"}
          </button>
        </div>
        <textarea
          readOnly
          value={iframeCode}
          data-embed-code
          aria-label="Embed iframe code"
          style={{
            width: "100%",
            minHeight: 120,
            padding: 12,
            borderRadius: 8,
            border: "1px solid var(--border, #333)",
            background: "var(--panel, #111)",
            color: "var(--text, #fff)",
            fontFamily: "monospace",
            fontSize: 12,
            resize: "vertical",
          }}
        />
      </div>

      {/* Preview */}
      <div>
        <label
          style={{
            fontSize: 13,
            fontWeight: 600,
            color: "var(--muted, #888)",
            display: "block",
            marginBottom: 8,
          }}
        >
          Preview
        </label>
        <div
          style={{
            background: "var(--surface, #1a1a2e)",
            borderRadius: 12,
            padding: 16,
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            minHeight: 200,
            border: "1px dashed var(--border, #333)",
          }}
        >
          {shareToken ? (
            <iframe
              src={embedUrl}
              width={isResponsive ? "100%" : size.width}
              height={isResponsive ? "300" : Math.min(parseInt(size.height), 300).toString()}
              style={{ border: "none", borderRadius: 8, maxWidth: "100%" }}
              title="Embed preview"
              loading="lazy"
              sandbox="allow-scripts allow-same-origin"
            />
          ) : (
            <p
              style={{
                fontSize: 13,
                color: "var(--muted, #888)",
                fontStyle: "italic",
              }}
            >
              Generate a share link first to preview the embed
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
