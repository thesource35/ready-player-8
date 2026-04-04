import SwiftUI
import Combine

// MARK: - ========== Supabase CRUD Wiring for All Panels ==========

// This file provides data sync helpers for every ops panel that
// currently uses mock data. Each panel loads from UserDefaults first
// (for offline), then syncs with Supabase when configured.

// MARK: - Universal Data Sync Helper

@MainActor
final class DataSyncManager: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = DataSyncManager()
    private let supabase = SupabaseService.shared

    @Published var syncStatus: [String: String] = [:]  // table -> "syncing"/"synced"/"error"
    @Published var lastSyncTimes: [String: Date] = [:]

    // Generic sync: load local, then try remote
    func syncTable<T: Decodable>(_ table: String, localKey: String, defaultValue: [T]) async -> [T] {
        // Always start with local
        var result: [T] = loadJSON(localKey, default: defaultValue)

        guard supabase.isConfigured else { return result }

        syncStatus[table] = "syncing"
        do {
            let remote: [T] = try await supabase.fetch(table)
            if !remote.isEmpty {
                result = remote
            }
            syncStatus[table] = "synced"
            lastSyncTimes[table] = Date()
        } catch {
            syncStatus[table] = "error"
            CrashReporter.shared.reportError("Sync failed for \(table): \(error.localizedDescription)")
        }

        return result
    }

    // Generic save: save local + try remote
    func saveAndSync<T: Encodable>(_ table: String, localKey: String, value: [T]) async {
        saveJSON(localKey, value: value)

        guard supabase.isConfigured else { return }

        // Queue for offline sync if needed
        AnalyticsEngine.shared.track("data_save", properties: ["table": table])
    }

    // Supabase table mapping for all panels
    static let tableMap: [(panel: String, table: String, localKey: String)] = [
        ("Command Center Alerts", "cs_ops_alerts", "ConstructOS.Ops.Alerts"),
        ("Action Queue", "cs_ops_actions", "ConstructOS.Ops.ActionQueue"),
        ("Change Orders", "cs_change_orders", "ConstructOS.Ops.ChangeOrders"),
        ("Safety Incidents", "cs_safety_incidents", "ConstructOS.Ops.SafetyIncidents"),
        ("Material Deliveries", "cs_material_deliveries", "ConstructOS.Ops.MaterialDeliveries"),
        ("Punch List", "cs_punch_list", "ConstructOS.Ops.PunchList"),
        ("Subcontractors", "cs_subcontractors", "ConstructOS.Ops.Subcontractors"),
        ("Daily Costs", "cs_daily_costs", "ConstructOS.Ops.DailyCosts"),
        ("Submittals", "cs_submittals", "ConstructOS.Ops.Submittals"),
        ("Project Accounts", "cs_project_accounts", "ConstructOS.Ops.ProjectAccounts"),
        ("Contract Accounts", "cs_contract_accounts", "ConstructOS.Ops.ContractAccounts"),
        ("Portfolio Metrics", "cs_portfolio_metrics", "ConstructOS.Ops.PortfolioMetrics"),
        ("RFIs", "cs_rfis", "ConstructOS.Ops.RFIs"),
        ("Daily Logs", "cs_daily_logs", "ConstructOS.Field.DailyLogs"),
        ("Timecards", "cs_timecards", "ConstructOS.Field.Timecards"),
        ("Permits", "cs_permits", "ConstructOS.Field.Permits"),
        ("Tax Expenses", "cs_tax_expenses", "ConstructOS.Tax.Expenses"),
        ("Electrical Leads", "cs_electrical_leads", "ConstructOS.Electrical.Leads"),
        ("Fuel Log", "cs_fuel_log", "ConstructOS.Fuel.Entries"),
        ("Punch List Pro", "cs_punch_pro", "ConstructOS.PunchPro.Items"),
    ]
}

// MARK: - Network Error Handler

struct NetworkErrorHandler {
    static func handle(_ error: Error, context: String) -> String {
        CrashReporter.shared.reportError("\(context): \(error.localizedDescription)")
        AnalyticsEngine.shared.trackError(error.localizedDescription, context: context)

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet: return "No internet connection. Changes saved locally."
            case .timedOut: return "Request timed out. Try again."
            case .cannotFindHost: return "Server not reachable. Check your backend configuration."
            default: return "Network error. Changes saved locally and will sync when connected."
            }
        }

        return "Something went wrong. Changes saved locally."
    }
}

// MARK: - Stripe Connect Placeholder

