// Phase 22: VOD upload client.
//
// Flow (D-24, D-31, D-40):
//   1. Probe file — duration via AVURLAsset, size via FileManager. Client-side D-31
//      pre-check: 2GB / 60min / mp4|mov|m4v. Throws before any network work.
//   2. POST /api/video/vod/upload-url with {project_id, org_id, name, file_size_bytes,
//      duration_s, container} → receives {asset_id, object_name, bucket_name, upload_url, auth_token}.
//   3. Upload to Supabase Storage resumable endpoint (upload_url). For v1 iOS we PUT the
//      whole file with 3x retry on transient 5xx / network. tus-native resume is a
//      follow-up (RESEARCH Upload UX option B — see VideoUploadClient.md comment).
//   4. Emit D-40 analytics events: video_upload_started on start, video_upload_failed
//      on terminal failure. Success analytics fire once the transcode completes
//      (polled in 22-06 player).
//
// Mirrors the FieldPhotoUpload (Phase 13) shape: progress callback + AppError surface.
// Errors surface through AppError — no silent swallowing. See AppError.swift for the
// Phase 22 D-40 cases (clipTooLarge / clipTooLong / unsupportedVideoFormat).

import Foundation
import AVFoundation

// MARK: - Response shape from /api/video/vod/upload-url

struct VideoUploadURLResponse: Decodable {
    let asset_id: String
    let bucket_name: String
    let object_name: String
    let upload_url: String
    let auth_token: String
}

// MARK: - Probe result

struct VideoProbeResult {
    let durationSeconds: Double
    let sizeBytes: Int
    let containerExt: String
}

// MARK: - Analytics event names (D-40)
// These string constants are fired through AnalyticsEngine in 22-11; here we just emit them.

private enum VideoUploadAnalyticsEvent {
    static let started = "video_upload_started"
    static let failed = "video_upload_failed"
}

// MARK: - VideoUploadClient

final class VideoUploadClient {
    /// D-31 caps mirror web/src/lib/video/types.ts constants (2 GB / 60 min / mp4|mov|m4v).
    static let maxFileSizeBytes = 2 * 1024 * 1024 * 1024  // 2 GB
    static let maxDurationSeconds: Double = 3600           // 60 min
    static let allowedContainers: Set<String> = ["mp4", "mov", "m4v"]

    private var activeTask: URLSessionDataTask?
    private let session: URLSession

    let progress: (Double) -> Void
    let onComplete: (Result<String, AppError>) -> Void  // success yields asset_id

    init(
        progress: @escaping (Double) -> Void = { _ in },
        onComplete: @escaping (Result<String, AppError>) -> Void = { _ in },
        session: URLSession = .shared
    ) {
        self.progress = progress
        self.onComplete = onComplete
        self.session = session
    }

    // MARK: - Probe

    /// Async probe: returns (durationSeconds, sizeBytes) using AVURLAsset + FileManager.
    /// Throws the precise AppError D-40 case on any D-31 violation so upload is never started.
    static func probeFile(_ url: URL) async throws -> VideoProbeResult {
        // Size via FileManager
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0

        // Duration via AVURLAsset
        let asset = AVURLAsset(url: url)
        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
        } catch {
            throw AppError.unsupportedVideoFormat(details: "Unable to read duration — \(error.localizedDescription)")
        }
        let seconds: Double = {
            if duration.isIndefinite { return 0 }
            let s = CMTimeGetSeconds(duration)
            return s.isFinite ? s : 0
        }()

