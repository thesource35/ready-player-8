import { createClient } from "@/lib/supabase/client";
import type {
  Equipment,
  EquipmentLocation,
  EquipmentWithPosition,
  GpsPhoto,
  MapSiteRow,
} from "./types";

/**
 * Validates that lat/lng are within legal GPS ranges.
 * lat must be in [-90, 90], lng must be in [-180, 180], and neither may be NaN.
 */
export function validateCoordinates(
  lat: number,
  lng: number
): { valid: boolean; error?: string } {
  if (Number.isNaN(lat) || Number.isNaN(lng)) {
    return { valid: false, error: "Coordinates must be valid numbers" };
  }
  if (lat < -90 || lat > 90) {
    return { valid: false, error: "Latitude must be between -90 and 90" };
  }
  if (lng < -180 || lng > 180) {
    return { valid: false, error: "Longitude must be between -180 and 180" };
  }
  return { valid: true };
}

/**
 * Fetches equipment from cs_equipment table.
 * If projectId is provided, filters by assigned_project.
 */
export async function fetchEquipment(
  projectId?: string
): Promise<Equipment[]> {
  try {
    const supabase = createClient();
    if (!supabase) return [];

    let query = supabase.from("cs_equipment").select("*");
    if (projectId) {
      query = query.eq("assigned_project", projectId);
    }

    const { data, error } = await query;
    if (error) {
      console.error("[maps] fetchEquipment error:", error);
      return [];
    }
    return (data as Equipment[]) || [];
  } catch (err) {
    console.error("[maps] fetchEquipment exception:", err);
    return [];
  }
}

/**
 * Fetches equipment with their latest positions from the
 * cs_equipment_latest_positions view.
 */
export async function fetchEquipmentPositions(): Promise<
  EquipmentWithPosition[]
> {
  try {
    const supabase = createClient();
    if (!supabase) return [];

    const { data, error } = await supabase
      .from("cs_equipment_latest_positions")
      .select("*");

    if (error) {
      console.error("[maps] fetchEquipmentPositions error:", error);
      return [];
    }
    return (data as EquipmentWithPosition[]) || [];
  } catch (err) {
    console.error("[maps] fetchEquipmentPositions exception:", err);
    return [];
  }
}

/**
 * Records a manual equipment check-in at the given coordinates.
 * Validates coordinates before inserting.
 */
export async function checkInEquipment(
  equipmentId: string,
  lat: number,
  lng: number,
  accuracyM: number | null,
  notes?: string
): Promise<EquipmentLocation | null> {
  const validation = validateCoordinates(lat, lng);
  if (!validation.valid) {
    console.error("[maps] checkInEquipment validation failed:", validation.error);
    return null;
  }

  try {
    const supabase = createClient();
    if (!supabase) return null;

    const { data, error } = await supabase
      .from("cs_equipment_locations")
      .insert({
        equipment_id: equipmentId,
        lat,
        lng,
        accuracy_m: accuracyM,
        source: "manual",
        notes: notes ?? null,
      })
      .select()
      .single();

    if (error) {
      console.error("[maps] checkInEquipment error:", error);
      return null;
    }
    return data as EquipmentLocation;
  } catch (err) {
    console.error("[maps] checkInEquipment exception:", err);
    return null;
  }
}

/**
 * Fetches documents that have GPS coordinates attached (photos with location).
 * Optionally filters by project via entity_type + entity_id.
 */
export async function fetchGpsPhotos(
  projectId?: string
): Promise<GpsPhoto[]> {
  try {
    const supabase = createClient();
    if (!supabase) return [];

    let query = supabase
      .from("cs_documents")
      .select("id, filename, gps_lat, gps_lng, created_at, entity_type, entity_id")
      .not("gps_lat", "is", null)
      .not("gps_lng", "is", null);

    if (projectId) {
      query = query.eq("entity_id", projectId);
    }

    const { data, error } = await query;
    if (error) {
      console.error("[maps] fetchGpsPhotos error:", error);
      return [];
    }
    return (data as GpsPhoto[]) || [];
  } catch (err) {
    console.error("[maps] fetchGpsPhotos exception:", err);
    return [];
  }
}

/**
 * Fetches projects that have lat/lng set (map sites).
 */
export async function fetchMapSites(): Promise<MapSiteRow[]> {
  try {
    const supabase = createClient();
    if (!supabase) return [];

    const { data, error } = await supabase
      .from("cs_projects")
      .select("id, name, lat, lng, status, type, client")
      .not("lat", "is", null)
      .not("lng", "is", null);

    if (error) {
      console.error("[maps] fetchMapSites error:", error);
      return [];
    }
    return (data as MapSiteRow[]) || [];
  } catch (err) {
    console.error("[maps] fetchMapSites exception:", err);
    return [];
  }
}
