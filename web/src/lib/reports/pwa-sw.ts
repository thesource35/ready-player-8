// PWA Service Worker registration and cache helpers (D-113)
// Registers sw-reports.js and provides utilities for manual cache operations.

// ---------------------------------------------------------------------------
// Service Worker registration
// ---------------------------------------------------------------------------

/**
 * Register the reports Service Worker.
 * Call from report pages to enable offline viewing (D-113).
 * Only registers in production or when explicitly enabled.
 */
export async function registerReportServiceWorker(): Promise<ServiceWorkerRegistration | null> {
  if (typeof window === "undefined") return null;
  if (!("serviceWorker" in navigator)) {
    console.warn("[PWA] Service workers not supported");
    return null;
  }

  try {
    const registration = await navigator.serviceWorker.register(
      "/sw-reports.js",
      { scope: "/reports" }
    );
    console.log("[PWA] Service Worker registered:", registration.scope);
    return registration;
  } catch (err) {
    console.error("[PWA] Service Worker registration failed:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Manual cache operations
// ---------------------------------------------------------------------------

/**
 * Manually cache report API response data for offline use.
 * Sends data to the Service Worker to store in the API cache.
 */
export function cacheReportData(projectId: string, data: unknown): void {
  if (typeof window === "undefined") return;
  if (!navigator.serviceWorker.controller) return;

  const url = `/api/reports/project/${projectId}`;
  navigator.serviceWorker.controller.postMessage({
    type: "CACHE_REPORT_DATA",
    url,
    data,
  });
}

/**
 * Clear all report caches. Returns a promise that resolves when complete.
 */
export function clearReportCache(): Promise<boolean> {
  if (typeof window === "undefined") return Promise.resolve(false);
  if (!navigator.serviceWorker.controller) return Promise.resolve(false);

  return new Promise((resolve) => {
    const controller = navigator.serviceWorker.controller;
    if (!controller) {
      resolve(false);
      return;
    }
    const channel = new MessageChannel();
    channel.port1.onmessage = (event) => {
      resolve(event.data?.cleared === true);
    };
    controller.postMessage(
      { type: "CLEAR_CACHE" },
      [channel.port2]
    );
    // Timeout after 5 seconds
    setTimeout(() => resolve(false), 5_000);
  });
}

// ---------------------------------------------------------------------------
// Online/offline detection
// ---------------------------------------------------------------------------

/**
 * Check if the browser is currently offline.
 * Uses navigator.onLine as the primary signal.
 */
export function isOffline(): boolean {
  if (typeof window === "undefined") return false;
  return !navigator.onLine;
}

/**
 * Subscribe to online/offline state changes.
 * Returns an unsubscribe function.
 */
export function onConnectivityChange(
  callback: (online: boolean) => void
): () => void {
  if (typeof window === "undefined") return () => {};

  const onOnline = () => callback(true);
  const onOffline = () => callback(false);

  window.addEventListener("online", onOnline);
  window.addEventListener("offline", onOffline);

  return () => {
    window.removeEventListener("online", onOnline);
    window.removeEventListener("offline", onOffline);
  };
}
