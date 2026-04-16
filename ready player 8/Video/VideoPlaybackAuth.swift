// Phase 22: Swift client for server-minted playback credentials.
//
// D-14: Playback tokens are minted by the web API — NEVER forged client-side.
// D-19: Dual-path support for logged-in users (session bearer) vs portal viewers
//       (portal_token in body; no auth header).
//
// Routes consumed:
//   POST /api/video/mux/playback-token         (user, 22-03 Task 2)
//   POST /api/portal/video/playback-token      (portal, landed in Phase 22-09)
//   GET  /api/video/vod/playback-url?asset_id  (user, 22-04 Task 1)
//   GET  /api/portal/video/playback-url        (portal, 22-09)

import Foundation

// MARK: - Response shapes

struct MuxPlaybackToken: Decodable {
    let token: String
    let ttl: Int
    let playback_id: String
}

struct VodPlaybackResponse {
    let manifestUrl: URL
}

// MARK: - VideoPlaybackAuth

enum VideoPlaybackAuth {
    /// Base URL for the web API (reuses existing Backend.BaseURL AppStorage key used by SupabaseService).
    static var apiBaseURL: URL? {
        if let raw = UserDefaults.standard.string(forKey: "ConstructOS.Integrations.Backend.BaseURL"),
           let url = URL(string: raw) { return url }
        return nil
    }

    /// Fetch a short-lived Mux JWT for a live or live-DVR source.
    ///
    /// - When `portalToken` is nil: calls /api/video/mux/playback-token with
    ///   `Authorization: Bearer <sessionToken>` (logged-in user path).
    /// - When `portalToken` is provided: calls /api/portal/video/playback-token with
    ///   the token in the body (no session header). D-19 portal path.
    ///
    /// Throws:
    /// - `.supabaseNotConfigured` if base URL unset
    /// - `.permissionDenied(feature:)` on 401/403
    /// - `.validationFailed(...)` on 429 rate limit (per D-37 30 req/min/IP)
    /// - `.supabaseHTTP(...)` on other non-2xx
    /// - `.network(underlying:)` on URLSession error
    static func fetchMuxToken(
        sourceId: UUID,
        sessionToken: String,
        portalToken: String? = nil
    ) async throws -> MuxPlaybackToken {
        guard let base = apiBaseURL else { throw AppError.supabaseNotConfigured }
        let path = portalToken == nil
            ? "/api/video/mux/playback-token"
            : "/api/portal/video/playback-token"
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let portalToken {
            let body: [String: String] = [
                "source_id": sourceId.uuidString,
                "portal_token": portalToken
            ]
            req.httpBody = try JSONEncoder().encode(body)
        } else {
            req.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            let body: [String: String] = ["source_id": sourceId.uuidString]
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw AppError.network(underlying: error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network(underlying: URLError(.badServerResponse))
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw AppError.permissionDenied(feature: "Video playback")
        }
        if http.statusCode == 429 {
            throw AppError.validationFailed(
                field: "rate",
                reason: "Too many playback requests. Wait a minute and try again."
            )
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.supabaseHTTP(
                statusCode: http.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
        return try JSONDecoder().decode(MuxPlaybackToken.self, from: data)
    }

    /// Build the VOD manifest URL — AVPlayer loads this URL directly.
    /// The web route returns the rewritten manifest inline (application/vnd.apple.mpegurl)
    /// with signed segment URIs, so AVPlayer can follow them without additional auth.
    ///
    /// - When `portalToken` is provided: uses /api/portal/video/playback-url and appends
    ///   `portal_token` as a query item (D-19 portal path).
    /// - Otherwise: uses /api/video/vod/playback-url (logged-in user path; relies on session cookie).
    ///
    /// Throws `.supabaseNotConfigured` if base URL unset, `.unknown(_)` on URL composition failure.
    static func vodManifestUrl(assetId: UUID, portalToken: String? = nil) throws -> URL {
        guard let base = apiBaseURL else { throw AppError.supabaseNotConfigured }
        let path = portalToken == nil
            ? "/api/video/vod/playback-url"
            : "/api/portal/video/playback-url"
        guard var comp = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw AppError.unknown("Bad playback URL components")
        }
        var items: [URLQueryItem] = [URLQueryItem(name: "asset_id", value: assetId.uuidString)]
        if let portalToken {
            items.append(URLQueryItem(name: "portal_token", value: portalToken))
        }
        comp.queryItems = items
        guard let url = comp.url else {
            throw AppError.unknown("Could not compose playback URL for asset \(assetId)")
        }
        return url
    }
}
