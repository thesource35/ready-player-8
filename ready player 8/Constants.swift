// Constants.swift — Centralized enums and constants
// ConstructionOS

import Foundation

// MARK: - App Constants

enum AppConstants {
    enum Sync {
        static let pollingInterval: TimeInterval = 30
        static let maxPendingWrites = 100
        static let offlineQueueKey = "ConstructOS.Sync.PendingWrites"
    }

    enum Auth {
        static let minPasswordLength = 8
        static let accessTokenKey = "Auth.AccessToken"
        static let refreshTokenKey = "Auth.RefreshToken"
        static let emailKey = "Auth.Email"
    }

    enum Limits {
        static let maxAnalyticsEvents = 500
        static let maxCrashLogs = 100
        static let maxRiskLogEntries = 25
    }

    enum App {
        static let version = "2.0"
        static let buildNumber = "3"
        static let deepLinkScheme = "constructionos"
    }
}

// MARK: - Supabase Endpoint Builder

enum SupabaseEndpoint {
    case signup
    case signIn
    case refreshToken
    case table(String)
    case record(table: String, id: String)

    func path(baseURL: String) -> String {
        switch self {
        case .signup:
            return "\(baseURL)/auth/v1/signup"
        case .signIn:
            return "\(baseURL)/auth/v1/token?grant_type=password"
        case .refreshToken:
            return "\(baseURL)/auth/v1/token?grant_type=refresh_token"
        case .table(let name):
            return "\(baseURL)/rest/v1/\(name)"
        case .record(let table, let id):
            return "\(baseURL)/rest/v1/\(table)?id=eq.\(id)"
        }
    }
}

// MARK: - Supabase Table Names

enum SupabaseTable {
    static let projects = "cs_projects"
    static let contracts = "cs_contracts"
    static let marketData = "cs_market_data"
    static let aiMessages = "cs_ai_messages"
    static let wealthOpportunities = "cs_wealth_opportunities"
    static let decisionJournal = "cs_decision_journal"
    static let psychologySessions = "cs_psychology_sessions"
    static let leverageSnapshots = "cs_leverage_snapshots"
    static let wealthTracking = "cs_wealth_tracking"
    static let dailyLogs = "cs_daily_logs"
    static let taxExpenses = "cs_tax_expenses"
    static let verificationRequests = "cs_verification_requests"
}

// MARK: - Roofing Rates

enum RoofingRates {
    static let materialRates: [String: Double] = [
        "Asphalt Shingle": 4.50,
        "Metal Standing Seam": 12.00,
        "TPO Membrane": 7.50,
        "EPDM Rubber": 6.00,
        "Clay Tile": 15.00,
        "Slate": 22.00,
        "Wood Shake": 10.00,
        "Composite": 8.50,
        "Green Roof": 25.00,
    ]
    static let laborMultiplier = 0.6
    static let wastePercent = 0.12
    static let dumpsterCostMultiLayer = 650.0
    static let dumpsterCostSingleLayer = 450.0
    static let permitCostLarge = 350.0  // > 2000 sqft
    static let permitCostSmall = 200.0
    static let tearOffRatePerSqFt = 1.50
    static let largeRoofThreshold = 2000.0  // sqft
}

// MARK: - Storage Keys

enum StorageKey {
    static let configPrefix = "ConstructOS.Integrations.Backend."
    static let psychologyScore = "ConstructOS.Wealth.PsychologyScore"
    static let mindsetAnswers = "ConstructOS.Wealth.MindsetAnswers"
    static let psychHistoryRaw = "ConstructOS.Wealth.PsychHistoryRaw"
    static let affirmationStreak = "ConstructOS.Wealth.AffirmationStreak"
    static let lastAffirmationDate = "ConstructOS.Wealth.LastAffirmationDate"
    static let resolvedBeliefs = "ConstructOS.Wealth.ResolvedBeliefs"
    static let leverageScores = "ConstructOS.Wealth.LeverageScores"
    static let leverageHistoryRaw = "ConstructOS.Wealth.LeverageHistoryRaw"
    static let playBookProgressRaw = "ConstructOS.Wealth.PlaybookProgressRaw"
    static let milestonesRaw = "ConstructOS.Wealth.MilestonesRaw"
    static let opportunitiesRaw = "ConstructOS.Wealth.OpportunitiesRaw"
    static let archivedOpportunitiesRaw = "ConstructOS.Wealth.ArchivedOpportunitiesRaw"
    static let decisionJournalRaw = "ConstructOS.Wealth.DecisionJournalRaw"
    static let customScenariosRaw = "ConstructOS.Wealth.CustomScenariosRaw"
    static let questionResponsesRaw = "ConstructOS.Wealth.QuestionResponsesRaw"
    static let trackingRaw = "ConstructOS.Wealth.TrackingRaw"
    static let capitalAllocation = "ConstructOS.Wealth.CapitalAllocation"
    static let analyticsEvents = "ConstructOS.Analytics.Events"
    static let crashes = "ConstructOS.Crashes"
    static let biometricEnabled = "ConstructOS.Security.BiometricEnabled"
    // 999.5 cleanup: angelicAPIKey constant removed -- the value was the
    // legacy UserDefaults key migrated to Keychain in AngelicAIView.swift:120-123.
    // After the migration shipped, this constant became unused (grep returns 0
    // call sites). Keeping the legacy key string in source code was a tiny
    // SEC-02 risk vector (could be referenced again by future code without
    // realizing the secret should live in Keychain).
    static let angelicSessionID = "ConstructOS.AngelicAI.SessionID"
}
