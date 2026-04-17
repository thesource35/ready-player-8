// Owner: 22-05-PLAN.md Wave 2 — SupabaseService video playback-token client (VIDEO-01-I)
// Un-skipped in 22-11: real assertions covering VideoPlaybackAuth error mapping.
import XCTest
@testable import ready_player_8

final class VideoAuthTests: XCTestCase {
    /// Verify that the MuxPlaybackToken Decodable shape matches the server's JSON contract.
    func test_MuxPlaybackToken_decodable() throws {
        let json = Data("""
        {"token":"jwt-test-token","ttl":300,"playback_id":"pb-abc-123"}
        """.utf8)
        let token = try JSONDecoder().decode(MuxPlaybackToken.self, from: json)
        XCTAssertEqual(token.token, "jwt-test-token")
        XCTAssertEqual(token.ttl, 300)
        XCTAssertEqual(token.playback_id, "pb-abc-123")
    }

    /// Verify vodManifestUrl composition for logged-in user path.
    func test_vodManifestUrl_user_path() throws {
        // Set a test base URL so vodManifestUrl can compose
        UserDefaults.standard.set("https://test.example.com", forKey: "ConstructOS.Integrations.Backend.BaseURL")
        defer {
            UserDefaults.standard.removeObject(forKey: "ConstructOS.Integrations.Backend.BaseURL")
        }

        let assetId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let url = try VideoPlaybackAuth.vodManifestUrl(assetId: assetId)
        XCTAssertTrue(url.absoluteString.contains("/api/video/vod/playback-url"))
        XCTAssertTrue(url.absoluteString.contains("asset_id=11111111"))
        // User path should NOT have portal_token
        XCTAssertFalse(url.absoluteString.contains("portal_token"))
    }

    /// Verify vodManifestUrl composition for portal viewer path.
    func test_vodManifestUrl_portal_path() throws {
        UserDefaults.standard.set("https://test.example.com", forKey: "ConstructOS.Integrations.Backend.BaseURL")
        defer {
            UserDefaults.standard.removeObject(forKey: "ConstructOS.Integrations.Backend.BaseURL")
        }

        let assetId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let url = try VideoPlaybackAuth.vodManifestUrl(assetId: assetId, portalToken: "portal-tok-123")
        XCTAssertTrue(url.absoluteString.contains("/api/portal/video/playback-url"))
        XCTAssertTrue(url.absoluteString.contains("portal_token=portal-tok-123"))
        XCTAssertTrue(url.absoluteString.contains("asset_id=22222222"))
    }

    /// Verify vodManifestUrl throws when base URL is not configured.
    func test_vodManifestUrl_throws_when_unconfigured() {
        UserDefaults.standard.removeObject(forKey: "ConstructOS.Integrations.Backend.BaseURL")
        let assetId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        XCTAssertThrowsError(try VideoPlaybackAuth.vodManifestUrl(assetId: assetId)) { error in
            // Should throw AppError.supabaseNotConfigured
            if let appErr = error as? AppError {
                switch appErr {
                case .supabaseNotConfigured:
                    break // expected
                default:
                    XCTFail("Expected supabaseNotConfigured, got \(appErr)")
                }
            }
        }
    }
}
