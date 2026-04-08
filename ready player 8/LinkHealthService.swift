import Foundation

enum LinkHealthStatus: String {
    case ok
    case redirect
    case error
    case timeout
    case invalid
    case blocked
}

struct LinkHealthResult {
    let url: String
    let status: LinkHealthStatus
    let statusCode: Int?
    let checkedAt: Date
    let responseTimeMS: Int?
    let finalURL: String?
    let error: String?

    var isReachable: Bool {
        status == .ok || status == .redirect || status == .blocked
    }
}

actor LinkHealthService {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = LinkHealthService()

    private let cacheTTL: TimeInterval = 5 * 60
    private let timeout: TimeInterval = 8
    private var cache: [String: LinkHealthResult] = [:]

    func check(urlString: String, force: Bool = false) async -> LinkHealthResult {
        let normalized = normalize(urlString)
        if !force, let cached = cache[normalized], !isExpired(cached) {
            return cached
        }

        guard let url = URL(string: normalized) else {
            let result = LinkHealthResult(
                url: normalized,
                status: .invalid,
                statusCode: nil,
                checkedAt: Date(),
                responseTimeMS: nil,
                finalURL: nil,
                error: "Invalid URL."
            )
            cache[normalized] = result
            return result
        }

        if isBlockedHost(url) {
            let result = LinkHealthResult(
                url: normalized,
                status: .blocked,
                statusCode: nil,
                checkedAt: Date(),
                responseTimeMS: nil,
                finalURL: nil,
                error: "Blocked host."
            )
            cache[normalized] = result
            return result
        }

        let result = await checkLink(url, original: normalized)
        cache[normalized] = result
        return result
    }

    private func checkLink(_ url: URL, original: String) async -> LinkHealthResult {
        let startedAt = Date()
        do {
            var response = try await fetch(url, method: "HEAD")
            if let code = response.statusCode, (200...399).contains(code) == false || response.statusCode == 403 || response.statusCode == 405 {
                response = try await fetch(url, method: "GET")
            }

            let status = mapStatus(response.statusCode)
            return LinkHealthResult(
                url: original,
                status: status,
                statusCode: response.statusCode,
                checkedAt: Date(),
                responseTimeMS: Int(Date().timeIntervalSince(startedAt) * 1000),
                finalURL: response.finalURL,
                error: nil
            )
        } catch {
            let isTimeout = (error as NSError).code == NSURLErrorTimedOut
            return LinkHealthResult(
                url: original,
                status: isTimeout ? .timeout : .error,
                statusCode: nil,
                checkedAt: Date(),
                responseTimeMS: Int(Date().timeIntervalSince(startedAt) * 1000),
                finalURL: nil,
                error: error.localizedDescription
            )
        }
    }

    private func fetch(_ url: URL, method: String) async throws -> (statusCode: Int?, finalURL: String?) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        if method == "GET" {
            request.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        return (http?.statusCode, http?.url?.absoluteString)
    }

    private func mapStatus(_ statusCode: Int?) -> LinkHealthStatus {
        guard let statusCode else { return .error }
        if (200...299).contains(statusCode) { return .ok }
        if (300...399).contains(statusCode) { return .redirect }
        if statusCode == 401 || statusCode == 403 || statusCode == 405 { return .blocked }
        return .error
    }

    private func isExpired(_ result: LinkHealthResult) -> Bool {
        Date().timeIntervalSince(result.checkedAt) > cacheTTL
    }

    private func normalize(_ url: String) -> String {
        var trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        // Enforce HTTPS — upgrade HTTP URLs
        if trimmed.lowercased().hasPrefix("http://") {
            trimmed = "https://" + trimmed.dropFirst("http://".count)
        }
        // Add HTTPS if no scheme
        if !trimmed.lowercased().hasPrefix("https://") && !trimmed.contains("://") {
            trimmed = "https://" + trimmed
        }
        return trimmed
    }

    private func isBlockedHost(_ url: URL) -> Bool {
        let hostname = url.host?.lowercased() ?? ""
        // Localhost and local network
        if hostname == "localhost" || hostname.hasSuffix(".local") { return true }
        if hostname == "0.0.0.0" || hostname == "127.0.0.1" { return true }
        // IPv4 private ranges
        if let ip = IPv4Address(hostname), ip.isPrivate { return true }
        // IPv6 — loopback, link-local, unique local (ULA)
        if hostname == "::1" || hostname == "[::1]" { return true }
        if hostname.hasPrefix("fe80") { return true }  // Link-local
        if hostname.hasPrefix("fc") || hostname.hasPrefix("fd") { return true }  // ULA
        if hostname.hasPrefix("::ffff:127.") { return true }  // IPv4-mapped loopback
        if hostname.hasPrefix("::ffff:10.") || hostname.hasPrefix("::ffff:192.168.") { return true }  // IPv4-mapped private
        return false
    }
}

private struct IPv4Address {
    let octets: [Int]

    init?(_ string: String) {
        let parts = string.split(separator: ".").map { Int($0) ?? -1 }
        guard parts.count == 4, parts.allSatisfy({ $0 >= 0 && $0 <= 255 }) else { return nil }
        octets = parts
    }

    var isPrivate: Bool {
        let a = octets[0]
        let b = octets[1]
        if a == 10 { return true }
        if a == 127 { return true }
        if a == 192 && b == 168 { return true }
        if a == 172 && (16...31).contains(b) { return true }
        return false
    }
}
