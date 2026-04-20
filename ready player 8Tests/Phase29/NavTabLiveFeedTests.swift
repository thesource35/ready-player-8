// Owner: 29-05-PLAN.md Wave 3 — LIVE-03 (iOS): NavTab.liveFeed + LiveSuggestion Codable.
// NavTab is nested under ContentView in ContentView.swift (enum NavTab: String), so the
// fully-qualified path is ContentView.NavTab.liveFeed.
import XCTest
@testable import ready_player_8

final class NavTabLiveFeedTests: XCTestCase {

    // LIVE-03: NavTab.liveFeed rawValue matches the intel-group nav item id.
    func testNavTabLiveFeedExistsWithKebabRawValue() {
        XCTAssertEqual(ContentView.NavTab.liveFeed.rawValue, "live-feed")
    }

    // UI-SPEC §Color line 121 locks the enum to exactly 3 values (routine / opportunity / alert).
    func testLiveSuggestionSeverityHasExactlyThreeCases() {
        XCTAssertEqual(LiveSuggestionSeverity.allCases.count, 3)
        XCTAssertTrue(LiveSuggestionSeverity.allCases.contains(.routine))
        XCTAssertTrue(LiveSuggestionSeverity.allCases.contains(.opportunity))
        XCTAssertTrue(LiveSuggestionSeverity.allCases.contains(.alert))
    }

    // D-17 Codable wire shape — snake_case keys, nested structured_fields.
    func testLiveSuggestionDecodesSnakeCaseJSON() throws {
        let json = """
        {
          "id": "aaaa",
          "project_id": "pp",
          "org_id": "oo",
          "generated_at": "2026-04-20T12:00:00Z",
          "source_asset_id": "ss",
          "model": "claude-haiku-4-5-20251001",
          "suggestion_text": "Concrete pour in NW.",
          "action_hint": {
            "verb": "prep dock 2",
            "severity": "opportunity",
            "structured_fields": { "equipment_active_count": 3 }
          },
          "dismissed_at": null,
          "dismissed_by": null
        }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(LiveSuggestion.self, from: json)
        XCTAssertEqual(row.model, "claude-haiku-4-5-20251001")
        XCTAssertEqual(row.actionHint?.severity, .opportunity)
        XCTAssertEqual(row.actionHint?.structuredFields?.equipmentActiveCount, 3)
        XCTAssertFalse(row.isBudgetMarker)
    }

    // LIVE-11 UI-SPEC line 326 — model == 'budget_reached_marker' flips the sentinel flag.
    func testBudgetMarkerSentinelIsRecognized() throws {
        let json = """
        {
          "id":"m1","project_id":"p","org_id":"o",
          "generated_at":"2026-04-20T12:00:00Z","source_asset_id":"s",
          "model":"budget_reached_marker",
          "suggestion_text":"(budget reached)",
          "action_hint":null,
          "dismissed_at":null,"dismissed_by":null
        }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(LiveSuggestion.self, from: json)
        XCTAssertTrue(row.isBudgetMarker)
    }
}
