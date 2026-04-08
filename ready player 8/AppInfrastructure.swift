import SwiftUI
import Combine

// MARK: - ========== App Infrastructure: Analytics, Crash Reporting, Feature Gates ==========

// MARK: - Analytics Engine

@MainActor
final class AnalyticsEngine: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = AnalyticsEngine()

    @Published var events: [AnalyticsEvent] = []
    @Published var sessionStart: Date = Date()
    @Published var screenViews: [String: Int] = [:]

    private let key = "ConstructOS.Analytics.Events"
    private let maxEvents = 500

    init() {
        events = loadJSON(key, default: [AnalyticsEvent]())
    }

    func track(_ name: String, properties: [String: String] = [:]) {
        let event = AnalyticsEvent(name: name, properties: properties, timestamp: Date(), sessionDuration: Date().timeIntervalSince(sessionStart))
        events.insert(event, at: 0)
        if events.count > maxEvents { events = Array(events.prefix(maxEvents)) }
        saveJSON(key, value: events)

        // Screen view tracking
        if name.hasPrefix("screen_") {
            let screen = name.replacingOccurrences(of: "screen_", with: "")
            screenViews[screen, default: 0] += 1
        }
    }

    func trackScreen(_ name: String) {
        track("screen_\(name)")
    }

    func trackAction(_ action: String, on screen: String) {
        track("action_\(action)", properties: ["screen": screen])
    }

    func trackError(_ error: String, context: String) {
        track("error", properties: ["message": error, "context": context])
    }

    var totalEvents: Int { events.count }
    var uniqueScreens: Int { screenViews.count }
    var avgSessionMinutes: Double {
        guard !events.isEmpty else { return 0 }
        let sessions = events.filter { $0.name == "app_opened" }
        guard !sessions.isEmpty else { return Date().timeIntervalSince(sessionStart) / 60 }
        return sessions.reduce(0) { $0 + $1.sessionDuration } / Double(sessions.count) / 60
    }

    var topScreens: [(screen: String, views: Int)] {
        screenViews.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }
}

struct AnalyticsEvent: Codable, Identifiable {
    var id = UUID()
    let name: String
    let properties: [String: String]
    let timestamp: Date
    let sessionDuration: TimeInterval
}

// MARK: - Crash Reporter

@MainActor
final class CrashReporter: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = CrashReporter()

    @Published var crashLogs: [CrashLog] = []
    private let key = "ConstructOS.Crashes"

    init() {
        crashLogs = loadJSON(key, default: [CrashLog]())
        setupCrashHandler()
    }

    func reportError(_ error: String, file: String = #file, line: Int = #line, function: String = #function) {
        let log = CrashLog(
            message: error,
            file: URL(fileURLWithPath: file).lastPathComponent,
            line: line,
            function: function,
            timestamp: Date(),
            appVersion: "2.0",
            buildNumber: "3",
            deviceModel: deviceModel()
        )
        crashLogs.insert(log, at: 0)
        if crashLogs.count > 100 { crashLogs = Array(crashLogs.prefix(100)) }
        saveJSON(key, value: crashLogs)
    }

    private func setupCrashHandler() {
        // Set up NSException and signal handlers for production
        NSSetUncaughtExceptionHandler { exception in
            let log = CrashLog(
                message: "\(exception.name.rawValue): \(exception.reason ?? "Unknown")",
                file: "Exception", line: 0,
                function: exception.callStackSymbols.prefix(5).joined(separator: "\n"),
                timestamp: Date(), appVersion: "2.0", buildNumber: "3", deviceModel: ""
            )
            let logs = loadJSON("ConstructOS.Crashes", default: [CrashLog]())
            saveJSON("ConstructOS.Crashes", value: [log] + logs)
        }
    }

    private func deviceModel() -> String {
        #if os(iOS)
        return UIDevice.current.model
        #else
        return "Mac"
        #endif
    }
}

struct CrashLog: Codable, Identifiable {
    var id = UUID()
    let message: String
    let file: String
    let line: Int
    let function: String
    let timestamp: Date
    let appVersion: String
    let buildNumber: String
    let deviceModel: String
}

// MARK: - Feature Gate (Coming Soon)

enum FeatureStatus {
    case live
    case comingSoon
    case beta

    var isAvailable: Bool { self == .live || self == .beta }
}

struct FeatureGates {
    // Core features - LIVE
    static let projects: FeatureStatus = .live
    static let contracts: FeatureStatus = .live
    static let ops: FeatureStatus = .live
    static let maps: FeatureStatus = .live
    static let network: FeatureStatus = .live
    static let angelic: FeatureStatus = .live
    static let wealth: FeatureStatus = .live
    static let rentals: FeatureStatus = .live
    static let punchList: FeatureStatus = .live
    static let field: FeatureStatus = .live
    static let settings: FeatureStatus = .live

    // Financial features - COMING SOON (require licensing)
    static let payments: FeatureStatus = .comingSoon
    static let capital: FeatureStatus = .comingSoon
    static let insurance: FeatureStatus = .comingSoon
    static let bonds: FeatureStatus = .comingSoon

    // Operational - BETA
    static let workforce: FeatureStatus = .beta
    static let supplyChain: FeatureStatus = .beta
    static let intelligence: FeatureStatus = .beta
}

