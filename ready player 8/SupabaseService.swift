import Combine
import Foundation
import SwiftUI

// MARK: - ========== SupabaseService.swift ==========

//
// Reads credentials from UserDefaults keys set by IntegrationHub:
//   ConstructOS.Integrations.Backend.BaseURL
//   ConstructOS.Integrations.Backend.ApiKey
//
// ─────────────────────────────────────────────────────────────────────────────
// SUPABASE TABLE SCHEMAS — run in your Supabase SQL editor:
//
// create table cs_projects (
//   id uuid primary key default gen_random_uuid(),
//   name text not null,
//   client text not null default '',
//   type text not null default 'General',
//   status text not null default 'Active',
//   progress int not null default 0,
//   budget text not null default '$0',
//   score text not null default '—',
//   team text not null default '',
//   created_at timestamptz default now()
// );
//
// create table cs_contracts (
//   id uuid primary key default gen_random_uuid(),
//   title text not null,
//   client text not null default '',
//   location text not null default '',
//   sector text not null default '',
//   stage text not null default 'Pursuit',
//   package text not null default '',
//   budget text not null default '$0',
//   bid_due text not null default '',
//   live_feed_status text not null default '',
//   bidders int not null default 0,
//   score int not null default 0,
//   watch_count int not null default 0,
//   created_at timestamptz default now()
// );
//
// create table cs_market_data (
//   id uuid primary key default gen_random_uuid(),
//   city text not null,
//   vacancy double precision not null default 0,
//   new_biz int not null default 0,
//   closed int not null default 0,
//   trend text not null default 'flat',
//   updated_at timestamptz default now()
// );
//
// create table cs_ai_messages (
//   id uuid primary key default gen_random_uuid(),
//   session_id text not null,
//   role text not null,
//   content text not null,
//   created_at timestamptz default now()
// );
//
// -- Wealth Suite Tables
//
// create table cs_wealth_opportunities (
//   id uuid primary key default gen_random_uuid(),
//   name text not null,
//   wealth_signal int not null default 0,
//   contract_id text,
//   status text not null default 'active',
//   created_at timestamptz default now()
// );
//
// create table cs_decision_journal (
//   id uuid primary key default gen_random_uuid(),
//   title text not null,
//   context text not null default '',
//   thinking_mode text not null default 'Strategic',
//   decision text not null default '',
//   first_order text not null default '',
//   second_order text not null default '',
//   gates_passed int not null default 0,
//   outcome_status text not null default 'pending',
//   created_at timestamptz default now(),
//   reviewed_at timestamptz
// );
//
// create table cs_psychology_sessions (
//   id uuid primary key default gen_random_uuid(),
//   score double precision not null default 0,
//   profile_label text not null default '',
//   created_at timestamptz default now()
// );
//
// create table cs_leverage_snapshots (
//   id uuid primary key default gen_random_uuid(),
//   total_score double precision not null default 0,
//   created_at timestamptz default now()
// );
//
// create table cs_wealth_tracking (
//   id uuid primary key default gen_random_uuid(),
//   name text not null default '',
//   revenue double precision not null default 0,
//   expenses double precision not null default 0,
//   margin double precision not null default 0,
//   notes text not null default '',
//   created_at timestamptz default now()
// );
// ─────────────────────────────────────────────────────────────────────────────


// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notConfigured
    case httpError(Int, String)
    case decodingError(Error)
    case encodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase not configured. Enter your Base URL and API key in COMMAND → Integration Hub."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Service

