// Owner: 22-02-PLAN.md Wave 1 — VideoSource/VideoAsset model types (VIDEO-01-A)
// Un-skipped in 22-11: real Codable round-trip assertions.
import XCTest
@testable import ready_player_8

final class VideoModelTests: XCTestCase {
    func test_VideoSource_codable_roundtrip() throws {
        let json = Data("""
        {"id":"11111111-1111-1111-1111-111111111111","org_id":"22222222-2222-2222-2222-222222222222","project_id":"33333333-3333-3333-3333-333333333333","kind":"fixed_camera","name":"North Gate","location_label":null,"mux_live_input_id":"live-123","mux_playback_id":"play-456","audio_enabled":false,"status":"active","last_active_at":"2026-04-15T12:00:00Z","created_at":"2026-04-15T10:00:00Z","created_by":"44444444-4444-4444-4444-444444444444"}
        """.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let src = try decoder.decode(VideoSource.self, from: json)
        XCTAssertEqual(src.kind, .fixedCamera)
        XCTAssertEqual(src.audioEnabled, false)
        XCTAssertEqual(src.status, .active)
        XCTAssertEqual(src.name, "North Gate")
        XCTAssertEqual(src.muxLiveInputId, "live-123")
        XCTAssertEqual(src.muxPlaybackId, "play-456")
    }

    func test_VideoAsset_drone_discriminator() throws {
        // Phase 29 row shape — must decode cleanly in Phase 22 types (D-08)
        let json = Data("""
        {"id":"11111111-1111-1111-1111-111111111111","source_id":"22222222-2222-2222-2222-222222222222","org_id":"33333333-3333-3333-3333-333333333333","project_id":"44444444-4444-4444-4444-444444444444","source_type":"drone","kind":"vod","storage_path":"org/proj/asset/raw.mp4","mux_playback_id":null,"mux_asset_id":null,"status":"ready","started_at":"2026-04-15T12:00:00Z","ended_at":null,"duration_s":180.5,"retention_expires_at":"2026-05-15T12:00:00Z","name":"Flight 1","portal_visible":false,"last_error":null,"created_at":"2026-04-15T10:00:00Z","created_by":"55555555-5555-5555-5555-555555555555"}
        """.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let asset = try decoder.decode(VideoAsset.self, from: json)
        XCTAssertEqual(asset.sourceType, .drone)
        XCTAssertEqual(asset.kind, .vod)
        XCTAssertEqual(asset.status, .ready)
        XCTAssertEqual(asset.durationS, 180.5)
        XCTAssertEqual(asset.portalVisible, false)
    }

    func test_VideoSource_upload_kind() throws {
        let json = Data("""
        {"id":"11111111-1111-1111-1111-111111111111","org_id":"22222222-2222-2222-2222-222222222222","project_id":"33333333-3333-3333-3333-333333333333","kind":"upload","name":"Uploads","location_label":null,"mux_live_input_id":null,"mux_playback_id":null,"audio_enabled":true,"status":"idle","last_active_at":null,"created_at":"2026-04-15T10:00:00Z","created_by":"44444444-4444-4444-4444-444444444444"}
        """.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let src = try decoder.decode(VideoSource.self, from: json)
        XCTAssertEqual(src.kind, .upload)
        XCTAssertEqual(src.status, .idle)
        XCTAssertEqual(src.audioEnabled, true)
    }
}