struct ComingSoonOverlay: View {
    let feature: String
    let description: String
    let expectedDate: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark").font(.system(size: 40)).foregroundColor(Theme.gold)
            Text("COMING SOON").font(.system(size: 16, weight: .heavy)).tracking(3).foregroundColor(Theme.gold)
            Text(feature).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
            Text(description).font(.system(size: 11)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            Text("Expected: \(expectedDate)").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text("WHY ISN'T THIS LIVE YET?").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                Text("Financial features require regulatory licensing and banking partnerships. We're building this the right way to protect your money and your business.")
                    .font(.system(size: 10)).foregroundColor(Theme.muted)
            }
            .padding(14).background(Theme.surface).cornerRadius(10).frame(maxWidth: 320)

            Button { ToastManager.shared.show("Coming soon") } label: {
                Text("NOTIFY ME WHEN LIVE").font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                    .frame(maxWidth: 280).padding(.vertical, 12)
                    .background(Theme.gold).cornerRadius(8)
            }.buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.opacity(0.95))
    }
}

struct BetaBadge: View {
    var body: some View {
        Text("BETA").font(.system(size: 7, weight: .black)).foregroundColor(.black)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Theme.cyan).cornerRadius(3)
    }
}

// MARK: - Legal Disclaimers

struct LegalDisclaimers {
    static let paymentDisclaimer = "ConstructionOS Pay is a payment tracking dashboard. Actual payment processing requires integration with a licensed payment processor. ConstructionOS does not hold, transfer, or process funds directly."

    static let capitalDisclaimer = "ConstructionOS Capital displays estimated factoring offers for informational purposes. Actual invoice factoring requires a separate agreement with a licensed lending institution. ConstructionOS is not a bank or licensed lender."

    static let insuranceDisclaimer = "Insurance quotes displayed are estimates for comparison purposes only. ConstructionOS is not a licensed insurance broker or agent. Contact carriers directly or consult a licensed insurance professional for binding coverage."

    static let bondDisclaimer = "Surety bond information is for tracking purposes only. ConstructionOS does not issue, underwrite, or broker surety bonds. Contact a licensed surety agent for bonding needs."

    static let workforceDisclaimer = "ConstructionOS Workforce connects employers with available workers. ConstructionOS is not an employer, staffing agency, or labor broker. All employment relationships are between the parties directly."

    static let dataDisclaimer = "Market intelligence reports contain aggregated, anonymized data from the ConstructionOS network. Data is provided as-is for informational purposes and should not be the sole basis for business decisions."
}

struct LegalDisclaimerView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle").font(.system(size: 9)).foregroundColor(Theme.muted.opacity(0.5))
            Text(text).font(.system(size: 8)).foregroundColor(Theme.muted.opacity(0.5)).lineLimit(3)
        }
        .padding(8).background(Theme.surface.opacity(0.5)).cornerRadius(6)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?

    init(icon: String, title: String, message: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon; self.title = title; self.message = message
        self.actionLabel = actionLabel; self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(icon).font(.system(size: 40))
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
            Text(message).font(.system(size: 11)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            if let label = actionLabel, let action = action {
                Button(action: action) {
                    Text(label).font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(Theme.accent).cornerRadius(8)
                }.buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity).padding(32).background(Theme.surface).cornerRadius(14)
    }
}

// MARK: - Analytics Dashboard (for Settings)

struct AnalyticsDashboardMiniView: View {
    @ObservedObject var analytics = AnalyticsEngine.shared
    @ObservedObject var crashes = CrashReporter.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APP ANALYTICS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("\(analytics.totalEvents)").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.cyan); Text("EVENTS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(analytics.uniqueScreens)").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.green); Text("SCREENS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(crashes.crashLogs.count)").font(.system(size: 16, weight: .heavy)).foregroundColor(crashes.crashLogs.isEmpty ? Theme.green : Theme.red); Text("CRASHES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background((crashes.crashLogs.isEmpty ? Theme.green : Theme.red).opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text(String(format: "%.1f", analytics.avgSessionMinutes)).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent); Text("AVG MIN").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(8).background(Theme.accent.opacity(0.06)).cornerRadius(8)
            }

            if !analytics.topScreens.isEmpty {
                Text("TOP SCREENS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                ForEach(analytics.topScreens.prefix(5), id: \.screen) { item in
                    HStack {
                        Text(item.screen).font(.system(size: 9)).foregroundColor(Theme.text)
                        Spacer()
                        Text("\(item.views) views").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                    }
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }
}

// MARK: - IAP Setup Guide

struct IAPSetupGuide {
    static let products = """
    CREATE THESE IN APP STORE CONNECT > SUBSCRIPTIONS:

    Subscription Group: "ConstructionOS Plans"

    1. com.constructionos.fieldworker.monthly — $9.99/mo
    2. com.constructionos.fieldworker.annual — $99.99/yr
    3. com.constructionos.pm.monthly — $24.99/mo
    4. com.constructionos.pm.annual — $249.99/yr
    5. com.constructionos.owner.monthly — $49.99/mo
    6. com.constructionos.owner.annual — $499.99/yr

    Subscription Group: "Verification Badges"

    7. com.constructionos.verified.licensed — $27.99/mo
    8. com.constructionos.verified.company — $49.99/mo

    Each product needs:
    - Display name
    - Description
    - Price
    - Screenshot of the paywall/feature
    - Review notes: "Subscription unlocks premium features"
    """
}
