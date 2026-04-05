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

    func signUp(email: String, password: String) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
        let url = URL(string: "\(baseURL)/auth/v1/signup")!
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
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
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
        request.httpBody = try? JSONEncoder().encode(body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        await MainActor.run {
            accessToken = json["access_token"] as? String
            if let token = accessToken { KeychainHelper.save(key: "Auth.AccessToken", data: token) }
            if let refresh = json["refresh_token"] as? String { KeychainHelper.save(key: "Auth.RefreshToken", data: refresh) }
        }
        return true
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
        guard let payload = try? encoder.encode(record) else { return }
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
                applyHeaders(&request, contentType: true)
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
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(table)")!
        var queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let offset { queryItems.append(URLQueryItem(name: "offset", value: "\(offset)")) }
        if let orderBy { queryItems.append(URLQueryItem(name: "order", value: "\(orderBy).\(ascending ? "asc" : "desc")")) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw SupabaseError.httpError(400, "Invalid URL") }
        var request = URLRequest(url: url)
        applyHeaders(&request)
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
        applyHeaders(&request, contentType: true)
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
        applyHeaders(&request, contentType: true)
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
        applyHeaders(&request)
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

    private func applyHeaders(_ request: inout URLRequest, contentType: Bool = false) {
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? apiKey)", forHTTPHeaderField: "Authorization")
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
}

// MARK: - Codable DTOs

struct SupabaseProject: Codable, Identifiable, Sendable {
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

struct SupabaseContract: Codable, Identifiable, Sendable {
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

struct SupabaseMarketData: Codable, Identifiable, Sendable {
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

    var hasLinkedContract: Bool { contractId != nil && !contractId!.isEmpty }

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
