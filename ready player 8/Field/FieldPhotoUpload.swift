// FieldPhotoUpload.swift — Phase 16 Wave 2 (FIELD-01 / FIELD-02)
// ConstructionOS
//
// Helpers layered on top of DocumentSyncManager that inject GPS + captured_at
// into the upload pipeline and build the manual-pin update payload (D-07).
// Kept small and pure so the core logic is unit-testable without network I/O.

import Foundation

enum FieldPhotoUpload {

    /// Build the PATCH payload for a manual pin edit. The returned dictionary
    /// is what DocumentSyncManager / SupabaseService sends to cs_documents.
    /// Always flips `gps_source` to `manual_pin` (D-07).
    static func manualPinUpdatePayload(
        newLat: Double,
        newLng: Double,
        updatedBy: String,
        now: Date = Date()
    ) -> [String: String] {
        let iso = ISO8601DateFormatter().string(from: now)
        return [
            "gps_lat": String(newLat),
            "gps_lng": String(newLng),
            "gps_source": GpsSource.manualPin.rawValue,
            "updated_by": updatedBy,
            "updated_at": iso
        ]
    }

    /// Apply a captured location onto a new SupabaseDocument DTO — used by
    /// the iOS capture flow before inserting into cs_documents.
    static func applyCapturedLocation(
        to doc: inout SupabaseDocument,
        location: CapturedLocation
    ) {
        doc.gpsLat = location.lat
        doc.gpsLng = location.lng
        doc.gpsAccuracyM = location.accuracyM
        doc.gpsSource = location.source.rawValue
        doc.capturedAt = ISO8601DateFormatter().string(from: location.capturedAt)
    }

    /// UI badge string for a document. Returns nil when no badge should show.
    static func gpsBadgeLabel(for doc: SupabaseDocument) -> String? {
        switch doc.gpsSource {
        case "stale_last_known": return "stale GPS"
        case "manual_pin":       return "manual pin"
        default:                 return nil
        }
    }
}
