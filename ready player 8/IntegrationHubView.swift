import Combine
import CryptoKit
import Foundation
import SwiftUI
import UserNotifications
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


// MARK: - ========== IntegrationHubView.swift ==========


// MARK: - Platform Integrations

enum IntegrationRole: String, CaseIterable {
    case field = "FIELD"
    case pm = "PM"
    case accounting = "ACCOUNTING"
    case executive = "EXECUTIVE"

    var color: Color {
        switch self {
        case .field: return Theme.green
        case .pm: return Theme.cyan
        case .accounting: return Theme.gold
        case .executive: return Theme.accent
        }
    }
}

enum IntegrationBackendProvider: String, CaseIterable {
    case supabase = "SUPABASE"
    case firebase = "FIREBASE"

    var color: Color {
        switch self {
        case .supabase: return Theme.green
        case .firebase: return Theme.gold
        }
    }
}

struct IntegrationCheckRecord: Identifiable {
    let id = UUID()
    let timestamp: String
    let stage: String
    let detail: String
    let succeeded: Bool
    let latencyMS: Int?

    var accent: Color {
        succeeded ? Theme.green : Theme.red
    }
}

enum BusinessPlatform: String, CaseIterable, Identifiable {
    case outlook = "OUTLOOK"
    case quickBooks = "QUICKBOOKS"
    case microsoft365 = "MICROSOFT 365"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .outlook: return Theme.cyan
        case .quickBooks: return Theme.green
        case .microsoft365: return Theme.gold
        }
    }

    var subtitle: String {
        switch self {
        case .outlook: return "Mail, calendar, and field notifications"
        case .quickBooks: return "Invoices, billing, and accounting handoff"
        case .microsoft365: return "Excel, SharePoint, OneDrive, and docs"
        }
    }

    var storageKey: String {
        switch self {
        case .outlook: return "Outlook"
        case .quickBooks: return "QuickBooks"
        case .microsoft365: return "Microsoft365"
        }
    }
}

@MainActor
final class IntegrationHub: ObservableObject {
    @Published var backendStatus: String = "Idle"
    @Published var lastSyncAt: String = "Never"
    @Published var connectionStatus: String = "Not tested"
    @Published var liveValidationStatus: String = "Not run"

    @Published var backendProvider: IntegrationBackendProvider = .supabase
    @Published var backendBaseURL: String = ""
    @Published var backendProjectId: String = ""
    @Published var backendApiKey: String = ""
    @Published var backendAuthToken: String = ""
    @Published var includeSecretsInExport: Bool = false
    @Published var signaturePassphrase: String = ""
    @Published var requireSignatureOnImport: Bool = false
    @Published var configTransferPayload: String = ""
    @Published var configTransferStatus: String = "No import/export yet"

    @Published var signedInUser: String = "Not signed in"
    @Published var role: IntegrationRole = .field

    @Published var analyticsEvents: [String] = []
    @Published var crashLogs: [String] = []
    @Published var checkHistory: [IntegrationCheckRecord] = []
    @Published var lastBackendResponseAt: String = "Never"
    @Published var lastMeasuredLatencyMS: Int = 0

    @Published var pushStatus: String = "Unknown"
    @Published var lastPushMessage: String = "None"

    @Published var lastPDFPath: String = "None"
    @Published var cloudExportStatus: String = "Not started"

    @Published var selectedBusinessPlatform: BusinessPlatform = .outlook

    @Published var outlookConnected: Bool = false
    @Published var outlookTenant: String = ""
    @Published var outlookMailbox: String = ""
    @Published var outlookStatus: String = "Not connected"
    @Published var outlookLastSyncAt: String = "Never"
    @Published var outlookPendingItems: Int = 0

    @Published var quickBooksConnected: Bool = false
    @Published var quickBooksCompanyID: String = ""
    @Published var quickBooksRealm: String = ""
    @Published var quickBooksStatus: String = "Not connected"
    @Published var quickBooksLastSyncAt: String = "Never"
    @Published var quickBooksPendingItems: Int = 0

    @Published var microsoft365Connected: Bool = false
    @Published var microsoft365Tenant: String = ""
    @Published var microsoft365Site: String = ""
    @Published var microsoft365Status: String = "Not connected"
    @Published var microsoft365LastSyncAt: String = "Never"
    @Published var microsoft365PendingItems: Int = 0

    // Payment Gateway — Paddle (Merchant of Record)
    @Published var paddleConnected: Bool = false
    @Published var paddleAPIKey: String = ""
    @Published var paddleWebhookSecret: String = ""
    @Published var paddleStatus: String = "Not connected"
    @Published var paddleEnvironment: String = "sandbox"

    // Crypto Payments — Coinbase Commerce
    @Published var coinbaseConnected: Bool = false
    @Published var coinbaseAPIKey: String = ""
    @Published var coinbaseWebhookSecret: String = ""
    @Published var coinbaseStatus: String = "Not connected"

    // CoinGecko — Live crypto prices (no key needed)
    @Published var coinGeckoStatus: String = "Connected (free API)"

    // Mapbox — Maps & satellite
    @Published var mapboxConnected: Bool = false
    @Published var mapboxToken: String = ""
    @Published var mapboxStatus: String = "Not connected"

    func configurePaddle() {
        guard !paddleAPIKey.isEmpty else { return }
        KeychainHelper.save(key: "Paddle.APIKey", data: paddleAPIKey)
        KeychainHelper.save(key: "Paddle.WebhookSecret", data: paddleWebhookSecret)
        paddleConnected = true
        paddleStatus = "Connected (\(paddleEnvironment))"
        PaymentGatewayConfig.configurePaddle(apiKey: paddleAPIKey, webhookSecret: paddleWebhookSecret)
    }

    func configureCoinbase() {
        guard !coinbaseAPIKey.isEmpty else { return }
        KeychainHelper.save(key: "Coinbase.APIKey", data: coinbaseAPIKey)
        coinbaseConnected = true
        coinbaseStatus = "Connected"
        PaymentGatewayConfig.configureCoinbase(apiKey: coinbaseAPIKey)
    }

    func configureMapbox() {
        guard !mapboxToken.isEmpty else { return }
        KeychainHelper.save(key: "Mapbox.Token", data: mapboxToken)
        mapboxConnected = true
        mapboxStatus = "Connected"
    }

    private let configKeyPrefix = "ConstructOS.Integrations.Backend."
    private let businessPlatformKeyPrefix = "ConstructOS.Integrations.BusinessPlatform."
    private let redactedSecretToken = "[REDACTED]"

    var isConfigReady: Bool {
        missingConfigFields().isEmpty
    }

    var readinessStatus: String {
        let missing = missingConfigFields()
        if missing.isEmpty {
            return "Ready for test + live check"
        }
        return "Missing: " + missing.joined(separator: ", ")
    }