@MainActor
final class SupabaseService: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = SupabaseService()

    private let configKeyPrefix = "ConstructOS.Integrations.Backend."

    init() {
        migrateCredentials()
    }

    /// Migrate legacy UserDefaults credentials to Keychain on first launch (SEC-02, SEC-03)
    private func migrateCredentials() {
        let keys = ["BaseURL", "ApiKey"]
        for key in keys {
            if KeychainHelper.read(key: "Backend.\(key)") == nil {
                if let legacy = UserDefaults.standard.string(forKey: configKeyPrefix + key), !legacy.isEmpty {
                    KeychainHelper.save(key: "Backend.\(key)", data: legacy)
                    UserDefaults.standard.removeObject(forKey: configKeyPrefix + key)
                }
            }
        }
    }

    // MARK: - Rate Limiting
    private var refreshTimer: Timer?
    private var lastRequestTime: Date = .distantPast
    private let minRequestInterval: TimeInterval = 0.1  // 100ms between requests (10 req/sec max)

    private func throttle() async {
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minRequestInterval {
            try? await Task.sleep(for: .seconds(minRequestInterval - elapsed))
        }
        lastRequestTime = Date()
    }
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    var baseURL: String {
        (KeychainHelper.read(key: "Backend.BaseURL") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "BaseURL") ?? "").trimmingCharacters(in: .whitespaces)
    }
    var apiKey: String {
        (KeychainHelper.read(key: "Backend.ApiKey") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "ApiKey") ?? "").trimmingCharacters(in: .whitespaces)
    }

    var isConfigured: Bool {
        !baseURL.isEmpty
            && !apiKey.isEmpty
            && !baseURL.contains("your-project.supabase.co")
            && URL(string: baseURL) != nil
    }

    func configure(baseURL: String, apiKey: String) {
        KeychainHelper.save(key: "Backend.BaseURL", data: baseURL)
        KeychainHelper.save(key: "Backend.ApiKey", data: apiKey)
        UserDefaults.standard.removeObject(forKey: configKeyPrefix + "BaseURL")
        UserDefaults.standard.removeObject(forKey: configKeyPrefix + "ApiKey")
        objectWillChange.send()
    }

    // MARK: - Auth

    @Published var currentUserEmail: String? = nil
    @Published var accessToken: String? = nil

    var isAuthenticated: Bool { accessToken != nil }

    /// Org identifier used by Phase 13 document uploads. Reads from
    /// UserDefaults so Integration Hub can configure it later; falls back to a
    /// stable per-install UUID so single-tenant dev installs still work.
    var currentOrgId: String {
        let key = "ConstructOS.Integrations.Backend.OrgId"
        if let v = UserDefaults.standard.string(forKey: key), !v.isEmpty { return v }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }

    func signUp(email: String, password: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        guard let url = URL(string: "\(baseURL)/auth/v1/signup") else {
            throw SupabaseError.httpError(400, "Invalid signup URL from baseURL: \(baseURL)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["email": email, "password": password])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, body)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        await MainActor.run {
            accessToken = json?["access_token"] as? String
            currentUserEmail = (json?["user"] as? [String: Any])?["email"] as? String
            if let token = accessToken { KeychainHelper.save(key: "Auth.AccessToken", data: token) }
            if let email = currentUserEmail { KeychainHelper.save(key: "Auth.Email", data: email) }
        }
        guard accessToken != nil else {
            throw SupabaseError.httpError(0, "Auth succeeded but no access token returned")
        }
    }

    func signIn(email: String, password: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password") else {
            throw SupabaseError.httpError(400, "Invalid token URL from baseURL: \(baseURL)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["email": email, "password": password])
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError(statusCode, body)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        await MainActor.run {
            accessToken = json?["access_token"] as? String
            currentUserEmail = (json?["user"] as? [String: Any])?["email"] as? String
            if let token = accessToken { KeychainHelper.save(key: "Auth.AccessToken", data: token) }
            if let refresh = json?["refresh_token"] as? String { KeychainHelper.save(key: "Auth.RefreshToken", data: refresh) }
            if let email = currentUserEmail { KeychainHelper.save(key: "Auth.Email", data: email) }
        }
        guard accessToken != nil else {
            throw SupabaseError.httpError(0, "Auth succeeded but no access token returned")
        }
        startAutoRefresh()
    }

    func refreshToken() async -> Bool {
        guard isConfigured,
              let refreshToken = KeychainHelper.read(key: "Auth.RefreshToken"),
              !refreshToken.isEmpty else { return false }
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["refresh_token": refreshToken]
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                CrashReporter.shared.reportError("Token refresh failed: bad response")
                return false
            }
            await MainActor.run {
                accessToken = json["access_token"] as? String
                if let token = accessToken { KeychainHelper.save(key: "Auth.AccessToken", data: token) }
                if let refresh = json["refresh_token"] as? String { KeychainHelper.save(key: "Auth.RefreshToken", data: refresh) }
            }
            return accessToken != nil
        } catch {
            CrashReporter.shared.reportError("Token refresh error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Password Reset (AUTH-10)

    func resetPassword(email: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        guard let url = URL(string: "\(baseURL)/auth/v1/recover") else {
            throw SupabaseError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["email": email])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, body)
        }
    }

    // MARK: - MFA (Multi-Factor Authentication)

    struct MFAFactor: Codable {
        let id: String
        let factorType: String
        let status: String

        enum CodingKeys: String, CodingKey {
            case id
            case factorType = "factor_type"
            case status
        }
    }

    struct MFAChallengeResponse: Codable {
        let id: String
    }

    func listMFAFactors() async throws -> [MFAFactor] {
        guard isConfigured, let token = accessToken else { return [] }
        guard let url = URL(string: "\(baseURL)/auth/v1/factors") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return [] }
        do {
            return try JSONDecoder().decode([MFAFactor].self, from: data)
        } catch {
            CrashReporter.shared.reportError("MFA factors decode failed: \(error.localizedDescription)")
            return []
        }
    }

    func hasMFAEnabled() async -> Bool {
        let factors: [MFAFactor]
        do {
            factors = try await listMFAFactors()
        } catch {
            CrashReporter.shared.reportError("MFA check failed: \(error.localizedDescription)")
            return false
        }
        return factors.contains { $0.factorType == "totp" && $0.status == "verified" }
    }

    func createMFAChallenge(factorId: String) async throws -> String {
        guard isConfigured, let token = accessToken else { throw SupabaseError.notConfigured }
        guard let url = URL(string: "\(baseURL)/auth/v1/factors/\(factorId)/challenge") else {
            throw SupabaseError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, body)
        }
        let challenge = try JSONDecoder().decode(MFAChallengeResponse.self, from: data)
        return challenge.id
    }

    func verifyMFA(factorId: String, challengeId: String, code: String) async throws {
        guard isConfigured, let token = accessToken else { throw SupabaseError.notConfigured }
        guard let url = URL(string: "\(baseURL)/auth/v1/factors/\(factorId)/verify") else {
            throw SupabaseError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["challenge_id": challengeId, "code": code])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, body)
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let newAccessToken = json["access_token"] as? String {
                await MainActor.run {
                    accessToken = newAccessToken
                    KeychainHelper.save(key: "Auth.AccessToken", data: newAccessToken)
                    if let refresh = json["refresh_token"] as? String {
                        KeychainHelper.save(key: "Auth.RefreshToken", data: refresh)
                    }
                }
            }
        } catch {
            CrashReporter.shared.reportError("MFA verify response parse failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Session Auto-Refresh (AUTH-03)

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 50 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { let _ = await self.refreshToken() }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func signOut() {
        stopAutoRefresh()
        accessToken = nil
        currentUserEmail = nil
        KeychainHelper.delete(key: "Auth.AccessToken")
        KeychainHelper.delete(key: "Auth.RefreshToken")
        KeychainHelper.delete(key: "Auth.Email")
    }

    func restoreSession() {
        accessToken = KeychainHelper.read(key: "Auth.AccessToken")
        currentUserEmail = KeychainHelper.read(key: "Auth.Email")
        if accessToken != nil {
            Task { let _ = await refreshToken() }
            startAutoRefresh()
        }
    }

    // MARK: - Offline Sync Queue

    struct PendingWrite: Codable, Identifiable {
        var id = UUID()
        let table: String
        let jsonPayload: Data
        let createdAt: Date
        var retryCount: Int = 0
    }

    @Published var pendingWrites: [PendingWrite] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var conflictCount: Int = 0

    private let pendingWritesKey = "ConstructOS.Sync.PendingWrites"
    private let maxRetries = 3
    private let maxPendingAge: TimeInterval = 7 * 24 * 3600 // 7 days

    func queueWrite<T: Encodable>(_ table: String, record: T) {
        let payload: Data
        do {
            payload = try encoder.encode(record)
        } catch {
            CrashReporter.shared.reportError("Failed to encode pending write for \(table): \(error.localizedDescription)")
            return
        }
        let pending = PendingWrite(table: table, jsonPayload: payload, createdAt: Date())
        pendingWrites.append(pending)
        // Enforce queue size limit
        if pendingWrites.count > 100 {
            pendingWrites = Array(pendingWrites.suffix(100))
        }
        savePendingWrites()
    }

    func flushPendingWrites() async {
        guard isConfigured else { return }
        var remaining: [PendingWrite] = []
        var conflicts = 0
        for var write in pendingWrites {
            // Drop stale writes older than max age
            if Date().timeIntervalSince(write.createdAt) > maxPendingAge { continue }
            do {
                guard let url = URL(string: "\(baseURL)/rest/v1/\(write.table)") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                try applyHeaders(&request, contentType: true)
                // Use upsert to resolve conflicts — last write wins
                request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
                request.httpBody = write.jsonPayload
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                // Handle conflict (409) — retry with PATCH
                if statusCode == 409 {
                    conflicts += 1
                    request.httpMethod = "PATCH"
                    request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
                    try checkHTTPStatus(data: retryData, response: retryResponse)
                } else {
                    try checkHTTPStatus(data: data, response: response)
                }
            } catch {
                write.retryCount += 1
                if write.retryCount < maxRetries {
                    remaining.append(write)
                }
                // Exceeded retries — drop the write to prevent queue buildup
            }
        }
        await MainActor.run {
            pendingWrites = remaining
            conflictCount += conflicts
            savePendingWrites()
        }
    }


    // MARK: - Real-Time Subscriptions (WebSocket with polling fallback)

    @Published var lastSyncAt: Date?
    private var realtimeTask: URLSessionWebSocketTask?
    private var syncTimer: Timer?
    private var realtimeConnected = false

    /// Connect to Supabase Realtime via WebSocket. Falls back to polling if unavailable.
    func startRealtimeSync(tables: [String] = ["cs_projects", "cs_contracts"]) {
        stopRealtimeSync()

        guard isConfigured,
              let wsURL = URL(string: baseURL.replacingOccurrences(of: "https://", with: "wss://") + "/realtime/v1/websocket?apikey=\(apiKey)&vsn=1.0.0") else {
            startPollingFallback()
            return
        }

        let task = URLSession.shared.webSocketTask(with: wsURL)
        realtimeTask = task
        task.resume()

        // Join channels for each table
        for table in tables {
            let joinMsg = """
            {"topic":"realtime:\(table)","event":"phx_join","payload":{},"ref":"\(UUID().uuidString.prefix(8))"}
            """
            task.send(.string(joinMsg)) { [weak self] error in
                if error != nil {
                    Task { @MainActor [weak self] in self?.startPollingFallback() }
                }
            }
        }

        realtimeConnected = true
        listenForMessages()
    }

    private func listenForMessages() {
        realtimeTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                switch result {
                case .success:
                    self?.lastSyncAt = Date()
                    self?.objectWillChange.send()
                    self?.listenForMessages() // Continue listening
                case .failure:
                    self?.realtimeConnected = false
                    self?.startPollingFallback()
                }
            }
        }
    }

    /// Polling fallback when WebSocket is unavailable
    private func startPollingFallback() {
        guard !realtimeConnected else { return }
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.lastSyncAt = Date()
                self?.objectWillChange.send()
            }
        }
    }

    func stopRealtimeSync() {
        realtimeTask?.cancel(with: .goingAway, reason: nil)
        realtimeTask = nil
        realtimeConnected = false
        syncTimer?.invalidate()
        syncTimer = nil
    }

    func loadPendingWrites() {
        pendingWrites = loadJSON(pendingWritesKey, default: [PendingWrite]())
    }

    private func savePendingWrites() {
        saveJSON(pendingWritesKey, value: pendingWrites)
    }

    func insertWithOfflineSupport<T: Encodable>(_ table: String, record: T) async {
        do {
            await MainActor.run { isLoading = true; lastError = nil }
            try await insert(table, record: record)
            await MainActor.run { isLoading = false }
        } catch {
            queueWrite(table, record: record)
            await MainActor.run {
                isLoading = false
                lastError = "Saved offline — will sync when connected"
            }
        }
    }

    // MARK: Fetch

    /// Fetch records with optional pagination and ordering
    func fetch<T: Decodable>(
        _ table: String,
        query: [String: String] = [:],
        limit: Int? = nil,
        offset: Int? = nil,
        orderBy: String? = nil,
        ascending: Bool = false
    ) async throws -> [T] {
        guard isConfigured else { throw SupabaseError.notConfigured }
        try validateTable(table)
        await throttle()
        guard var components = URLComponents(string: "\(baseURL)/rest/v1/\(table)") else {
            throw SupabaseError.httpError(400, "Invalid URL components for table: \(table)")
        }
        var queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let offset { queryItems.append(URLQueryItem(name: "offset", value: "\(offset)")) }
        if let orderBy { queryItems.append(URLQueryItem(name: "order", value: "\(orderBy).\(ascending ? "asc" : "desc")")) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw SupabaseError.httpError(400, "Invalid URL") }
        var request = URLRequest(url: url)
        try applyHeaders(&request)
        // Request total count header for pagination
        if limit != nil { request.setValue("count=exact", forHTTPHeaderField: "Prefer") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPStatus(data: data, response: response)
        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            throw SupabaseError.decodingError(error)
        }
    }

    /// Fetch a single page of results with total count
    func fetchPaginated<T: Decodable>(
        _ table: String,
        query: [String: String] = [:],
        page: Int = 0,
        pageSize: Int = 50,
        orderBy: String? = "created_at"
    ) async throws -> (items: [T], hasMore: Bool) {
        let offset = page * pageSize
        let items: [T] = try await fetch(table, query: query, limit: pageSize + 1, offset: offset, orderBy: orderBy)
        let hasMore = items.count > pageSize
        return (Array(items.prefix(pageSize)), hasMore)
    }

    // MARK: Insert

    func insert<T: Encodable>(_ table: String, record: T) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        try validateTable(table)
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)") else {
            throw SupabaseError.httpError(400, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try applyHeaders(&request, contentType: true)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        do {
            request.httpBody = try encoder.encode(record)
        } catch {
            throw SupabaseError.encodingError(error)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPStatus(data: data, response: response)
    }

    // MARK: Update

    func update<T: Encodable>(_ table: String, id: String, record: T) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        try validateTable(table)
        let safeID = sanitizeID(id)
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)?id=eq.\(safeID)") else {
            throw SupabaseError.httpError(400, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        try applyHeaders(&request, contentType: true)
        do {
            request.httpBody = try encoder.encode(record)
        } catch {
            throw SupabaseError.encodingError(error)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPStatus(data: data, response: response)
    }

    // MARK: Delete

    func delete(_ table: String, id: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        try validateTable(table)
        let safeID = sanitizeID(id)
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)?id=eq.\(safeID)") else {
            throw SupabaseError.httpError(400, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try applyHeaders(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPStatus(data: data, response: response)
    }

    // MARK: Private Helpers

    /// Allowed table names — prevents injection via table parameter
    private static let allowedTables: Set<String> = [
        // Core tables
        "cs_projects", "cs_contracts", "cs_market_data", "cs_ai_messages",
        // Wealth suite
        "cs_wealth_opportunities", "cs_decision_journal", "cs_psychology_sessions",
        "cs_leverage_snapshots", "cs_wealth_tracking",
        // Ops panels
        "cs_ops_alerts", "cs_ops_actions", "cs_change_orders", "cs_safety_incidents",
        "cs_material_deliveries", "cs_punch_list", "cs_subcontractors", "cs_daily_costs",
        "cs_submittals", "cs_project_accounts", "cs_contract_accounts", "cs_portfolio_metrics",
        "cs_rfis",
        // Field & trade
        "cs_daily_logs", "cs_timecards", "cs_permits", "cs_tax_expenses",
        "cs_electrical_leads", "cs_fuel_log", "cs_punch_pro",
        // System
        "cs_verification_requests",
        // Phase 13: Document Management
        "cs_documents", "cs_document_attachments", "cs_document_versions",
        // Phase 16: Field Tools
        "cs_photo_annotations",
        // Phase 17: Calendar & Scheduling
        "cs_project_tasks", "cs_task_dependencies",
    ]

    /// Validates table name against allowlist
    private func validateTable(_ table: String) throws {
        guard Self.allowedTables.contains(table) else {
            throw SupabaseError.httpError(400, "Invalid table name: \(table)")
        }
    }

    /// Sanitizes a string for safe use in URL query parameters
    private func sanitizeID(_ id: String) -> String {
        // Only allow UUID-safe characters
        id.filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    private func applyHeaders(_ request: inout URLRequest, contentType: Bool = false) throws {
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        // Use access token if available, fall back to API key, reject if neither exists
        let authValue: String
        if let token = accessToken, !token.isEmpty {
            authValue = "Bearer \(token)"
        } else if !apiKey.isEmpty {
            authValue = "Bearer \(apiKey)"
        } else {
            throw SupabaseError.notConfigured
        }
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if contentType {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }

    private func checkHTTPStatus(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode >= 400 {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw SupabaseError.httpError(http.statusCode, body)
        }
    }

    // MARK: - Phase 17 Calendar API (Next.js routes)

    /// Base URL for the Next.js web app API. Reads from UserDefaults key
    /// `ConstructOS.Integrations.WebApp.BaseURL`. When the iOS app and web app
    /// share the same Supabase backend, this points to the deployed Next.js
    /// instance (e.g., "https://constructionos.vercel.app") so that iOS routes
    /// through the same validation, CSRF, and RLS logic that web uses.
    var webAppBaseURL: String {
        (UserDefaults.standard.string(forKey: "ConstructOS.Integrations.WebApp.BaseURL") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    var isWebAppConfigured: Bool {
        let url = webAppBaseURL
        return !url.isEmpty && URL(string: url) != nil
    }

    /// Build a URLRequest for a Next.js API route, attaching the auth token
    /// as a Bearer header and setting Content-Type when needed.
    private func makeWebAPIRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard isWebAppConfigured else {
            throw AppError.supabaseNotConfigured
        }
        guard let url = URL(string: "\(webAppBaseURL)\(path)") else {
            throw AppError.validationFailed(field: "URL", reason: "Invalid API path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        // Auth: forward the Supabase access token so the Next.js API can
        // create an authenticated Supabase client server-side.
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        // CSRF: the Next.js server checks Origin header via verifyCsrfOrigin.
        // URLSession on iOS does not set Origin automatically, so we set it to
        // the web app's own origin so the server's same-origin check passes.
        request.setValue(webAppBaseURL, forHTTPHeaderField: "Origin")
        request.setValue("1", forHTTPHeaderField: "X-CSRF-Token")
        return request
    }

    /// Fetch project tasks for a given project from the Next.js calendar API.
    func fetchProjectTasks(projectId: String) async throws -> [SupabaseProjectTask] {
        await throttle()
        let safeId = sanitizeID(projectId)
        let request = try makeWebAPIRequest(path: "/api/calendar/tasks?project_id=\(safeId)")
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch statusCode {
        case 200...299:
            break
        case 401:
            throw AppError.authFailed(reason: "Sign in required")
        case 403:
            throw AppError.permissionDenied(feature: "Calendar")
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppError.network(underlying: SupabaseError.httpError(statusCode, body))
        }
        do {
            return try decoder.decode([SupabaseProjectTask].self, from: data)
        } catch {
            throw AppError.decoding(underlying: error)
        }
    }

    /// Fetch the full timeline payload (projects, tasks, milestones, crew, events, deps).
    func fetchTimeline(from: String, to: String) async throws -> TimelinePayload {
        await throttle()
        let request = try makeWebAPIRequest(
            path: "/api/calendar/timeline?from=\(from)&to=\(to)"
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch statusCode {
        case 200...299:
            break
        case 401:
            throw AppError.authFailed(reason: "Sign in required")
        case 403:
            throw AppError.permissionDenied(feature: "Calendar")
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppError.network(underlying: SupabaseError.httpError(statusCode, body))
        }
        do {
            // Timeline response uses camelCase for crewAssignments key
            let camelDecoder = JSONDecoder()
            return try camelDecoder.decode(TimelinePayload.self, from: data)
        } catch {
            throw AppError.decoding(underlying: error)
        }
    }

    /// PATCH a project task's dates via the Next.js calendar API.
    /// Returns the updated task row on success.
    @discardableResult
    func patchProjectTask(id: String, startDate: String, endDate: String) async throws -> SupabaseProjectTask {
        await throttle()
        let safeId = sanitizeID(id)
        let bodyDict: [String: String] = ["start_date": startDate, "end_date": endDate]
        let bodyData = try JSONEncoder().encode(bodyDict)
        let request = try makeWebAPIRequest(
            path: "/api/calendar/tasks/\(safeId)",
            method: "PATCH",
            body: bodyData
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch statusCode {
        case 200...299:
            break
        case 400:
            let body = String(data: data, encoding: .utf8) ?? "Validation error"
            throw AppError.validationFailed(field: "dates", reason: body)
        case 401:
            throw AppError.authFailed(reason: "Sign in required")
        case 403, 404:
            throw AppError.permissionDenied(feature: "Task reschedule")
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppError.network(underlying: SupabaseError.httpError(statusCode, body))
        }
        do {
            return try decoder.decode(SupabaseProjectTask.self, from: data)
        } catch {
            throw AppError.decoding(underlying: error)
        }
    }
}

// MARK: - Codable DTOs

struct SupabaseProject: Codable, Identifiable, Sendable, Equatable {
    var id: String?
    var name: String
    var client: String
    var type: String
    var status: String
    var progress: Int
    var budget: String
    var score: String
    var team: String

    enum CodingKeys: String, CodingKey {
        case id, name, client, type, status, progress, budget, score, team
    }
}

struct SupabaseContract: Codable, Identifiable, Sendable, Equatable {
    var id: String?
    var title: String
    var client: String
    var location: String
    var sector: String
    var stage: String
    var package: String
    var budget: String
    var bidDue: String
    var liveFeedStatus: String
    var bidders: Int
    var score: Int
    var watchCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, client, location, sector, stage, package, budget
        case bidDue = "bid_due"
        case liveFeedStatus = "live_feed_status"
        case bidders
        case score
        case watchCount = "watch_count"
    }
}

struct SupabaseMarketData: Codable, Identifiable, Sendable, Equatable {
    var id: String?
    var city: String
    var vacancy: Double
    var newBiz: Int
    var closed: Int
    var trend: String

    enum CodingKeys: String, CodingKey {
        case id, city, vacancy, trend, closed
        case newBiz = "new_biz"
    }
}

struct SupabaseAIMessage: Codable, Identifiable, Sendable {
    var id: String?
    var sessionId: String
    var role: String
    var content: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case role
        case content
        case createdAt = "created_at"
    }
}

// MARK: - Wealth Suite DTOs (with validation)

struct SupabaseWealthOpportunity: Codable, Identifiable, Sendable {
    var id: String?
    var name: String
    var wealthSignal: Int
    var contractId: String?
    var status: String

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case wealthSignal = "wealth_signal"
        case contractId = "contract_id"
    }

    /// Resolve the linked contract (lazy fetch)
    func linkedContract(from contracts: [SupabaseContract]) -> SupabaseContract? {
        guard let cid = contractId else { return nil }
        return contracts.first { $0.id == cid }
    }

    var hasLinkedContract: Bool { !(contractId ?? "").isEmpty }

    var isValid: Bool { !name.isEmpty && (0...100).contains(wealthSignal) && ["active", "archived", "pending"].contains(status) }
    var validationErrors: [String] {
        var errors: [String] = []
        if name.isEmpty { errors.append("Name is required") }
        if !(0...100).contains(wealthSignal) { errors.append("Wealth signal must be 0-100") }
        if !["active", "archived", "pending"].contains(status) { errors.append("Invalid status") }
        return errors
    }
}

struct SupabaseDecisionJournal: Codable, Identifiable, Sendable {
    var id: String?
    var title: String
    var context: String
    var thinkingMode: String
    var decision: String
    var firstOrder: String
    var secondOrder: String
    var gatesPassed: Int
    var outcomeStatus: String

    enum CodingKeys: String, CodingKey {
        case id, title, context, decision
        case thinkingMode = "thinking_mode"
        case firstOrder = "first_order"
        case secondOrder = "second_order"
        case gatesPassed = "gates_passed"
        case outcomeStatus = "outcome_status"
    }

    static let validThinkingModes = ["Strategic", "Analytical", "Creative", "Intuitive"]
    static let validOutcomeStatuses = ["pending", "successful", "failed", "revisit"]

    var isValid: Bool { !title.isEmpty && (0...5).contains(gatesPassed) }
    var validationErrors: [String] {
        var errors: [String] = []
        if title.isEmpty { errors.append("Title is required") }
        if !(0...5).contains(gatesPassed) { errors.append("Gates passed must be 0-5") }
        if !Self.validThinkingModes.contains(thinkingMode) { errors.append("Invalid thinking mode") }
        if !Self.validOutcomeStatuses.contains(outcomeStatus) { errors.append("Invalid outcome status") }
        return errors
    }
}

struct SupabasePsychologySession: Codable, Identifiable, Sendable {
    var id: String?
    var score: Double
    var profileLabel: String

    enum CodingKeys: String, CodingKey {
        case id, score
        case profileLabel = "profile_label"
    }

    var isValid: Bool { (0...100).contains(score) && !profileLabel.isEmpty }
}

struct SupabaseLeverageSnapshot: Codable, Identifiable, Sendable {
    var id: String?
    var totalScore: Double

    enum CodingKeys: String, CodingKey {
        case id
        case totalScore = "total_score"
    }

    var isValid: Bool { (0...500).contains(totalScore) }
}

struct SupabaseWealthTracking: Codable, Identifiable, Sendable {
    var id: String?
    var name: String
    var revenue: Double
    var expenses: Double
    var margin: Double
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id, name, revenue, expenses, margin, notes
    }

    var isValid: Bool { !name.isEmpty && revenue >= 0 && expenses >= 0 }
    var computedMargin: Double { revenue > 0 ? ((revenue - expenses) / revenue) * 100 : 0 }
    var validationErrors: [String] {
        var errors: [String] = []
        if name.isEmpty { errors.append("Name is required") }
        if revenue < 0 { errors.append("Revenue must be non-negative") }
        if expenses < 0 { errors.append("Expenses must be non-negative") }
        return errors
    }
}

// MARK: - Daily Log DTO
struct SupabaseDailyLog: Codable, Identifiable, Sendable {
    var id: String?
    var date: String
    var weather: String
    var tempHigh: Int
    var tempLow: Int
    var manpower: Int
    var workPerformed: String
    var visitors: String
    var delays: String
    var safetyNotes: String
    var photoCount: Int
    var createdBy: String
    var site: String?
}

// MARK: - Timecard DTO
struct SupabaseTimecard: Codable, Identifiable, Sendable {
    var id: String?
    var crewMember: String
    var trade: String
    var clockIn: String
    var clockOut: String
    var hoursRegular: Double
    var hoursOt: Double
    var rate: Double
    var site: String
    var date: String
}

// MARK: - Tax Expense DTO
struct SupabaseTaxExpense: Codable, Identifiable, Sendable {
    var id: String?
    var date: String
    var description: String
    var amount: Double
    var category: String
    var projectRef: String
    var receiptAttached: Bool
    var deductible: Bool
}

// MARK: - Storage (Phase 13: Document Management)
//
// Adds Supabase Storage REST helpers for document upload/download. Errors
// are surfaced as `AppError` (not `SupabaseError`) so the document layer
// can flow them through `AlertState` directly.

extension SupabaseService {

    private var storageBaseURL: String { "\(baseURL)/storage/v1" }

    private func authHeader() -> String {
        if let token = accessToken, !token.isEmpty { return "Bearer \(token)" }
        return "Bearer \(apiKey)"
    }

    /// Upload raw bytes to `{bucket}/{path}` via Supabase Storage REST.
    /// Refuses to overwrite existing objects (`x-upsert: false`).
    /// - Returns: the storage path on success.
    func uploadFile(
        bucket: String,
        path: String,
        data: Data,
        mimeType: String
    ) async throws -> String {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard let url = URL(string: "\(storageBaseURL)/object/\(bucket)/\(path)") else {
            throw AppError.unknown("Invalid storage URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        req.setValue("false", forHTTPHeaderField: "x-upsert")
        do {
            let (respData, response) = try await URLSession.shared.upload(for: req, from: data)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.network(underlying: URLError(.badServerResponse))
            }
            guard (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: http.statusCode,
                    body: String(data: respData, encoding: .utf8) ?? ""
                )
            }
            return path
        } catch let e as AppError {
            throw e
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    /// Generate a short-lived signed URL for `{bucket}/{path}`.
    /// Default TTL = 3600s (~1h). Returns a fully-qualified URL.
    func createSignedURL(bucket: String, path: String, expiresIn: Int = 3600) async throws -> URL {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard let url = URL(string: "\(storageBaseURL)/object/sign/\(bucket)/\(path)") else {
            throw AppError.unknown("Invalid sign URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["expiresIn": expiresIn])
        do {
            let (respData, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw AppError.supabaseHTTP(
                    statusCode: code,
                    body: String(data: respData, encoding: .utf8) ?? ""
                )
            }
            let decoded = try JSONDecoder().decode(SignedURLResponse.self, from: respData)
            // signedURL is path-relative — prepend storage base.
            let full = "\(storageBaseURL)\(decoded.signedURL)"
            guard let resultURL = URL(string: full) else {
                throw AppError.unknown("Bad signed URL")
            }
            return resultURL
        } catch let e as AppError {
            throw e
        } catch let e as DecodingError {
            throw AppError.decoding(underlying: e)
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    /// Download a signed URL to a temporary file. Caller is responsible for moving it.
    func downloadFile(signedURL: URL) async throws -> URL {
        do {
            let (tempURL, response) = try await URLSession.shared.download(from: signedURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                    body: ""
                )
            }
            return tempURL
        } catch let e as AppError {
            throw e
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    /// Upload with exponential-backoff retry for retryable AppErrors (5xx, network).
    func uploadFileWithRetry(
        bucket: String,
        path: String,
        data: Data,
        mimeType: String,
        maxAttempts: Int = 3
    ) async throws -> String {
        var lastError: Error?
        for attempt in 1...maxAttempts {
            do {
                return try await uploadFile(bucket: bucket, path: path, data: data, mimeType: mimeType)
            } catch let e as AppError where e.isRetryable && attempt < maxAttempts {
                lastError = e
                let backoff = pow(2.0, Double(attempt - 1))
                try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                continue
            } catch {
                throw error
            }
        }
        throw lastError ?? AppError.unknown("upload retry exhausted")
    }

    /// Insert an Encodable row into a Phase-13 document table. Bypasses the
    /// allowlist used by the generic `insert(_:record:)` (which doesn't yet
    /// know about cs_documents / cs_document_attachments).
    func insertDocumentRow<T: Encodable>(table: String, row: T) async throws {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard table == "cs_documents" || table == "cs_document_attachments" else {
            throw AppError.unknown("insertDocumentRow: unsupported table \(table)")
        }
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)") else {
            throw AppError.unknown("Invalid REST URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            req.httpBody = try encoder.encode(row)
        } catch {
            throw AppError.encoding(underlying: error)
        }
        do {
            let (respData, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                    body: String(data: respData, encoding: .utf8) ?? ""
                )
            }
        } catch let e as AppError {
            throw e
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    /// Call a Supabase RPC (e.g. `create_document_version`).
    func callRPC<T: Decodable>(name: String, params: [String: String]) async throws -> T {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard let url = URL(string: "\(baseURL)/rest/v1/rpc/\(name)") else {
            throw AppError.unknown("Invalid RPC URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: params)
        do {
            let (respData, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                    body: String(data: respData, encoding: .utf8) ?? ""
                )
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: respData)
        } catch let e as AppError {
            throw e
        } catch let e as DecodingError {
            throw AppError.decoding(underlying: e)
        } catch {
            throw AppError.network(underlying: error)
        }
    }
}

// MARK: - Phase 14: Notifications & Activity Feed
//
// Schema authoritative source: supabase/migrations/20260407_phase14_notifications.sql
//
//   cs_activity_events(id, project_id, entity_type, entity_id, action, category,
//                      actor_id, payload, created_at)
//   cs_notifications(id, user_id, event_id, project_id, category, title, body,
//                    entity_type, entity_id, read_at, dismissed_at, created_at)
//   cs_device_tokens(user_id, device_token, platform, app_version, last_seen_at,
//                    created_at)
//
// Decoder uses .convertFromSnakeCase, so Swift property names are camelCase.

struct SupabaseNotification: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var eventId: String?
    var projectId: String?
    var category: String   // 'bid_deadline'|'safety_alert'|'assigned_task'|'generic'
    var title: String
    var body: String?
    var entityType: String?
    var entityId: String?
    var readAt: String?
    var dismissedAt: String?
    var createdAt: String?

    var isUnread: Bool { readAt == nil && dismissedAt == nil }
}

struct SupabaseActivityEvent: Codable, Identifiable, Equatable {
    var id: String
    var projectId: String?
    var entityType: String
    var entityId: String?
    var action: String
    var category: String
    var actorId: String?
    var createdAt: String?
    // payload omitted — jsonb decoding is brittle and not needed for the timeline UI
}

struct SupabaseDeviceToken: Codable, Equatable {
    var userId: String
    var deviceToken: String
    var platform: String
    var appVersion: String?
    var lastSeenAt: String?
}

extension SupabaseService {
    /// User UUID extracted from the JWT `sub` claim. Returns nil when signed out
    /// or when the token can't be parsed. Notifications + device-token paths key
    /// off this rather than email since cs_notifications.user_id is a uuid.
    var currentUserId: String? {
        guard let token = accessToken else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count == 3,
              let payloadData = Data(base64URLEncoded: String(parts[1])),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let sub = json["sub"] as? String
        else { return nil }
        return sub
    }

    private func phase14ISO8601Now() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    /// Generic GET on a Phase-14 table that bypasses the strict allowlist used
    /// by `fetchTable(_:)`. Notifications/activity tables live only here.
    private func phase14Get<T: Decodable>(path: String) async throws -> [T] {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard let url = URL(string: "\(baseURL)/rest/v1/\(path)") else {
            throw AppError.unknown("Invalid Phase 14 URL: \(path)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                    body: String(data: data, encoding: .utf8) ?? ""
                )
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([T].self, from: data)
        } catch let e as AppError {
            throw e
        } catch let e as DecodingError {
            throw AppError.decoding(underlying: e)
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    private func phase14Patch(path: String, jsonBody: [String: Any]) async throws {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard let url = URL(string: "\(baseURL)/rest/v1/\(path)") else {
            throw AppError.unknown("Invalid Phase 14 URL: \(path)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                    body: String(data: data, encoding: .utf8) ?? ""
                )
            }
        } catch let e as AppError {
            throw e
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    private func phase14Upsert(path: String, jsonBody: [String: Any]) async throws {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        guard let url = URL(string: "\(baseURL)/rest/v1/\(path)") else {
            throw AppError.unknown("Invalid Phase 14 URL: \(path)")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.supabaseHTTP(
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                    body: String(data: data, encoding: .utf8) ?? ""
                )
            }
        } catch let e as AppError {
            throw e
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    func fetchNotifications(
        userId: String,
        projectId: String? = nil,
        limit: Int = 50,
        includeDismissed: Bool = false
    ) async throws -> [SupabaseNotification] {
        var qs = "cs_notifications?user_id=eq.\(userId)"
        if !includeDismissed { qs += "&dismissed_at=is.null" }
        if let projectId { qs += "&project_id=eq.\(projectId)" }
        qs += "&order=created_at.desc&limit=\(limit)"
        return try await phase14Get(path: qs)
    }

    /// Returns count of unread notifications using HEAD + Prefer: count=exact
    /// (cheap server-side count via Content-Range header).
    func fetchUnreadCount(userId: String, projectId: String? = nil) async throws -> Int {
        guard isConfigured else { throw AppError.supabaseNotConfigured }
        var qs = "cs_notifications?select=id&user_id=eq.\(userId)&read_at=is.null&dismissed_at=is.null"
        if let projectId { qs += "&project_id=eq.\(projectId)" }
        guard let url = URL(string: "\(baseURL)/rest/v1/\(qs)") else {
            throw AppError.unknown("Invalid unread-count URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.setValue(authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("count=exact", forHTTPHeaderField: "Prefer")
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.supabaseHTTP(statusCode: 0, body: "")
            }
            // Content-Range: "0-9/42" — total after the slash
            if let range = http.value(forHTTPHeaderField: "Content-Range"),
               let total = range.split(separator: "/").last,
               let n = Int(total) {
                return n
            }
            return 0
        } catch let e as AppError {
            throw e
        } catch {
            throw AppError.network(underlying: error)
        }
    }

    func markNotificationRead(id: String) async throws {
        try await phase14Patch(
            path: "cs_notifications?id=eq.\(id)",
            jsonBody: ["read_at": phase14ISO8601Now()]
        )
    }

    func markNotificationDismissed(id: String) async throws {
        try await phase14Patch(
            path: "cs_notifications?id=eq.\(id)",
            jsonBody: ["dismissed_at": phase14ISO8601Now()]
        )
    }

    func markAllNotificationsRead(userId: String, projectId: String? = nil) async throws {
        var qs = "cs_notifications?user_id=eq.\(userId)&read_at=is.null&dismissed_at=is.null"
        if let projectId { qs += "&project_id=eq.\(projectId)" }
        try await phase14Patch(path: qs, jsonBody: ["read_at": phase14ISO8601Now()])
    }

    func fetchActivityEvents(projectId: String, limit: Int = 100) async throws -> [SupabaseActivityEvent] {
        let qs = "cs_activity_events?project_id=eq.\(projectId)&order=created_at.desc&limit=\(limit)"
        return try await phase14Get(path: qs)
    }

    /// Upsert a device token for the current user. Called from Plan 14-05 after
    /// APNs registration. No-op when signed out.
    func upsertDeviceToken(token: String, platform: String = "ios", appVersion: String? = nil) async throws {
        guard let userId = currentUserId else { return }
        var body: [String: Any] = [
            "user_id": userId,
            "device_token": token,
            "platform": platform,
            "last_seen_at": phase14ISO8601Now()
        ]
        if let appVersion { body["app_version"] = appVersion }
        try await phase14Upsert(path: "cs_device_tokens", jsonBody: body)
    }
}

// MARK: - Phase 14: base64url helper for JWT decoding
private extension Data {
    init?(base64URLEncoded input: String) {
        var s = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = s.count % 4
        if pad > 0 { s += String(repeating: "=", count: 4 - pad) }
        self.init(base64Encoded: s)
    }
}

// MARK: - ========== Phase 15: Team & Crew DTOs ==========

struct SupabaseTeamMember: Codable, Identifiable {
    let id: String
    let kind: String   // "internal" | "subcontractor" | "vendor"
    let user_id: String?
    let name: String
    let role: String?
    let trade: String?
    let email: String?
    let phone: String?
    let company: String?
    let notes: String?
    let created_at: String?
    let updated_at: String?
}

struct SupabaseProjectAssignment: Codable, Identifiable {
    let id: String
    let project_id: String
    let member_id: String
    let role_on_project: String?
    let start_date: String?
    let end_date: String?
    let status: String
    let created_at: String?
}

struct SupabaseCertification: Codable, Identifiable {
    let id: String
    let member_id: String
    let name: String
    let issuer: String?
    let number: String?
    let issued_date: String?
    let expires_at: String?
    let document_id: String?
    let status: String
    let created_at: String?
    let updated_at: String?
}

struct SupabaseDailyCrew: Codable, Identifiable {
    let id: String
    let project_id: String
    let assignment_date: String
    let member_ids: [String]
    let notes: String?
    let created_by: String?
    let created_at: String?
}

// MARK: - ========== Phase 17: Calendar & Scheduling DTOs ==========

struct SupabaseProjectTask: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let org_id: String?
    let project_id: String
    let name: String
    let trade: String?
    let start_date: String
    let end_date: String
    let duration_days: Int?
    let percent_complete: Int
    let is_critical: Bool
    let created_by: String?
    let created_at: String?
    let updated_by: String?
    let updated_at: String?
}

struct SupabaseTaskDependency: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let org_id: String?
    let predecessor_task_id: String
    let successor_task_id: String
    let dep_type: String
    let lag_days: Int
    let created_at: String?
}

/// Payload returned by GET /api/calendar/timeline
struct TimelinePayload: Codable {
    struct TimelineProject: Codable, Identifiable {
        let id: String
        let name: String?
        let start_date: String?
        let end_date: String?
    }
    struct TimelineMilestone: Codable, Identifiable {
        let id: String
        let project_id: String?
        let date: String
        let label: String
        let kind: String
    }
    struct TimelineCrewAssignment: Codable, Identifiable {
        let id: String
        let project_id: String?
        let date: String?
    }
    struct TimelineEvent: Codable, Identifiable {
        let id: String
        let project_id: String?
        let event_type: String?
        let date: String?
        let title: String?
    }
    struct TimelineWindow: Codable {
        let from: String
        let to: String
    }

    let window: TimelineWindow
    let projects: [TimelineProject]
    let tasks: [SupabaseProjectTask]
    let milestones: [TimelineMilestone]
    let crewAssignments: [TimelineCrewAssignment]
    let events: [TimelineEvent]
    let dependencies: [SupabaseTaskDependency]
}

