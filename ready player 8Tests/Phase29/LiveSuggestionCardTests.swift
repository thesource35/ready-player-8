// Owner: 29-07-PLAN.md Wave 3 — LIVE-09 (iOS): LiveSuggestionCard severity + dismiss
//
// Locks the severity enum ↔ color mapping, the budget-marker sentinel behavior,
// and the LiveSuggestionsStore optimistic-dismiss/undo contract. Network PATCH
// is not exercised (SupabaseService defaults to unconfigured in unit runs); the
// local Published state mutations are what the row/card UI actually binds to.

import XCTest
import SwiftUI
@testable import ready_player_8

final class LiveSuggestionCardTests: XCTestCase {

    // MARK: - Fixtures

    private func sample(
        severity: LiveSuggestionSeverity,
        budgetMarker: Bool = false,
        id: String = UUID().uuidString
    ) -> LiveSuggestion {
        LiveSuggestion(
            id: id,
            projectId: "p",
            orgId: "o",
            generatedAt: "2026-04-20T12:00:00Z",
            sourceAssetId: "a",
            model: budgetMarker ? "budget_reached_marker" : "claude-haiku-4-5-20251001",
            suggestionText: budgetMarker ? "(budget reached)" : "Rebar delivery at east gate.",
            actionHint: budgetMarker
                ? nil
                : LiveSuggestionActionHint(
                    verb: "prep dock",
                    severity: severity,
                    structuredFields: nil
                ),
            dismissedAt: nil,
            dismissedBy: nil
        )
    }

    // MARK: - Severity identity (locks the enum so the card's switch covers all 3 cases)

    func testRoutineSeverityIdentified() {
        let s = sample(severity: .routine)
        XCTAssertEqual(s.actionHint?.severity, .routine)
    }

    func testOpportunitySeverityIdentified() {
        let s = sample(severity: .opportunity)
        XCTAssertEqual(s.actionHint?.severity, .opportunity)
    }

    func testAlertSeverityIdentified() {
        let s = sample(severity: .alert)
        XCTAssertEqual(s.actionHint?.severity, .alert)
    }

    // MARK: - Budget-marker sentinel (UI-SPEC LIVE-11 line 326)

    func testBudgetMarkerSentinel() {
        let s = sample(severity: .routine, budgetMarker: true)
        XCTAssertTrue(s.isBudgetMarker)
        XCTAssertNil(s.actionHint)
    }

    // MARK: - Store optimistic dismiss + undo (LIVE-09)

    @MainActor
    func testStoreOptimisticDismissRecordsUndoPayload() {
        let store = LiveSuggestionsStore(projectId: "p")
        let s = sample(severity: .routine)

        store.dismiss(s)

        // Undo payload is the load-bearing observable — LiveSuggestionCardRow
        // binds `store.undoPending` to show the "Suggestion dismissed. [Undo]" toast.
        XCTAssertNotNil(store.undoPending)
        XCTAssertEqual(store.undoPending?.suggestion.id, s.id)
    }

    @MainActor
    func testStoreUndoClearsPending() {
        let store = LiveSuggestionsStore(projectId: "p")
        let s = sample(severity: .routine)

        store.dismiss(s)
        XCTAssertNotNil(store.undoPending)

        store.undo()
        XCTAssertNil(store.undoPending)
    }

    // MARK: - Budget state thresholds (UI-SPEC §Color line 125-129)

    func testBudgetStateThresholds() {
        let healthy = LiveSuggestionsStore.BudgetState(used: 20, remaining: 76, cap: 96, resetsAt: nil)
        XCTAssertTrue(healthy.isHealthy)
        XCTAssertFalse(healthy.isWarning)
        XCTAssertFalse(healthy.isReached)

        let warning = LiveSuggestionsStore.BudgetState(used: 85, remaining: 11, cap: 96, resetsAt: nil)
        XCTAssertFalse(warning.isHealthy)
        XCTAssertTrue(warning.isWarning)
        XCTAssertFalse(warning.isReached)

        let reached = LiveSuggestionsStore.BudgetState(used: 96, remaining: 0, cap: 96, resetsAt: nil)
        XCTAssertFalse(reached.isHealthy)
        XCTAssertFalse(reached.isWarning)
        XCTAssertTrue(reached.isReached)
    }
}
