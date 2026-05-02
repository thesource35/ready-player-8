// DocumentSyncManager.swift — Phase 13 Document Management
// Local-then-remote sync orchestration for cs_documents, mirroring the
// pattern in DataSyncManager (SupabaseCRUDWiring.swift).

import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
final class DocumentSyncManager: ObservableObject {
    static let shared = DocumentSyncManager()
    private init() { hydrateFromCache() }

    @Published private(set) var documentsByEntity: [String: [SupabaseDocument]] = [:]
    @Published private(set) var lastError: AppError?
    @Published private(set) var isSyncing: Bool = false

    private let bucket = "documents"
    private let cacheKey = "ConstructOS.Documents.CacheRaw"
    private let lastSyncKey = "ConstructOS.Documents.LastSyncDate"

    // MARK: - Cache

    private func entityKey(_ type: DocumentEntityType, _ id: String) -> String {
        "\(type.rawValue):\(id)"
    }

    private func hydrateFromCache() {
        guard let raw = UserDefaults.standard.data(forKey: cacheKey) else { return }
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        if let cached = try? dec.decode([String: [SupabaseDocument]].self, from: raw) {
            documentsByEntity = cached
        }
    }

    private func persistCache() {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        if let data = try? enc.encode(documentsByEntity) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    // MARK: - Reads

    /// Load attachments for an entity. Hydrates from local cache immediately,
    /// then refreshes from Supabase if configured. Errors are surfaced via
    /// `lastError` rather than thrown so callers can use this from `.task {}`.
    func loadAttachments(entityType: DocumentEntityType, entityId: String) async {
        hydrateFromCache()
        let svc = SupabaseService.shared
        guard svc.isConfigured else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let q: [String: String] = [
                "select": "*,cs_document_attachments!inner(entity_type,entity_id)",
                "cs_document_attachments.entity_type": "eq.\(entityType.rawValue)",
                "cs_document_attachments.entity_id": "eq.\(entityId)",
                "is_current": "eq.true"
            ]
            let docs: [SupabaseDocument] = try await svc.fetch(
                "cs_documents",
                query: q,
                orderBy: "created_at"
            )
            let key = entityKey(entityType, entityId)
            documentsByEntity[key] = docs
            persistCache()
            UserDefaults.standard.set(Date(), forKey: lastSyncKey)
        } catch let e as AppError {
            lastError = e
        } catch let e as SupabaseError {
            lastError = .unknown(e.localizedDescription)
        } catch {
            lastError = .network(underlying: error)
        }
    }

    /// All versions in a chain, newest first.
    func listVersions(chainId: String) async throws -> [SupabaseDocument] {
        try await SupabaseService.shared.fetch(
            "cs_documents",
            query: ["version_chain_id": "eq.\(chainId)"],
            orderBy: "version_number"
        )
    }

    // MARK: - Writes

    /// Upload a local file as a brand-new document (version 1).
    func uploadDocument(
        fileURL: URL,
        entityType: DocumentEntityType,
        entityId: String,
        orgId: String,
        uploadedBy: String
    ) async throws -> SupabaseDocument {
        // Phase 26 D-06: pre-flight before any side effect (HEIC conversion,
        // upload, row insert). Any failure raises AppError.validationFailed.
        try await preflightEntityExists(entityType: entityType, entityId: entityId)

        var data = try Data(contentsOf: fileURL)
        var mime = mimeType(for: fileURL)
        var filename = fileURL.lastPathComponent

        // D-12: HEIC → JPEG before upload.
        if mime == "image/heic" {
            data = try HEICConverter.heicToJpeg(data)
            mime = "image/jpeg"
            filename = (filename as NSString).deletingPathExtension + ".jpg"
        }

        try DocumentValidator.validate(size: Int64(data.count), mime: mime)

        let docId = UUID().uuidString
        let ext = (filename as NSString).pathExtension.lowercased()
        // Path convention: {org_id}/{entity_type}/{entity_id}/{document_id}.{ext}
        let path = "\(orgId)/\(entityType.rawValue)/\(entityId)/\(docId).\(ext)"

        _ = try await SupabaseService.shared.uploadFileWithRetry(
            bucket: bucket, path: path, data: data, mimeType: mime
        )

        let nowISO = ISO8601DateFormatter().string(from: Date())
        let doc = SupabaseDocument(
            id: docId,
            orgId: orgId,
            versionChainId: docId,
            versionNumber: 1,
            isCurrent: true,
            filename: filename,
            mimeType: mime,
            sizeBytes: Int64(data.count),
            storagePath: path,
            uploadedBy: uploadedBy,
            createdAt: nowISO
        )
        try await SupabaseService.shared.insertDocumentRow(table: "cs_documents", row: doc)

        let attach = SupabaseDocumentAttachment(
            documentId: docId,
            entityType: entityType,
            entityId: entityId,
            createdAt: nowISO
        )
        try await SupabaseService.shared.insertDocumentRow(table: "cs_document_attachments", row: attach)

        // Local cache update.
        let key = entityKey(entityType, entityId)
        documentsByEntity[key, default: []].insert(doc, at: 0)
        persistCache()
        return doc
    }

