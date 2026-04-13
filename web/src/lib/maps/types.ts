// Phase 21 map types per D-06, D-07, D-08, D-10

export type EquipmentType = "equipment" | "vehicle" | "material";
export type EquipmentStatus = "active" | "idle" | "needs_attention";
export type LocationSource = "manual" | "gps_tracker" | "telematics";

export type Equipment = {
  id: string;
  org_id: string;
  name: string;
  type: EquipmentType;
  subtype: string | null;
  assigned_project: string | null;
  status: EquipmentStatus;
  created_at: string;
  updated_at: string;
};

export type EquipmentLocation = {
  id: string;
  equipment_id: string;
  lat: number;
  lng: number;
  accuracy_m: number | null;
  source: LocationSource;
  recorded_at: string;
  recorded_by: string | null;
  notes: string | null;
};

export type EquipmentWithPosition = Equipment & {
  latest_lat: number;
  latest_lng: number;
  latest_recorded_at: string;
  latest_accuracy_m: number | null;
};

export type MapSiteRow = {
  id: string;
  name: string;
  lat: number | null;
  lng: number | null;
  status: string;
  type: string | null;
  client: string | null;
  crews?: number;
  deliveries?: number;
  alerts?: number;
  zone?: string;
};

export type GpsPhoto = {
  id: string;
  filename: string;
  gps_lat: number;
  gps_lng: number;
  created_at: string;
  entity_type: string;
  entity_id: string;
};

export type PortalMapOverlays = {
  show_map: boolean;
  satellite: boolean;
  traffic: boolean;
  equipment: boolean;
  photos: boolean;
};

export type MapOverlayKey = "SATELLITE" | "THERMAL" | "CREWS" | "WEATHER" | "AUTO TRACK" | "TRAFFIC" | "PHOTOS";

export const ALL_OVERLAY_KEYS: MapOverlayKey[] = [
  "SATELLITE", "THERMAL", "CREWS", "WEATHER", "AUTO TRACK", "TRAFFIC", "PHOTOS"
];

export const DEFAULT_ACTIVE_OVERLAYS: MapOverlayKey[] = ["SATELLITE", "CREWS"];

export const STATUS_COLORS: Record<EquipmentStatus, string> = {
  active: "#69D294",
  idle: "#FCC757",
  needs_attention: "#D94D48",
};

export const TRAFFIC_COLORS: Record<string, string> = {
  low: "#69D294",
  moderate: "#FCC757",
  heavy: "#FF8C42",
  severe: "#D94D48",
};

// Equipment icon shapes per asset type (D-07) — used by web map markers
export const EQUIPMENT_ICONS: Record<EquipmentType, { web: string; shape: string }> = {
  equipment: { web: "gear", shape: "circle" },
  vehicle: { web: "truck", shape: "rounded-square" },
  material: { web: "box", shape: "diamond" },
};

// LocalStorage keys for map persistence (D-11, D-12)
export const MAP_STORAGE_KEYS = {
  overlays: "constructos.maps.overlays",
  cameraPrefix: "constructos.maps.camera.",
} as const;
