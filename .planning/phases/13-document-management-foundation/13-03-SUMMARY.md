---
phase: 13
plan: 03
subsystem: documents
tags: [ios, supabase, storage, heic, versioning]
duration: ~25min
completed: 2026-04-07
requirements: [DOC-01, DOC-02, DOC-03, DOC-05]
---

# Phase 13 Plan 03: iOS Document Storage Layer Summary

iOS data layer for document upload/download/versioning — HEIC→JPEG conversion, Supabase Storage REST helpers, sync manager mirroring DataSyncManager.

## Commits

| # | Hash    | Message                                                          |
|---|---------|------------------------------------------------------------------|
| 1 | 5a98083 | feat(13-03): add document DTOs, HEIC converter, AppError cases   |
| 2 | eebf99e | feat(13-03): add Supabase Storage helpers (upload/sign/download/RPC) |
| 3 | ef0b230 | feat(13-03): add DocumentSyncManager + versioning tests          |

## Files

**Created**
- `ready player 8/DocumentModels.swift` — `SupabaseDocument`, `SupabaseDocumentAttachment`, `DocumentEntityType`, `SignedURLResponse`, `DocumentValidator`
- `ready player 8/HEICConverter.swift` — `HEICConverter.heicToJpeg(_:quality:)`
- `ready player 8/DocumentSyncManager.swift` — `@MainActor` singleton with `loadAttachments`, `uploadDocument`, `createNewVersion`, `listVersions`
- `ready player 8Tests/HEICConversionTests.swift`
- `ready player 8Tests/SupabaseServiceUploadTests.swift`
- `ready player 8Tests/DocumentVersioningTests.swift`
- `ready player 8Tests/Fixtures/sample.{pdf,png,heic}`

**Modified**
- `ready player 8/AppError.swift` — added `.uploadFailed`, `.fileTooLarge`, `.unsupportedFileType`; `.uploadFailed` is retryable
- `ready player 8/SupabaseService.swift` — appended Storage extension; added 3 doc tables to allowlist

## Public API Added

### `SupabaseService` (extension)
```swift
func uploadFile(bucket:path:data:mimeType:) async throws -> String
func createSignedURL(bucket:path:expiresIn:) async throws -> URL
func downloadFile(signedURL:) async throws -> URL
func uploadFileWithRetry(bucket:path:data:mimeType:maxAttempts:) async throws -> String
func insertDocumentRow<T: Encodable>(table:row:) async throws
func callRPC<T: Decodable>(name:params:) async throws -> T
```
All throw `AppError` (not `SupabaseError`) so the document layer can flow errors directly through `AlertState`.

### `DocumentSyncManager`
```swift
@MainActor final class DocumentSyncManager: ObservableObject {
    static let shared: DocumentSyncManager
    @Published var documentsByEntity: [String: [SupabaseDocument]]
    @Published var lastError: AppError?
    @Published var isSyncing: Bool

    func loadAttachments(entityType:entityId:) async
    func uploadDocument(fileURL:entityType:entityId:orgId:uploadedBy:) async throws -> SupabaseDocument
    func createNewVersion(chainId:fileURL:orgId:) async throws -> String
    func listVersions(chainId:) async throws -> [SupabaseDocument]
}
```

## Deviations from Plan

1. **DTO casing — adapted to existing encoder.** SupabaseService's `JSONEncoder`/`JSONDecoder` use `.convertToSnakeCase` / `.convertFromSnakeCase`. The plan's snippets used Swift property names like `org_id`, `version_chain_id` directly — that would have round-tripped to `org__id`. Switched all DTO properties to camelCase (`orgId`, `versionChainId`, `mimeType`, etc.) so the existing key strategies do the conversion.

2. **AppError associated values — adapted to existing shapes.** Existing `AppError` already has `.decoding(underlying:)`, `.validationFailed(field:reason:)`, `.permissionDenied(feature:)`. Plan snippets used simpler shapes. New code uses the existing labels.

3. **Test framework — Swift Testing, not XCTest.** Existing test target uses `import Testing` / `@Test`. Plan snippets used XCTest. Rewrote all three test files to match.

4. **`insertRow` → `insertDocumentRow`.** SupabaseService already had `insert<T>(_:record:)` gated by a static table allowlist. Rather than weaken the allowlist or duplicate the generic insert, added a small dedicated `insertDocumentRow` that only accepts `cs_documents` / `cs_document_attachments`. Also added those tables (and `cs_document_versions`) to the main `allowedTables` set so `fetch()` works for them.

5. **`accessToken`-aware auth header.** Storage helpers prefer the user JWT (`accessToken`) over the anon API key when present, matching the behavior of the existing `applyHeaders` helper.

## Known Stubs

None — every code path either succeeds or throws `AppError`.

## Verification

- `xcodebuild build -scheme "ready player 8" -destination 'generic/platform=iOS Simulator'` → **BUILD SUCCEEDED** (only pre-existing `AppEnvironment.swift` Swift 6 actor warnings).
- `SupabaseService.swift` remains a single file (~1220 lines, was 1023; not split).
- All acceptance grep checks pass.
- Three fixture files exist and are non-empty.

## Self-Check: PASSED

- All commits exist on `main` (5a98083, eebf99e, ef0b230)
- All listed files exist on disk
- Build green
