// NetworkClient.swift — API abstraction with retry, caching, and testability
// ConstructionOS

import Foundation

// MARK: - Errors

enum APIClientError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Protocol

protocol APIClientProtocol: Sendable {
    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse)
    func get(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
    func post(url: URL, body: Data?, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
    func patch(url: URL, body: Data?, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
    func delete(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse)
}

// MARK: - Concrete Implementation

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let maxRetries: Int
    private let retryDelay: TimeInterval

    init(session: URLSession = .shared, maxRetries: Int = 2, retryDelay: TimeInterval = 1.0) {
        self.session = session
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error = APIClientError.invalidResponse

        for attempt in 0...maxRetries {
            do {
                #if DEBUG
                if attempt > 0 {
                    print("[APIClient] Retry \(attempt)/\(maxRetries): \(urlRequest.httpMethod ?? "GET") \(urlRequest.url?.path ?? "")")
                }
                #endif

                let (data, response) = try await session.data(for: urlRequest)
                guard let http = response as? HTTPURLResponse else {
                    throw APIClientError.invalidResponse
                }

                // Don't retry client errors (4xx)
                if http.statusCode >= 400 && http.statusCode < 500 {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    throw APIClientError.httpError(statusCode: http.statusCode, body: body)
                }

                // Retry server errors (5xx)
                if http.statusCode >= 500 {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    lastError = APIClientError.httpError(statusCode: http.statusCode, body: body)
                    if attempt < maxRetries {
                        let delay = retryDelay * pow(2.0, Double(attempt))
                        try await Task.sleep(for: .seconds(delay))
                        continue
                    }
                    throw lastError
                }

                return (data, http)

            } catch let error as URLError where error.code == .timedOut {
                lastError = APIClientError.timeout
                if attempt < maxRetries {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
            } catch let error as URLError {
                lastError = APIClientError.networkError(error)
                if attempt < maxRetries {
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
            } catch {
                throw error
            }
        }

        throw lastError
    }

    func get(url: URL, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return try await self.request(request)
    }

    func post(url: URL, body: Data? = nil, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return try await self.request(request)
    }

    func patch(url: URL, body: Data? = nil, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = body
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return try await self.request(request)
    }

    func delete(url: URL, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return try await self.request(request)
    }
}

// MARK: - Mock for Testing

final class MockAPIClient: APIClientProtocol {
    var responses: [(Data, HTTPURLResponse)] = []
    var requestLog: [URLRequest] = []
    var errorToThrow: Error?

    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requestLog.append(urlRequest)
        if let error = errorToThrow { throw error }
        guard !responses.isEmpty else {
            throw APIClientError.invalidResponse
        }
        return responses.removeFirst()
    }

    func get(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await self.request(request)
    }

    func post(url: URL, body: Data?, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        return try await self.request(request)
    }

    func patch(url: URL, body: Data?, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = body
        return try await self.request(request)
    }

    func delete(url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return try await self.request(request)
    }
}
