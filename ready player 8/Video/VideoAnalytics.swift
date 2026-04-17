// Phase 22 D-40 — iOS video analytics emission helper.
// Wraps AnalyticsEngine.shared.track with sanitization to prevent PII leaks.
// All 8 D-40 event names match web/src/lib/video/analytics.ts exactly.

import Foundation

enum VideoAnalytics {
    // MARK: - Generic track wrapper (sanitizes before forwarding)

    @MainActor
    static func track(_ event: String, properties: [String: String]) {
        var safe = properties
        safe.removeValue(forKey: "stream_key")
        safe.removeValue(forKey: "signed_url")
        AnalyticsEngine.shared.track(event, properties: safe)
    }

    // MARK: - D-40 typed helpers

    @MainActor
    static func uploadStarted(
        assetId: String,
        fileSizeBytes: Int,
        container: String,
        clientDurationEstimate: Double? = nil,
        projectId: UUID,
        orgId: UUID,
        userId: UUID? = nil
    ) {
        var props: [String: String] = [
            "asset_id": assetId,
            "file_size_bytes": String(fileSizeBytes),
            "container": container,
            "project_id": projectId.uuidString,
            "org_id": orgId.uuidString
        ]
        if let clientDurationEstimate { props["client_duration_estimate"] = String(clientDurationEstimate) }
        if let userId { props["user_id"] = userId.uuidString }
        track("video_upload_started", properties: props)
    }

    @MainActor
    static func uploadFailed(
        assetId: String,
        errorCode: String,
        bytesSent: Int,
        projectId: UUID,
        orgId: UUID,
        userId: UUID? = nil
    ) {
        var props: [String: String] = [
            "asset_id": assetId,
            "error_code": errorCode,
            "bytes_sent": String(bytesSent),
            "project_id": projectId.uuidString,
            "org_id": orgId.uuidString
        ]
        if let userId { props["user_id"] = userId.uuidString }
        track("video_upload_failed", properties: props)
    }

    @MainActor
    static func playbackStarted(
        assetId: String? = nil,
        sourceId: String? = nil,
        kind: String,
        qualityRendition: String? = nil,
        isCellular: Bool? = nil,
        projectId: UUID,
        orgId: UUID,
        userId: UUID? = nil
    ) {
        var props: [String: String] = [
            "kind": kind,
            "project_id": projectId.uuidString,
            "org_id": orgId.uuidString
        ]
        if let assetId { props["asset_id"] = assetId }
        if let sourceId { props["source_id"] = sourceId }
        if let qualityRendition { props["quality_rendition"] = qualityRendition }
        if let isCellular { props["is_cellular"] = String(isCellular) }
        if let userId { props["user_id"] = userId.uuidString }
        track("video_playback_started", properties: props)
    }
}
