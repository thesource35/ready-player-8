"use client";

// Offline banner for report pages (D-113)
// Shows "Offline -- showing cached data" when offline,
// auto-dismisses with "Back online" toast when connectivity returns.

import { useState, useEffect, useCallback } from "react";

export default function OfflineBanner() {
  const [isOffline, setIsOffline] = useState(false);
  const [showBackOnline, setShowBackOnline] = useState(false);

  const handleOnline = useCallback(() => {
    setIsOffline(false);
    // Show "Back online" toast briefly
    setShowBackOnline(true);
    const timer = setTimeout(() => setShowBackOnline(false), 3_000);
    return () => clearTimeout(timer);
  }, []);

  const handleOffline = useCallback(() => {
    setIsOffline(true);
    setShowBackOnline(false);
  }, []);

  useEffect(() => {
    // Check initial state
    if (!navigator.onLine) {
      setIsOffline(true);
    }

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, [handleOnline, handleOffline]);

  if (!isOffline && !showBackOnline) return null;

  return (
    <div
      role="status"
      aria-live="polite"
      style={{
        position: "sticky",
        top: 0,
        zIndex: 1000,
        padding: "10px 20px",
        textAlign: "center",
        fontSize: 14,
        fontWeight: 600,
        letterSpacing: 0.5,
        transition: "background 0.3s ease, color 0.3s ease",
        background: isOffline ? "var(--gold, #f59e0b)" : "var(--green, #22c55e)",
        color: isOffline ? "#1a1a1a" : "#fff",
      }}
    >
      {isOffline ? (
        <span>
          <OfflineIcon /> Offline &mdash; showing cached data
        </span>
      ) : (
        <span>
          <OnlineIcon /> Back online
        </span>
      )}
    </div>
  );
}

function OfflineIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      style={{ verticalAlign: "middle", marginRight: 6 }}
      aria-hidden="true"
    >
      <line x1="1" y1="1" x2="23" y2="23" />
      <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55" />
      <path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39" />
      <path d="M10.71 5.05A16 16 0 0 1 22.56 9" />
      <path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88" />
      <path d="M8.53 16.11a6 6 0 0 1 6.95 0" />
      <line x1="12" y1="20" x2="12.01" y2="20" />
    </svg>
  );
}

function OnlineIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      style={{ verticalAlign: "middle", marginRight: 6 }}
      aria-hidden="true"
    >
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
      <polyline points="22 4 12 14.01 9 11.01" />
    </svg>
  );
}