    /// Add a new version to an existing chain via the `create_document_version` RPC.
    /// - Returns: The new document's UUID string.
    func createNewVersion(
        chainId: String,
        fileURL: URL,
        orgId: String
    ) async throws -> String {
        var data = try Data(contentsOf: fileURL)
        var mime = mimeType(for: fileURL)
        var filename = fileURL.lastPathComponent
        if mime == "image/heic" {
            data = try HEICConverter.heicToJpeg(data)
            mime = "image/jpeg"
            filename = (filename as NSString).deletingPathExtension + ".jpg"
        }
        try DocumentValidator.validate(size: Int64(data.count), mime: mime)

        let newDocId = UUID().uuidString
        let ext = (filename as NSString).pathExtension.lowercased()
        let path = "\(orgId)/version-chain/\(chainId)/\(newDocId).\(ext)"

        _ = try await SupabaseService.shared.uploadFileWithRetry(
            bucket: bucket, path: path, data: data, mimeType: mime
        )

        let result: [String: String] = try await SupabaseService.shared.callRPC(
            name: "create_document_version",
            params: [
                "p_chain_id": chainId,
                "p_filename": filename,
                "p_mime_type": mime,
                "p_size_bytes": "\(data.count)",
                "p_storage_path": path,
                "p_org_id": orgId
            ]
        )
        guard let id = result["id"] else {
            throw AppError.unknown("RPC create_document_version returned no id")
        }
        return id
    }

    // MARK: - Helpers

    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if let type = UTType(filenameExtension: ext)?.preferredMIMEType { return type }
        return "application/octet-stream"
    }

    // MARK: - Phase 26 D-12 picker helper

    /// Returns the subset of DocumentEntityType values whose backing table
    /// has at least one row visible to the current user. Used by picker UIs
    /// to hide entity types with empty stub tables until future feature
    /// phases populate them (web parity: see
    /// `web/src/lib/documents/entityPickerQuery.ts` nonEmptyEntityTypes).
    ///
    /// Implementation: one bounded `fetch` per entity type inside a
    /// TaskGroup — exactly 7 parallel HEAD-shaped requests (select=id,
    /// limit=1), no N+1 recursion. Table names are resolved by a
    /// hard-coded switch on DocumentEntityType — user input never flows
    /// into the table-name position (T-26-SQLI iOS parity).
    ///
    /// When Supabase is not configured (offline / demo mode), returns
    /// `DocumentEntityType.allCases` so the picker is permissive — the
    /// server-side pre-flight will still catch bogus entity ids.
    func nonEmptyEntityTypes() async -> [DocumentEntityType] {
        let svc = SupabaseService.shared
        guard svc.isConfigured else { return DocumentEntityType.allCases }

        let tableFor: (DocumentEntityType) -> String = { t in
            switch t {
            case .project:         return "cs_projects"
            case .rfi:             return "cs_rfis"
            case .submittal:       return "cs_submittals"
            case .changeOrder:     return "cs_change_orders"
            case .dailyLog:        return "cs_daily_logs"
            case .safetyIncident:  return "cs_safety_incidents"
            case .punchItem:       return "cs_punch_items"
            }
        }

        struct IdRow: Decodable { let id: String }
        var out: [DocumentEntityType] = []
        await withTaskGroup(of: (DocumentEntityType, Bool).self) { group in
            for t in DocumentEntityType.allCases {
                group.addTask {
                    // 999.5 (d) audit: was try? -- silent network/RLS failures here
                    // would mark an entity type as "no rows" when it might have rows
                    // we just couldn't fetch. Log to telemetry so we can detect.
                    do {
                        let rows: [IdRow] = try await svc.fetch(
                            tableFor(t),
                            query: ["select": "id", "limit": "1"],
                            orderBy: nil
                        )
                        return (t, !rows.isEmpty)
                    } catch {
                        await MainActor.run {
                            CrashReporter.shared.reportError("[DocumentSync] hasAny probe \(t) failed: \(error.localizedDescription)")
                        }
                        return (t, false)
                    }
                }
            }
            for await (t, hasRow) in group where hasRow {
                out.append(t)
            }
        }
        return out
    }

    // MARK: - Phase 26 pre-flight

    /// Phase 26 D-06: verify the target entity exists before touching storage
    /// or inserting document rows. Replaces the silent RLS 403 with an
    /// actionable AppError.validationFailed.
    ///
    /// The `table` parameter is a HARD-CODED switch on the DocumentEntityType
    /// enum — never interpolated from user input — so there is no
    /// SQL-injection exposure (T-26-SQLI iOS parity).
    private func preflightEntityExists(
        entityType: DocumentEntityType,
        entityId: String
    ) async throws {
        let svc = SupabaseService.shared
        guard svc.isConfigured else { return }  // offline-first: defer to server
        let table: String
        switch entityType {
        case .project:         table = "cs_projects"
        case .rfi:             table = "cs_rfis"
        case .submittal:       table = "cs_submittals"
        case .changeOrder:     table = "cs_change_orders"
        case .dailyLog:        table = "cs_daily_logs"
        case .safetyIncident:  table = "cs_safety_incidents"
        case .punchItem:       table = "cs_punch_items"
        }
        struct IdRow: Decodable { let id: String }
        // 999.5 (d) audit: was try? -- silent fetch failure would treat the entity as
        // missing (and throw .validationFailed below) even when it actually exists.
        let rows: [IdRow]
        do {
            rows = try await svc.fetch(
                table,
                query: ["select": "id", "id": "eq.\(entityId)"],
                orderBy: nil
            )
        } catch {
            CrashReporter.shared.reportError("[DocumentSync] entity verify \(table)/\(entityId) failed: \(error.localizedDescription)")
            throw error
        }
        if rows.isEmpty {
            throw AppError.validationFailed(
                field: "entity",
                reason: "\(entityType.rawValue) not found"
            )
        }
    }
}
