// Service Worker for offline report viewing (D-113)
// Cache strategies: cache-first for static assets, network-first for API data,
// stale-while-revalidate for chart images.

const CACHE_NAME = 'constructionos-reports-v1';
const STATIC_CACHE = 'constructionos-reports-static-v1';
const API_CACHE = 'constructionos-reports-api-v1';
const IMAGE_CACHE = 'constructionos-reports-images-v1';

// Static assets to pre-cache on install
const PRECACHE_URLS = [
  '/reports',
  '/reports/rollup',
  '/reports/schedules',
];

// ---------------------------------------------------------------------------
// Install: pre-cache report page shell
// ---------------------------------------------------------------------------

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => {
      return cache.addAll(PRECACHE_URLS).catch((err) => {
        console.warn('[SW] Pre-cache failed for some URLs:', err);
      });
    })
  );
  // Activate immediately without waiting for existing clients to close
  self.skipWaiting();
});

// ---------------------------------------------------------------------------
// Activate: clean up old caches
// ---------------------------------------------------------------------------

self.addEventListener('activate', (event) => {
  const currentCaches = [CACHE_NAME, STATIC_CACHE, API_CACHE, IMAGE_CACHE];
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith('constructionos-reports-') && !currentCaches.includes(name))
          .map((name) => caches.delete(name))
      );
    }).then(() => {
      // Take control of all open clients immediately
      return self.clients.claim();
    })
  );
});

// ---------------------------------------------------------------------------
// Fetch: route-based cache strategies
// ---------------------------------------------------------------------------

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Only handle same-origin requests
  if (url.origin !== self.location.origin) return;

  // Strategy selection based on request type
  if (isStaticAsset(url)) {
    // Cache-first for static assets (report page shell, CSS, JS)
    event.respondWith(cacheFirst(event.request, STATIC_CACHE));
  } else if (isReportAPI(url)) {
    // Network-first for API data (report JSON responses)
    event.respondWith(networkFirst(event.request, API_CACHE));
  } else if (isChartImage(url)) {
    // Stale-while-revalidate for chart images
    event.respondWith(staleWhileRevalidate(event.request, IMAGE_CACHE));
  }
  // All other requests pass through to network normally
});

// ---------------------------------------------------------------------------
// URL classification helpers
// ---------------------------------------------------------------------------

function isStaticAsset(url) {
  // CSS, JS bundles, fonts, and report page routes
  return (
    url.pathname.endsWith('.css') ||
    url.pathname.endsWith('.js') ||
    url.pathname.endsWith('.woff2') ||
    url.pathname.endsWith('.woff') ||
    (url.pathname.startsWith('/reports') && !url.pathname.startsWith('/api/'))
  );
}

function isReportAPI(url) {
  return url.pathname.startsWith('/api/reports/');
}

function isChartImage(url) {
  return (
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('.svg') ||
    url.pathname.endsWith('.jpg') ||
    url.pathname.endsWith('.jpeg')
  );
}

// ---------------------------------------------------------------------------
// Cache-first strategy (D-113: static assets)
// Try cache, fall back to network, cache the network response
// ---------------------------------------------------------------------------

async function cacheFirst(request, cacheName) {
  const cached = await caches.match(request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    // Offline and not in cache -- return offline fallback
    return new Response('Offline - content not cached', {
      status: 503,
      statusText: 'Service Unavailable',
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

// ---------------------------------------------------------------------------
// Network-first strategy (D-113: API data)
// Try network, fall back to cache for offline viewing
// ---------------------------------------------------------------------------

async function networkFirst(request, cacheName) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    // Network failed -- try cache
    const cached = await caches.match(request);
    if (cached) return cached;

    // No cache available
    return new Response(
      JSON.stringify({ error: 'Offline - no cached data available' }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

// ---------------------------------------------------------------------------
// Stale-while-revalidate strategy (chart images)
// Return cache immediately, update cache in background
// ---------------------------------------------------------------------------

async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);

  // Start network fetch in background regardless
  const networkPromise = fetch(request)
    .then((response) => {
      if (response.ok) {
        cache.put(request, response.clone());
      }
      return response;
    })
    .catch(() => null);

  // Return cached version immediately if available
  if (cached) return cached;

  // No cache -- wait for network
  const networkResponse = await networkPromise;
  if (networkResponse) return networkResponse;

  return new Response('Offline - image not cached', {
    status: 503,
    statusText: 'Service Unavailable',
    headers: { 'Content-Type': 'text/plain' },
  });
}

// ---------------------------------------------------------------------------
// Message handler for manual cache operations
// ---------------------------------------------------------------------------

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'CACHE_REPORT_DATA') {
    const { url, data } = event.data;
    caches.open(API_CACHE).then((cache) => {
      const response = new Response(JSON.stringify(data), {
        headers: { 'Content-Type': 'application/json' },
      });
      cache.put(url, response);
    });
  }

  if (event.data && event.data.type === 'CLEAR_CACHE') {
    Promise.all([
      caches.delete(STATIC_CACHE),
      caches.delete(API_CACHE),
      caches.delete(IMAGE_CACHE),
    ]).then(() => {
      if (event.ports && event.ports[0]) {
        event.ports[0].postMessage({ cleared: true });
      }
    });
  }
});