        let ext = url.pathExtension.lowercased()
        return VideoProbeResult(durationSeconds: seconds, sizeBytes: size, containerExt: ext)
    }

    // MARK: - Validate

    /// Apply D-31 client-side caps. Throws the specific AppError D-40 case on violation.
    static func validate(_ probe: VideoProbeResult) throws {
        guard allowedContainers.contains(probe.containerExt) else {
            throw AppError.unsupportedVideoFormat(details: probe.containerExt.isEmpty ? "(unknown)" : probe.containerExt)
        }
        // 2 GB cap (D-31)
        if probe.sizeBytes > maxFileSizeBytes {
            throw AppError.clipTooLarge(maxGB: 2)
        }
        // 60 min cap (D-31)
        if probe.durationSeconds > maxDurationSeconds {
            throw AppError.clipTooLong(maxMinutes: 60)
        }
    }

    // MARK: - Upload

    /// Full upload flow. See file header for steps. Calls `progress(fraction)` periodically
    /// (0.0 → 1.0). On completion calls `onComplete(.success(assetId))` or `.failure(AppError)`.
    ///
    /// - Parameters:
    ///   - fileUrl: local file to upload (mp4/mov/m4v)
    ///   - projectId: cs_projects.id
    ///   - orgId: organization scope for RLS
    ///   - name: display name (optional; first 128 chars kept server-side)
    ///   - sessionToken: Supabase access token for the /api/video/vod/upload-url call
    ///   - apiBaseURL: web API base URL (same as Backend.BaseURL)
    ///   - sourceType: Phase 29 LIVE-01 D-11. Optional discriminator written to
    ///     cs_video_assets.source_type. `nil` lets the server default to `'upload'`
    ///     (Phase 22 back-compat). Only `.upload` and `.drone` are accepted by the
    ///     route; `.fixedCamera` is server-side only and will 400.
    func upload(
        fileUrl: URL,
        projectId: UUID,
        orgId: UUID,
        name: String?,
        sessionToken: String,
        apiBaseURL: URL,
        sourceType: VideoSourceType? = nil
    ) async {
        // Analytics: video_upload_started (D-40) — emitted at top so failed probes still appear in the funnel.
        await MainActor.run {
            AnalyticsEngine.shared.track(VideoUploadAnalyticsEvent.started, properties: [
                "project_id": projectId.uuidString,
                "org_id": orgId.uuidString
            ])
        }

        // 1. Probe + validate
        let probe: VideoProbeResult
        do {
            probe = try await Self.probeFile(fileUrl)
            try Self.validate(probe)
        } catch let err as AppError {
            await self.failAndReport(err, reason: "probe/validate")
            return
        } catch {
            await self.failAndReport(.uploadFailed(error.localizedDescription), reason: "probe")
            return
        }

        // 2. Mint upload URL from web API
        let resp: VideoUploadURLResponse
        do {
            resp = try await requestUploadURL(
                projectId: projectId,
                orgId: orgId,
                name: name,
                probe: probe,
                sessionToken: sessionToken,
                apiBaseURL: apiBaseURL,
                sourceType: sourceType
            )
        } catch let err as AppError {
            await self.failAndReport(err, reason: "upload-url")
            return
        } catch {
            await self.failAndReport(.uploadFailed(error.localizedDescription), reason: "upload-url")
            return
        }

        // 3. Upload bytes with retry (3 attempts for transient failures)
        do {
            try await uploadBytes(
                fileUrl: fileUrl,
                response: resp,
                contentType: contentTypeFor(extension: probe.containerExt)
            )
            onComplete(.success(resp.asset_id))
        } catch let err as AppError {
            await self.failAndReport(err, reason: "upload-bytes")
        } catch {
            await self.failAndReport(.uploadFailed(error.localizedDescription), reason: "upload-bytes")
        }
    }

    /// Cancel the inflight upload task if any. Idempotent.
    func cancel() {
        activeTask?.cancel()
        activeTask = nil
    }

    // MARK: - Private helpers

    private func failAndReport(_ err: AppError, reason: String) async {
        let desc = err.errorDescription ?? "unknown"
        await MainActor.run {
            AnalyticsEngine.shared.track(VideoUploadAnalyticsEvent.failed, properties: [
                "reason": reason,
                "error": desc
            ])
        }
        print("[VideoUpload] failed (\(reason)): \(desc)")
        onComplete(.failure(err))
    }

    private func contentTypeFor(extension ext: String) -> String {
        switch ext {
        case "mp4", "m4v": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }

    private func requestUploadURL(
        projectId: UUID,
        orgId: UUID,
        name: String?,
        probe: VideoProbeResult,
        sessionToken: String,
        apiBaseURL: URL,
        sourceType: VideoSourceType?
    ) async throws -> VideoUploadURLResponse {
        let url = apiBaseURL.appendingPathComponent("/api/video/vod/upload-url")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "project_id": projectId.uuidString,
            "org_id": orgId.uuidString,
            "file_size_bytes": probe.sizeBytes,
            "duration_s": probe.durationSeconds,
            "container": probe.containerExt
        ]
        if let name { body["name"] = name }
        // Phase 29 LIVE-01: only serialize source_type when explicitly set; absent key
        // keeps the route on its Phase 22 back-compat default of 'upload'.
        if let sourceType { body["source_type"] = sourceType.rawValue }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network(underlying: URLError(.badServerResponse))
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw AppError.permissionDenied(feature: "Video upload")
        }
        if http.statusCode == 413 {
            // Server enforced D-31 caps — inspect body for code to pick the right AppError.
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            if bodyStr.contains("clip_too_long") { throw AppError.clipTooLong(maxMinutes: 60) }
            if bodyStr.contains("clip_too_large") { throw AppError.clipTooLarge(maxGB: 2) }
            throw AppError.uploadFailed("Server rejected upload (413): \(bodyStr)")
        }
        if http.statusCode == 400 {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            if bodyStr.contains("unsupported_format") {
                throw AppError.unsupportedVideoFormat(details: probe.containerExt)
            }
            throw AppError.uploadFailed("Bad request: \(bodyStr)")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.supabaseHTTP(statusCode: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(VideoUploadURLResponse.self, from: data)
    }

    /// Simple PUT-with-retry upload. File > 100 MB will log a warning that true tus-resumable
    /// chunking is a follow-up (RESEARCH Upload UX option B fallback).
    private func uploadBytes(
        fileUrl: URL,
        response: VideoUploadURLResponse,
        contentType: String
    ) async throws {
        let maxAttempts = 3
        var attempt = 0
        var lastError: Error?

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileUrl.path)[.size] as? NSNumber)?.intValue ?? 0
        if fileSize > 100 * 1024 * 1024 {
            print("[VideoUpload] NOTE: file is \(fileSize / (1024 * 1024)) MB; native tus-resumable chunked upload not yet implemented — full PUT with retry.")
        }

        while attempt < maxAttempts {
            attempt += 1
            do {
                try await singleUploadAttempt(
                    fileUrl: fileUrl,
                    response: response,
                    contentType: contentType
                )
                return
            } catch let err as AppError {
                lastError = err
                // Only retry on retryable AppErrors (network / 5xx).
                if !err.isRetryable { throw err }
                if attempt >= maxAttempts { throw err }
                let backoffMs = UInt64(attempt) * 1_000_000_000  // 1s, 2s, (3s — not used; 3 attempts total)
                try? await Task.sleep(nanoseconds: backoffMs)
            } catch {
                lastError = error
                if attempt >= maxAttempts { throw AppError.uploadFailed(error.localizedDescription) }
                let backoffMs = UInt64(attempt) * 1_000_000_000
                try? await Task.sleep(nanoseconds: backoffMs)
            }
        }

        throw AppError.uploadFailed(lastError?.localizedDescription ?? "All retries exhausted")
    }

    private func singleUploadAttempt(
        fileUrl: URL,
        response: VideoUploadURLResponse,
        contentType: String
    ) async throws {
        guard let uploadEndpoint = URL(string: response.upload_url) else {
            throw AppError.unknown("Invalid upload URL: \(response.upload_url)")
        }

        var req = URLRequest(url: uploadEndpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(response.auth_token)", forHTTPHeaderField: "Authorization")
        req.setValue("1.0.0", forHTTPHeaderField: "Tus-Resumable")
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")
        req.setValue(response.bucket_name, forHTTPHeaderField: "bucketName")
        req.setValue(response.object_name, forHTTPHeaderField: "objectName")
        req.setValue(contentType, forHTTPHeaderField: "contentType")

        // Report initial progress
        self.progress(0.0)

        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await session.upload(for: req, fromFile: fileUrl)
        } catch {
            throw AppError.network(underlying: error)
        }
        guard let http = resp as? HTTPURLResponse else {
            throw AppError.network(underlying: URLError(.badServerResponse))
        }

        // Storage resumable endpoint returns 201 on create / 204 on resume-complete.
        if http.statusCode == 401 || http.statusCode == 403 {
            throw AppError.permissionDenied(feature: "Video upload storage")
        }
        if http.statusCode >= 500 {
            // retryable
            throw AppError.supabaseHTTP(statusCode: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.uploadFailed("Storage returned \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
        }

        // Report completion
        self.progress(1.0)
    }
}
