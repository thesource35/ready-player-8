// DocumentModels.swift — Phase 13 Document Management DTOs
// ConstructionOS

import Foundation

/// Entity types a document can attach to.
enum DocumentEntityType: String, Codable, CaseIterable, Hashable {
    case project
    case rfi
    case submittal
    case changeOrder = "change_order"
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
