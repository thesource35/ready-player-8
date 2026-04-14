"use client";

import { useState, useEffect } from "react";

// D-120: Cookie consent banner with "Accept" and "Decline" buttons
// D-125: Store consent in localStorage (not auth cookie)
// Dismiss on accept or decline; remember choice

const CONSENT_KEY = "portal_cookie_consent";

export default function CookieConsent() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    // Check if user already made a choice
    const stored = localStorage.getItem(CONSENT_KEY);
    if (!stored) {
      setVisible(true);
    }
  }, []);

  function handleAccept() {
    localStorage.setItem(CONSENT_KEY, "accepted");
    setVisible(false);
  }

  function handleDecline() {
    localStorage.setItem(CONSENT_KEY, "declined");
    setVisible(false);
  }

  if (!visible) return null;

  return (
    <div
      style={{
        position: "fixed",
        bottom: 0,
        left: 0,
        right: 0,
        background: "#FFFFFF",
        borderTop: "1px solid #E2E5E9",
        padding: "16px 24px",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 16,
        flexWrap: "wrap",
        zIndex: 1000,
        boxShadow: "0 -2px 8px rgba(0,0,0,0.06)",
      }}
    >
      <p
        style={{
          fontSize: 13,
          color: "#374151",
          margin: 0,
          maxWidth: 480,
          lineHeight: 1.4,
        }}
      >
        This page uses cookies for analytics. Accept to help improve this
        experience.
      </p>

      <div style={{ display: "flex", gap: 8 }}>
        <button
          onClick={handleDecline}
          style={{
            fontSize: 13,
            fontWeight: 500,
            padding: "8px 16px",
            borderRadius: 6,
            border: "1px solid #E2E5E9",
            background: "#FFFFFF",
            color: "#6B7280",
            cursor: "pointer",
          }}
        >
          Decline
        </button>
        <button
          onClick={handleAccept}
          style={{
            fontSize: 13,
            fontWeight: 500,
            padding: "8px 16px",
            borderRadius: 6,
            border: "none",
            background: "var(--portal-primary, #2563EB)",
            color: "#FFFFFF",
            cursor: "pointer",
          }}
        >
          Accept
        </button>
      </div>
    </div>
  );
}
