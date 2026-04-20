// Owner: 29-05-PLAN.md Wave 3 — LIVE-04 (iOS): ProjectSwitcherSheet persists LastSelectedProjectId
// + Fleet toggle persists LastFleetSelection. Tests lock the contract strings + AppStorage
// round-trip at the UserDefaults layer (what @AppStorage actually binds to).
import XCTest
import SwiftUI
@testable import ready_player_8

final class ProjectSwitcherTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: LiveFeedStorageKey.lastSelectedProjectId)
        UserDefaults.standard.removeObject(forKey: LiveFeedStorageKey.lastFleetSelection)
        super.tearDown()
    }

    // Locks the 3 stable keys — downstream plans + test fixtures break if these strings change.
    func testStorageKeyConstantsAreStableStrings() {
        XCTAssertEqual(LiveFeedStorageKey.lastSelectedProjectId, "ConstructOS.LiveFeed.LastSelectedProjectId")
        XCTAssertEqual(LiveFeedStorageKey.lastFleetSelection, "ConstructOS.LiveFeed.LastFleetSelection")
        XCTAssertEqual(LiveFeedStorageKey.suggestionModel, "ConstructOS.LiveFeed.SuggestionModel")
    }

    // Per-project scoped keys interpolate projectId into the key suffix.
    func testPerProjectKeyIncludesProjectId() {
        let k = LiveFeedStorageKey.lastAnalyzedAt(projectId: "proj-xyz")
        XCTAssertEqual(k, "ConstructOS.LiveFeed.LastAnalyzedAt.proj-xyz")
        let s = LiveFeedStorageKey.lastScrubTimestamp(projectId: "proj-xyz")
        XCTAssertEqual(s, "ConstructOS.LiveFeed.LastScrubTimestamp.proj-xyz")
    }

    // @AppStorage round-trips a String via UserDefaults — assert the contract at the defaults layer.
    func testAppStorageRoundTripsSelectedProjectId() {
        UserDefaults.standard.set("proj-42", forKey: LiveFeedStorageKey.lastSelectedProjectId)
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: LiveFeedStorageKey.lastSelectedProjectId),
            "proj-42"
        )
    }

    // Fleet toggle persists as Bool under LastFleetSelection.
    func testAppStorageRoundTripsFleetSelection() {
        UserDefaults.standard.set(true, forKey: LiveFeedStorageKey.lastFleetSelection)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: LiveFeedStorageKey.lastFleetSelection))
    }

    // ProjectSummary is the Identifiable shape the switcher + Fleet grid iterate over.
    func testProjectSummaryIsIdentifiable() {
        let p = ProjectSummary(id: "abc", name: "Riverfront", client: nil)
        XCTAssertEqual(p.id, "abc")
        XCTAssertEqual(p.name, "Riverfront")
        XCTAssertNil(p.client)
    }
}