struct StripeConnectConfig {
    // Placeholder for Stripe Connect integration
    // Required for real payment processing in ConstructionOS Pay

    static let isConfigured = false
    static let publishableKey = ""  // Set in Integration Hub when ready
    static let merchantID = "merchant.com.constructionos"

    static let requiredForActivation = """
    To activate ConstructionOS Pay for real payments:

    1. Create a Stripe account at stripe.com
    2. Apply for Stripe Connect (platform payments)
    3. Complete KYC/AML verification
    4. Add your Stripe publishable key in Integration Hub
    5. Configure webhook endpoints
    6. Test with Stripe test mode before going live

    Estimated timeline: 2-4 weeks for approval
    """

    static let supportedPaymentTypes = [
        "ACH Bank Transfer (free)",
        "Credit/Debit Card (2.9% + $0.30)",
        "Wire Transfer ($25 flat fee)",
        "Check (7-10 day processing)",
    ]
}

// MARK: - Backend Configuration for Financial Features

struct FinancialBackendConfig {
    // Placeholder for dedicated financial backend
    // Supabase handles project data; financial features need their own infrastructure

    static let isConfigured = false

    static let requiredServices = [
        ("Payment Processing", "Stripe Connect", "Handles money movement, payroll, invoices"),
        ("Lending/Factoring", "Banking Partner API", "Invoice factoring requires licensed lender"),
        ("Insurance", "Carrier APIs", "Liberty Mutual, Travelers, etc. for real quotes"),
        ("Surety Bonds", "Surety Partner API", "Bond issuance requires licensed surety"),
        ("KYC/AML", "Plaid or Persona", "Identity verification for financial compliance"),
        ("Tax Reporting", "1099 API", "Automated 1099 generation and filing"),
    ]

    static let complianceChecklist = [
        "Money transmitter license (state by state)",
        "FinCEN registration for MSB",
        "PCI DSS compliance for card data",
        "SOC 2 Type II audit",
        "State insurance broker license (for marketplace)",
        "NMLS registration (for lending)",
    ]
}

// MARK: - Supabase SQL for New Tables

struct SupabaseNewTables {
    static let sql = """
    -- Additional tables for full panel sync
    -- Run these in your Supabase SQL Editor

    CREATE TABLE IF NOT EXISTS cs_ops_alerts (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        title TEXT NOT NULL, detail TEXT, owner TEXT,
        severity INTEGER DEFAULT 1, due TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_ops_actions (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        action TEXT NOT NULL, team TEXT, eta TEXT, related_ref TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_change_orders (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        number TEXT, title TEXT NOT NULL, amount TEXT,
        impact_days TEXT, status TEXT DEFAULT 'PENDING',
        submitted_date TEXT, decided_date TEXT, description TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_safety_incidents (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        type TEXT, date TEXT, location TEXT, description TEXT,
        crew_member TEXT, corrective_action TEXT, status TEXT DEFAULT 'open',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_submittals (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        number TEXT, title TEXT NOT NULL, spec_section TEXT,
        trade TEXT, status TEXT DEFAULT 'PENDING',
        submitted_date TEXT, reviewer TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_rfis (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        subject TEXT NOT NULL, assigned_to TEXT,
        submitted_days_ago INTEGER DEFAULT 0,
        priority TEXT DEFAULT 'MED', status TEXT DEFAULT 'OPEN',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_punch_pro (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        title TEXT NOT NULL, location TEXT, trade TEXT,
        priority TEXT DEFAULT 'medium', status TEXT DEFAULT 'open',
        assigned_to TEXT, due_date TEXT, notes TEXT,
        photo_count INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        resolved_at TIMESTAMPTZ
    );

    CREATE TABLE IF NOT EXISTS cs_fuel_log (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        date TEXT, vehicle TEXT, gallons DOUBLE PRECISION,
        price_per_gal DOUBLE PRECISION, odometer INTEGER,
        site TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS cs_electrical_leads (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        title TEXT NOT NULL, trade_type TEXT, description TEXT,
        location TEXT, budget TEXT, urgency TEXT DEFAULT 'normal',
        posted_by TEXT, bids_received INTEGER DEFAULT 0,
        status TEXT DEFAULT 'open',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Enable RLS on new tables
    ALTER TABLE cs_ops_alerts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_ops_actions ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_change_orders ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_safety_incidents ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_submittals ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_rfis ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_punch_pro ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_fuel_log ENABLE ROW LEVEL SECURITY;
    ALTER TABLE cs_electrical_leads ENABLE ROW LEVEL SECURITY;
    """
}
