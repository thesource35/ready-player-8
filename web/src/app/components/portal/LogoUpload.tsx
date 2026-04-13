"use client";

import { useState, useRef, useCallback } from "react";

type LogoUploadType = "logo_light" | "logo_dark" | "favicon" | "cover_image";

type LogoUploadProps = {
  type: LogoUploadType;
  currentPath?: string;
  onUpload: (path: string) => void;
};

// Size limits per type (D-75, D-61, D-62)
const TYPE_LIMITS: Record<LogoUploadType, { maxSize: number; formats: string; label: string; recommend: string }> = {
  logo_light: {
    maxSize: 2_000_000,
    formats: "PNG, SVG",
    label: "Logo (Light)",
    recommend: "Recommended: 400x100px",
  },
  logo_dark: {
    maxSize: 2_000_000,
    formats: "PNG, SVG",
    label: "Logo (Dark)",
    recommend: "Recommended: 400x100px",
  },
  favicon: {
    maxSize: 500_000,
    formats: "PNG",
    label: "Favicon",
    recommend: "Recommended: 180x180px",
  },
  cover_image: {
    maxSize: 5_000_000,
    formats: "PNG, JPEG, WebP",
    label: "Cover Image",
    recommend: "Recommended: 1200x400px",
  },
};

// Accept attributes per type
const ACCEPT_MAP: Record<LogoUploadType, string> = {
  logo_light: ".png,.svg,image/png,image/svg+xml",
  logo_dark: ".png,.svg,image/png,image/svg+xml",
  favicon: ".png,image/png",
  cover_image: ".png,.jpg,.jpeg,.webp,image/png,image/jpeg,image/webp",
};

export default function LogoUpload({ type, currentPath, onUpload }: LogoUploadProps) {
  const [preview, setPreview] = useState<string | null>(currentPath ?? null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const limits = TYPE_LIMITS[type];

  const handleFile = useCallback(
    async (file: File) => {
      setError(null);

      // Client-side validation
      if (file.size > limits.maxSize) {
        const maxMB = (limits.maxSize / (1024 * 1024)).toFixed(0);
        setError(`Upload failed. Use a ${limits.formats} file under ${maxMB === "0" ? "500KB" : maxMB + "MB"}.`);
        return;
      }

      // Check extension
      const ext = file.name.split(".").pop()?.toLowerCase() ?? "";
      const validExts =
        type === "favicon"
          ? ["png"]
          : type === "cover_image"
            ? ["png", "jpg", "jpeg", "webp"]
            : ["png", "svg"];

      if (!validExts.includes(ext)) {
        setError(`Upload failed. Use a ${limits.formats} file under ${limits.maxSize >= 1_000_000 ? Math.floor(limits.maxSize / 1_000_000) + "MB" : Math.floor(limits.maxSize / 1_000) + "KB"}.`);
        return;
      }

      setUploading(true);

      try {
        const formData = new FormData();
        formData.append("file", file);
        formData.append("type", type);

        const res = await fetch("/api/portal/branding/upload", {
          method: "POST",
          body: formData,
        });

        if (!res.ok) {
          const data = await res.json().catch(() => ({ error: "Upload failed" }));
          setError(data.error ?? `Upload failed. Use a ${limits.formats} file under 2MB.`);
          return;
        }

        const data = await res.json();
        setPreview(data.url ?? data.path);
        onUpload(data.path);
      } catch {
        setError(`Upload failed. Use a ${limits.formats} file under 2MB.`);
      } finally {
        setUploading(false);
      }
    },
    [type, limits, onUpload]
  );

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setDragOver(false);
      const file = e.dataTransfer.files[0];
      if (file) handleFile(file);
    },
    [handleFile]
  );

  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (file) handleFile(file);
    },
    [handleFile]
  );

  const handleRemove = useCallback(() => {
    setPreview(null);
    setError(null);
    onUpload("");
    if (inputRef.current) inputRef.current.value = "";
  }, [onUpload]);

  return (
    <div style={{ marginBottom: 16 }}>
      <label
        style={{
          display: "block",
          fontSize: 13,
          fontWeight: 600,
          color: "#374151",
          marginBottom: 6,
        }}
      >
        {limits.label}
      </label>

      {preview ? (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 12,
            padding: 12,
            border: "1px solid #E2E5E9",
            borderRadius: 8,
            background: "#F8F9FB",
          }}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={preview}
            alt={limits.label}
            style={{
              maxWidth: type === "favicon" ? 48 : 160,
              maxHeight: type === "favicon" ? 48 : 60,
              objectFit: "contain",
              borderRadius: 4,
            }}
          />
          <button
            type="button"
            onClick={handleRemove}
            style={{
              padding: "4px 12px",
              fontSize: 12,
              color: "#DC2626",
              background: "#FEF2F2",
              border: "1px solid #FECACA",
              borderRadius: 6,
              cursor: "pointer",
            }}
          >
            Remove
          </button>
        </div>
      ) : (
        <div
          onDrop={handleDrop}
          onDragOver={(e) => {
            e.preventDefault();
            setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
          onClick={() => inputRef.current?.click()}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            padding: 24,
            border: `2px dashed ${dragOver ? "#2563EB" : "#D1D5DB"}`,
            borderRadius: 8,
            background: dragOver ? "#EFF6FF" : "#F8F9FB",
            cursor: "pointer",
            transition: "all 200ms ease-in-out",
          }}
        >
          {uploading ? (
            <span style={{ fontSize: 13, color: "#6B7280" }}>Uploading...</span>
          ) : (
            <>
              {/* Image icon */}
              <svg
                width="32"
                height="32"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#9CA3AF"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <polyline points="21 15 16 10 5 21" />
              </svg>
              <span style={{ fontSize: 13, color: "#6B7280" }}>
                Add your company logo
              </span>
              <span style={{ fontSize: 11, color: "#9CA3AF" }}>
                {limits.formats} -- {limits.recommend}
              </span>
            </>
          )}
        </div>
      )}

      <input
        ref={inputRef}
        type="file"
        accept={ACCEPT_MAP[type]}
        onChange={handleInputChange}
        style={{ display: "none" }}
      />

      {error && (
        <p style={{ fontSize: 12, color: "#DC2626", marginTop: 6 }}>{error}</p>
      )}
    </div>
  );
}
