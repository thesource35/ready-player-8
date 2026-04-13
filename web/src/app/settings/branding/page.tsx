"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import type { CompanyBranding, PortalThemeConfig } from "@/lib/portal/types";
import { tokens } from "@/lib/design-tokens";
import ThemeEditor from "@/app/components/portal/ThemeEditor";

// Default branding when none exists in the database
const DEFAULT_THEME: PortalThemeConfig = {
  primary: "#2563EB",
  secondary: "#1D4ED8",
  background: "#F8F9FB",
  text: "#111827",
  cardBg: "#FFFFFF",
  fontFamily: "Inter",
  borderRadius: 8,
  customCSS: null,
};

const DEFAULT_BRANDING: CompanyBranding = {
  id: "",
  org_id: "",
  user_id: "",
  company_name: "",
  logo_light_path: null,
  logo_dark_path: null,
  favicon_path: null,
  cover_image_path: null,
  theme_config: DEFAULT_THEME,
  font_family: "Inter",
  custom_css: null,
  contact_info: {},
  created_at: "",
  updated_at: "",
};

type ToastState = {
  message: string;
  type: "success" | "error";
} | null;

export default function BrandingSettingsPage() {
  const [branding, setBranding] = useState<CompanyBranding>(DEFAULT_BRANDING);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<ToastState>(null);
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Auto-dismiss toast
  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 5000);
    return () => clearTimeout(timer);
  }, [toast]);

  // Fetch current branding on mount
  useEffect(() => {
    async function fetchBranding() {
      try {
        const res = await fetch("/api/portal/branding");
        if (!res.ok) {
          if (res.status === 401) {
            setToast({ message: "Authentication required. Please sign in.", type: "error" });
            return;
          }
          throw new Error("Failed to fetch branding");
        }
        const data = await res.json();
        if (data.branding) {
          setBranding(data.branding);
        }
      } catch (err) {
        console.error("[branding] Fetch error:", err);
      } finally {
        setLoading(false);
      }
    }
    fetchBranding();
  }, []);

  // Save branding
  const handleSave = useCallback(async () => {
    setSaving(true);
    try {
      const res = await fetch("/api/portal/branding", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(branding),
      });

      if (!res.ok) {
        throw new Error("Save failed");
      }

      const data = await res.json();
      if (data.branding) {
        setBranding(data.branding);
      }
      setToast({ message: "Branding saved successfully.", type: "success" });
    } catch {
      setToast({
        message: "Branding changes couldn't be saved. Your previous settings are still active.",
        type: "error",
      });
    } finally {
      setSaving(false);
    }
  }, [branding]);

  // Handle partial updates from ThemeEditor
  const handleBrandingChange = useCallback((updates: Partial<CompanyBranding>) => {
    setBranding((prev) => ({
      ...prev,
      ...updates,
      theme_config: updates.theme_config
        ? { ...prev.theme_config, ...updates.theme_config }
        : prev.theme_config,
      contact_info: updates.contact_info
        ? { ...prev.contact_info, ...updates.contact_info }
        : prev.contact_info,
    }));
  }, []);

  // JSON export (D-65)
  const handleExport = useCallback(() => {
    const exportData = {
      company_name: branding.company_name,
      theme_config: branding.theme_config,
      font_family: branding.font_family,
      custom_css: branding.custom_css,
      contact_info: branding.contact_info,
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    const safeName = (branding.company_name || "company").replace(/[^a-zA-Z0-9-_]/g, "-");
    a.download = `${safeName}-branding.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, [branding]);

  // JSON import (D-65)
  const handleImport = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (ev) => {
        try {
          const json = JSON.parse(ev.target?.result as string);

          // Validate JSON shape
          if (!json || typeof json !== "object") {
            setToast({ message: "Invalid branding file format.", type: "error" });
            return;
          }

          // Merge imported values with current branding
          const updates: Partial<CompanyBranding> = {};
          if (json.company_name && typeof json.company_name === "string") {
            updates.company_name = json.company_name;
          }
          if (json.theme_config && typeof json.theme_config === "object") {
            updates.theme_config = { ...branding.theme_config, ...json.theme_config };
          }
          if (json.font_family && typeof json.font_family === "string") {
            updates.font_family = json.font_family;
          }
          if (json.custom_css !== undefined) {
            updates.custom_css = json.custom_css;
          }
          if (json.contact_info && typeof json.contact_info === "object") {
            updates.contact_info = { ...branding.contact_info, ...json.contact_info };
          }

          handleBrandingChange(updates);
          setToast({ message: "Branding imported. Review changes and save.", type: "success" });
        } catch {
          setToast({ message: "Invalid JSON file.", type: "error" });
        }
      };
      reader.readAsText(file);

      // Reset input so same file can be re-imported
      if (fileInputRef.current) fileInputRef.current.value = "";
    },
    [branding, handleBrandingChange]
  );

  // Reset branding
  const handleReset = useCallback(() => {
    setBranding((prev) => ({
      ...prev,
      theme_config: DEFAULT_THEME,
      font_family: "Inter",
      custom_css: null,
      logo_light_path: null,
      logo_dark_path: null,
      favicon_path: null,
      cover_image_path: null,
      contact_info: {},
    }));
    setShowResetConfirm(false);
    setToast({ message: "Branding reset to defaults. Save to apply.", type: "success" });
  }, []);

  if (loading) {
    return (
      <div style={{ padding: 32, maxWidth: 900, margin: "0 auto" }}>
        <div
          style={{
            height: 32,
            width: 200,
            background: "#E2E5E9",
            borderRadius: 8,
            animation: `shimmer ${tokens.motion.shimmer} infinite`,
          }}
        />
      </div>
    );
  }

  return (
    <div style={{ padding: 32, maxWidth: 900, margin: "0 auto" }}>
      {/* Toast notification */}
      {toast && (
        <div
          style={{
            position: "fixed",
            top: 16,
            right: 16,
            padding: "12px 20px",
            borderRadius: 8,
            background:
              toast.type === "success"
                ? tokens.colors.toast.success.bg
                : tokens.colors.toast.error.bg,
            border: `1px solid ${
              toast.type === "success"
                ? tokens.colors.toast.success.border
                : tokens.colors.toast.error.border
            }`,
            color:
              toast.type === "success"
                ? tokens.colors.semantic.success
                : tokens.colors.semantic.error,
            fontSize: 14,
            fontWeight: 500,
            zIndex: 1000,
            boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
            transition: `opacity ${tokens.motion.toast} ease-out`,
          }}
        >
          {toast.message}
        </div>
      )}

      {/* Page header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 32,
        }}
      >
        <div>
          <h1
            style={{
              fontSize: tokens.typography.fontSize["3xl"],
              fontWeight: tokens.typography.fontWeight.bold,
              color: tokens.colors.gray[900],
              margin: 0,
            }}
          >
            Company Branding
          </h1>
          <p
            style={{
              fontSize: tokens.typography.fontSize.md,
              color: tokens.colors.gray[500],
              margin: "4px 0 0",
            }}
          >
            Customize how your portals look to clients.
          </p>
        </div>

        <div style={{ display: "flex", gap: 8 }}>
          {/* Import button */}
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            style={{
              padding: "8px 16px",
              fontSize: 13,
              fontWeight: 500,
              color: tokens.colors.gray[700],
              background: "#FFFFFF",
              border: `1px solid ${tokens.colors.gray[200]}`,
              borderRadius: 8,
              cursor: "pointer",
            }}
          >
            Import JSON
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept=".json,application/json"
            onChange={handleImport}
            style={{ display: "none" }}
          />

          {/* Export button */}
          <button
            type="button"
            onClick={handleExport}
            style={{
              padding: "8px 16px",
              fontSize: 13,
              fontWeight: 500,
              color: tokens.colors.gray[700],
              background: "#FFFFFF",
              border: `1px solid ${tokens.colors.gray[200]}`,
              borderRadius: 8,
              cursor: "pointer",
            }}
          >
            Export JSON
          </button>

          {/* Save button */}
          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            style={{
              padding: "8px 20px",
              fontSize: 14,
              fontWeight: 600,
              color: "#FFFFFF",
              background: saving ? tokens.colors.gray[400] : tokens.colors.primary[600],
              border: "none",
              borderRadius: 8,
              cursor: saving ? "not-allowed" : "pointer",
            }}
          >
            {saving ? "Saving..." : "Save Branding"}
          </button>
        </div>
      </div>

      {/* Theme editor */}
      <div
        style={{
          background: "#FFFFFF",
          border: tokens.card.border,
          borderRadius: tokens.card.borderRadius,
          padding: tokens.card.padding,
          marginBottom: 24,
        }}
      >
        <ThemeEditor branding={branding} onChange={handleBrandingChange} />
      </div>

      {/* Destructive actions */}
      <div
        style={{
          background: "#FFFFFF",
          border: "1px solid #FECACA",
          borderRadius: tokens.card.borderRadius,
          padding: tokens.card.padding,
        }}
      >
        <h3 style={{ fontSize: 16, fontWeight: 600, color: "#DC2626", margin: "0 0 8px" }}>
          Danger Zone
        </h3>

        {showResetConfirm ? (
          <div>
            <p style={{ fontSize: 14, color: "#374151", margin: "0 0 12px" }}>
              Reset all branding to defaults? Custom colors, fonts, and logos will be removed.
            </p>
            <div style={{ display: "flex", gap: 8 }}>
              <button
                type="button"
                onClick={handleReset}
                style={{
                  padding: "8px 16px",
                  fontSize: 13,
                  fontWeight: 600,
                  color: "#FFFFFF",
                  background: "#DC2626",
                  border: "none",
                  borderRadius: 8,
                  cursor: "pointer",
                }}
              >
                Yes, Reset Branding
              </button>
              <button
                type="button"
                onClick={() => setShowResetConfirm(false)}
                style={{
                  padding: "8px 16px",
                  fontSize: 13,
                  fontWeight: 500,
                  color: tokens.colors.gray[700],
                  background: "#FFFFFF",
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: 8,
                  cursor: "pointer",
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <button
            type="button"
            onClick={() => setShowResetConfirm(true)}
            style={{
              padding: "8px 16px",
              fontSize: 13,
              fontWeight: 500,
              color: "#DC2626",
              background: "#FEF2F2",
              border: "1px solid #FECACA",
              borderRadius: 8,
              cursor: "pointer",
            }}
          >
            Reset Branding
          </button>
        )}
      </div>
    </div>
  );
}
