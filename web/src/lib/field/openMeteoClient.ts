// Phase 16 Wave 0 scaffold — Open-Meteo weather client interface.
// Real HTTP implementation lands in Wave 4 (T-16-WX).

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
