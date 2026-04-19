// Owner: 29-02-PLAN.md Wave 1 — LiveSuggestion wire-shape anchor + VideoSourceType drone case.
// NOTE: The real LiveSuggestion struct lives in 29-05 LiveFeedModels.swift. This test uses an
// inline minimal wire struct to pin the cs_live_suggestions JSON shape (D-17) now, so Wave 3
// iOS plans implement against a known contract. The enum assertion also locks Phase 22's
// Phase-29-ready VideoSourceType.drone case, which this plan's widened upload route depends on.
import XCTest
@testable import ready_player_8

final class LiveFeedModelsTests: XCTestCase {

    // Inline minimal wire struct matching cs_live_suggestions columns (D-17).
    // Wave 3 replaces this with the real LiveSuggestion struct in LiveFeedModels.swift.
    struct WireLiveSuggestion: Decodable {
        let id: String
        let projectId: String
        let orgId: String
        let generatedAt: String
        let sourceAssetId: String
        let model: String
        let suggestionText: String
        let dismissedAt: String?

        enum CodingKeys: String, CodingKey {
            case id, model
            case projectId = "project_id"
            case orgId = "org_id"
            case generatedAt = "generated_at"
            case sourceAssetId = "source_asset_id"
            case suggestionText = "suggestion_text"
            case dismissedAt = "dismissed_at"
        }
    }

    func testDecodesSnakeCaseJSON() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "project_id": "22222222-2222-2222-2222-222222222222",
          "org_id": "33333333-3333-3333-3333-333333333333",
          "generated_at": "2026-04-20T12:00:00Z",
          "source_asset_id": "44444444-4444-4444-4444-444444444444",
          "model": "claude-haiku-4-5-20251001",
          "suggestion_text": "Material delivery at east gate.",
          "dismissed_at": null
        }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(WireLiveSuggestion.self, from: json)
        XCTAssertEqual(row.projectId, "22222222-2222-2222-2222-222222222222")
        XCTAssertEqual(row.model, "claude-haiku-4-5-20251001")
        XCTAssertEqual(row.suggestionText, "Material delivery at east gate.")
        XCTAssertNil(row.dismissedAt)
    }

    func testSourceTypeEnumIncludesDrone() {
        // Phase 29 LIVE-01 D-11 — drone case MUST exist in VideoSourceType (widened upload
        // route relies on rawValue matching the Zod enum on the web side).
        XCTAssertEqual(VideoSourceType.drone.rawValue, "drone")
        XCTAssertEqual(VideoSourceType.upload.rawValue, "upload")
        XCTAssertEqual(VideoSourceType.fixedCamera.rawValue, "fixed_camera")
    }
}
