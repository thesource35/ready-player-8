// Phase 16 FIELD-04: Open-Meteo client (real impl + mock).
//
// Wave 0 scaffold provided assertValidLatLng + MockOpenMeteoClient. Wave 4
// adds OpenMeteoFetchClient — the real HTTP impl.
//
// Threat: T-16-WX (Tampering). lat/lng MUST be validated numeric/in-range
// before being interpolated into the URL. assertValidLatLng below is the
// single enforcement point.
//
// Threat: T-16-DOS. Caller MUST treat fetch failure as best-effort: this
// client returns {error: ...} on any HTTP/network failure rather than
// throwing, so dailyLogCreate can still write the log row.

export type WeatherSnapshot =
  | { tempC: number; conditions: string; fetchedAt: string }
  | { error: string };

export interface OpenMeteoClient {
  fetch(lat: number, lng: number, date: string): Promise<WeatherSnapshot>;
}

/**
 * Validates latitude/longitude inputs. Throws on NaN or out-of-range values.
 * Shared by all implementations so validation stays consistent.
 */
export function assertValidLatLng(lat: number, lng: number): void {
  if (typeof lat !== "number" || Number.isNaN(lat)) {
    throw new Error("openMeteoClient: lat must be a finite number");
  }
  if (typeof lng !== "number" || Number.isNaN(lng)) {
    throw new Error("openMeteoClient: lng must be a finite number");
  }
  if (lat < -90 || lat > 90) {
    throw new Error(`openMeteoClient: lat out of range (-90..90): ${lat}`);
  }
  if (lng < -180 || lng > 180) {
    throw new Error(`openMeteoClient: lng out of range (-180..180): ${lng}`);
  }
}

// Minimal WMO weather code → label map. Open-Meteo returns a numeric
// `weather_code` per WMO 4677; we collapse to a human label for the log.
function weatherCodeToLabel(code: number): string {
  if (code === 0) return "Clear";
  if (code <= 3) return "Partly Cloudy";
  if (code <= 48) return "Fog";
  if (code <= 67) return "Rain";
  if (code <= 77) return "Snow";
  if (code <= 82) return "Showers";
  if (code <= 99) return "Thunderstorm";
  return "Unknown";
}

/**
 * Real Open-Meteo HTTP client. No auth required. Best-effort: any failure
 * collapses to {error} so callers don't have to wrap in try/catch.
 */
export class OpenMeteoFetchClient implements OpenMeteoClient {
  // 10-minute in-process cache (FIELD-04 plan: cache 10min per call site).
  private cache = new Map<string, { value: WeatherSnapshot; expiresAt: number }>();
  private readonly ttlMs = 10 * 60 * 1000;

  async fetch(lat: number, lng: number, date: string): Promise<WeatherSnapshot> {
    assertValidLatLng(lat, lng);
    const key = `${lat.toFixed(4)}:${lng.toFixed(4)}:${date}`;
    const now = Date.now();
    const cached = this.cache.get(key);
    if (cached && cached.expiresAt > now) {
      return cached.value;
    }

    const url =
      `https://api.open-meteo.com/v1/forecast` +
      `?latitude=${encodeURIComponent(String(lat))}` +
      `&longitude=${encodeURIComponent(String(lng))}` +
      `&current=temperature_2m,weather_code&timezone=auto`;

    let result: WeatherSnapshot;
    try {
      const res = await fetch(url, { method: "GET" });
      if (!res.ok) {
        result = { error: `open-meteo unavailable (status ${res.status})` };
      } else {
        const json = (await res.json()) as {
          current?: { temperature_2m?: number; weather_code?: number };
        };
        const temp = json.current?.temperature_2m;
        const code = json.current?.weather_code;
        if (typeof temp !== "number" || typeof code !== "number") {
          result = { error: "open-meteo unavailable (malformed payload)" };
        } else {
          result = {
            tempC: temp,
            conditions: weatherCodeToLabel(code),
            fetchedAt: new Date().toISOString(),
          };
        }
      }
    } catch (err) {
      result = {
        error: `open-meteo unavailable (${err instanceof Error ? err.message : "network"})`,
      };
    }

    this.cache.set(key, { value: result, expiresAt: now + this.ttlMs });
    return result;
  }
}

/**
 * Configurable mock used by tests and local development.
 * Defaults to a mild sunny day so happy-path tests stay terse.
 */
export class MockOpenMeteoClient implements OpenMeteoClient {
  snapshot: WeatherSnapshot;
  public calls: Array<{ lat: number; lng: number; date: string }> = [];

  constructor(
    snapshot: WeatherSnapshot = {
      tempC: 21,
      conditions: "Clear",
      fetchedAt: "2026-04-08T12:00:00Z",
    },
  ) {
    this.snapshot = snapshot;
  }

  async fetch(lat: number, lng: number, date: string): Promise<WeatherSnapshot> {
    assertValidLatLng(lat, lng);
    this.calls.push({ lat, lng, date });
    return this.snapshot;
  }
}