    var healthSuccessRate: Int {
        guard !checkHistory.isEmpty else { return 0 }
        let successCount = checkHistory.filter { $0.succeeded }.count
        return Int((Double(successCount) / Double(checkHistory.count) * 100).rounded())
    }

    var healthSummary: String {
        guard !checkHistory.isEmpty else { return "No backend checks yet" }
        let latest = checkHistory.first?.stage ?? "NONE"
        return "\(healthSuccessRate)% success across \(checkHistory.count) checks · latest \(latest) · response \(lastBackendResponseAt)"
    }

    var healthColor: Color {
        if checkHistory.isEmpty { return Theme.gold }
        switch healthSuccessRate {
        case 80...100:
            return Theme.green
        case 50..<80:
            return Theme.gold
        default:
            return Theme.red
        }
    }

    init() {
        loadBackendConfig()
        loadBusinessPlatformConfig()
    }

    func saveBackendConfig() {
        backendBaseURL = sanitizedBaseURL(backendBaseURL)
        backendProjectId = trimmed(backendProjectId)
        backendApiKey = trimmed(backendApiKey)
        backendAuthToken = trimmed(backendAuthToken)
        UserDefaults.standard.set(backendProvider.rawValue, forKey: configKeyPrefix + "Provider")
        KeychainHelper.save(key: "Backend.BaseURL", data: backendBaseURL)
        UserDefaults.standard.set(backendProjectId, forKey: configKeyPrefix + "ProjectID")
        KeychainHelper.save(key: "Backend.ApiKey", data: backendApiKey)
        KeychainHelper.save(key: "Backend.AuthToken", data: backendAuthToken)
        // Clean up any legacy UserDefaults secret entries
        UserDefaults.standard.removeObject(forKey: configKeyPrefix + "BaseURL")
        UserDefaults.standard.removeObject(forKey: configKeyPrefix + "ApiKey")
        UserDefaults.standard.removeObject(forKey: configKeyPrefix + "AuthToken")
        trackEvent("backend_config_saved")
    }

    func applyPreset(_ provider: IntegrationBackendProvider) {
        backendProvider = provider
        switch provider {
        case .supabase:
            if trimmed(backendBaseURL).isEmpty || isPlaceholderBaseURL(backendBaseURL) {
                backendBaseURL = ""
            }
            backendProjectId = ""
        case .firebase:
            if trimmed(backendProjectId).isEmpty || isPlaceholderProjectId(backendProjectId) {
                backendProjectId = ""
            }
            backendBaseURL = ""
            backendAuthToken = ""
        }
        trackEvent("backend_preset_\(provider.rawValue.lowercased())")
    }

    func exportConfigPayload() {
        saveBackendConfig()
        let exportedApiKey = includeSecretsInExport ? backendApiKey : redactedSecretToken
        let exportedAuthToken = includeSecretsInExport ? backendAuthToken : redactedSecretToken
        let checksum = configChecksum(
            providerRaw: backendProvider.rawValue,
            baseURL: backendBaseURL,
            projectId: backendProjectId,
            apiKey: exportedApiKey,
            authToken: exportedAuthToken,
            secretsIncluded: includeSecretsInExport
        )
        let passphrase = trimmed(signaturePassphrase)
        let signature = passphrase.isEmpty ? "" : configSignature(checksum: checksum, passphrase: passphrase)
        let payload: [String: String] = [
            "version": "1",
            "provider": backendProvider.rawValue,
            "baseURL": backendBaseURL,
            "projectId": backendProjectId,
            "apiKey": exportedApiKey,
            "authToken": exportedAuthToken,
            "secretsIncluded": includeSecretsInExport ? "true" : "false",
            "checksum": checksum,
            "signature": signature,
            "signatureMode": signature.isEmpty ? "none" : "hmac-sha256",
            "exportedAt": Self.timestamp()
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            configTransferPayload = String(data: data, encoding: .utf8) ?? ""
            configTransferStatus = includeSecretsInExport ? "Exported payload with secrets" : "Exported redacted payload"
            trackEvent(includeSecretsInExport ? "backend_config_exported_with_secrets" : "backend_config_exported_redacted")
        } catch {
            configTransferStatus = "Export failed"
        }
    }

