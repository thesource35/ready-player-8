"use client";

import { useState, useCallback } from "react";
import { sanitizePortalCSS } from "@/lib/portal/cssSanitizer";

type CSSOverrideEditorProps = {
  css: string | null;
  onChange: (css: string) => void;
};

const MAX_LENGTH = 10000;
const PLACEHOLDER = `/* Add custom CSS overrides here */\n/* Only visual properties allowed */`;

export default function CSSOverrideEditor({ css, onChange }: CSSOverrideEditorProps) {
  const [value, setValue] = useState(css ?? "");
  const [warnings, setWarnings] = useState<string[]>([]);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      const newValue = e.target.value;
      setValue(newValue);

      // Run sanitization for warnings display
      if (newValue.trim()) {
        const result = sanitizePortalCSS(newValue);
        setWarnings(result.warnings);
        // Pass the sanitized version to parent
        onChange(result.sanitized);
      } else {
        setWarnings([]);
        onChange("");
      }
    },
    [onChange]
  );

  return (
    <div>
      <label
        style={{
          display: "block",
          fontSize: 13,
          fontWeight: 600,
          color: "#374151",
          marginBottom: 6,
        }}
      >
        Custom CSS Overrides
      </label>

      <textarea
        value={value}
        onChange={handleChange}
        placeholder={PLACEHOLDER}
        maxLength={MAX_LENGTH}
        rows={10}
        style={{
          width: "100%",
          fontFamily: "JetBrains Mono, monospace",
          fontSize: 13,
          lineHeight: 1.5,
          padding: 12,
          border: "1px solid #E2E5E9",
          borderRadius: 8,
          background: "#F8F9FB",
          color: "#1F2937",
          resize: "vertical",
          outline: "none",
          boxSizing: "border-box",
        }}
      />

      {/* Character count */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginTop: 4,
        }}
      >
        <span style={{ fontSize: 11, color: "#9CA3AF" }}>
          Only visual properties (colors, fonts, spacing) are allowed.
        </span>
        <span
          style={{
            fontSize: 11,
            color: value.length > MAX_LENGTH * 0.9 ? "#DC2626" : "#9CA3AF",
          }}
        >
          {value.length}/{MAX_LENGTH}
        </span>
      </div>

      {/* Sanitization warnings */}
      {warnings.length > 0 && (
        <div
          style={{
            marginTop: 8,
            padding: 10,
            background: "#FFFBEB",
            border: "1px solid #F59E0B",
            borderRadius: 6,
          }}
        >
          {warnings.map((w, i) => (
            <p
              key={i}
              style={{
                fontSize: 12,
                color: "#92400E",
                margin: i === 0 ? 0 : "4px 0 0",
              }}
            >
              {w}
            </p>
          ))}
        </div>
      )}
    </div>
  );
}
