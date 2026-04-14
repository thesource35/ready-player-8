import Foundation
import MapKit
import SwiftUI

// MARK: - ========== Phase 21: Equipment Models ==========

// MARK: - Equipment Asset Type Enum (D-06)

enum EquipmentAssetType: String, Codable, CaseIterable {
    case equipment
    case vehicle
    case material

    var sfSymbolName: String {
        switch self {
        case .equipment: return "gearshape.fill"
        case .vehicle: return "truck.box.fill"
        case .material: return "shippingbox.fill"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Equipment Status Enum (D-07)

enum EquipmentStatus: String, Codable, CaseIterable {
    case active
    case idle
    // swiftlint:disable:next identifier_name
    case needs_attention

    var color: Color {
        switch self {
        case .active: return Theme.green
        case .idle: return Theme.gold
        case .needs_attention: return Theme.red
        }
    }

    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Location Source Enum (D-05)

enum LocationSource: String, Codable {
    case manual
    // swiftlint:disable:next identifier_name
    case gps_tracker
    case telematics
}

// MARK: - Supabase Equipment DTO (cs_equipment table)

struct SupabaseEquipment: Codable, Identifiable {
    let id: String
    let orgId: String
    let name: String
    let type: String
    let subtype: String?
    let assignedProject: String?
    let status: String
    let createdAt: String
    let updatedAt: String

    var assetType: EquipmentAssetType {
        EquipmentAssetType(rawValue: type) ?? .equipment
    }

    var equipmentStatus: EquipmentStatus {
        EquipmentStatus(rawValue: status) ?? .active
    }

    var sfSymbolName: String { assetType.sfSymbolName }
    var statusColor: Color { equipmentStatus.color }
}

// MARK: - Supabase Equipment Location DTO (cs_equipment_locations table)

struct SupabaseEquipmentLocation: Codable, Identifiable {
    let id: String
    let equipmentId: String
    let lat: Double
    let lng: Double
    let accuracyM: Double?
    let source: String
    let recordedAt: String
    let recordedBy: String?
    let notes: String?
}

// MARK: - Equipment Latest Position DTO (cs_equipment_latest_positions view)

/// Maps to the cs_equipment_latest_positions database view which joins
/// cs_equipment with its most recent cs_equipment_locations row.
/// View columns: id, org_id, name, type, subtype, assigned_project, status,
/// created_at, updated_at, latest_lat, latest_lng, latest_recorded_at, latest_accuracy_m
struct SupabaseEquipmentLatestPosition: Codable, Identifiable {
    // From cs_equipment (base columns)
    let id: String
    let orgId: String
    let name: String
    let type: String
    let subtype: String?
    let assignedProject: String?
    let status: String
    let createdAt: String
    let updatedAt: String

    // From cs_equipment_locations (aliased with latest_ prefix in view)
    let latestLat: Double
    let latestLng: Double
    let latestRecordedAt: String
    let latestAccuracyM: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latestLat, longitude: latestLng)
    }

    var assetType: EquipmentAssetType {
        EquipmentAssetType(rawValue: type) ?? .equipment
    }

    var equipmentStatus: EquipmentStatus {
        EquipmentStatus(rawValue: status) ?? .active
    }

    var sfSymbolName: String { assetType.sfSymbolName }
    var statusColor: Color { equipmentStatus.color }
}

// MARK: - Equipment Check-In Request (D-05, D-09)

struct EquipmentCheckInRequest: Encodable {
    let equipmentId: String
    let lat: Double
    let lng: Double
    let accuracyM: Double?
    let source: String
    let notes: String?

    init(equipmentId: String, lat: Double, lng: Double, accuracyM: Double? = nil, source: String = "manual", notes: String? = nil) {
        self.equipmentId = equipmentId
        self.lat = lat
        self.lng = lng
        self.accuracyM = accuracyM
        self.source = source
        self.notes = notes
    }
}

// MARK: - Hashable Conformance (for Picker usage)

extension SupabaseEquipment: Hashable {
    static func == (lhs: SupabaseEquipment, rhs: SupabaseEquipment) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Mock Data (D-14 fallback)

let mockEquipment: [SupabaseEquipment] = [
    SupabaseEquipment(id: "eq-001", orgId: "org-1", name: "CAT 320 Excavator", type: "equipment", subtype: "Excavator", assignedProject: "proj-1", status: "active", createdAt: "2026-01-15T08:00:00Z", updatedAt: "2026-04-01T14:30:00Z"),
    SupabaseEquipment(id: "eq-002", orgId: "org-1", name: "Concrete Mixer Truck #3", type: "vehicle", subtype: "Mixer", assignedProject: "proj-1", status: "active", createdAt: "2026-02-01T08:00:00Z", updatedAt: "2026-04-10T09:15:00Z"),
    SupabaseEquipment(id: "eq-003", orgId: "org-1", name: "Tower Crane TC-500", type: "equipment", subtype: "Crane", assignedProject: "proj-2", status: "idle", createdAt: "2026-01-20T08:00:00Z", updatedAt: "2026-04-08T16:45:00Z"),
    SupabaseEquipment(id: "eq-004", orgId: "org-1", name: "Steel Beam Delivery", type: "material", subtype: "Steel", assignedProject: "proj-1", status: "active", createdAt: "2026-03-15T08:00:00Z", updatedAt: "2026-04-12T07:00:00Z"),
    SupabaseEquipment(id: "eq-005", orgId: "org-1", name: "Forklift FL-200", type: "equipment", subtype: "Forklift", assignedProject: nil, status: "needs_attention", createdAt: "2026-02-10T08:00:00Z", updatedAt: "2026-04-05T11:20:00Z"),
]

let mockEquipmentPositions: [SupabaseEquipmentLatestPosition] = [
    SupabaseEquipmentLatestPosition(id: "eq-001", orgId: "org-1", name: "CAT 320 Excavator", type: "equipment", subtype: "Excavator", assignedProject: "proj-1", status: "active", createdAt: "2026-01-15T08:00:00Z", updatedAt: "2026-04-01T14:30:00Z", latestLat: 33.749, latestLng: -84.388, latestRecordedAt: "2026-04-12T14:30:00Z", latestAccuracyM: 5.0),
    SupabaseEquipmentLatestPosition(id: "eq-002", orgId: "org-1", name: "Concrete Mixer Truck #3", type: "vehicle", subtype: "Mixer", assignedProject: "proj-1", status: "active", createdAt: "2026-02-01T08:00:00Z", updatedAt: "2026-04-10T09:15:00Z", latestLat: 33.751, latestLng: -84.390, latestRecordedAt: "2026-04-12T09:15:00Z", latestAccuracyM: 8.0),
    SupabaseEquipmentLatestPosition(id: "eq-003", orgId: "org-1", name: "Tower Crane TC-500", type: "equipment", subtype: "Crane", assignedProject: "proj-2", status: "idle", createdAt: "2026-01-20T08:00:00Z", updatedAt: "2026-04-08T16:45:00Z", latestLat: 33.753, latestLng: -84.385, latestRecordedAt: "2026-04-08T16:45:00Z", latestAccuracyM: 3.0),
    SupabaseEquipmentLatestPosition(id: "eq-004", orgId: "org-1", name: "Steel Beam Delivery", type: "material", subtype: "Steel", assignedProject: "proj-1", status: "active", createdAt: "2026-03-15T08:00:00Z", updatedAt: "2026-04-12T07:00:00Z", latestLat: 33.748, latestLng: -84.392, latestRecordedAt: "2026-04-12T07:00:00Z", latestAccuracyM: 12.0),
]