    func importConfigPayload() {
        let raw = trimmed(configTransferPayload)
        guard !raw.isEmpty, let data = raw.data(using: .utf8) else {
            configTransferStatus = "Paste JSON payload first"
            return
        }

        do {
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                configTransferStatus = "Invalid JSON shape"
                return
            }

            guard let providerRaw = object["provider"] as? String,
                  let provider = IntegrationBackendProvider(rawValue: providerRaw) else {
                configTransferStatus = "Unknown provider"
                return
            }

            let importedBaseURL = sanitizedBaseURL(object["baseURL"] as? String ?? "")
            let importedProjectId = trimmed(object["projectId"] as? String ?? "")
            let importedApiKey = trimmed(object["apiKey"] as? String ?? "")
            let importedAuthToken = trimmed(object["authToken"] as? String ?? "")
            let secretsIncluded = (object["secretsIncluded"] as? String ?? "false").lowercased() == "true"
            let providedChecksum = trimmed(object["checksum"] as? String ?? "")
            let providedSignature = trimmed(object["signature"] as? String ?? "")
            let signatureMode = trimmed(object["signatureMode"] as? String ?? "")

            if !providedChecksum.isEmpty {
                let expectedChecksum = configChecksum(
                    providerRaw: providerRaw,
                    baseURL: importedBaseURL,
                    projectId: importedProjectId,
                    apiKey: importedApiKey,
                    authToken: importedAuthToken,
                    secretsIncluded: secretsIncluded
                )
                guard providedChecksum.lowercased() == expectedChecksum.lowercased() else {
                    configTransferStatus = "Import blocked: checksum mismatch"
                    trackEvent("backend_config_import_checksum_mismatch")
                    return
                }
            }

            if requireSignatureOnImport && providedSignature.isEmpty {
                configTransferStatus = "Import blocked: signature required"
                trackEvent("backend_config_import_signature_required")
                return
            }

            if !providedSignature.isEmpty {
                guard signatureMode == "hmac-sha256" else {
                    configTransferStatus = "Import blocked: unsupported signature"
                    trackEvent("backend_config_import_signature_mode_invalid")
                    return
                }
                let passphrase = trimmed(signaturePassphrase)
                guard !passphrase.isEmpty else {
                    configTransferStatus = "Signature present: enter passphrase"
                    return
                }
                guard !providedChecksum.isEmpty else {
                    configTransferStatus = "Import blocked: checksum required"
                    return
                }
                let expectedSignature = configSignature(checksum: providedChecksum, passphrase: passphrase)
                guard expectedSignature.lowercased() == providedSignature.lowercased() else {
                    configTransferStatus = "Import blocked: signature mismatch"
                    trackEvent("backend_config_import_signature_mismatch")
                    return
                }
            }

            backendProvider = provider
            backendBaseURL = importedBaseURL
            backendProjectId = importedProjectId
            let skippedRedactedSecrets = isRedactedSecret(importedApiKey) || isRedactedSecret(importedAuthToken)

            if !importedApiKey.isEmpty && !isRedactedSecret(importedApiKey) {
                backendApiKey = importedApiKey
            }
            if !importedAuthToken.isEmpty && !isRedactedSecret(importedAuthToken) {
                backendAuthToken = importedAuthToken
            }

            saveBackendConfig()
            configTransferStatus = skippedRedactedSecrets ? "Imported payload (redacted secrets kept local)" : "Imported config payload"
            trackEvent("backend_config_imported")
        } catch {
            configTransferStatus = "Import failed"
        }
    }

    private func loadBackendConfig() {
        if let provider = UserDefaults.standard.string(forKey: configKeyPrefix + "Provider"),
           let resolved = IntegrationBackendProvider(rawValue: provider) {
            backendProvider = resolved
        }
        backendBaseURL = KeychainHelper.read(key: "Backend.BaseURL") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "BaseURL") ?? ""
        backendProjectId = UserDefaults.standard.string(forKey: configKeyPrefix + "ProjectID") ?? ""
        if isPlaceholderBaseURL(backendBaseURL) { backendBaseURL = "" }
        if isPlaceholderProjectId(backendProjectId) { backendProjectId = "" }
        backendApiKey = KeychainHelper.read(key: "Backend.ApiKey") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "ApiKey") ?? ""
        backendAuthToken = KeychainHelper.read(key: "Backend.AuthToken") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "AuthToken") ?? ""

        // Migrate legacy UserDefaults secrets to Keychain (SEC-02, SEC-03)
        let secretKeys = ["BaseURL", "ApiKey", "AuthToken"]
        for key in secretKeys {
            if KeychainHelper.read(key: "Backend.\(key)") == nil,
               let legacy = UserDefaults.standard.string(forKey: configKeyPrefix + key), !legacy.isEmpty {
                KeychainHelper.save(key: "Backend.\(key)", data: legacy)
                UserDefaults.standard.removeObject(forKey: configKeyPrefix + key)
            }
        }
    }

    func connectBusinessPlatform(_ platform: BusinessPlatform) {
        switch platform {
        case .outlook:
            outlookConnected = true
            if trimmed(outlookMailbox).isEmpty {
                outlookMailbox = "fieldops@constructos.app"
            }
            if trimmed(outlookTenant).isEmpty {
                outlookTenant = "construction-tenant"
            }
            outlookStatus = "Connected to Microsoft Graph"
            outlookPendingItems = 4
            outlookLastSyncAt = Self.timestamp()
            signedInUser = outlookMailbox
        case .quickBooks:
            quickBooksConnected = true
            if trimmed(quickBooksCompanyID).isEmpty {
                quickBooksCompanyID = "ACME-COMPANY-01"
            }
            if trimmed(quickBooksRealm).isEmpty {
                quickBooksRealm = "realm-4521"
            }
            quickBooksStatus = "Connected to billing ledger"
            quickBooksPendingItems = 3
            quickBooksLastSyncAt = Self.timestamp()
        case .microsoft365:
            microsoft365Connected = true
            if trimmed(microsoft365Tenant).isEmpty {
                microsoft365Tenant = "construction-tenant"
            }
            if trimmed(microsoft365Site).isEmpty {
                microsoft365Site = "Projects/Harbor-Crossing"
            }
            microsoft365Status = "Connected to docs workspace"
            microsoft365PendingItems = 6
            microsoft365LastSyncAt = Self.timestamp()
        }

        saveBusinessPlatformConfig()
        trackEvent("platform_\(platform.storageKey.lowercased())_connected")
        recordCheck(stage: platform.rawValue, detail: "\(platform.rawValue) connected", succeeded: true)
    }

    func disconnectBusinessPlatform(_ platform: BusinessPlatform) {
        switch platform {
        case .outlook:
            outlookConnected = false
            outlookStatus = "Disconnected"
            outlookPendingItems = 0
        case .quickBooks:
            quickBooksConnected = false
            quickBooksStatus = "Disconnected"
            quickBooksPendingItems = 0
        case .microsoft365:
            microsoft365Connected = false
            microsoft365Status = "Disconnected"
            microsoft365PendingItems = 0
        }

        saveBusinessPlatformConfig()
        trackEvent("platform_\(platform.storageKey.lowercased())_disconnected")
    }

    func syncBusinessPlatform(_ platform: BusinessPlatform) {
        switch platform {
        case .outlook:
            guard outlookConnected else {
                outlookStatus = "Connect Outlook first"
                recordCheck(stage: "OUTLOOK", detail: outlookStatus, succeeded: false)
                return
            }
            outlookStatus = "Calendar + email digest synced"
            outlookPendingItems = max(0, outlookPendingItems - 1)
            outlookLastSyncAt = Self.timestamp()
        case .quickBooks:
            guard quickBooksConnected else {
                quickBooksStatus = "Connect QuickBooks first"
                recordCheck(stage: "QUICKBOOKS", detail: quickBooksStatus, succeeded: false)
                return
            }
            quickBooksStatus = "Invoices exported to accounting"
            quickBooksPendingItems = max(0, quickBooksPendingItems - 1)
            quickBooksLastSyncAt = Self.timestamp()
        case .microsoft365:
            guard microsoft365Connected else {
                microsoft365Status = "Connect Microsoft 365 first"
                recordCheck(stage: "MICROSOFT 365", detail: microsoft365Status, succeeded: false)
                return
            }
            microsoft365Status = "Docs + spreadsheets synced"
            microsoft365PendingItems = max(0, microsoft365PendingItems - 2)
            microsoft365LastSyncAt = Self.timestamp()
        }

        saveBusinessPlatformConfig()
        trackEvent("platform_\(platform.storageKey.lowercased())_synced")
        recordCheck(stage: platform.rawValue, detail: businessPlatformStatus(for: platform), succeeded: true)
    }

    func recommendedWorkflows(for platform: BusinessPlatform) -> [String] {
        switch platform {
        case .outlook:
            return ["Daily field digest emails", "RFI reminders on calendar", "Owner meeting invites"]
        case .quickBooks:
            return ["Progress invoice export", "Vendor aging follow-up", "Change order billing queue"]
        case .microsoft365:
            return ["Excel cost tracker refresh", "SharePoint site sync", "OneDrive PDF report drop"]
        }
    }

    func businessPlatformStatus(for platform: BusinessPlatform) -> String {
        switch platform {
        case .outlook: return outlookStatus
        case .quickBooks: return quickBooksStatus
        case .microsoft365: return microsoft365Status
        }
    }

    func businessPlatformLastSync(for platform: BusinessPlatform) -> String {
        switch platform {
        case .outlook: return outlookLastSyncAt
        case .quickBooks: return quickBooksLastSyncAt
        case .microsoft365: return microsoft365LastSyncAt
        }
    }

    func businessPlatformPendingItems(for platform: BusinessPlatform) -> Int {
        switch platform {
        case .outlook: return outlookPendingItems
        case .quickBooks: return quickBooksPendingItems
        case .microsoft365: return microsoft365PendingItems
        }
    }

    func businessPlatformConnected(for platform: BusinessPlatform) -> Bool {
        switch platform {
        case .outlook: return outlookConnected
        case .quickBooks: return quickBooksConnected
        case .microsoft365: return microsoft365Connected
        }
    }

    private func saveBusinessPlatformConfig() {
        UserDefaults.standard.set(selectedBusinessPlatform.rawValue, forKey: businessPlatformKeyPrefix + "Selected")

        UserDefaults.standard.set(outlookConnected, forKey: businessPlatformKeyPrefix + "Outlook.Connected")
        UserDefaults.standard.set(outlookTenant, forKey: businessPlatformKeyPrefix + "Outlook.Tenant")
        UserDefaults.standard.set(outlookMailbox, forKey: businessPlatformKeyPrefix + "Outlook.Mailbox")
        UserDefaults.standard.set(outlookStatus, forKey: businessPlatformKeyPrefix + "Outlook.Status")
        UserDefaults.standard.set(outlookLastSyncAt, forKey: businessPlatformKeyPrefix + "Outlook.LastSync")
        UserDefaults.standard.set(outlookPendingItems, forKey: businessPlatformKeyPrefix + "Outlook.Pending")

        UserDefaults.standard.set(quickBooksConnected, forKey: businessPlatformKeyPrefix + "QuickBooks.Connected")
        UserDefaults.standard.set(quickBooksCompanyID, forKey: businessPlatformKeyPrefix + "QuickBooks.CompanyID")
        UserDefaults.standard.set(quickBooksRealm, forKey: businessPlatformKeyPrefix + "QuickBooks.Realm")
        UserDefaults.standard.set(quickBooksStatus, forKey: businessPlatformKeyPrefix + "QuickBooks.Status")
        UserDefaults.standard.set(quickBooksLastSyncAt, forKey: businessPlatformKeyPrefix + "QuickBooks.LastSync")
        UserDefaults.standard.set(quickBooksPendingItems, forKey: businessPlatformKeyPrefix + "QuickBooks.Pending")

        UserDefaults.standard.set(microsoft365Connected, forKey: businessPlatformKeyPrefix + "Microsoft365.Connected")
        UserDefaults.standard.set(microsoft365Tenant, forKey: businessPlatformKeyPrefix + "Microsoft365.Tenant")
        UserDefaults.standard.set(microsoft365Site, forKey: businessPlatformKeyPrefix + "Microsoft365.Site")
        UserDefaults.standard.set(microsoft365Status, forKey: businessPlatformKeyPrefix + "Microsoft365.Status")
        UserDefaults.standard.set(microsoft365LastSyncAt, forKey: businessPlatformKeyPrefix + "Microsoft365.LastSync")
        UserDefaults.standard.set(microsoft365PendingItems, forKey: businessPlatformKeyPrefix + "Microsoft365.Pending")
    }

    private func loadBusinessPlatformConfig() {
        if let selected = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Selected"),
           let platform = BusinessPlatform(rawValue: selected) {
            selectedBusinessPlatform = platform
        }

        outlookConnected = UserDefaults.standard.bool(forKey: businessPlatformKeyPrefix + "Outlook.Connected")
        outlookTenant = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Outlook.Tenant") ?? ""
        outlookMailbox = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Outlook.Mailbox") ?? ""
        outlookStatus = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Outlook.Status") ?? "Not connected"
        outlookLastSyncAt = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Outlook.LastSync") ?? "Never"
        outlookPendingItems = UserDefaults.standard.integer(forKey: businessPlatformKeyPrefix + "Outlook.Pending")

        quickBooksConnected = UserDefaults.standard.bool(forKey: businessPlatformKeyPrefix + "QuickBooks.Connected")
        quickBooksCompanyID = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "QuickBooks.CompanyID") ?? ""
        quickBooksRealm = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "QuickBooks.Realm") ?? ""
        quickBooksStatus = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "QuickBooks.Status") ?? "Not connected"
        quickBooksLastSyncAt = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "QuickBooks.LastSync") ?? "Never"
        quickBooksPendingItems = UserDefaults.standard.integer(forKey: businessPlatformKeyPrefix + "QuickBooks.Pending")

        microsoft365Connected = UserDefaults.standard.bool(forKey: businessPlatformKeyPrefix + "Microsoft365.Connected")
        microsoft365Tenant = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Microsoft365.Tenant") ?? ""
        microsoft365Site = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Microsoft365.Site") ?? ""
        microsoft365Status = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Microsoft365.Status") ?? "Not connected"
        microsoft365LastSyncAt = UserDefaults.standard.string(forKey: businessPlatformKeyPrefix + "Microsoft365.LastSync") ?? "Never"
        microsoft365PendingItems = UserDefaults.standard.integer(forKey: businessPlatformKeyPrefix + "Microsoft365.Pending")
    }

    func syncNow() {
        backendStatus = "Syncing..."
        sendRemoteSyncEvent(eventName: "constructionos_sync", timestamp: Self.timestamp()) { success, message in
            DispatchQueue.main.async {
                self.backendStatus = success ? "Healthy" : "Degraded"
                if success {
                    self.lastSyncAt = Self.timestamp()
                    self.trackEvent("backend_sync_success")
                } else {
                    self.trackEvent("backend_sync_failed")
                }
                self.connectionStatus = message
            }
        }
    }

    func testConnection() {
        connectionStatus = "Testing..."
        guard let request = connectionProbeRequest() else {
            connectionStatus = "Invalid backend config"
            recordCheck(stage: "PROBE", detail: "Invalid backend config", succeeded: false)
            return
        }

        performRequest(request) { code, latencyMS, error in
            DispatchQueue.main.async {
                if let error {
                    self.connectionStatus = "Connection failed: \(error.localizedDescription)"
                    self.backendStatus = "Degraded"
                    self.recordCheck(stage: "PROBE", detail: self.connectionStatus, succeeded: false, latencyMS: latencyMS)
                    return
                }
                let code = code ?? 0
                if (200...299).contains(code) || code == 401 || code == 403 {
                    self.connectionStatus = "Reachable (HTTP \(code))"
                    self.backendStatus = "Connected"
                    self.trackEvent("backend_probe_http_\(code)")
                    self.recordCheck(stage: "PROBE", detail: self.connectionStatus, succeeded: true, latencyMS: latencyMS)
                } else {
                    self.connectionStatus = "Unhealthy (HTTP \(code))"
                    self.backendStatus = "Degraded"
                    self.recordCheck(stage: "PROBE", detail: self.connectionStatus, succeeded: false, latencyMS: latencyMS)
                }
            }
        }
    }

    func runLiveValidation() {
        saveBackendConfig()
        backendStatus = "Validating..."
        liveValidationStatus = "Running probe + write + read-back..."

        let timestamp = Self.timestamp()
        let eventName = "constructionos_sync_\(UUID().uuidString.prefix(8))"

        guard let probeRequest = connectionProbeRequest() else {
            liveValidationStatus = "Failed: invalid probe config"
            backendStatus = "Degraded"
            recordCheck(stage: "ROUND-TRIP", detail: liveValidationStatus, succeeded: false)
            return
        }
        guard let syncRequest = syncRequest(eventName: eventName, timestamp: timestamp) else {
            liveValidationStatus = "Failed: invalid sync config"
            backendStatus = "Degraded"
            recordCheck(stage: "ROUND-TRIP", detail: liveValidationStatus, succeeded: false)
            return
        }
        guard let verifyRequest = verificationRequest(eventName: eventName) else {
            liveValidationStatus = "Failed: invalid verify config"
            backendStatus = "Degraded"
            recordCheck(stage: "ROUND-TRIP", detail: liveValidationStatus, succeeded: false)
            return
        }

        performRequest(probeRequest) { probeCode, probeLatencyMS, probeError in
            DispatchQueue.main.async {
                if let probeError {
                    self.liveValidationStatus = "Probe failed: \(probeError.localizedDescription)"
                    self.backendStatus = "Degraded"
                    self.trackEvent("backend_live_validation_probe_failed")
                    self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: false, latencyMS: probeLatencyMS)
                    return
                }

                let probeCode = probeCode ?? 0
                let probeOk = (200...299).contains(probeCode) || probeCode == 401 || probeCode == 403
                if !probeOk {
                    self.liveValidationStatus = "Probe unhealthy (HTTP \(probeCode))"
                    self.backendStatus = "Degraded"
                    self.trackEvent("backend_live_validation_probe_http_\(probeCode)")
                    self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: false, latencyMS: probeLatencyMS)
                    return
                }

                self.performRequest(syncRequest) { syncCode, syncLatencyMS, syncError in
                    DispatchQueue.main.async {
                        if let syncError {
                            self.liveValidationStatus = "Write failed: \(syncError.localizedDescription)"
                            self.backendStatus = "Degraded"
                            self.trackEvent("backend_live_validation_write_failed")
                            self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: false, latencyMS: syncLatencyMS)
                            return
                        }

                        let syncCode = syncCode ?? 0
                        if (200...299).contains(syncCode) {
                            self.performRequestDetailed(verifyRequest) { verifyCode, verifyData, verifyLatencyMS, verifyError in
                                DispatchQueue.main.async {
                                    if let verifyError {
                                        self.backendStatus = "Degraded"
                                        self.liveValidationStatus = "Read-back failed: \(verifyError.localizedDescription)"
                                        self.trackEvent("backend_live_validation_read_failed")
                                        self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: false, latencyMS: verifyLatencyMS)
                                        return
                                    }

                                    let verifyCode = verifyCode ?? 0
                                    let body = String(data: verifyData ?? Data(), encoding: .utf8) ?? ""
                                    let sawEvent = body.contains(eventName)

                                    if (200...299).contains(verifyCode) && sawEvent {
                                        self.lastSyncAt = timestamp
                                        self.backendStatus = "Healthy"
                                        self.connectionStatus = "Reachable (HTTP \(probeCode))"
                                        self.liveValidationStatus = "Round-trip pass (\(probeCode)/\(syncCode)/\(verifyCode))"
                                        self.trackEvent("backend_live_validation_pass")
                                        self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: true, latencyMS: verifyLatencyMS)
                                    } else {
                                        self.backendStatus = "Degraded"
                                        self.liveValidationStatus = "Read-back mismatch (HTTP \(verifyCode))"
                                        self.trackEvent("backend_live_validation_read_mismatch")
                                        self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: false, latencyMS: verifyLatencyMS)
                                    }
                                }
                            }
                        } else {
                            self.backendStatus = "Degraded"
                            self.liveValidationStatus = "Write rejected (HTTP \(syncCode))"
                            self.trackEvent("backend_live_validation_write_http_\(syncCode)")
                            self.recordCheck(stage: "ROUND-TRIP", detail: self.liveValidationStatus, succeeded: false, latencyMS: syncLatencyMS)
                        }
                    }
                }
            }
        }
    }

    private func sendRemoteSyncEvent(eventName: String, timestamp: String, completion: @escaping (Bool, String) -> Void) {
        guard let request = syncRequest(eventName: eventName, timestamp: timestamp) else {
            recordCheck(stage: "SYNC", detail: "Missing backend config", succeeded: false)
            completion(false, "Missing backend config")
            return
        }

        performRequest(request) { code, latencyMS, error in
            if let error {
                self.recordCheck(stage: "SYNC", detail: "Sync error: \(error.localizedDescription)", succeeded: false, latencyMS: latencyMS)
                completion(false, "Sync error: \(error.localizedDescription)")
                return
            }
            let code = code ?? 0
            if (200...299).contains(code) {
                self.recordCheck(stage: "SYNC", detail: "Synced (HTTP \(code))", succeeded: true, latencyMS: latencyMS)
                completion(true, "Synced (HTTP \(code))")
            } else {
                self.recordCheck(stage: "SYNC", detail: "Sync failed (HTTP \(code))", succeeded: false, latencyMS: latencyMS)
                completion(false, "Sync failed (HTTP \(code))")
            }
        }
    }

    private func performRequest(_ request: URLRequest, completion: @escaping @MainActor @Sendable (Int?, Int?, Error?) -> Void) {
        performRequestDetailed(request) { code, _, latencyMS, error in
            completion(code, latencyMS, error)
        }
    }

    private func performRequestDetailed(_ request: URLRequest, completion: @escaping @MainActor @Sendable (Int?, Data?, Int?, Error?) -> Void) {
        let startedAt = Date()
        URLSession.shared.dataTask(with: request) { data, response, error in
            let latencyMS = Int(Date().timeIntervalSince(startedAt) * 1000)
            if let error {
                Task { @MainActor in
                    completion(nil, nil, latencyMS, error)
                }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode
            Task { @MainActor in
                completion(code, data, latencyMS, nil)
            }
        }.resume()
    }

    private func connectionProbeRequest() -> URLRequest? {
        switch backendProvider {
        case .supabase:
            guard !backendBaseURL.isEmpty,
                  let url = URL(string: backendBaseURL + "/auth/v1/settings") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(backendApiKey, forHTTPHeaderField: "apikey")
            if !backendAuthToken.isEmpty {
                request.setValue("Bearer \(backendAuthToken)", forHTTPHeaderField: "Authorization")
            }
            return request
        case .firebase:
            guard !backendProjectId.isEmpty,
                  !backendApiKey.isEmpty,
                  let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(backendProjectId)/databases/(default)/documents?key=\(backendApiKey)&pageSize=1") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return request
        }
    }

    private func syncRequest(eventName: String, timestamp: String) -> URLRequest? {
        let eventBody = "{\"event\":\"\(eventName)\",\"timestamp\":\"\(timestamp)\"}"
        switch backendProvider {
        case .supabase:
            guard !backendBaseURL.isEmpty,
                  let url = URL(string: backendBaseURL + "/rest/v1/integration_events") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = "[\(eventBody)]".data(using: .utf8)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(backendApiKey, forHTTPHeaderField: "apikey")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
            if !backendAuthToken.isEmpty {
                request.setValue("Bearer \(backendAuthToken)", forHTTPHeaderField: "Authorization")
            }
            return request
        case .firebase:
            guard !backendProjectId.isEmpty,
                  !backendApiKey.isEmpty,
                  let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(backendProjectId)/databases/(default)/documents/integration_events?documentId=\(encodedQueryValue(eventName))&key=\(backendApiKey)") else { return nil }
            let payload = "{\"fields\":{\"event\":{\"stringValue\":\"\(eventName)\"},\"timestamp\":{\"stringValue\":\"\(timestamp)\"}}}"
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = payload.data(using: .utf8)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            return request
        }
    }

    private func verificationRequest(eventName: String) -> URLRequest? {
        switch backendProvider {
        case .supabase:
            guard !backendBaseURL.isEmpty,
                  let url = URL(string: backendBaseURL + "/rest/v1/integration_events?select=event,timestamp&event=eq.\(encodedQueryValue(eventName))&limit=1") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(backendApiKey, forHTTPHeaderField: "apikey")
            if !backendAuthToken.isEmpty {
                request.setValue("Bearer \(backendAuthToken)", forHTTPHeaderField: "Authorization")
            }
            return request
        case .firebase:
            guard !backendProjectId.isEmpty,
                  !backendApiKey.isEmpty,
                  let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(backendProjectId)/databases/(default)/documents/integration_events/\(encodedQueryValue(eventName))?key=\(backendApiKey)") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return request
        }
    }

    private func encodedQueryValue(_ value: String) -> String {
        let disallowed = CharacterSet(charactersIn: "&=?+#")
        let allowed = CharacterSet.urlQueryAllowed.subtracting(disallowed)
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    func signIn(role: IntegrationRole) {
        self.role = role
        self.signedInUser = "demo@constructionos.app"
        trackEvent("auth_sign_in_\(role.rawValue.lowercased())")
    }

    func signOut() {
        signedInUser = "Not signed in"
        trackEvent("auth_sign_out")
    }

    func trackEvent(_ event: String) {
        analyticsEvents.insert("[\(Self.timestamp())] \(event)", at: 0)
        analyticsEvents = Array(analyticsEvents.prefix(20))
    }

    func recordCrashSample() {
        crashLogs.insert("[\(Self.timestamp())] Handled sample exception in cost pipeline", at: 0)
        crashLogs = Array(crashLogs.prefix(20))
        trackEvent("crash_sample_logged")
    }

    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.pushStatus = granted ? "Authorized" : "Denied"
                self.trackEvent("push_permission_\(granted ? "granted" : "denied")")
            }
        }
    }

    func sendTestPush() {
        let content = UNMutableNotificationContent()
        content.title = "ConstructionOS Alert"
        content.body = "Test notification: schedule risk increased on P-1188"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
        lastPushMessage = "Queued at \(Self.timestamp())"
        trackEvent("push_test_queued")
    }

    func generatePDFReport() {
        let report = [
            "ConstructionOS Executive Snapshot",
            "Generated: \(Self.timestamp())",
            "Backend: \(backendStatus)",
            "Signed In: \(signedInUser)",
            "Role: \(role.rawValue)",
            "Push: \(pushStatus)",
            "Analytics Events: \(analyticsEvents.count)",
            "Crash Logs: \(crashLogs.count)",
        ].joined(separator: "\n")

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ConstructionOS-Report-\(Int(Date().timeIntervalSince1970)).pdf")

        #if os(macOS)
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            lastPDFPath = "PDF generation failed"
            return
        }
        context.beginPDFPage(nil)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.black
        ]
        NSString(string: report).draw(in: CGRect(x: 40, y: 80, width: 532, height: 680), withAttributes: attrs)
        context.endPDFPage()
        context.closePDF()
        #endif

        lastPDFPath = url.path
        trackEvent("pdf_generated")
    }

    func exportToCloud() {
        guard lastPDFPath != "None", lastPDFPath != "PDF generation failed" else {
            cloudExportStatus = "Generate PDF first"
            return
        }

        let sourceURL = URL(fileURLWithPath: lastPDFPath)

        if let cloudRoot = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let cloudURL = cloudRoot.appendingPathComponent("Documents/ConstructionOS-")
                .appendingPathExtension("pdf")
            do {
                if FileManager.default.fileExists(atPath: cloudURL.path) {
                    try FileManager.default.removeItem(at: cloudURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: cloudURL)
                cloudExportStatus = "Exported to iCloud Documents"
                trackEvent("cloud_export_success")
            } catch {
                cloudExportStatus = "Cloud export failed"
            }
        } else {
            cloudExportStatus = "iCloud unavailable (enable capability)"
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    private func missingConfigFields() -> [String] {
        switch backendProvider {
        case .supabase:
            var missing: [String] = []
            if trimmed(backendBaseURL).isEmpty || isPlaceholderBaseURL(backendBaseURL) { missing.append("base URL") }
            if trimmed(backendApiKey).isEmpty { missing.append("API key") }
            return missing
        case .firebase:
            var missing: [String] = []
            if trimmed(backendProjectId).isEmpty || isPlaceholderProjectId(backendProjectId) { missing.append("project ID") }
            if trimmed(backendApiKey).isEmpty { missing.append("API key") }
            return missing
        }
    }

    private func sanitizedBaseURL(_ value: String) -> String {
        let cleaned = trimmed(value)
        return cleaned.hasSuffix("/") ? String(cleaned.dropLast()) : cleaned
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isPlaceholderBaseURL(_ value: String) -> Bool {
        let cleaned = trimmed(value).lowercased()
        if cleaned.isEmpty { return false }
        return cleaned.contains("your-project.supabase.co") || cleaned.contains("<your-project>")
    }

    private func isPlaceholderProjectId(_ value: String) -> Bool {
        let cleaned = trimmed(value).lowercased()
        if cleaned.isEmpty { return false }
        return cleaned == "your-firebase-project-id" || cleaned.contains("<your-project-id>")
    }

    private func isRedactedSecret(_ value: String) -> Bool {
        trimmed(value).uppercased() == redactedSecretToken
    }

    private func configChecksum(providerRaw: String, baseURL: String, projectId: String, apiKey: String, authToken: String, secretsIncluded: Bool) -> String {
        let canonical = [
            "v1",
            providerRaw,
            baseURL,
            projectId,
            apiKey,
            authToken,
            secretsIncluded ? "1" : "0"
        ].joined(separator: "|")
        let digest = SHA256.hash(data: Data(canonical.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func configSignature(checksum: String, passphrase: String) -> String {
        let key = SymmetricKey(data: Data(passphrase.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(checksum.utf8), using: key)
        return Data(mac).map { String(format: "%02x", $0) }.joined()
    }

    private func recordCheck(stage: String, detail: String, succeeded: Bool, latencyMS: Int? = nil) {
        if let latencyMS {
            lastMeasuredLatencyMS = latencyMS
        }
        lastBackendResponseAt = Self.timestamp()
        checkHistory.insert(
            IntegrationCheckRecord(
                timestamp: Self.timestamp(),
                stage: stage,
                detail: detail,
                succeeded: succeeded,
                latencyMS: latencyMS
            ),
            at: 0
        )
        checkHistory = Array(checkHistory.prefix(8))
    }
}

struct PlatformIntegrationPanel: View {
    @StateObject private var hub = IntegrationHub()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "INTEGRATIONS",
                    title: "Platform integrations",
                    detail: "Backend sync, business systems, exports, and health monitoring for the operating stack.",
                    accent: Theme.gold
                )
                Spacer()
                Text(hub.backendStatus.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accent)
                    .cornerRadius(5)
            }

            HStack(spacing: 8) {
                DashboardStatPill(value: hub.backendStatus.uppercased(), label: "BACKEND", color: Theme.accent)
                DashboardStatPill(value: "\(hub.healthSuccessRate)%", label: "HEALTH", color: hub.healthColor)
                DashboardStatPill(value: hub.businessPlatformConnected(for: hub.selectedBusinessPlatform) ? "LIVE" : "IDLE", label: hub.selectedBusinessPlatform.rawValue.uppercased(), color: hub.selectedBusinessPlatform.color)
            }

            HStack(spacing: 8) {
                integrationCard(
                    title: "BACKEND SYNC",
                    subtitle: "Last sync: \(hub.lastSyncAt)",
                    actionLabel: "SYNC NOW",
                    action: { hub.syncNow() },
                    color: Theme.cyan
                )
                integrationCard(
                    title: "AUTH + ROLES",
                    subtitle: hub.signedInUser,
                    actionLabel: "SIGN IN",
                    action: { hub.signIn(role: .projectManagerFallback) },
                    color: Theme.green
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BUSINESS PLATFORMS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(Theme.cyan)
                    Spacer()
                    Text("Outlook + QuickBooks + Microsoft 365")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }

                HStack(spacing: 8) {
                    ForEach(BusinessPlatform.allCases) { platform in
                        Button {
                            hub.selectedBusinessPlatform = platform
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(platform.rawValue)
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(hub.selectedBusinessPlatform == platform ? .black : platform.color)
                                Text(platform.subtitle)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(hub.selectedBusinessPlatform == platform ? Color.black.opacity(0.75) : Theme.muted)
                                    .lineLimit(2)
                                Text(hub.businessPlatformConnected(for: platform) ? "CONNECTED" : "NOT CONNECTED")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(hub.businessPlatformConnected(for: platform) ? Theme.green : Theme.red)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(hub.selectedBusinessPlatform == platform ? platform.color.opacity(0.95) : platform.color.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(hub.selectedBusinessPlatform.rawValue)
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(hub.selectedBusinessPlatform.color)
                        Spacer()
                        Text("Last sync: \(hub.businessPlatformLastSync(for: hub.selectedBusinessPlatform))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }

                    if hub.selectedBusinessPlatform == .outlook {
                        HStack(spacing: 6) {
                            TextField("Outlook tenant", text: $hub.outlookTenant)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                            TextField("Mailbox", text: $hub.outlookMailbox)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                        }
                    } else if hub.selectedBusinessPlatform == .quickBooks {
                        HStack(spacing: 6) {
                            TextField("Company ID", text: $hub.quickBooksCompanyID)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                            TextField("Realm ID", text: $hub.quickBooksRealm)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                        }
                    } else {
                        HStack(spacing: 6) {
                            TextField("Microsoft tenant", text: $hub.microsoft365Tenant)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                            TextField("SharePoint / OneDrive path", text: $hub.microsoft365Site)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                        }
                    }

                    HStack(spacing: 6) {
                        Button(hub.businessPlatformConnected(for: hub.selectedBusinessPlatform) ? "SYNC NOW" : "CONNECT") {
                            if hub.businessPlatformConnected(for: hub.selectedBusinessPlatform) {
                                hub.syncBusinessPlatform(hub.selectedBusinessPlatform)
                            } else {
                                hub.connectBusinessPlatform(hub.selectedBusinessPlatform)
                            }
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.selectedBusinessPlatform.color)
                        .cornerRadius(5)
                        .buttonStyle(.plain)

                        Button("DISCONNECT") {
                            hub.disconnectBusinessPlatform(hub.selectedBusinessPlatform)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.muted)
                        .buttonStyle(.plain)
                        .opacity(hub.businessPlatformConnected(for: hub.selectedBusinessPlatform) ? 1 : 0.45)
                        .disabled(!hub.businessPlatformConnected(for: hub.selectedBusinessPlatform))

                        Text(hub.businessPlatformStatus(for: hub.selectedBusinessPlatform))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.muted)
                            .lineLimit(1)

                        Spacer()

                        Text("Queue: \(hub.businessPlatformPendingItems(for: hub.selectedBusinessPlatform))")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(hub.selectedBusinessPlatform.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("RECOMMENDED WORKFLOWS")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Theme.muted)
                        ForEach(hub.recommendedWorkflows(for: hub.selectedBusinessPlatform), id: \.self) { workflow in
                            Text("• \(workflow)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.text)
                        }
                    }
                }
                .padding(10)
                .background(Theme.surface.opacity(0.78))
                .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("BACKEND TARGET")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Theme.muted)
                    ForEach(IntegrationBackendProvider.allCases, id: \.rawValue) { provider in
                        Button(provider.rawValue) { hub.backendProvider = provider }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(hub.backendProvider == provider ? .black : provider.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(hub.backendProvider == provider ? provider.color : provider.color.opacity(0.14))
                            .cornerRadius(5)
                            .buttonStyle(.plain)
                    }
                    Spacer()
                }

                HStack(spacing: 6) {
                    Text("QUICK PRESETS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Theme.muted)
                    Button("SUPABASE STARTER") { hub.applyPreset(.supabase) }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.green)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    Button("FIREBASE STARTER") { hub.applyPreset(.firebase) }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.gold)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    Spacer()
                }

                HStack(spacing: 6) {
                    TextField("Base URL (Supabase)", text: $hub.backendBaseURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                    TextField("Project ID (Firebase)", text: $hub.backendProjectId)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                }

                HStack(spacing: 6) {
                    SecureField("API Key", text: $hub.backendApiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                    SecureField("Auth Token (optional)", text: $hub.backendAuthToken)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                }

                HStack(spacing: 6) {
                    Button("SAVE CONFIG") { hub.saveBackendConfig() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.gold)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    Button("TEST CONNECTION") { hub.testConnection() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.cyan)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                        .disabled(!hub.isConfigReady)
                        .opacity(hub.isConfigReady ? 1 : 0.45)
                    Text(hub.connectionStatus)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                    Spacer()
                }

                HStack(spacing: 6) {
                    Button("RUN LIVE CHECK") { hub.runLiveValidation() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.green)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                        .disabled(!hub.isConfigReady)
                        .opacity(hub.isConfigReady ? 1 : 0.45)
                    Text(hub.liveValidationStatus)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                    Spacer()
                }

                Text(hub.readinessStatus)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(hub.isConfigReady ? Theme.green : Theme.gold)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("CONFIG TRANSFER")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Theme.muted)
                        Spacer()
                        Button("EXPORT JSON") { hub.exportConfigPayload() }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.purple)
                            .cornerRadius(5)
                            .buttonStyle(.plain)
                        Button("IMPORT JSON") { hub.importConfigPayload() }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(5)
                            .buttonStyle(.plain)
                        Button(hub.includeSecretsInExport ? "SECRETS ON" : "SECRETS OFF") {
                            hub.includeSecretsInExport.toggle()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.includeSecretsInExport ? Theme.red : Theme.green)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    }

                    Text(hub.includeSecretsInExport ? "Warning: export includes API key/token" : "Safe mode: secrets are redacted on export")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(hub.includeSecretsInExport ? Theme.red : Theme.green)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        SecureField("Transfer passphrase (optional)", text: $hub.signaturePassphrase)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(6)
                            .background(Theme.surface)
                            .cornerRadius(6)
                        Button(hub.requireSignatureOnImport ? "REQUIRE SIGNATURE" : "SIGNATURE OPTIONAL") {
                            hub.requireSignatureOnImport.toggle()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.requireSignatureOnImport ? Theme.red : Theme.cyan)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    }

                    TextEditor(text: $hub.configTransferPayload)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(height: 86)
                        .padding(4)
                        .background(Theme.surface)
                        .cornerRadius(6)

                    Text(hub.configTransferStatus)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(Theme.surface.opacity(0.75))
            .cornerRadius(8)

            HStack(spacing: 6) {
                ForEach(IntegrationRole.allCases, id: \.rawValue) { role in
                    Button(role.rawValue) { hub.signIn(role: role) }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(hub.role == role ? .black : role.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.role == role ? role.color : role.color.opacity(0.14))
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                }
                Button("SIGN OUT") { hub.signOut() }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.muted)
                    .buttonStyle(.plain)
                Spacer()
            }

            HStack(spacing: 8) {
                integrationCard(
                    title: "TELEMETRY",
                    subtitle: "Events: \(hub.analyticsEvents.count) · Crashes: \(hub.crashLogs.count)",
                    actionLabel: "LOG SAMPLE",
                    action: { hub.recordCrashSample() },
                    color: Theme.purple
                )
                integrationCard(
                    title: "PUSH",
                    subtitle: "Status: \(hub.pushStatus)",
                    actionLabel: "REQUEST + TEST",
                    action: {
                        hub.requestPushPermission()
                        hub.sendTestPush()
                    },
                    color: Theme.red
                )
            }

            HStack(spacing: 8) {
                integrationCard(
                    title: "PDF REPORT",
                    subtitle: hub.lastPDFPath == "None" ? "No report yet" : "Report ready",
                    actionLabel: "GENERATE",
                    action: { hub.generatePDFReport() },
                    color: Theme.gold
                )
                integrationCard(
                    title: "CLOUD EXPORT",
                    subtitle: hub.cloudExportStatus,
                    actionLabel: "EXPORT",
                    action: { hub.exportToCloud() },
                    color: Theme.accent
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BACKEND HEALTH")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(hub.healthColor)
                    Spacer()
                    Text("\(hub.healthSuccessRate)%")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(hub.healthColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.surface)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hub.healthColor)
                            .frame(width: max(10, geometry.size.width * CGFloat(hub.healthSuccessRate) / 100.0))
                    }
                }
                .frame(height: 8)

                HStack(spacing: 12) {
                    healthMetric(label: "Checks", value: "\(hub.checkHistory.count)", color: Theme.cyan)
                    healthMetric(label: "Passed", value: "\(hub.checkHistory.filter { $0.succeeded }.count)", color: Theme.green)
                    healthMetric(label: "Failed", value: "\(hub.checkHistory.filter { !$0.succeeded }.count)", color: Theme.red)
                    healthMetric(label: "Latency", value: hub.lastMeasuredLatencyMS > 0 ? "\(hub.lastMeasuredLatencyMS)ms" : "--", color: hub.healthColor)
                }

                Text(hub.healthSummary)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            .padding(10)
            .background(Theme.surface.opacity(0.78))
            .cornerRadius(10)

            if !hub.checkHistory.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECENT CHECKS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(Theme.cyan)

                    ForEach(hub.checkHistory) { record in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(record.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(record.stage)
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(record.accent)
                                    Text(record.timestamp)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Theme.muted)
                                    if let latencyMS = record.latencyMS {
                                        Text("· \(latencyMS)ms")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Theme.muted)
                                    }
                                }
                                Text(record.detail)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Theme.surface.opacity(0.72))
                        .cornerRadius(8)
                    }
                }
            }

            if let latestEvent = hub.analyticsEvents.first {
                Text("Last telemetry: \(latestEvent)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.gold)
        .padding(.horizontal, 16)
    }

    private func integrationCard(title: String, subtitle: String, actionLabel: String, action: @escaping () -> Void, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.muted)
                .lineLimit(2)
            Spacer(minLength: 0)
            Button(actionLabel, action: action)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .cornerRadius(5)
                .buttonStyle(.plain)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .background(Theme.surface.opacity(0.8))
        .cornerRadius(8)
    }

    private func healthMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension IntegrationRole {
    static var projectManagerFallback: IntegrationRole { .pm }
}
