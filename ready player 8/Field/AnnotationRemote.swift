// Phase 16 FIELD-03: Supabase DTO + upsert helper for cs_photo_annotations.
//
// Isolated from SupabaseService.swift to avoid merge conflicts with
// concurrent Phase 16 work. Attaches to SupabaseService via extension.

import Foundation

/// DTO that round-trips to the cs_photo_annotations table.
/// `layer_json` is encoded as nested JSON (jsonb column in Postgres).
public struct SupabasePhotoAnnotation: Codable, Equatable {
    public var id: String?
    public var document_id: String
    public var org_id: String
    public var layer_json: LayerJSON
    public var schema_version: Int

    public init(
        id: String? = nil,
        document_id: String,
        org_id: String,
        layer_json: LayerJSON,
        schema_version: Int = 1
    ) {
        self.id = id
        self.document_id = document_id
        self.org_id = org_id
        self.layer_json = layer_json
        self.schema_version = schema_version
    }
}

extension SupabaseService {
    /// Upsert an annotation keyed on document_id (unique constraint
    /// cs_photo_annotations_document_unique). On RLS denial (HTTP 401/403)
    /// the error is remapped to `AppError.permissionDenied`.
    func upsertPhotoAnnotation(_ record: SupabasePhotoAnnotation) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        guard let url = URL(string: "\(baseURL)/rest/v1/cs_photo_annotations?on_conflict=document_id") else {
            throw SupabaseError.httpError(400, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=representation",
                         forHTTPHeaderField: "Prefer")
        do {
            request.httpBody = try JSONEncoder().encode(record)
        } catch {
            throw SupabaseError.encodingError(error)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.httpError(-1, "No HTTP response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw AppError.permissionDenied(feature: "photo annotations")
        }
        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError(http.statusCode, body)
        }
    }
}
