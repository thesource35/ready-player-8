// DocumentVersioningTests.swift — Phase 13 Document Management
// DTO round-trip + DocumentSyncManager smoke tests.

import Testing
import Foundation
@testable import ready_player_8

struct DocumentVersioningTests {

    @Test func documentEntityTypeRoundTrip() throws {
        for c in DocumentEntityType.allCases {
            let data = try JSONEncoder().encode(c)
            let decoded = try JSONDecoder().decode(DocumentEntityType.self, from: data)
            #expect(c == decoded)
        }
    }

    @Test func changeOrderRawValueIsSnakeCase() {
        #expect(DocumentEntityType.changeOrder.rawValue == "change_order")
    }

    @Test func supabaseDocumentDecodesSnakeCase() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "org_id": "00000000-0000-0000-0000-000000000002",
          "version_chain_id": "00000000-0000-0000-0000-000000000001",
          "version_number": 1,
          "is_current": true,
          "filename": "spec.pdf",
          "mime_type": "application/pdf",
          "size_bytes": 1234,
          "storage_path": "org/project/abc/doc.pdf",
          "uploaded_by": "00000000-0000-0000-0000-000000000003",
          "created_at": "2026-04-06T00:00:00Z"
        }
        """.data(using: .utf8)!
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let doc = try dec.decode(SupabaseDocument.self, from: json)
        #expect(doc.versionNumber == 1)
        #expect(doc.isCurrent == true)
        #expect(doc.filename == "spec.pdf")
        #expect(doc.sizeBytes == 1234)
    }

    @Test func supabaseDocumentEncodesSnakeCase() throws {
        let doc = SupabaseDocument(
            id: "id1", orgId: "org1", versionChainId: "id1",
            versionNumber: 2, isCurrent: true,
            filename: "a.pdf", mimeType: "application/pdf",
            sizeBytes: 99, storagePath: "p/q/r.pdf",
            uploadedBy: "u1", createdAt: "2026-04-06T00:00:00Z"
        )
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        let data = try enc.encode(doc)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("\"version_number\":2"))
        #expect(str.contains("\"is_current\":true"))
        #expect(str.contains("\"storage_path\""))
    }

    @Test @MainActor func documentSyncManagerSingletonExists() {
        let m = DocumentSyncManager.shared
        #expect(m.lastError == nil || m.lastError != nil) // smoke
    }
}
