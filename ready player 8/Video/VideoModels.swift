// Phase 22: Video model types shared across iOS playback, upload, and sync paths.
// Per D-07 / D-08 / D-25 / D-26 / D-38. Changes to field names or enum rawValues
// MUST coordinate with web/src/lib/video/types.ts and Phase 29 row-inserts.

import Foundation

enum VideoKind: String, Codable, CaseIterable, Hashable {
    case fixedCamera = "fixed_camera"
    case drone = "drone"
    case upload = "upload"
}

// VideoSourceType mirrors cs_video_assets.source_type. Same 3 values as VideoKind
// by design — Phase 29 relies on the discriminator matching source.kind for filtering.
enum VideoSourceType: String, Codable, CaseIterable, Hashable {
    case fixedCamera = "fixed_camera"
    case drone = "drone"
    case upload = "upload"
}

enum VideoAssetKind: String, Codable, CaseIterable, Hashable {
    case live, vod
}

enum VideoSourceStatus: String, Codable, CaseIterable, Hashable {
    case idle, active, offline, archived
}

enum VideoAssetStatus: String, Codable, CaseIterable, Hashable {
    case uploading, transcoding, ready, failed
}

struct VideoSource: Codable, Identifiable, Hashable {
    let id: UUID
    let orgId: UUID
    let projectId: UUID
    let kind: VideoKind
    let name: String
    let locationLabel: String?
    let muxLiveInputId: String?
    let muxPlaybackId: String?
    let audioEnabled: Bool
    let status: VideoSourceStatus
    let lastActiveAt: Date?
    let createdAt: Date
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case id, kind, name, status
        case orgId = "org_id"
        case projectId = "project_id"
        case locationLabel = "location_label"
        case muxLiveInputId = "mux_live_input_id"
        case muxPlaybackId = "mux_playback_id"
        case audioEnabled = "audio_enabled"
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}

struct VideoAsset: Codable, Identifiable, Hashable {
    let id: UUID
    let sourceId: UUID
    let orgId: UUID
    let projectId: UUID
    let sourceType: VideoSourceType
    let kind: VideoAssetKind
    let storagePath: String?
    let muxPlaybackId: String?
    let muxAssetId: String?
    let status: VideoAssetStatus
    let startedAt: Date
    let endedAt: Date?
    let durationS: Double?
    let retentionExpiresAt: Date?
    let name: String?
    let portalVisible: Bool
    let lastError: String?
    let createdAt: Date
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case id, kind, name, status
        case sourceId = "source_id"
        case orgId = "org_id"
        case projectId = "project_id"
        case sourceType = "source_type"
        case storagePath = "storage_path"
        case muxPlaybackId = "mux_playback_id"
        case muxAssetId = "mux_asset_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationS = "duration_s"
        case retentionExpiresAt = "retention_expires_at"
        case portalVisible = "portal_visible"
        case lastError = "last_error"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}

enum VideoDefaultQuality: String, Codable, CaseIterable, Hashable {
    case auto, ld, sd, hd
}

// MARK: - AppStorage key namespace (D-26)

extension ConstructOS {
    enum Video {
        static let defaultQualityKey = "ConstructOS.Video.DefaultQuality"
        static let muxEnvironmentKey = "ConstructOS.Video.MuxEnvironment"
        // per-project last-played asset id uses format ConstructOS.Video.LastPlayedAssetId.{projectId}
        static func lastPlayedAssetIdKey(projectId: UUID) -> String {
            "ConstructOS.Video.LastPlayedAssetId.\(projectId.uuidString)"
        }
    }
}
