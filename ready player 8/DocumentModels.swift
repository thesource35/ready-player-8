// DocumentModels.swift — Phase 13 Document Management DTOs
// ConstructionOS

import Foundation

/// Entity types a document can attach to. Raw values MUST match the
/// `cs_document_entity_type` Postgres enum. Phase 16 added `daily_log`,
/// `safety_incident`, `punch_item` (migration 20260408004).
enum DocumentEntityType: String, Codable, CaseIterable, Hashable {
    case project
    case rfi
    case submittal
    case changeOrder = "change_order"
    case dailyLog = "daily_log"
    case safetyIncident = "safety_incident"
    case punchItem = "punch_item"
}

/// Metadata row in `cs_documents`. Property names are camelCase; the
/// SupabaseService encoder/decoder use snake_case key conversion.
struct SupabaseDocument: Codable, Identifiable, Hashable {
    var id: String                  // UUID string
    var orgId: String
    var versionChainId: String
    var versionNumber: Int
    var isCurrent: Bool
    var filename: String
    var mimeType: String
    var sizeBytes: Int64
    var storagePath: String
    var uploadedBy: String
    var createdAt: String

    // Phase 16 FIELD-01: GPS + capture time. Nullable so pre-existing rows
    // continue to decode untouched (D-02).
    var gpsLat: Double?
    var gpsLng: Double?
    var gpsAccuracyM: Double?
    var gpsSource: String?          // cs_gps_source enum raw value
    var capturedAt: String?         // ISO8601; device clock at shutter (D-08)

    /// Convenience: true when this photo was GPS-tagged with a stale fallback.
    var isStaleGPS: Bool { gpsSource == "stale_last_known" }

    /// Convenience: true when the pin was manually repositioned post-capture.
    var isManualPin: Bool { gpsSource == "manual_pin" }
}

/// Junction row in `cs_document_attachments` (many-to-many docs ↔ entities).
struct SupabaseDocumentAttachment: Codable, Hashable {
    var documentId: String
    var entityType: DocumentEntityType
    var entityId: String
    var createdAt: String
}

/// Decoded shape returned by `POST /storage/v1/object/sign/{bucket}/{path}`.
struct SignedURLResponse: Codable {
    let signedURL: String
}

/// Client-side validation gate for uploads. Mirrors the DB CHECK constraints
/// in `cs_documents` (mime_type allowlist, size limit). Throws AppError so the
/// caller can surface a single unified error type to the UI.
enum DocumentValidator {
    static let maxBytes: Int64 = 52_428_800 // 50 MB
    static let allowedMime: Set<String> = [
        "application/pdf",
        "image/png",
        "image/jpeg",
        "image/heic",
        "image/webp"
    ]

    static func validate(size: Int64, mime: String) throws {
        guard size > 0 else {
            throw AppError.validationFailed(field: "file", reason: "Empty file")
        }
        guard size <= maxBytes else {
            throw AppError.fileTooLarge(maxMB: 50)
        }
        guard allowedMime.contains(mime) else {
            throw AppError.unsupportedFileType(mime)
        }
    }
}
