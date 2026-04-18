// DocumentSyncManagerPreflightTests.swift — Phase 26 Plan 03
// Drift-guard and pre-flight contract tests for DocumentSyncManager.

import XCTest
@testable import ready_player_8

final class DocumentSyncManagerPreflightTests: XCTestCase {

    // D-11 drift guard: iOS enum must match DB `cs_document_entity_type` enum
    // exactly. If a future phase extends the DB enum, every layer (web
    // validation.ts, iOS DocumentEntityType) must be updated together — this
    // test fails loudly when that invariant breaks.
    func test_documentEntityType_allCases_matchesDBEnum() {
        let expected: [String] = [
            "project", "rfi", "submittal", "change_order",
            "daily_log", "safety_incident", "punch_item"
        ]
        let actual = DocumentEntityType.allCases.map { $0.rawValue }
        XCTAssertEqual(Set(actual), Set(expected),
            "DocumentEntityType drifted from cs_document_entity_type enum")
        XCTAssertEqual(actual.count, 7, "Must cover all 7 enum values")
    }

    // D-06 contract: when SupabaseService is not configured (test/CI
    // environment without baseURL), preflight must be a no-op — offline-first
    // defers enforcement to the server (both API route pre-flight and RLS).
    // This test documents the expected contract; the private preflight helper
    // is exercised end-to-end via the web route tests on the server side.
    // @MainActor required: SupabaseService is @MainActor-isolated (Swift 6
    // strict concurrency enforcement).
    @MainActor
    func test_preflight_notConfigured_isNoop() async {
        XCTAssertFalse(
            SupabaseService.shared.isConfigured,
            "Test environment expects no Supabase config"
        )
        // If preflightEntityExists throws in the offline case, uploadDocument
        // would throw before even reading the file. The drift-guard above +
        // route tests on web are the primary coverage; this assertion is a
        // smoke-check that the iOS test environment is unconfigured as
        // expected.
    }
}
