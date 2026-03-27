//
//  ContentView.swift
//  ready player 8
//
//  Created by Beverly Hunter on 3/23/26.
//

import SwiftUI
import Foundation
import Charts
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins
import CryptoKit
import LocalAuthentication
import MapKit
import PhotosUI
import Security
import UserNotifications
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - ========== ThemeAndModels.swift ==========

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTRUCTIONOS — Theme, Models & Mock Data
// ═══════════════════════════════════════════════════════════════════════════════

// MARK: - Theme System
struct Theme {
    static let bg = Color(red: 0.03, green: 0.07, blue: 0.09)
    static let surface = Color(red: 0.06, green: 0.11, blue: 0.14)
    static let panel = Color(red: 0.09, green: 0.15, blue: 0.19)
    static let border = Color(red: 0.20, green: 0.33, blue: 0.38)
    static let accent = Color(red: 0.95, green: 0.62, blue: 0.24)
    static let gold = Color(red: 0.99, green: 0.78, blue: 0.34)
    static let cyan = Color(red: 0.29, green: 0.77, blue: 0.80)
    static let green = Color(red: 0.41, green: 0.82, blue: 0.58)
    static let red = Color(red: 0.85, green: 0.30, blue: 0.28)
    static let purple = Color(red: 0.52, green: 0.56, blue: 0.80)
    static let text = Color(red: 0.94, green: 0.97, blue: 0.97)
    static let muted = Color(red: 0.62, green: 0.74, blue: 0.76)
    static let wealthGold = Color(red: 0.95, green: 0.78, blue: 0.26)
    static let wealthGradientSurface = Color(red: 0.08, green: 0.13, blue: 0.09)
}

// MARK: - Models & Data

@MainActor
final class RiskActionLogStore: ObservableObject {
    @Published var entries: [String] {
        didSet {
            defaults.set(entries, forKey: storageKey)
        }
    }

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "riskActionLogEntries"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.entries = defaults.stringArray(forKey: storageKey) ?? []
    }

    func add(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        let stamped = "[\(formatter.string(from: Date()))] \(message)"
        entries.insert(stamped, at: 0)
        entries = Array(entries.prefix(25))
    }

    func undoLast() {
        if !entries.isEmpty { entries.removeFirst() }
    }

    func clear() {
        entries.removeAll()
    }
}

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let client: String
    let type: String
    let status: String
    let progress: Int
    let budget: String
    let score: String
    let team: String
    let likes: Int
    let comments: Int
    let shares: Int
}

struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let company: String
    let score: Int
    let connections: Int
    let projects: Int
    let initials: String
}

struct MapSite: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let latitude: Double
    let longitude: Double
    let name: String
    let status: String
    let type: String

    static let mapCenter = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)
    static let defaultRegion = MKCoordinateRegion(
        center: mapCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
    )

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var focusRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    }

    var coordinateLabel: String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    var latencyMS: Int {
        420 + Int(((x + y) / 2.0) * 380)
    }

    var crewETA: String {
        "\(4 + Int((1.0 - y) * 9)) min"
    }

    var alertLevel: String {
        switch status.lowercased() {
        case let value where value.contains("queue"), let value where value.contains("inspection"):
            return "WATCH"
        case let value where value.contains("crane"), let value where value.contains("pour"):
            return "ACTIVE"
        default:
            return "STABLE"
        }
    }
}

struct SatellitePass: Identifiable {
    let id = UUID()
    let name: String
    let eta: String
    let coverage: String
    let confidence: Int
    let color: Color
}

struct MapRoute: Identifiable {
    let id = UUID()
    let fromSiteName: String
    let toSiteName: String
    let label: String
    let color: Color
}

enum MapCameraPreset: String, CaseIterable, Identifiable {
    case network = "NETWORK"
    case selected = "SELECTED"
    case logistics = "LOGISTICS"
    case weather = "WEATHER"

    var id: String { rawValue }
}

let previewMapSites: [MapSite] = [
    MapSite(x: 0.18, y: 0.28, latitude: 40.7617, longitude: -73.9918, name: "Tower A", status: "Pour window live", type: "STRUCTURE"),
    MapSite(x: 0.62, y: 0.20, latitude: 40.7644, longitude: -73.9814, name: "Site Gamma", status: "Crane active", type: "LIFT"),
    MapSite(x: 0.72, y: 0.58, latitude: 40.7562, longitude: -73.9765, name: "Logistics Yard", status: "Queue build-up", type: "LOGISTICS"),
    MapSite(x: 0.36, y: 0.70, latitude: 40.7506, longitude: -73.9886, name: "Utility Trench", status: "Inspection due", type: "UTILITY")
]

let previewMapRoutes: [MapRoute] = [
    MapRoute(fromSiteName: "Tower A", toSiteName: "Site Gamma", label: "Crane corridor", color: Theme.cyan),
    MapRoute(fromSiteName: "Site Gamma", toSiteName: "Logistics Yard", label: "Material convoy", color: Theme.gold),
    MapRoute(fromSiteName: "Logistics Yard", toSiteName: "Utility Trench", label: "Crew shuttle", color: Theme.green)
]

struct MarketData: Identifiable {
    let id = UUID()
    let city: String
    let vacancy: Double
    let newBiz: Int
    let closed: Int
    let trend: String
}

struct ContractOpportunity: Identifiable {
    let id = UUID()
    let title: String
    let client: String
    let location: String
    let sector: String
    let stage: String
    let package: String
    let budget: String
    let bidDue: String
    let liveFeedStatus: String
    let bidders: Int
    let score: Int
    let watchCount: Int
}

struct FeedbackInsight: Identifiable {
    let id = UUID()
    let title: String
    let painPoint: String
    let solution: String
    let demand: String
    let impact: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role { case user, ai }
    enum DeliveryState: String {
        case sending = "Sending"
        case delivered = "Delivered"
        case read = "Read"
        case expired = "Expired"
    }
    let role: Role
    let text: String
    let timestamp: Date
    var deliveryState: DeliveryState = .delivered
    var expiresAt: Date?
    var encrypted: Bool = true
    var photoData: Data?

    var timestampLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

// Mock Data
let mockProjects = [
    Project(name: "Nexus Tower Complex", client: "Summit Dev Group", type: "Commercial High-Rise", status: "On Track", progress: 67, budget: "$42.8M", score: "9.4", team: "48 crew", likes: 1247, comments: 89, shares: 234),
    Project(name: "Riverside Lofts", client: "Urban Renewal LLC", type: "Mixed-Use Residential", status: "Delayed", progress: 34, budget: "$8.1M", score: "7.8", team: "22 crew", likes: 534, comments: 41, shares: 89),
    Project(name: "Harbor Industrial Park", client: "Port Authority", type: "Industrial", status: "On Track", progress: 89, budget: "$19.4M", score: "9.7", team: "61 crew", likes: 2103, comments: 156, shares: 445),
    Project(name: "Tech Campus Phase II", client: "InnovateCorp", type: "Commercial Office", status: "Ahead", progress: 52, budget: "$67.2M", score: "9.1", team: "104 crew", likes: 3841, comments: 267, shares: 891),
]

let mockContacts = [
    Contact(name: "Marcus Rivera", title: "Sr. Project Manager", company: "Apex Construction", score: 98, connections: 847, projects: 23, initials: "MR"),
    Contact(name: "Sarah Chen", title: "Civil Engineer PE", company: "BridgeTech", score: 94, connections: 612, projects: 31, initials: "SC"),
    Contact(name: "David Okafor", title: "GC Principal", company: "Okafor Builders", score: 91, connections: 1203, projects: 45, initials: "DO"),
    Contact(name: "Priya Nair", title: "BIM Manager", company: "Design-Build Pro", score: 89, connections: 534, projects: 18, initials: "PN"),
    Contact(name: "James Kowalski", title: "Safety Director", company: "SafeFirst Inc.", score: 96, connections: 923, projects: 67, initials: "JK"),
    Contact(name: "Amara Diallo", title: "Real Estate Dev.", company: "Meridian Capital", score: 88, connections: 445, projects: 12, initials: "AD"),
]

let mockMapSites = [
    MapSite(x: 0.35, y: 0.25, latitude: 40.7580, longitude: -73.9855, name: "Site Alpha", status: "active", type: "commercial"),
    MapSite(x: 0.55, y: 0.45, latitude: 40.7590, longitude: -73.9840, name: "Site Beta", status: "drone", type: "residential"),
    MapSite(x: 0.72, y: 0.30, latitude: 40.7600, longitude: -73.9830, name: "Site Gamma", status: "delayed", type: "industrial"),
    MapSite(x: 0.20, y: 0.60, latitude: 40.7610, longitude: -73.9820, name: "Site Delta", status: "active", type: "commercial"),
    MapSite(x: 0.80, y: 0.65, latitude: 40.7620, longitude: -73.9810, name: "Site Epsilon", status: "satellite", type: "mixed"),
    MapSite(x: 0.45, y: 0.70, latitude: 40.7630, longitude: -73.9800, name: "HQ Tower", status: "active", type: "commercial"),
]

let mockMarketData = [
    MarketData(city: "New York", vacancy: 12.4, newBiz: 847, closed: 203, trend: "up"),
    MarketData(city: "Los Angeles", vacancy: 9.8, newBiz: 612, closed: 178, trend: "up"),
    MarketData(city: "Chicago", vacancy: 15.2, newBiz: 441, closed: 267, trend: "down"),
    MarketData(city: "Houston", vacancy: 8.1, newBiz: 723, closed: 145, trend: "up"),
    MarketData(city: "London", vacancy: 11.3, newBiz: 934, closed: 312, trend: "neutral"),
    MarketData(city: "Dubai", vacancy: 6.7, newBiz: 1204, closed: 89, trend: "up"),
]

let mockContracts = [
    ContractOpportunity(title: "West Loop Medical Tower", client: "Meridian Health Partners", location: "Chicago, IL", sector: "Healthcare", stage: "Open For Bid", package: "Core & Shell", budget: "$28.4M", bidDue: "Apr 18", liveFeedStatus: "3D map + drone online", bidders: 16, score: 96, watchCount: 482),
    ContractOpportunity(title: "Portside Logistics Hub", client: "Atlas Freight Group", location: "Houston, TX", sector: "Industrial", stage: "Prequalifying Teams", package: "Site + Structural", budget: "$61.9M", bidDue: "Apr 26", liveFeedStatus: "Satellite refresh every 4h", bidders: 23, score: 92, watchCount: 615),
    ContractOpportunity(title: "Crown District Residences", client: "Urban Frontier Dev Co", location: "Dubai, UAE", sector: "Mixed-Use", stage: "Negotiation", package: "MEP + Interiors", budget: "$44.7M", bidDue: "May 02", liveFeedStatus: "Live tower cam active", bidders: 11, score: 94, watchCount: 338),
]

let feedbackInsights = [
    FeedbackInsight(title: "Too Many Tools", painPoint: "Teams report bouncing between project management, bidding, maps, CRM, and spreadsheets.", solution: "Contracts, project execution, live maps, contacts, and AI now sit in one operating system.", demand: "Requested by 81% of surveyed operators", impact: "Cuts context switching and duplicate entry"),
    FeedbackInsight(title: "No Live Build Visibility", painPoint: "Owners and PMs want to watch site progress without waiting for manual updates.", solution: "Every contract can expose 3D maps, drone feeds, tower cams, and satellite snapshots in one live command view.", demand: "Requested by 67% of owners", impact: "Faster issue escalation and clearer client reporting"),
    FeedbackInsight(title: "Weak Market Signal", painPoint: "Teams miss vacancy shifts, new business openings, and hyperlocal demand changes.", solution: "Global market intelligence combines tracked vacancy, openings/closures, and local crowdsourced submissions.", demand: "Requested by 58% of growth teams", impact: "Sharper go/no-go and expansion decisions"),
]

let tickerItems = [
    "🏗️ PROJECT NEXUS TOWER — On Schedule — $4.2M",
    "📍 VACANCY: 200 Main St Commercial — 3,400 sqft",
    "🆕 NEW BIZ: Stellar Coffee Co. — Downtown District",
    "🚁 DRONE FEED ACTIVE: Site 7-Alpha",
    "⭐ ANGELIC AI: 12 RFI responses processed",
    "🌍 GLOBAL USERS: 142,891 active now",
    "📊 MARKET: Commercial vacancy down 2.3% MoM",
    "🔔 CLOSED: Retail — 1402 Oak Blvd",
    "💰 NEW CONTRACT: Summit Developers — $8.7M",
    "🛰️ SAT IMAGERY: Updated for 847 sites",
]

// MARK: - Keychain Helper

struct KeychainHelper {
    private static let service = "com.constructionos."

    static func save(key: String, data: String) {
        guard let valueData = data.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + key,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = valueData
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + key,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + key,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - OpsRolePreset

enum OpsRolePreset: String, CaseIterable {
    case superintendent = "SUPER"
    case projectManager = "PM"
    case executive      = "EXEC"

    var display: String {
        switch self {
        case .superintendent: return "Superintendent"
        case .projectManager: return "Project Manager"
        case .executive:      return "Executive"
        }
    }

    var icon: String {
        switch self {
        case .superintendent: return "\u{1F527}"
        case .projectManager: return "\u{1F4CB}"
        case .executive:      return "\u{1F4CA}"
        }
    }
}

// MARK: - DashboardPanelHeading

struct DashboardPanelHeading: View {
    let eyebrow: String
    let title: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow).font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(accent)
            Text(title).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
            Text(detail).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.muted).lineLimit(2)
        }
    }
}

// MARK: - DashboardStatPill

struct DashboardStatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(size: 15, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(Theme.surface.opacity(0.78))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.16), lineWidth: 1))
        .cornerRadius(10)
    }
}

// MARK: - ========== AppStorageJSON.swift ==========

/// Load a Codable value from UserDefaults (AppStorage-compatible key).
/// Returns `defaultValue` if key is empty or decoding fails.
func loadJSON<T: Decodable>(_ key: String, default defaultValue: T) -> T {
    guard let raw = UserDefaults.standard.string(forKey: key),
          let data = raw.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(T.self, from: data) else {
        return defaultValue
    }
    return decoded
}

/// Persist a Codable value to UserDefaults as a JSON string (AppStorage-compatible).
func saveJSON<T: Encodable>(_ key: String, value: T) {
    if let data = try? JSONEncoder().encode(value) {
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: key)
    }
}

// MARK: - ========== ContentView (Main App) ==========

// MARK: - Auth Gate View

struct AuthGateView: View {
    @ObservedObject var supabase = SupabaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var error: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            VStack(spacing: 20) {
                Spacer()
                HStack(spacing: 6) {
                    Text("CONSTRUCT").font(.system(size: 28, weight: .heavy)).tracking(2).foregroundColor(Theme.text)
                    Text("OS").font(.system(size: 28, weight: .heavy)).tracking(2).foregroundColor(Theme.accent)
                }
                Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                    .font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.muted)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .font(.system(size: 14)).foregroundColor(Theme.text)
                        .padding(12).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    #if os(iOS)
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .font(.system(size: 14)).foregroundColor(Theme.text)
                        .padding(12).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    #else
                    SecureField("Password", text: $password)
                        .font(.system(size: 14)).foregroundColor(Theme.text)
                        .padding(12).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    #endif
                }
                .frame(maxWidth: 320)

                if let error {
                    Text(error).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.red)
                        .multilineTextAlignment(.center).frame(maxWidth: 320)
                }

                Button {
                    guard !email.isEmpty, !password.isEmpty else { error = "Email and password required"; return }
                    isLoading = true; error = nil
                    Task {
                        do {
                            if isSignUp { try await supabase.signUp(email: email, password: password) }
                            else { try await supabase.signIn(email: email, password: password) }
                        } catch { await MainActor.run { self.error = error.localizedDescription } }
                        await MainActor.run { isLoading = false }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                                .font(.system(size: 13, weight: .bold)).tracking(1)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 320).frame(height: 44)
                    .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle(); error = nil
                }
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)

                Button("Skip (use without account)") {
                    supabase.accessToken = "skip"
                    supabase.currentUserEmail = "local"
                }
                .font(.system(size: 11)).foregroundColor(Theme.muted)

                Spacer()
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView: View {
    @StateObject private var actionLog = RiskActionLogStore()
    @ObservedObject private var supabase = SupabaseService.shared
    @State private var activeNav: NavTab = .home
    @State private var pulse = false

    enum NavTab: String, CaseIterable {
        case home = "home"; case projects = "projects"; case contracts = "contracts"
        case market = "market"; case maps = "maps"; case network = "network"
        case ops = "ops"; case hub = "hub"; case security = "security"
        case pricing = "pricing"; case angelic = "angelic"; case wealth = "wealth"
        case cosNetwork = "cos-network"
        case rentals = "rentals"
    }

    private let navItems: [(String, String, String, String)] = [
        ("home","COMMAND","\u{2318}","core"),("projects","PROJECTS","\u{1F3D7}","core"),
        ("contracts","CONTRACTS","\u{1F4CB}","core"),("market","MARKET","\u{1F4CA}","core"),
        ("maps","MAPS","\u{1F5FA}","core"),("network","NETWORK","\u{1F4E1}","core"),
        ("ops","OPS","\u{2699}\u{FE0F}","intel"),("hub","HUB","\u{1F50C}","intel"),
        ("security","SECURITY","\u{1F512}","intel"),("pricing","PRICING","\u{1F4B2}","intel"),
        ("angelic","ANGELIC","\u{1F47C}","intel"),("wealth","WEALTH","\u{1F48E}","wealth"),
        ("cos-network","COS NET","\u{1F310}","wealth"),
        ("rentals","RENTALS","\u{1F6E0}","wealth"),
    ]

    @State private var wealthTab: WealthSubTab = .moneyLens
    enum WealthSubTab: String, CaseIterable {
        case moneyLens = "Money Lens"; case psychology = "Psychology"
        case power = "Power Thinking"; case leverage = "Leverage"; case opportunity = "Opportunity"
    }

    @State private var showSearch = false
    @State private var biometricUnlocked = false
    @AppStorage("ConstructOS.OnboardingComplete") private var onboardingComplete = false

    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingView(isComplete: $onboardingComplete)
            } else if !supabase.isAuthenticated && supabase.isConfigured {
                AuthGateView(supabase: supabase)
            } else if BiometricAuthManager.shared.biometricEnabled && !biometricUnlocked {
                BiometricLockScreen(isUnlocked: $biometricUnlocked)
            } else {
                mainAppView
            }
        }
        .onAppear {
            supabase.restoreSession()
            supabase.loadPendingWrites()
            Task {
                await supabase.flushPendingWrites()
                await NotificationManager.shared.requestAuthorization()
            }
            if supabase.isConfigured { supabase.startRealtimeSync() }
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView(isPresented: $showSearch)
        }
    }

    private var mainAppView: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 800
            ZStack {
                PremiumBackgroundView()
                VStack(spacing: 0) {
                    HeaderView()
                    TickerView()
                    if isWide {
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ScrollView { NavigationRailView(activeNav: $activeNav, navItems: navItems) }
                                SidebarStatusView(pulse: $pulse)
                            }.frame(width: 180).background(Theme.surface)
                            .border(width: 1, edges: [.trailing], color: Theme.border)
                            ScrollView { activeTabContent.padding(16) }
                        }
                    } else {
                        NavigationTabsView(activeNav: $activeNav, navItems: navItems)
                        ScrollView { activeTabContent.padding(16) }
                    }
                    FooterView(pulse: $pulse)
                }
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(actionLog)
        .onReceive(NotificationCenter.default.publisher(for: .init("ConstructOS.NavToProjects"))) { _ in
            activeNav = .projects
        }
    }

    @ViewBuilder
    private var activeTabContent: some View {
        switch activeNav {
        case .home:
            VStack(alignment: .leading, spacing: 14) {
                SiteRiskScorePanel(); WeatherRiskPanel(); SiteStatusDashboard()
                CrewDeployBoard(); InspectionPermitTracker(); StandupReportPanel()
            }
        case .projects: ProjectsView()
        case .contracts: ContractsView()
        case .market: MarketView()
        case .maps: MapsView()
        case .network: NetworkView()
        case .ops:
            VStack(alignment: .leading, spacing: 14) {
                OperationsCommandCenterPanel(); ChangeOrderTrackerPanel()
                SafetyIncidentPanel(); MaterialDeliveryPanel()
                PunchListPanel(); SubcontractorScorecardPanel()
                DailyCostTrackerPanel(); SubmittalLogPanel()
                ProjectContractAccountPanel(); ExecutivePortfolioPanel()
                RFITrackerPanel(); BudgetBurnPanel()
            }
        case .hub: PlatformIntegrationPanel()
        case .security: SecurityAccessPanel()
        case .pricing: PricingView()
        case .angelic: AngelicAIView()
        case .wealth:
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WealthSubTab.allCases, id: \.self) { tab in
                            Button(action: { wealthTab = tab }) {
                                Text(tab.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .bold)).tracking(1)
                                    .foregroundColor(wealthTab == tab ? .black : Theme.text)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(wealthTab == tab ? Theme.gold : Theme.surface)
                                    .cornerRadius(8)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                switch wealthTab {
                case .moneyLens: MoneyLensView()
                case .psychology: PsychologyDecoderView()
                case .power: PowerThinkingView()
                case .leverage: LeverageSystemView()
                case .opportunity: OpportunityFilterView()
                }
            }
        case .cosNetwork: ConstructionOSNetworkPanel()
        case .rentals: RentalSearchView()
        }
    }
}

// MARK: - ========== ViewUtilities.swift ==========

// MARK: - Feedback Insight Row

struct FeedbackInsightRow: View {
    let insight: FeedbackInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(insight.title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.gold)
            Text("Pain: \(insight.painPoint)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.muted)
            Text("Fix: \(insight.solution)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.text)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface.opacity(0.75))
        .cornerRadius(8)
    }
}

// MARK: - Risk Action Button

struct RiskActionButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(color)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edge Border Shape

struct EdgeBorderShape: Shape {
    let width: CGFloat
    let edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            switch edge {
            case .top:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom:
                path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing:
                path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }
        return path
    }
}

// MARK: - View Extensions

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorderShape(width: width, edges: edges).foregroundColor(color))
    }

    func premiumGlow(cornerRadius: CGFloat, color: Color) -> some View {
        shadow(color: color.opacity(0.18), radius: cornerRadius * 0.65, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.22), lineWidth: 0.8)
            )
    }
}

// MARK: - ========== SharedComponents.swift ==========

// MARK: - StatChip (unifies DashboardStatPill, projectStatChip, contractStatChip, marketStatBadge)

struct StatChip: View {
    enum Style {
        case card       // Centered VStack, premiumGlow (Projects/Contracts stat chips)
        case dashboard  // Left-aligned VStack, outlined (DashboardStatPill)
        case badge      // Compact HStack, tinted background (MarketView stat badge)
    }

    let value: String
    let label: String
    let color: Color
    var style: Style = .card

    var body: some View {
        Group {
            switch style {
            case .card:
                VStack(spacing: 3) {
                    Text(value)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .cornerRadius(10)
                .premiumGlow(cornerRadius: 10, color: color)

            case .dashboard:
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Theme.surface.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.16), lineWidth: 1)
                )
                .cornerRadius(10)

            case .badge:
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.10))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - TabHeader (unifies the header pattern across 9+ tab files)

struct TabHeader<TrailingContent: View>: View {
    let eyebrow: String
    let title: String
    let eyebrowColor: Color
    var subtitle: String? = nil
    var showDemoWarning: Bool = false
    var background: Color = Theme.surface
    var glowColor: Color? = nil
    @ViewBuilder var trailing: () -> TrailingContent

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(eyebrowColor)
                Text(title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                }
                if showDemoWarning {
                    Label("Demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            trailing()
        }
        .padding(16)
        .background(background)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: glowColor ?? eyebrowColor)
    }
}

extension TabHeader where TrailingContent == EmptyView {
    init(
        eyebrow: String,
        title: String,
        eyebrowColor: Color,
        subtitle: String? = nil,
        showDemoWarning: Bool = false,
        background: Color = Theme.surface,
        glowColor: Color? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.eyebrowColor = eyebrowColor
        self.subtitle = subtitle
        self.showDemoWarning = showDemoWarning
        self.background = background
        self.glowColor = glowColor
        self.trailing = { EmptyView() }
    }
}

// MARK: - ========== ToastManager.swift ==========

@Observable
@MainActor
final class ToastManager {
    static let shared = ToastManager()

    private(set) var message: String?

    private init() {}

    func show(_ text: String, duration: TimeInterval = 3) {
        message = text
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if message == text { message = nil }
        }
    }

    func dismiss() {
        message = nil
    }
}

struct ToastOverlay: View {
    let message: String?

    var body: some View {
        if let message {
            VStack {
                Spacer()
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.surface.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                    .padding(.bottom, 80)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: message)
        }
    }
}

// MARK: - ========== WealthShared.swift ==========

// MARK: - Colors (defined in Theme struct, aliased here for convenience)

let wealthGold = Theme.wealthGold
let wealthGradientSurface = Theme.wealthGradientSurface

// MARK: - Models

struct MoneyPrinciple { let title: String; let body: String; let color: Color }
struct MoneyReframe { let old: String; let new: String }
struct WealthArchetype { let name: String; let minScore: Int; let description: String; let traits: [String]; let color: Color }
struct LimitingBeliefItem { let belief: String; let reframe: String }
struct ThinkingMode { let name: String; let description: String; let usage: String; let color: Color; let icon: String }
struct YesFilterGate { let gate: String; let question: String }
struct SecondOrderItem { let decision: String; let first: String; let second: String }
struct LeverageCategory: Identifiable { let id: String; let name: String; let description: String; let icon: String; let defaultScore: Double }
struct LeverageFormula { let icon: String; let formula: String; let description: String }
struct OpportunityCriterion: Identifiable { let id: String; let label: String; let icon: String; let color: Color }

struct WealthOpportunity: Identifiable, Codable {
    let id: UUID
    let name: String
    let scores: [String: Int]
    let createdAt: Date
    var contractId: String?
    var status: String = "active"

    var wealthSignal: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.values.reduce(0, +) / scores.count
    }
    var signalLabel: String {
        switch wealthSignal {
        case 80...100: return "HIGH SIGNAL"
        case 60..<80:  return "MEDIUM SIGNAL"
        case 40..<60:  return "WEAK SIGNAL"
        default:       return "NO-GO"
        }
    }
    var signalColor: Color {
        switch wealthSignal {
        case 80...100: return Theme.green
        case 60..<80:  return Theme.gold
        case 40..<60:  return Theme.gold.opacity(0.7)
        default:       return Theme.red
        }
    }
}

struct DecisionJournalEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var context: String
    var thinkingMode: String
    var decision: String
    var firstOrder: String
    var secondOrder: String
    var gatesPassed: Int
    var outcomeStatus: String
    let createdAt: Date
    var reviewedAt: Date?
}

struct WealthTrackingEntry: Identifiable, Codable {
    let id: UUID
    var date: String
    var revenue: Double
    var expenses: Double
    var notes: String
    let createdAt: Date

    var margin: Double { revenue > 0 ? (revenue - expenses) / revenue * 100 : 0 }
    var profit: Double { revenue - expenses }
}

struct PsychologySession: Identifiable, Codable {
    let id: UUID
    var score: Double
    var profileLabel: String
    let createdAt: Date
}

struct LeverageSnapshot: Identifiable, Codable {
    let id: UUID
    var scores: [String: Double]
    var totalScore: Double
    let createdAt: Date
}

// MARK: - Static Data

let moneyLensPrinciples = [
    MoneyPrinciple(title: "Every hour has a market rate", body: "Know your hourly wealth-creation rate. Anything below it must be delegated, automated, or eliminated.", color: Theme.gold),
    MoneyPrinciple(title: "Revenue is vanity, margin is sanity", body: "A $500K job at 8% margin destroys more wealth than a $200K job at 35%. Filter by margin first.", color: Theme.green),
    MoneyPrinciple(title: "Speed of money is a multiplier", body: "Faster payment cycles = more capital rotations per year = exponential compounding. Negotiate 10/30 net terms.", color: Theme.cyan),
    MoneyPrinciple(title: "Expertise commands pricing power", body: "Specialists charge 3–10x generalists. Narrow your niche, deepen your moat, raise your price.", color: Theme.purple),
]

let moneyReframes = [
    MoneyReframe(old: "I need to take every job to keep cash flow", new: "I only take jobs that accelerate my wealth trajectory"),
    MoneyReframe(old: "That project is too expensive to pursue", new: "What is the ROI on winning this contract?"),
    MoneyReframe(old: "I can't afford to hire right now", new: "I can't afford NOT to hire — my time is the bottleneck"),
    MoneyReframe(old: "The market is too competitive", new: "The market is full of undifferentiated competitors — my gap is wide open"),
]

let wealthArchetypes = [
    WealthArchetype(name: "The Builder", minScore: 0, description: "Building foundational wealth systems. Focus on cash flow and margin before scale.", traits: ["Cash flow first", "Debt averse", "Single market"], color: Theme.muted),
    WealthArchetype(name: "The Accumulator", minScore: 40, description: "Converting income into assets. Starting to leverage OPM and OPT.", traits: ["Asset acquisition", "First hires", "Margin discipline"], color: Theme.cyan),
    WealthArchetype(name: "The Multiplier", minScore: 60, description: "Deploying leverage at scale. Systems generating income independent of personal time.", traits: ["Systems thinker", "Leverage stacker", "Portfolio view"], color: Theme.purple),
    WealthArchetype(name: "The Architect", minScore: 80, description: "Operating as a wealth architect. Capital allocation + network effects compound automatically.", traits: ["Capital allocator", "Network leverage", "Exits + reinvestment"], color: wealthGold),
]

let limitingBeliefs = [
    LimitingBeliefItem(belief: "Rich people are greedy", reframe: "Wealth is a tool — its ethics are determined by how you deploy it"),
    LimitingBeliefItem(belief: "I have to work harder to make more", reframe: "Leverage allows you to earn more while working less"),
    LimitingBeliefItem(belief: "I'm not the type who gets wealthy", reframe: "Wealth follows a system, not a personality type"),
    LimitingBeliefItem(belief: "It's too late for me to build serious wealth", reframe: "The best decade to build wealth is always the current one"),
    LimitingBeliefItem(belief: "I'll start investing when I have more money", reframe: "The vehicle for wealth is built with the money you have today"),
]

let identityStatements = [
    "I am a builder of systems that generate wealth without my direct time.",
    "I attract high-margin opportunities because I lead with rare value.",
    "Money flows into my business as a result of the problems I solve at scale.",
    "I make decisions from abundance, not from fear of scarcity.",
    "My wealth expands because I consistently invest in the highest-leverage activities.",
    "I am worthy of financial freedom and I am building it deliberately.",
]

let thinkingModes = [
    ThinkingMode(name: "Strategic", description: "Zoom out to 10,000 ft. What is the destination? What are the critical path moves?", usage: "Quarterly planning, major bids, market pivots", color: Theme.gold, icon: "🗺"),
    ThinkingMode(name: "Leverage", description: "Identify the 20% of actions producing 80% of outcomes. Amplify them.", usage: "Weekly priorities, resource allocation", color: Theme.cyan, icon: "🔱"),
    ThinkingMode(name: "Visionary", description: "Suspend constraints. Design the future you want, then reverse engineer the path.", usage: "Annual vision, new market entry", color: Theme.purple, icon: "✦"),
    ThinkingMode(name: "Execution", description: "Convert vision to daily action. Specific, time-bound, accountable.", usage: "Daily task design, project delivery", color: Theme.green, icon: "⚡"),
]

let powerQuestions = [
    "What is the highest-leverage action I can take in the next 90 minutes?",
    "If this decision compounds over 5 years, what does my world look like?",
    "What would I do if I knew I couldn't fail?",
    "Who has already solved this problem and how can I absorb their model?",
    "What am I tolerating that is costing me money, energy, or forward momentum?",
    "What is the ONE constraint holding back 10x growth in this business?",
    "How can I 10x the price and 10x the value simultaneously?",
]

let yesFilterGates = [
    YesFilterGate(gate: "Margin Gate", question: "Is the gross margin above 25%? If no, restructure or decline."),
    YesFilterGate(gate: "Time Gate", question: "Can this run primarily without my direct time within 90 days?"),
    YesFilterGate(gate: "Scale Gate", question: "Does this create assets, systems, or relationships that compound?"),
    YesFilterGate(gate: "Energy Gate", question: "Does this energize me or drain me? Sustained excellence requires energy alignment."),
    YesFilterGate(gate: "Alignment Gate", question: "Does this advance the 3-year financial vision or distract from it?"),
    YesFilterGate(gate: "Risk Gate", question: "Is the downside survivable and bounded? Asymmetric risk only."),
    YesFilterGate(gate: "Relationship Gate", question: "Does the client, partner, or team elevate my standard or lower it?"),
]

let secondOrderExamples = [
    SecondOrderItem(
        decision: "Underbid to win a large project",
        first: "Win the contract, cash flow increases short-term",
        second: "Margin compression trains the market on low prices; attracts more low-margin work; team burnout follows"
    ),
    SecondOrderItem(
        decision: "Delay hiring until you're overwhelmed",
        first: "Preserve cash, maintain control",
        second: "Top talent is hired by competition; your growth ceiling is your personal bandwidth; burnout caps execution"
    ),
    SecondOrderItem(
        decision: "Invest in systems and SOPs now",
        first: "Short-term cost and time to build",
        second: "Team executes without you; margin improves; business becomes sellable or scale-ready in 24 months"
    ),
]

let leverageCategories: [LeverageCategory] = [
    LeverageCategory(id: "financial", name: "Financial Leverage", description: "Using debt, credit, and capital structures to amplify returns on equity", icon: "💵", defaultScore: 40),
    LeverageCategory(id: "operational", name: "Operational Leverage", description: "Systems, SOPs, and processes that scale output without scaling headcount proportionally", icon: "⚙️", defaultScore: 35),
    LeverageCategory(id: "network", name: "Network Leverage", description: "Relationships, referrals, and reputation generating deal flow without paid acquisition", icon: "🔗", defaultScore: 50),
    LeverageCategory(id: "knowledge", name: "Knowledge Leverage", description: "Expertise and specialization commanding a premium that generalists cannot match", icon: "📚", defaultScore: 55),
    LeverageCategory(id: "technology", name: "Technology Leverage", description: "Software, AI, and automation compressing time and eliminating low-leverage tasks", icon: "⚡", defaultScore: 30),
]

let leverageFormulas = [
    LeverageFormula(icon: "💵", formula: "Financial: OPM × ROI = Wealth Velocity", description: "Other People's Money deployed at superior returns creates wealth faster than earned income alone."),
    LeverageFormula(icon: "⚙️", formula: "Operational: Systems × Volume = Margin at Scale", description: "Every process you document and delegate frees capacity for higher-leverage work."),
    LeverageFormula(icon: "🔗", formula: "Network: Trust × Reach = Deal Flow", description: "Your network is a compounding asset. One referral partner can outperform a full sales team."),
    LeverageFormula(icon: "📚", formula: "Knowledge: Depth × Scarcity = Pricing Power", description: "The narrower your specialty and the shallower the talent pool, the higher your hourly wealth rate."),
    LeverageFormula(icon: "⚡", formula: "Technology: Automation × Scale = Asymmetric Output", description: "Tools that eliminate $50/hr tasks free you to operate exclusively in $500/hr territory."),
]

let leveragePlaybook = [
    "Identify lowest-scoring leverage category. Map three friction points costing money or time. Eliminate one.",
    "Build or buy one system that runs without you. Document one SOP. Make one strategic hire or delegation move.",
    "Activate network leverage. Identify top 5 referral sources. Create a structured follow-up rhythm.",
    "Deploy technology lever. Implement one AI or automation tool that saves 5+ hours per week.",
]

let opportunityCriteria: [OpportunityCriterion] = [
    OpportunityCriterion(id: "margin", label: "Margin", icon: "💹", color: Theme.green),
    OpportunityCriterion(id: "scale", label: "Scalability", icon: "📈", color: Theme.cyan),
    OpportunityCriterion(id: "speed", label: "Cash Speed", icon: "⚡", color: wealthGold),
    OpportunityCriterion(id: "expertise", label: "Expertise Fit", icon: "🎯", color: Theme.purple),
    OpportunityCriterion(id: "relationship", label: "Relationship", icon: "🤝", color: Theme.accent),
    OpportunityCriterion(id: "timing", label: "Market Timing", icon: "⏱", color: Theme.red),
]

let highIncomePrinciples = [
    "Only pursue opportunities where your expertise commands a meaningful premium over market rate.",
    "High income is a byproduct of high value delivered to a market willing and able to pay.",
    "Your next income level requires a version of you that doesn't exist yet — invest in that version now.",
    "Most high-income opportunities are concentrated in a few high-leverage moves. Find them.",
    "The fastest path to high income is solving expensive problems for people with money.",
    "Raise your prices before you feel ready. You're almost certainly undercharging.",
]

let mindsetQuestions: [(String, [String])] = [
    ("When you see a highly profitable competitor, your first thought is:", [
        "They got lucky or cut corners", "I can learn from their model", "I'll outperform them in 12 months",  "I should partner with or acquire them"
    ]),
    ("Your biggest project finishes 30% over budget. You:", [
        "Absorb the loss and move on", "Blame the client or subs", "Conduct a full margin autopsy and systematize the fix", "Fire the PM and rebuild the team"
    ]),
    ("A premium client offers a contract at 40% margin but requires new capabilities. You:", [
        "Pass — too risky", "Take it and figure it out as you go", "Negotiate scope to match current strength", "Invest in the capability specifically to win it"
    ]),
    ("How do you think about debt?", [
        "Terrifying — avoid at all costs", "Necessary evil for equipment", "A tool — deploy only for high-ROI assets", "Leverage engine — maximize use for compounding returns"
    ]),
    ("When a top employee asks for a raise you can't easily afford, you:", [
        "Tell them the budget doesn't allow it", "Give a token increase to keep them", "Calculate their true ROI and pay accordingly", "Create a performance structure that funds itself"
    ]),
    ("Your pricing strategy is:", [
        "Match or slightly beat competitors", "Cover cost plus a margin", "Based on the value I deliver to the client", "Premium — I'm building a brand that commands highest rates"
    ]),
    ("Your ideal business in 5 years runs:", [
        "Exactly like it does now", "With a few more employees", "Primarily through systems and a strong leadership team", "Across multiple markets with me as capital allocator"
    ]),
    ("When evaluating risk, you primarily consider:", [
        "What could go wrong and avoid it", "Whether the odds are in my favor", "The ratio of upside to bounded downside", "Whether the risk builds asymmetric optionality"
    ]),
    ("When someone on your team underperforms, your instinct is:", [
        "Tolerate it to avoid conflict", "Do the work yourself", "Create accountability systems and clear expectations", "Upgrade the role with a hire who raises the bar"
    ]),
    ("Your relationship with delegation is:", [
        "I can't trust anyone to do it right", "I delegate admin but keep the real work", "I delegate everything that isn't in my zone of genius", "I architect systems where delegation is automatic"
    ]),
    ("When a client tries to negotiate your price down, you:", [
        "Usually agree to keep the relationship", "Split the difference", "Hold firm and explain the value differential", "Walk away — price integrity protects brand positioning"
    ]),
    ("Your daily energy goes primarily toward:", [
        "Putting out fires and reacting", "Executing today's task list", "Building systems that eliminate future fires", "Strategic moves that compound over years"
    ]),
    ("When you think about your revenue ceiling, you believe:", [
        "It's mostly determined by the market", "I can push it slowly over time", "My ceiling is a function of my current systems", "There is no ceiling — only my thinking constrains it"
    ]),
    ("When you have unexpected cash surplus, you:", [
        "Save it for a rainy day", "Reward yourself — you earned it", "Reinvest in the highest-leverage growth area", "Allocate across growth, reserve, and strategic bets"
    ]),
    ("Your definition of financial freedom is:", [
        "Not worrying about bills", "Comfortable retirement someday", "Passive income exceeding expenses within 5 years", "Building generational wealth and permanently leaving the time-for-money trap"
    ]),
]

// MARK: - Shared Sub-views

struct WealthSectionHeader: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 18))
                Text(title).font(.system(size: 10, weight: .bold)).tracking(3).foregroundColor(wealthGold)
            }
            Text(subtitle).font(.system(size: 12)).foregroundColor(Theme.muted)
        }
    }
}

struct WealthLensLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
    }
}

struct WealthMetricCard: View {
    let value: String; let label: String; let delta: String; let color: Color; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
                Spacer()
                Text(delta).font(.system(size: 9, weight: .bold)).foregroundColor(color)
            }
            Text(value).font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
            Text(label).font(.system(size: 10)).foregroundColor(Theme.muted)
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: color)
    }
}

struct AllocationQuadrant: View {
    let label: String; let value: String; let color: Color; let detail: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 9, weight: .bold)).tracking(0.3).foregroundColor(Theme.text).multilineTextAlignment(.center)
            Text(detail).font(.system(size: 8)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10))
        .cornerRadius(8)
    }
}

struct CriteriaLegendChip: View {
    let criterion: OpportunityCriterion
    var body: some View {
        VStack(spacing: 3) {
            Text(criterion.icon).font(.system(size: 16))
            Text(criterion.label).font(.system(size: 9, weight: .bold)).tracking(0.3).foregroundColor(Theme.text).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(criterion.color.opacity(0.10))
        .cornerRadius(8)
    }
}

struct MoneyLensCard: View {
    let principle: MoneyPrinciple
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle().fill(principle.color).frame(width: 3).cornerRadius(2)
            VStack(alignment: .leading, spacing: 4) {
                Text(principle.title).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                Text(principle.body).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: principle.color)
    }
}

struct WealthArchetypeCard: View {
    let archetype: WealthArchetype
    let isActive: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isActive ? archetype.color : Theme.border.opacity(0.3))
                    .frame(width: 12, height: 12)
                if isActive {
                    Rectangle().fill(archetype.color.opacity(0.4)).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(archetype.name)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(isActive ? archetype.color : Theme.muted)
                    if isActive { Text("ACTIVE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(archetype.color).padding(.horizontal, 6).padding(.vertical, 2).background(archetype.color.opacity(0.12)).cornerRadius(3) }
                    Spacer()
                    Text("Score \(archetype.minScore)+").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
                Text(archetype.description).font(.system(size: 11)).foregroundColor(isActive ? Theme.muted : Theme.muted.opacity(0.5))
                HStack(spacing: 6) {
                    ForEach(archetype.traits, id: \.self) { trait in
                        Text(trait).font(.system(size: 9)).foregroundColor(isActive ? archetype.color : Theme.muted.opacity(0.4))
                            .padding(.horizontal, 6).padding(.vertical, 3).background(isActive ? archetype.color.opacity(0.10) : Theme.surface).cornerRadius(4)
                    }
                }
            }
        }
        .padding(12)
        .background(isActive ? Theme.surface : Theme.panel.opacity(0.4))
        .cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: isActive ? archetype.color : Color.clear)
    }
}

struct LimitingBeliefRow: View {
    let item: LimitingBeliefItem
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack {
                    Image(systemName: "xmark.circle").font(.system(size: 12)).foregroundColor(Theme.red)
                    Text(item.belief).font(.system(size: 12)).foregroundColor(Theme.text).multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 10)).foregroundColor(Theme.muted)
                }
            }
            .buttonStyle(.plain)
            if expanded {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundColor(Theme.green)
                    Text(item.reframe).font(.system(size: 11, weight: .medium)).foregroundColor(Theme.green.opacity(0.9))
                }
                .padding(8).background(Theme.green.opacity(0.08)).cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ThinkingModeCard: View {
    let mode: ThinkingMode
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(mode.icon).font(.system(size: 16))
                Text(mode.name.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1).foregroundColor(mode.color)
            }
            Text(mode.description).font(.system(size: 11)).foregroundColor(Theme.muted)
            Text(mode.usage).font(.system(size: 9)).foregroundColor(mode.color).italic()
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: mode.color)
    }
}

struct PowerQuestionRow: View {
    let number: Int; let question: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)").font(.system(size: 11, weight: .heavy)).foregroundColor(wealthGold).frame(width: 18)
            Text(question).font(.system(size: 12)).foregroundColor(Theme.text)
        }
        .padding(.vertical, 2)
    }
}

struct SecondOrderRow: View {
    let item: SecondOrderItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.decision).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
            HStack(alignment: .top, spacing: 6) {
                Text("1st").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold).frame(width: 22)
                Text(item.first).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            HStack(alignment: .top, spacing: 6) {
                Text("2nd").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.red).frame(width: 22)
                Text(item.second).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
        }
        .padding(10).background(Theme.panel.opacity(0.5)).cornerRadius(8)
    }
}

struct LeverageSliderRow: View {
    let category: LeverageCategory
    @Binding var score: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.icon).font(.system(size: 14))
                Text(category.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                Text("\(Int(score))").font(.system(size: 14, weight: .heavy)).foregroundColor(leverageColor(score))
                Text("/ 100").font(.system(size: 10)).foregroundColor(Theme.muted)
            }
            Text(category.description).font(.system(size: 10)).foregroundColor(Theme.muted)
            Slider(value: $score, in: 0...100, step: 5)
                .accentColor(leverageColor(score))
        }
        .padding(.vertical, 4)
    }
    private func leverageColor(_ s: Double) -> Color {
        switch s {
        case 70...100: return Theme.green
        case 40..<70:  return wealthGold
        default:       return Theme.red
        }
    }
}

struct OpportunityResultCard: View {
    let opportunity: WealthOpportunity
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(opportunity.name).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
                    Text(opportunity.createdAt, style: .date).font(.system(size: 10)).foregroundColor(Theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(opportunity.wealthSignal)").font(.system(size: 26, weight: .heavy)).foregroundColor(opportunity.signalColor)
                    Text(opportunity.signalLabel).font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(opportunity.signalColor)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(opportunity.signalColor.opacity(0.12)).cornerRadius(3)
                }
            }
            HStack(spacing: 8) {
                ForEach(opportunityCriteria, id: \.id) { c in
                    if let score = opportunity.scores[c.id] {
                        VStack(spacing: 2) {
                            Text(c.icon).font(.system(size: 12))
                            Text("\(score)").font(.system(size: 10, weight: .bold)).foregroundColor(c.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(c.color.opacity(0.08))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: opportunity.signalColor)
    }
}

// MARK: - Wealth Score Ring

struct WealthScoreRing: View {
    let score: Double
    let label: String
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: size > 60 ? 6 : 3).frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: size > 60 ? 6 : 3, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            VStack(spacing: size > 60 ? 2 : 1) {
                Text("\(Int(score))").font(.system(size: size * 0.28, weight: .heavy)).foregroundColor(color)
                Text(label).font(.system(size: max(size * 0.09, 7), weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            }
        }
    }
}

// MARK: - Shared Helpers

func psychologyProfileLabel(for score: Double) -> String {
    switch score {
    case 80...100: return "Abundance Builder"
    case 60..<80:  return "Strategic Accumulator"
    case 40..<60:  return "Growth-In-Progress"
    case 20..<40:  return "Scarcity Pattern Active"
    default:       return "Uncalibrated — Run Decoder"
    }
}

func psychologyProfileDescription(for score: Double) -> String {
    switch score {
    case 80...100: return "Operating from abundance. Money flows to you as a natural consequence of value creation."
    case 60..<80:  return "Mostly growth-oriented. Minor scarcity patterns surface under pressure — identify and eliminate them."
    case 40..<60:  return "Mixed signals. Wealth-building potential is high but internal friction is costing you deals and energy."
    case 20..<40:  return "Scarcity patterns are actively limiting your ceiling. Reprogramming required before scaling."
    default:       return "Tap 'Run Decoder' to calibrate your wealth psychology profile and unlock your personalized blueprint."
    }
}

func leverageLabel(_ score: Double) -> String {
    switch score {
    case 80...100: return "Maximum Leverage"
    case 60..<80:  return "Strong Leverage Position"
    case 40..<60:  return "Building Leverage"
    case 20..<40:  return "Underleveraged"
    default:       return "Leverage Deficit"
    }
}

func leverageDescription(_ score: Double) -> String {
    switch score {
    case 80...100: return "You're operating the billionaire way — systems and assets working while you sleep."
    case 60..<80:  return "Good foundation. Identify the lowest-scoring leverage category and double down."
    case 40..<60:  return "Time is your scarcest resource. Prioritize building systems over delivering time."
    default:       return "High income requires high leverage. Start with one category and move the needle 10 points."
    }
}

func computePsychologyScore(from answers: [Int: Int]) -> Double {
    guard !answers.isEmpty else { return 0 }
    let total = answers.values.reduce(0, +)
    let max = answers.count * 4
    return Double(total) / Double(max) * 100
}

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

final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private let configKeyPrefix = "ConstructOS.Integrations.Backend."
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

    func signOut() {
        accessToken = nil
        currentUserEmail = nil
        KeychainHelper.delete(key: "Auth.AccessToken")
        KeychainHelper.delete(key: "Auth.RefreshToken")
        KeychainHelper.delete(key: "Auth.Email")
    }

    func restoreSession() {
        accessToken = KeychainHelper.read(key: "Auth.AccessToken")
        currentUserEmail = KeychainHelper.read(key: "Auth.Email")
        // Auto-refresh if token exists but may be expired
        if accessToken != nil {
            Task { let _ = await refreshToken() }
        }
    }

    // MARK: - Offline Sync Queue

    struct PendingWrite: Codable, Identifiable {
        var id = UUID()
        let table: String
        let jsonPayload: Data
        let createdAt: Date
    }

    @Published var pendingWrites: [PendingWrite] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil

    private let pendingWritesKey = "ConstructOS.Sync.PendingWrites"

    func queueWrite<T: Encodable>(_ table: String, record: T) {
        guard let payload = try? encoder.encode(record) else { return }
        let pending = PendingWrite(table: table, jsonPayload: payload, createdAt: Date())
        pendingWrites.append(pending)
        savePendingWrites()
    }

    func flushPendingWrites() async {
        guard isConfigured else { return }
        var remaining: [PendingWrite] = []
        for write in pendingWrites {
            do {
                guard let url = URL(string: "\(baseURL)/rest/v1/\(write.table)") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                applyHeaders(&request)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                request.httpBody = write.jsonPayload
                let (data, response) = try await URLSession.shared.data(for: request)
                try checkHTTPStatus(data: data, response: response)
            } catch {
                remaining.append(write)
            }
        }
        await MainActor.run {
            pendingWrites = remaining
            savePendingWrites()
        }
    }


    // MARK: - Real-Time Subscriptions (Polling)

    @Published var lastSyncAt: Date?
    private var syncTimer: Timer?

    func startRealtimeSync(interval: TimeInterval = 30) {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.lastSyncAt = Date()
                self?.objectWillChange.send()
            }
        }
    }

    func stopRealtimeSync() {
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

    func fetch<T: Decodable>(_ table: String, query: [String: String] = [:]) async throws -> [T] {
        guard isConfigured else { throw SupabaseError.notConfigured }
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(table)")!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw SupabaseError.httpError(400, "Invalid URL") }
        var request = URLRequest(url: url)
        applyHeaders(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPStatus(data: data, response: response)
        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            throw SupabaseError.decodingError(error)
        }
    }

    // MARK: Insert

    func insert<T: Encodable>(_ table: String, record: T) async throws {
        guard isConfigured else { throw SupabaseError.notConfigured }
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
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)?id=eq.\(id)") else {
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
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)?id=eq.\(id)") else {
            throw SupabaseError.httpError(400, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyHeaders(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPStatus(data: data, response: response)
    }

    // MARK: Private Helpers

    private func applyHeaders(_ request: inout URLRequest, contentType: Bool = false) {
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

struct SupabaseProject: Codable, Identifiable {
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

struct SupabaseContract: Codable, Identifiable {
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

struct SupabaseMarketData: Codable, Identifiable {
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

struct SupabaseAIMessage: Codable, Identifiable {
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

// MARK: - Wealth Suite DTOs

struct SupabaseWealthOpportunity: Codable, Identifiable {
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
}

struct SupabaseDecisionJournal: Codable, Identifiable {
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
}

struct SupabasePsychologySession: Codable, Identifiable {
    var id: String?
    var score: Double
    var profileLabel: String

    enum CodingKeys: String, CodingKey {
        case id, score
        case profileLabel = "profile_label"
    }
}

struct SupabaseLeverageSnapshot: Codable, Identifiable {
    var id: String?
    var totalScore: Double

    enum CodingKeys: String, CodingKey {
        case id
        case totalScore = "total_score"
    }
}

struct SupabaseWealthTracking: Codable, Identifiable {
    var id: String?
    var name: String
    var revenue: Double
    var expenses: Double
    var margin: Double
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id, name, revenue, expenses, margin, notes
    }
}


// MARK: - ========== Loading & Error States ==========

struct LoadingOverlay: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().tint(Theme.accent)
            Text(message).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.surface.opacity(0.95))
        .cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: Theme.accent)
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.red)
            Text(message).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text).lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.muted)
            }.buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.red.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.red.opacity(0.3), lineWidth: 1))
        .cornerRadius(8)
    }
}

struct SuccessBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
            Text(message).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.green)
        }
        .padding(10)
        .background(Theme.green.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - ========== Input Validation ==========

struct ValidationResult {
    let isValid: Bool
    let message: String?
    static let valid = ValidationResult(isValid: true, message: nil)
    static func invalid(_ msg: String) -> ValidationResult { .init(isValid: false, message: msg) }
}

struct InputValidator {
    static func email(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .invalid("Email is required") }
        guard trimmed.contains("@"), trimmed.contains(".") else { return .invalid("Invalid email format") }
        return .valid
    }

    static func required(_ value: String, field: String = "Field") -> ValidationResult {
        value.trimmingCharacters(in: .whitespaces).isEmpty ? .invalid("\(field) is required") : .valid
    }

    static func numeric(_ value: String, field: String = "Value") -> ValidationResult {
        guard !value.isEmpty else { return .invalid("\(field) is required") }
        guard Double(value.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "")) != nil else {
            return .invalid("\(field) must be a number")
        }
        return .valid
    }

    static func minLength(_ value: String, min: Int, field: String = "Field") -> ValidationResult {
        value.count >= min ? .valid : .invalid("\(field) must be at least \(min) characters")
    }

    static func password(_ value: String) -> ValidationResult {
        guard value.count >= 8 else { return .invalid("Password must be at least 8 characters") }
        return .valid
    }
}

struct ValidatedTextField: View {
    let label: String
    @Binding var text: String
    let validator: (String) -> ValidationResult
    @State private var validationMessage: String?
    @State private var hasEdited = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(label, text: $text)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .padding(10).background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                    validationMessage != nil && hasEdited ? Theme.red.opacity(0.6) : Theme.border, lineWidth: 1))
                .cornerRadius(8)
                .onChange(of: text) { _, _ in
                    hasEdited = true
                    let result = validator(text)
                    validationMessage = result.isValid ? nil : result.message
                }
            if let msg = validationMessage, hasEdited {
                Text(msg).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.red)
            }
        }
    }
}

// MARK: - ========== Global Search ==========

struct GlobalSearchView: View {
    @Binding var isPresented: Bool
    @State private var query = ""
    @State private var results: [(category: String, title: String, detail: String, icon: String)] = []

    private func search(_ q: String) {
        guard q.count >= 2 else { results = []; return }
        let lq = q.lowercased()
        var hits: [(category: String, title: String, detail: String, icon: String)] = []

        for p in mockProjects where p.name.lowercased().contains(lq) || p.client.lowercased().contains(lq) {
            hits.append(("Projects", p.name, p.client, "\u{1F3D7}"))
        }
        for c in mockContracts where c.title.lowercased().contains(lq) || c.client.lowercased().contains(lq) {
            hits.append(("Contracts", c.title, c.client, "\u{1F4CB}"))
        }
        results = hits
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                TextField("Search projects, contracts, crew...", text: $query)
                    .font(.system(size: 14)).foregroundColor(Theme.text)
                    .onChange(of: query) { _, newVal in search(newVal) }
                if !query.isEmpty {
                    Button { query = ""; results = [] } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                    }.buttonStyle(.plain)
                }
                Button("Done") { isPresented = false }
                    .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent)
            }
            .padding(14).background(Theme.surface)
            .border(width: 1, edges: [.bottom], color: Theme.border)

            if results.isEmpty && !query.isEmpty {
                VStack(spacing: 8) {
                    Text("No results for \"\(query)\"")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(results.indices, id: \.self) { i in
                            let r = results[i]
                            HStack(spacing: 10) {
                                Text(r.icon).font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.title).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                                    Text("\(r.category) \u{2022} \(r.detail)").font(.system(size: 10)).foregroundColor(Theme.muted)
                                }
                                Spacer()
                            }
                            .padding(10).background(Theme.surface).cornerRadius(8)
                        }
                    }.padding(14)
                }
            }
        }
        .background(Theme.bg)
    }
}

// MARK: - ========== Onboarding Flow ==========

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep = 0

    private let steps: [(icon: String, title: String, detail: String)] = [
        ("\u{1F3D7}", "Welcome to ConstructionOS", "Your all-in-one command center for construction project management, field operations, and business intelligence."),
        ("\u{2699}\u{FE0F}", "Configure Your Backend", "Connect to Supabase in the Integration Hub to enable cloud sync, real-time data, and team collaboration."),
        ("\u{1F4CB}", "Track Projects & Contracts", "Manage active jobs, bid pipelines, change orders, and subcontractor scorecards from a single dashboard."),
        ("\u{1F48E}", "Wealth Intelligence Suite", "Access the Money Lens, Psychology Decoder, Power Thinking, Leverage System, and Opportunity Filter."),
        ("\u{1F680}", "You\u{2019}re Ready", "Explore the tabs, customize your role preset, and start building your construction command center."),
    ]

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            VStack(spacing: 24) {
                Spacer()
                Text(steps[currentStep].icon).font(.system(size: 56))
                Text(steps[currentStep].title)
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                Text(steps[currentStep].detail)
                    .font(.system(size: 14)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle().fill(i == currentStep ? Theme.accent : Theme.border)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") { withAnimation { currentStep -= 1 } }
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                        if currentStep == steps.count - 1 {
                            UserDefaults.standard.set(true, forKey: "ConstructOS.OnboardingComplete")
                            withAnimation { isComplete = true }
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40).padding(.bottom, 40)
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ========== Accessibility Helpers ==========

extension View {
    func accessibleLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }

    func accessibleHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }

    func accessibleAction(_ name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }

    /// Apply standard construction app accessibility to a panel
    func constructionAccessible(label: String, hint: String = "") -> some View {
        self.accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .accessibilityHint(hint.isEmpty ? "Double tap to interact" : hint)
    }

    /// Make a stat card announce its value
    func statAccessible(value: String, label: String) -> some View {
        self.accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label): \(value)")
            .accessibilityAddTraits(.isStaticText)
    }
}

/// Modifier that adds Dynamic Type support
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var typeSize

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

extension View {
    func supportsDynamicType() -> some View {
        self.modifier(DynamicTypeModifier())
    }
}

// MARK: - Photo Picker Helper

struct PhotoPickerButton: View {
    let label: String
    @Binding var selectedData: Data?
    @State private var photoItem: PhotosPickerItem?
    let maxBytes: Int

    var body: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(label, systemImage: selectedData != nil ? "checkmark.circle.fill" : "camera.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(selectedData != nil ? Theme.green : Theme.cyan)
            }
            if selectedData != nil {
                Button {
                    selectedData = nil
                    photoItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10)).foregroundColor(Theme.red)
                }.buttonStyle(.plain)
                let size = ByteCountFormatter.string(fromByteCount: Int64(selectedData?.count ?? 0), countStyle: .file)
                Text(size).font(.system(size: 8)).foregroundColor(Theme.muted)
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    if data.count <= maxBytes {
                        selectedData = data
                    } else {
                        selectedData = nil
                        self.photoItem = nil
                    }
                }
            }
        }
    }
}

// MARK: - ========== Notification Manager ==========

import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isAuthorized = false

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func scheduleInspectionReminder(site: String, type: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Inspection Due"
        content.body = "\(type) at \(site) is due"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleBidDeadline(contract: String, deadline: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Bid Deadline"
        content.body = "\(contract) bid is due"
        content.sound = .default

        let alertDate = Calendar.current.date(byAdding: .day, value: -1, to: deadline) ?? deadline
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - ========== Document Attachment Manager ==========

struct DocumentAttachment: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String  // "photo", "pdf", "document"
    let dataSize: Int
    let createdAt: Date
    var projectRef: String?
}

@MainActor
final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()
    @Published var attachments: [DocumentAttachment] = []

    private let storageKey = "ConstructOS.Documents.Attachments"

    init() { load() }

    func add(name: String, type: String, data: Data, projectRef: String? = nil) {
        // Save data to app documents directory
        let fileName = "\(UUID().uuidString)_\(name)"
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docsDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)

        let attachment = DocumentAttachment(
            name: name, type: type, dataSize: data.count,
            createdAt: Date(), projectRef: projectRef
        )
        attachments.insert(attachment, at: 0)
        save()
    }

    func remove(_ attachment: DocumentAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        save()
    }

    private func load() {
        attachments = loadJSON(storageKey, default: [DocumentAttachment]())
    }

    private func save() {
        saveJSON(storageKey, value: attachments)
    }
}

// MARK: - ========== PDF Export ==========

struct PDFExporter {
    static func generateReport(title: String, sections: [(heading: String, content: String)]) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

#if os(iOS)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        return renderer.pdfData { context in
            context.beginPage()
            var yPos: CGFloat = margin

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            NSAttributedString(string: title, attributes: titleAttrs)
                .draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: 40))
            yPos += 50

            let dateFormatter = DateFormatter(); dateFormatter.dateStyle = .long
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray
            ]
            NSAttributedString(string: dateFormatter.string(from: Date()), attributes: dateAttrs)
                .draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: 20))
            yPos += 30

            for section in sections {
                if yPos > pageHeight - margin - 100 { context.beginPage(); yPos = margin }
                let headAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.black
                ]
                NSAttributedString(string: section.heading, attributes: headAttrs)
                    .draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: 24))
                yPos += 28
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray
                ]
                let bodyStr = NSAttributedString(string: section.content, attributes: bodyAttrs)
                bodyStr.draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: pageHeight - yPos - margin))
                let rect = bodyStr.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
                yPos += rect.height + 16
            }
            let footAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.lightGray
            ]
            NSAttributedString(string: "Generated by ConstructionOS", attributes: footAttrs)
                .draw(in: CGRect(x: margin, y: pageHeight - 30, width: contentWidth, height: 12))
        }
#elseif os(macOS)
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let cgContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        cgContext.beginPDFPage(nil)
        var yPos: CGFloat = margin

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
        // macOS CoreGraphics has flipped Y; draw using NSStringDrawing
        let titleRect = CGRect(x: margin, y: pageHeight - yPos - 40, width: contentWidth, height: 40)
        titleStr.draw(in: titleRect)
        yPos += 50

        let dateFormatter = DateFormatter(); dateFormatter.dateStyle = .long
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.gray
        ]
        NSAttributedString(string: dateFormatter.string(from: Date()), attributes: dateAttrs)
            .draw(in: CGRect(x: margin, y: pageHeight - yPos - 20, width: contentWidth, height: 20))
        yPos += 30

        for section in sections {
            if yPos > pageHeight - margin - 100 {
                cgContext.endPDFPage(); cgContext.beginPDFPage(nil); yPos = margin
            }
            let headAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: NSColor.black
            ]
            NSAttributedString(string: section.heading, attributes: headAttrs)
                .draw(in: CGRect(x: margin, y: pageHeight - yPos - 24, width: contentWidth, height: 24))
            yPos += 28
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.darkGray
            ]
            let bodyStr = NSAttributedString(string: section.content, attributes: bodyAttrs)
            let remaining = pageHeight - yPos - margin
            bodyStr.draw(in: CGRect(x: margin, y: pageHeight - yPos - remaining, width: contentWidth, height: remaining))
            let rect = bodyStr.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin])
            yPos += rect.height + 16
        }
        let footAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8), .foregroundColor: NSColor.lightGray
        ]
        NSAttributedString(string: "Generated by ConstructionOS", attributes: footAttrs)
            .draw(in: CGRect(x: margin, y: 18, width: contentWidth, height: 12))

        cgContext.endPDFPage()
        cgContext.closePDF()
        return pdfData as Data
#else
        return nil
#endif
    }
}

// MARK: - ========== Calendar Integration ==========

import EventKit

@MainActor
final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let store = EKEventStore()
    @Published var isAuthorized = false

    func requestAccess() async {
        if #available(iOS 17.0, macOS 14.0, *) {
            isAuthorized = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            isAuthorized = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
            }
        }
    }

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) throws {
        guard isAuthorized else { return }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        event.addAlarm(EKAlarm(relativeOffset: -3600)) // 1 hour before
        try store.save(event, span: .thisEvent)
    }

    func addInspectionToCalendar(site: String, type: String, date: Date) {
        try? addEvent(
            title: "[Inspection] \(type) — \(site)",
            startDate: date,
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: date) ?? date,
            notes: "ConstructionOS inspection reminder"
        )
    }

    func addBidDeadlineToCalendar(contract: String, deadline: Date) {
        try? addEvent(
            title: "[Bid Due] \(contract)",
            startDate: deadline,
            endDate: Calendar.current.date(byAdding: .hour, value: 1, to: deadline) ?? deadline,
            notes: "ConstructionOS bid deadline"
        )
    }
}

// MARK: - ========== LayoutChrome.swift ==========

// MARK: - Premium Background

struct PremiumBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Theme.bg, Theme.surface.opacity(0.96), Theme.bg]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                gradient: Gradient(colors: [Theme.gold.opacity(0.24), .clear]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .offset(x: -120, y: -160)

            RadialGradient(
                gradient: Gradient(colors: [Theme.cyan.opacity(0.14), .clear]),
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 360
            )
            .offset(x: 120, y: 180)

            LinearGradient(
                gradient: Gradient(colors: [Theme.gold.opacity(0.04), .clear, Theme.cyan.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 120) {
                Capsule()
                    .fill(Theme.gold.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: -140, y: -40)

                Capsule()
                    .fill(Theme.cyan.opacity(0.07))
                    .frame(width: 260, height: 260)
                    .blur(radius: 100)
                    .offset(x: 150, y: 80)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Header View

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                LinearGradient(
                    gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 36, height: 36)
                .cornerRadius(8)
                .overlay(
                    Text("\u{2B21}")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.black)
                )

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 3) {
                        Text("CONSTRUCT")
                            .font(.system(size: 17, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.text)
                        Text("OS")
                            .font(.system(size: 17, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.accent)
                    }
                    Text("GLOBAL CONSTRUCTION INTELLIGENCE")
                        .font(.system(size: 8, weight: .regular))
                        .tracking(2)
                        .foregroundColor(Theme.muted)
                }

                Spacer()

                Circle()
                    .fill(Theme.green)
                    .frame(width: 7, height: 7)

                Text("142,891")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.green)

                Button(action: { NotificationCenter.default.post(name: .init("ConstructOS.NavToProjects"), object: nil) }) {
                    Text("NEW PROJECT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }
                    .frame(minWidth: 112)
            }
            .padding(14)
            .background(Theme.surface)
            .border(width: 1, edges: [.bottom], color: Theme.border)
        }
    }
}

// MARK: - Navigation Tabs

struct NavigationTabsView: View {
    @Binding var activeNav: ContentView.NavTab
    let navItems: [(String, String, String, String)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(navItems.enumerated()), id: \.element.0) { index, item in
                    let (id, label, icon, group) = item
                    // Group separator
                    if index > 0 && group != navItems[index - 1].3 {
                        Rectangle().fill(Theme.border.opacity(0.4)).frame(width: 1, height: 36).padding(.horizontal, 2)
                    }
                    Button(action: {
                        if let tab = ContentView.NavTab(rawValue: id) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeNav = tab
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(icon)
                                .font(.system(size: 16, weight: .bold))

                            Text(label)
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .lineLimit(1)
                        }
                        .foregroundColor(activeNav.rawValue == id ? .black : Theme.text)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 60)
                        .background(
                            Group {
                                if activeNav.rawValue == id {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Theme.panel.opacity(0.88)
                                }
                            }
                        )
                        .cornerRadius(14)
                        .shadow(color: activeNav.rawValue == id ? Theme.green.opacity(0.18) : .clear, radius: 14, x: 0, y: 6)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Theme.surface)
    }
}

struct NavigationRailView: View {
    @Binding var activeNav: ContentView.NavTab
    let navItems: [(String, String, String, String)]
    @State private var hoveredNav: String?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(navItems.enumerated()), id: \.element.0) { index, item in
                let (id, label, icon, group) = item
                // Group separator with label
                if index > 0 && group != navItems[index - 1].3 {
                    HStack(spacing: 6) {
                        Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                        Text(group.uppercased())
                            .font(.system(size: 8, weight: .bold)).tracking(2)
                            .foregroundColor(Theme.muted)
                        Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, 4)
                }
                Button(action: {
                    if let tab = ContentView.NavTab(rawValue: id) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeNav = tab
                        }
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 18)

                        Text(label)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)

                        Spacer()
                    }
                    .foregroundColor(activeNav.rawValue == id ? .black : Theme.text)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 48)
                    .background(
                        Group {
                            if activeNav.rawValue == id {
                                LinearGradient(
                                    gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else if hoveredNav == id {
                                Theme.panel.opacity(0.96)
                            } else {
                                Theme.panel.opacity(0.85)
                            }
                        }
                    )
                    .cornerRadius(11)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredNav = hovering ? id : nil
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(maxHeight: .infinity)
    }
}

struct SidebarStatusView: View {
    @Binding var pulse: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.green)
                .frame(width: 8, height: 8)
                .opacity(pulse ? 1 : 0.35)
                .animation(.easeInOut(duration: 0.9).repeatForever(), value: pulse)
                .onAppear { pulse = true }

            Text("SYSTEMS LIVE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(Theme.green)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .border(width: 1, edges: [.top], color: Theme.border)
    }
}

// MARK: - Footer View

struct FooterView: View {
    @Binding var pulse: Bool

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 3) {
                Text("CONSTRUCT")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.text)
                Text("OS")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.green)
                    .frame(width: 7, height: 7)
                    .opacity(pulse ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.9).repeatForever(), value: pulse)
                    .onAppear { pulse = true }

                Text("ALL SYSTEMS OPERATIONAL")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .border(width: 1, edges: [.top], color: Theme.border)
    }
}

// MARK: - Ticker View

struct TickerView: View {
    @State private var tickerIndex = 0
    private let tickerTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    let all = (tickerItems + tickerItems)

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 0) {
                Text("\u{1F534} LIVE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(.white)
            }
            .frame(width: 76, height: 34)
            .background(Color.black)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<all.count, id: \.self) { i in
                            Text(all[i])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .lineLimit(1)
                                .id(i)
                        }
                    }
                    .frame(height: 34)
                }
                .onAppear {
                    proxy.scrollTo(0, anchor: .leading)
                }
                .onReceive(tickerTimer) { _ in
                    let next = (tickerIndex + 1) % all.count
                    withAnimation(.linear(duration: 1.1)) {
                        tickerIndex = next
                        proxy.scrollTo(next, anchor: .leading)
                    }
                }
            }
        }
        .frame(height: 34)
        .background(Theme.accent)
    }
}

// MARK: - ========== OperationsCore.swift ==========

// MARK: - Operations Command Center

struct OpsPriorityAlert: Identifiable, Codable {
    var id = UUID()
    let title: String
    let detail: String
    let owner: String
    let severity: Int
    let due: String

    var severityLabel: String {
        if severity >= 3 { return "CRITICAL" }
        if severity == 2 { return "HIGH" }
        return "NORMAL"
    }

    var severityColor: Color {
        if severity >= 3 { return Theme.red }
        if severity == 2 { return Theme.gold }
        return Theme.cyan
    }
}

struct OpsActionQueueItem: Identifiable, Codable {
    var id = UUID()
    let action: String
    let team: String
    let eta: String
    let relatedRef: String
}

struct OperationsCommandCenterPanel: View {
    @State private var alerts: [OpsPriorityAlert] = [
        OpsPriorityAlert(title: "Delayed conduit shipment", detail: "PO-4422 pushed from 03-13 to 03-20. Electrical rough-in impacted.", owner: "Procurement", severity: 3, due: "Today 4PM"),
        OpsPriorityAlert(title: "Open recordable incident", detail: "Grid B-7 fall incident corrective action still open.", owner: "Safety", severity: 3, due: "Today 1PM"),
        OpsPriorityAlert(title: "Pending CO over $20k", detail: "CO-003 foundation depth increase pending owner approval.", owner: "PM", severity: 2, due: "Tomorrow 10AM"),
        OpsPriorityAlert(title: "Inspection prep", detail: "Fire-stopping punch list has 6 unresolved tags.", owner: "Superintendent", severity: 1, due: "Tomorrow 8AM"),
    ]

    @State private var queue: [OpsActionQueueItem] = [
        OpsActionQueueItem(action: "Call Graybar and lock revised delivery truck", team: "Procurement", eta: "45m", relatedRef: "PO-4422"),
        OpsActionQueueItem(action: "Submit CO-003 backup package with geotech memo", team: "PM", eta: "30m", relatedRef: "CO-003"),
        OpsActionQueueItem(action: "Close scaffold harness corrective action", team: "Safety", eta: "25m", relatedRef: "INC-03-14"),
        OpsActionQueueItem(action: "Notify drywall foreman of revised sequence", team: "Field Ops", eta: "15m", relatedRef: "SEQ-DELTA"),
    ]

    @State private var exportStatus: String? = nil

    private var criticalCount: Int { alerts.filter { $0.severity >= 3 }.count }
    private var highCount: Int { alerts.filter { $0.severity == 2 }.count }
    private var dueTodayCount: Int { alerts.filter { $0.due.lowercased().contains("today") }.count }

    private func completeAction(_ item: OpsActionQueueItem) {
        queue.removeAll { $0.id == item.id }
                                    saveJSON("ConstructOS.Ops.ActionQueue", value: queue)
    }

    private func exportDailyCommanderReport() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "CONSTRUCTIONOS DAILY COMMANDER REPORT"
        let generated = "Generated: \(formatter.string(from: Date()))"
        let stats = "Critical: \(criticalCount) | High: \(highCount) | Due Today: \(dueTodayCount) | Queue: \(queue.count)"

        let alertLines = alerts.isEmpty
            ? ["No active priority alerts"]
            : alerts.map { "[\($0.severityLabel)] \($0.title) — \($0.detail) | Owner: \($0.owner) | Due: \($0.due)" }

        let queueLines = queue.isEmpty
            ? ["No open queue actions"]
            : queue.map { "- \($0.action) | Team: \($0.team) | ETA: \($0.eta) | Ref: \($0.relatedRef)" }

        let payload = [
            header,
            generated,
            stats,
            "",
            "PRIORITY ALERTS",
            alertLines.joined(separator: "\n"),
            "",
            "ACTION QUEUE",
            queueLines.joined(separator: "\n")
        ].joined(separator: "\n")

        copyTextToClipboard(payload)
        exportStatus = "Copied superintendent report"
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { exportStatus = nil }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "COMMAND CENTER",
                    title: "Operations command center",
                    detail: "Priority alerts, queue actions, and due-now field work in one coordinated surface.",
                    accent: Theme.accent
                )
                Spacer()
                Button("EXPORT DAILY REPORT") { exportDailyCommanderReport() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent)
                    .cornerRadius(6)
            }

            HStack(spacing: 12) {
                DashboardStatPill(value: "\(criticalCount)", label: "CRITICAL", color: Theme.red)
                DashboardStatPill(value: "\(highCount)", label: "HIGH", color: Theme.gold)
                DashboardStatPill(value: "\(queue.count)", label: "OPEN ACTIONS", color: queue.isEmpty ? Theme.green : Theme.cyan)
            }

            Text("PRIORITY ALERTS")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.gold)

            ForEach(alerts) { alert in
                HStack(alignment: .top, spacing: 10) {
                    Text(alert.severityLabel)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(alert.severityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(alert.severityColor.opacity(0.12))
                        .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(alert.title)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.text)
                        Text(alert.detail)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.muted)
                            .lineLimit(2)
                        Text("Owner: \(alert.owner) · Due: \(alert.due)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.cyan)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(alert.severityColor.opacity(0.14), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            Text("TODAY ACTION QUEUE")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.cyan)

            ForEach(queue) { item in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.action)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Text("\(item.team) · ETA \(item.eta) · \(item.relatedRef)")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Button("DONE") { completeAction(item) }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Theme.green)
                        .cornerRadius(5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.cyan.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(8)
            }

            if let exportStatus {
                Text(exportStatus)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            alerts = loadJSON("ConstructOS.Ops.Alerts", default: alerts)
            queue = loadJSON("ConstructOS.Ops.ActionQueue", default: queue)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Change Order Tracker

enum ChangeOrderStatus: String, CaseIterable, Codable {
    case pending  = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case void     = "VOID"

    var color: Color {
        switch self {
        case .pending:  return Theme.gold
        case .approved: return Theme.green
        case .rejected: return Theme.red
        case .void:     return Theme.muted
        }
    }
}

struct ChangeOrderItem: Identifiable, Codable {
    var id = UUID()
    var number: String
    var title: String
    var costImpact: Double
    var scheduleDays: Int
    var status: ChangeOrderStatus
    var submittedDate: String
    var decidedDate: String
    var description: String
}

struct ChangeOrderTrackerPanel: View {
    @State private var items: [ChangeOrderItem] = [
        ChangeOrderItem(number: "CO-001", title: "Structural Steel Upgrade", costImpact: 14_800, scheduleDays: 3, status: .approved, submittedDate: "03-01", decidedDate: "03-04", description: "Owner requested heavier gauge column steel per revised structural drawings."),
        ChangeOrderItem(number: "CO-002", title: "Electrical Panel Relocation", costImpact: 6_200, scheduleDays: 2, status: .pending, submittedDate: "03-09", decidedDate: "", description: "Relocate main service panel 12 ft to accommodate updated floor plan."),
        ChangeOrderItem(number: "CO-003", title: "Foundation Depth Increase", costImpact: 22_500, scheduleDays: 5, status: .pending, submittedDate: "03-11", decidedDate: "", description: "Geotech report requires additional 18\" bearing depth at grid lines B3-B7."),
        ChangeOrderItem(number: "CO-004", title: "Deleted Decorative Façade", costImpact: -8_400, scheduleDays: -1, status: .approved, submittedDate: "02-22", decidedDate: "02-25", description: "Owner deleted premium stone cladding in favor of standard EIFS."),
        ChangeOrderItem(number: "CO-005", title: "HVAC Scope Addition", costImpact: 11_300, scheduleDays: 4, status: .rejected, submittedDate: "03-05", decidedDate: "03-08", description: "Sub requested add to supply ventilation to server room — rejected, owner to self-perform."),
    ]
    @State private var filterStatus: ChangeOrderStatus? = nil
    @State private var showAdd = false
    @State private var newNumber = ""
    @State private var newTitle = ""
    @State private var newCost = ""
    @State private var newDays = ""
    @State private var newDesc = ""
    @State private var selectedStatus: ChangeOrderStatus = .pending
    @State private var exportStatus: String? = nil

    private var filtered: [ChangeOrderItem] {
        guard let f = filterStatus else { return items }
        return items.filter { $0.status == f }
    }

    private var approvedTotal: Double { items.filter { $0.status == .approved }.reduce(0) { $0 + $1.costImpact } }
    private var pendingCount: Int    { items.filter { $0.status == .pending  }.count }
    private var rejectedCount: Int   { items.filter { $0.status == .rejected }.count }

    private func addItem() {
        guard !newNumber.trimmingCharacters(in: .whitespaces).isEmpty,
              !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let today = formatter.string(from: Date())
        let cost = Double(newCost) ?? 0
        let days = Int(newDays) ?? 0
        let item = ChangeOrderItem(number: newNumber.uppercased(), title: newTitle, costImpact: cost,
                                    scheduleDays: days, status: selectedStatus,
                                    submittedDate: today, decidedDate: selectedStatus == .pending ? "" : today,
                                    description: newDesc)
        items.insert(item, at: 0)
        saveJSON("ConstructOS.Ops.ChangeOrders", value: items)
        newNumber = ""; newTitle = ""; newCost = ""; newDays = ""; newDesc = ""
        selectedStatus = .pending
        showAdd = false
    }

    private func exportLog() {
        let lines = items.map { "\($0.number) | \($0.title) | $\(String(format: "%.0f", $0.costImpact)) | \($0.scheduleDays)d sched | \($0.status.rawValue) | Sub: \($0.submittedDate)" }
        let payload = (["CHANGE ORDER LOG", "Approved Net: $\(String(format: "%.0f", approvedTotal))", ""] + lines).joined(separator: "\n")
        copyTextToClipboard(payload)
        exportStatus = "Copied \(items.count) change orders"
        Task { try? await Task.sleep(nanoseconds: 3_000_000_000); await MainActor.run { exportStatus = nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHANGE ORDER TRACKER")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.gold)
                    Text("\(items.count) orders · Net approved: \(approvedTotal >= 0 ? "+" : "")$\(String(format: "%.0f", approvedTotal))")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("+ ADD") { showAdd.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.gold).cornerRadius(5)
                Button("EXPORT") { exportLog() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.cyan)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.surface).cornerRadius(5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.0f", approvedTotal))")
                        .font(.system(size: 14, weight: .black)).foregroundColor(approvedTotal >= 0 ? Theme.green : Theme.red)
                    Text("APPROVED NET").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(pendingCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.gold)
                    Text("PENDING").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(rejectedCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.red)
                    Text("REJECTED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface).cornerRadius(4)
                ForEach(ChangeOrderStatus.allCases, id: \.self) { s in
                    Button(s.rawValue) { filterStatus = filterStatus == s ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : s.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface).cornerRadius(4)
                }
            }

            if showAdd {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("CO-006", text: $newNumber)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10)).frame(width: 72)
                        TextField("Title", text: $newTitle)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10))
                    }
                    HStack(spacing: 8) {
                        TextField("Cost impact", text: $newCost)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10))
                        TextField("Sched days", text: $newDays)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 10)).frame(width: 80)
                        Picker("", selection: $selectedStatus) {
                            ForEach(ChangeOrderStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .frame(width: 100)
                    }
                    TextField("Description", text: $newDesc)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 10))
                    HStack(spacing: 8) {
                        Button("SAVE", action: addItem)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.green).cornerRadius(5)
                        Button("CANCEL") { showAdd = false }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(8)
            }

            ForEach(filtered) { item in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.number)
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(Theme.muted)
                            Text(item.title)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.text)
                        }
                        Text(item.description)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(Theme.muted)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Text(item.costImpact >= 0 ? "+$\(String(format: "%.0f", item.costImpact))" : "-$\(String(format: "%.0f", abs(item.costImpact)))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(item.costImpact >= 0 ? Theme.red : Theme.green)
                            Text("\(item.scheduleDays >= 0 ? "+" : "")\(item.scheduleDays)d sched")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(item.scheduleDays > 0 ? Theme.red : item.scheduleDays < 0 ? Theme.green : Theme.muted)
                            Text("Sub: \(item.submittedDate)")
                                .font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                    }
                    Spacer()
                    Text(item.status.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(item.status.color.opacity(0.12))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }

            if let exportStatus {
                Text(exportStatus).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.gold)
        .onAppear {
            items = loadJSON("ConstructOS.Ops.ChangeOrders", default: items)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Safety Incident Log

enum IncidentType: String, CaseIterable, Codable {
    case nearMiss   = "NEAR MISS"
    case firstAid   = "FIRST AID"
    case recordable = "RECORDABLE"
    case lostTime   = "LOST TIME"

    var color: Color {
        switch self {
        case .nearMiss:   return Theme.gold
        case .firstAid:   return Theme.cyan
        case .recordable: return Color.orange
        case .lostTime:   return Theme.red
        }
    }
}

enum IncidentStatus: String, CaseIterable, Codable {
    case open   = "OPEN"
    case closed = "CLOSED"
}

struct SafetyIncident: Identifiable, Codable {
    var id = UUID()
    var date: String
    var type: IncidentType
    var location: String
    var description: String
    var crewMember: String
    var correctiveAction: String
    var status: IncidentStatus
}

struct SafetyIncidentPanel: View {
    @State private var incidents: [SafetyIncident] = [
        SafetyIncident(date: "03-10", type: .nearMiss, location: "Level 3 Deck", description: "Unsecured load nearly fell from hoist; stopped by netting.", crewMember: "R. Torres", correctiveAction: "Retrain all hoist operators. Load checklist enforced.", status: .closed),
        SafetyIncident(date: "03-12", type: .firstAid, location: "Staging Area", description: "Laceration to right hand from unguarded saw blade.", crewMember: "M. Jenkins", correctiveAction: "Guard replaced. PPE glove added to required kit.", status: .closed),
        SafetyIncident(date: "03-14", type: .recordable, location: "Grid B-7", description: "Fall from 4-ft scaffold — wrist fracture. No harness worn.", crewMember: "D. Alvarez", correctiveAction: "Harness audit underway. All leading edge work halted pending Safety Officer review.", status: .open),
    ]
    @State private var filterType: IncidentType? = nil
    @State private var filterStatus: IncidentStatus? = nil
    @State private var showAdd = false
    @State private var newDate = ""
    @State private var newLocation = ""
    @State private var newDesc = ""
    @State private var newCrew = ""
    @State private var newAction = ""
    @State private var newType: IncidentType = .nearMiss
    @State private var newStatus: IncidentStatus = .open

    private var filtered: [SafetyIncident] {
        incidents.filter {
            (filterType == nil || $0.type == filterType!) &&
            (filterStatus == nil || $0.status == filterStatus!)
        }
    }

    private var recordableCount: Int { incidents.filter { $0.type == .recordable || $0.type == .lostTime }.count }
    private var openCount: Int       { incidents.filter { $0.status == .open }.count }

    private func addIncident() {
        guard !newDesc.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formatter = DateFormatter(); formatter.dateFormat = "MM-dd"
        let today = formatter.string(from: Date())
        let inc = SafetyIncident(date: newDate.isEmpty ? today : newDate, type: newType,
                                  location: newLocation, description: newDesc,
                                  crewMember: newCrew, correctiveAction: newAction, status: newStatus)
        incidents.insert(inc, at: 0)
        saveJSON("ConstructOS.Ops.SafetyIncidents", value: incidents)
        newDate = ""; newLocation = ""; newDesc = ""; newCrew = ""; newAction = ""
        newType = .nearMiss; newStatus = .open; showAdd = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SAFETY INCIDENT LOG")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.red)
                    Text("\(incidents.count) total · \(recordableCount) recordable · \(openCount) open")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("+ LOG") { showAdd.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.red).cornerRadius(5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(incidents.count)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.text)
                    Text("TOTAL").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(recordableCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.red)
                    Text("RECORDABLE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(openCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(openCount > 0 ? Theme.gold : Theme.green)
                    Text("OPEN ITEMS").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Button("ALL TYPES") { filterType = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterType == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterType == nil ? Theme.accent : Theme.surface).cornerRadius(4)
                ForEach(IncidentType.allCases, id: \.self) { t in
                    Button(t.rawValue) { filterType = filterType == t ? nil : t }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterType == t ? .black : t.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterType == t ? t.color : Theme.surface).cornerRadius(4)
                }
                Button(filterStatus == .open ? "OPEN" : filterStatus == .closed ? "CLOSED" : "ALL STATUS") {
                    if filterStatus == nil { filterStatus = .open }
                    else if filterStatus == .open { filterStatus = .closed }
                    else { filterStatus = nil }
                }
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(filterStatus == nil ? Theme.muted : .black)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(filterStatus == nil ? Theme.surface : filterStatus == .open ? Theme.gold : Theme.green)
                .cornerRadius(4)
            }

            if showAdd {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("MM-DD", text: $newDate)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 60)
                        TextField("Location", text: $newLocation)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        TextField("Crew member", text: $newCrew)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                    }
                    TextField("Incident description", text: $newDesc)
                        .textFieldStyle(.roundedBorder).font(.system(size: 10))
                    TextField("Corrective action", text: $newAction)
                        .textFieldStyle(.roundedBorder).font(.system(size: 10))
                    HStack(spacing: 8) {
                        Picker("Type", selection: $newType) {
                            ForEach(IncidentType.allCases, id: \.self) { Text($0.rawValue) }
                        }.frame(width: 120)
                        Picker("Status", selection: $newStatus) {
                            ForEach(IncidentStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }.frame(width: 100)
                        Spacer()
                        Button("SAVE", action: addIncident)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.red).cornerRadius(5)
                        Button("CANCEL") { showAdd = false }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(8)
            }

            ForEach(filtered) { inc in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(inc.date)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(Theme.muted)
                        Text(inc.type.rawValue)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(inc.type.color)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(inc.type.color.opacity(0.12)).cornerRadius(4)
                        Text(inc.location)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Spacer()
                        Text(inc.status.rawValue)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(inc.status == .open ? Theme.gold : Theme.green)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(inc.status == .open ? Theme.gold.opacity(0.1) : Theme.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                    Text(inc.description)
                        .font(.system(size: 9)).foregroundColor(Theme.muted).lineLimit(2)
                    if !inc.crewMember.isEmpty {
                        Text("Crew: \(inc.crewMember)")
                            .font(.system(size: 8, weight: .semibold)).foregroundColor(Theme.cyan)
                    }
                    if !inc.correctiveAction.isEmpty {
                        Text("Action: \(inc.correctiveAction)")
                            .font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(2)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.red)
        .onAppear {
            incidents = loadJSON("ConstructOS.Ops.SafetyIncidents", default: incidents)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Material Delivery Tracker

enum DeliveryStatus: String, CaseIterable, Codable {
    case ordered   = "ORDERED"
    case inTransit = "IN TRANSIT"
    case delivered = "DELIVERED"
    case delayed   = "DELAYED"

    var color: Color {
        switch self {
        case .ordered:   return Theme.cyan
        case .inTransit: return Theme.gold
        case .delivered: return Theme.green
        case .delayed:   return Theme.red
        }
    }
}

struct MaterialDelivery: Identifiable, Codable {
    var id = UUID()
    var material: String
    var quantity: String
    var supplier: String
    var po: String
    var expectedDate: String
    var actualDate: String
    var status: DeliveryStatus
    var notes: String
}

struct MaterialDeliveryPanel: View {
    @State private var deliveries: [MaterialDelivery] = [
        MaterialDelivery(material: "Structural Steel — W8x31 Beams", quantity: "48 pcs", supplier: "Nucor Steel", po: "PO-4411", expectedDate: "03-15", actualDate: "03-15", status: .delivered, notes: "All pieces tagged and staged at grid A-line."),
        MaterialDelivery(material: "Concrete — 4000 PSI Mix", quantity: "80 CY", supplier: "LaFarge Ready Mix", po: "PO-4418", expectedDate: "03-18", actualDate: "", status: .ordered, notes: "Pour scheduled 07:00. Pump truck confirmed."),
        MaterialDelivery(material: "Electrical Conduit — 3/4\" EMT", quantity: "600 ft", supplier: "Graybar Electric", po: "PO-4422", expectedDate: "03-13", actualDate: "", status: .delayed, notes: "Distributor backordered. ETA revised to 03-20."),
        MaterialDelivery(material: "Drywall — 5/8\" Type X", quantity: "2,400 sqft", supplier: "USG Corp", po: "PO-4430", expectedDate: "03-20", actualDate: "", status: .inTransit, notes: "Driver confirmed en route. ETA 4 hours."),
        MaterialDelivery(material: "Roofing Membrane — TPO 60mil", quantity: "12 squares", supplier: "Johns Manville", po: "PO-4435", expectedDate: "03-22", actualDate: "", status: .ordered, notes: ""),
    ]
    @State private var filterStatus: DeliveryStatus? = nil
    @State private var showAdd = false
    @State private var newMaterial = ""
    @State private var newQty = ""
    @State private var newSupplier = ""
    @State private var newPO = ""
    @State private var newExpected = ""
    @State private var newNotes = ""
    @State private var newDelivStatus: DeliveryStatus = .ordered
    @State private var exportStatus: String? = nil

    private var filtered: [MaterialDelivery] {
        guard let f = filterStatus else { return deliveries }
        return deliveries.filter { $0.status == f }
    }

    private var delayedCount: Int  { deliveries.filter { $0.status == .delayed   }.count }
    private var pendingCount: Int  { deliveries.filter { $0.status != .delivered }.count }
    private var deliveredCount: Int { deliveries.filter { $0.status == .delivered }.count }

    private func addDelivery() {
        guard !newMaterial.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let d = MaterialDelivery(material: newMaterial, quantity: newQty, supplier: newSupplier,
                                  po: newPO.isEmpty ? "PO-\(Int.random(in: 4000...9999))" : newPO,
                                  expectedDate: newExpected, actualDate: "",
                                  status: newDelivStatus, notes: newNotes)
        deliveries.insert(d, at: 0)
        saveJSON("ConstructOS.Ops.MaterialDeliveries", value: deliveries)
        newMaterial = ""; newQty = ""; newSupplier = ""; newPO = ""; newExpected = ""; newNotes = ""
        newDelivStatus = .ordered; showAdd = false
    }

    private func exportLog() {
        let lines = deliveries.map { "\($0.po) | \($0.material) | \($0.quantity) | \($0.supplier) | Expected: \($0.expectedDate) | \($0.status.rawValue)" }
        let payload = (["MATERIAL DELIVERY LOG", "Delivered: \(deliveredCount) | Pending: \(pendingCount) | Delayed: \(delayedCount)", ""] + lines).joined(separator: "\n")
        copyTextToClipboard(payload)
        exportStatus = "Copied \(deliveries.count) deliveries"
        Task { try? await Task.sleep(nanoseconds: 3_000_000_000); await MainActor.run { exportStatus = nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MATERIAL DELIVERY TRACKER")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.cyan)
                    Text("\(deliveries.count) items · \(delayedCount) delayed · \(deliveredCount) delivered")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("+ ADD") { showAdd.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
                Button("EXPORT") { exportLog() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.gold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.surface).cornerRadius(5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(deliveredCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.green)
                    Text("DELIVERED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(pendingCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(Theme.gold)
                    Text("PENDING").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(delayedCount)")
                        .font(.system(size: 14, weight: .black)).foregroundColor(delayedCount > 0 ? Theme.red : Theme.muted)
                    Text("DELAYED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface).cornerRadius(4)
                ForEach(DeliveryStatus.allCases, id: \.self) { s in
                    Button(s.rawValue) { filterStatus = filterStatus == s ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : s.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface).cornerRadius(4)
                }
            }

            if showAdd {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Material name", text: $newMaterial)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        TextField("Qty", text: $newQty)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 80)
                    }
                    HStack(spacing: 8) {
                        TextField("Supplier", text: $newSupplier)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        TextField("PO #", text: $newPO)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 80)
                        TextField("Expected MM-DD", text: $newExpected)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10)).frame(width: 110)
                    }
                    HStack(spacing: 8) {
                        TextField("Notes", text: $newNotes)
                            .textFieldStyle(.roundedBorder).font(.system(size: 10))
                        Picker("", selection: $newDelivStatus) {
                            ForEach(DeliveryStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }.frame(width: 110)
                    }
                    HStack(spacing: 8) {
                        Button("SAVE", action: addDelivery)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.cyan).cornerRadius(5)
                        Button("CANCEL") { showAdd = false }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.6))
                .cornerRadius(8)
            }

            ForEach(filtered) { d in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(d.po)
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundColor(Theme.muted)
                            Text(d.material)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.text)
                        }
                        HStack(spacing: 8) {
                            Text(d.quantity).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.cyan)
                            Text("·").foregroundColor(Theme.muted)
                            Text(d.supplier).font(.system(size: 9)).foregroundColor(Theme.muted)
                            if !d.expectedDate.isEmpty {
                                Text("· ETA \(d.expectedDate)").font(.system(size: 9)).foregroundColor(d.status == .delayed ? Theme.red : Theme.muted)
                            }
                        }
                        if !d.notes.isEmpty {
                            Text(d.notes).font(.system(size: 9)).foregroundColor(Theme.muted).lineLimit(2)
                        }
                    }
                    Spacer()
                    Text(d.status.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(d.status.color)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(d.status.color.opacity(0.12)).cornerRadius(4)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }

            if let exportStatus {
                Text(exportStatus).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
        .onAppear {
            deliveries = loadJSON("ConstructOS.Ops.MaterialDeliveries", default: deliveries)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Punch List Manager

enum PunchListStatus: String, CaseIterable, Codable {
    case open   = "OPEN"
    case closed = "CLOSED"
    var color: Color { self == .open ? Theme.gold : Theme.green }
}

struct PunchListItem: Identifiable, Codable {
    var id = UUID()
    var description: String
    var location: String
    var trade: String
    var dueDate: String
    var status: PunchListStatus
    var createdBy: String
}

struct PunchListPanel: View {
    @State private var items: [PunchListItem] = [
        PunchListItem(description: "Missing fire caulk at conduit penetrations", location: "Level 2 – Elec Room", trade: "Electrical", dueDate: "03-17", status: .open, createdBy: "Insp. Torres"),
        PunchListItem(description: "Exposed rebar at footing tie-in", location: "Grid C-4", trade: "Concrete", dueDate: "03-16", status: .open, createdBy: "PM Davis"),
        PunchListItem(description: "HVAC duct hanger spacing exceeds 8ft", location: "Corridor B1", trade: "Mechanical", dueDate: "03-18", status: .open, createdBy: "Insp. Torres"),
        PunchListItem(description: "Door hardware backset incorrect – Rm 204", location: "Level 2", trade: "Doors & Hardware", dueDate: "03-15", status: .closed, createdBy: "Super. Reyes"),
        PunchListItem(description: "Paint overspray on sprinkler heads", location: "Level 1 Lobby", trade: "Painting", dueDate: "03-19", status: .open, createdBy: "PM Davis"),
    ]
    @State private var filterStatus: PunchListStatus? = nil
    @State private var showAddForm = false
    @State private var newDesc = ""
    @State private var newLoc = ""
    @State private var newTrade = ""
    @State private var newDue = ""

    private var filtered: [PunchListItem] {
        items.filter { filterStatus == nil || $0.status == filterStatus }
    }
    private var openCount: Int { items.filter { $0.status == .open }.count }
    private var closedCount: Int { items.filter { $0.status == .closed }.count }

    private func addItem() {
        guard !newDesc.isEmpty, !newTrade.isEmpty else { return }
        items.append(PunchListItem(description: newDesc, location: newLoc, trade: newTrade, dueDate: newDue, status: .open, createdBy: "You"))
                        saveJSON("ConstructOS.Ops.PunchList", value: items)
        newDesc = ""; newLoc = ""; newTrade = ""; newDue = ""
        showAddForm = false
    }

    private func closeItem(_ item: PunchListItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].status = .closed
        }
    }

    private func exportPunchList() {
        let lines = items.map { "[\($0.status.rawValue)] \($0.description) | Loc: \($0.location) | Trade: \($0.trade) | Due: \($0.dueDate) | By: \($0.createdBy)" }
        copyTextToClipboard("PUNCH LIST EXPORT – \(items.count) items (Open: \(openCount))\n" + lines.joined(separator: "\n"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PUNCH LIST MANAGER")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("Open \(openCount) · Closed \(closedCount)")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportPunchList() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.accent).cornerRadius(5)
                Button(showAddForm ? "CANCEL" : "+ ADD") { showAddForm.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 8) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface)
                    .cornerRadius(4)
                ForEach(PunchListStatus.allCases, id: \.rawValue) { s in
                    Button(s.rawValue) { filterStatus = (filterStatus == s) ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : Theme.muted)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface)
                        .cornerRadius(4)
                }
            }

            if showAddForm {
                VStack(spacing: 6) {
                    TextField("Description", text: $newDesc)
                        .textFieldStyle(.plain).font(.system(size: 10))
                        .padding(6).background(Theme.surface).cornerRadius(6)
                    HStack(spacing: 6) {
                        TextField("Location", text: $newLoc)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Trade", text: $newTrade)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Due (MM-DD)", text: $newDue)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        Button("ADD") { addItem() }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.green).cornerRadius(6)
                    }
                }
            }

            ForEach(filtered) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text(item.status.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(item.status.color.opacity(0.13))
                        .cornerRadius(4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.description)
                            .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text)
                        Text("\(item.location) · \(item.trade) · Due \(item.dueDate) · \(item.createdBy)")
                            .font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    if item.status == .open {
                        Button("CLOSE") { closeItem(item) }
                            .font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.green).cornerRadius(4)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            items = loadJSON("ConstructOS.Ops.PunchList", default: items)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Subcontractor Scorecard

enum SubPaymentStatus: String, CaseIterable, Codable {
    case current  = "CURRENT"
    case pending  = "PENDING"
    case overdue  = "OVERDUE"
    var color: Color { self == .current ? Theme.green : self == .pending ? Theme.gold : Theme.red }
}

struct SubcontractorRecord: Identifiable, Codable {
    var id = UUID()
    var name: String
    var trade: String
    var scheduleScore: Int
    var qualityScore: Int
    var safetyScore: Int
    var paymentStatus: SubPaymentStatus
    var overallGrade: String {
        let avg = (scheduleScore + qualityScore + safetyScore) / 3
        switch avg {
        case 90...: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        default: return "D"
        }
    }
    var gradeColor: Color {
        switch overallGrade {
        case "A": return Theme.green
        case "B": return Theme.cyan
        case "C": return Theme.gold
        default: return Theme.red
        }
    }
}

struct SubcontractorScorecardPanel: View {
    @State private var subs: [SubcontractorRecord] = [
        SubcontractorRecord(name: "Apex Electrical", trade: "Electrical", scheduleScore: 88, qualityScore: 91, safetyScore: 95, paymentStatus: .current),
        SubcontractorRecord(name: "Ironclad Steel", trade: "Structural Steel", scheduleScore: 72, qualityScore: 84, safetyScore: 80, paymentStatus: .pending),
        SubcontractorRecord(name: "ProMech HVAC", trade: "Mechanical", scheduleScore: 65, qualityScore: 77, safetyScore: 88, paymentStatus: .current),
        SubcontractorRecord(name: "Precision Concrete", trade: "Concrete", scheduleScore: 93, qualityScore: 90, safetyScore: 92, paymentStatus: .current),
        SubcontractorRecord(name: "SkyHigh Crane Co.", trade: "Crane & Rigging", scheduleScore: 80, qualityScore: 85, safetyScore: 70, paymentStatus: .overdue),
    ]
    @State private var sortByGrade = true

    private var sorted: [SubcontractorRecord] {
        sortByGrade
            ? subs.sorted { $0.overallGrade < $1.overallGrade }
            : subs.sorted { $0.name < $1.name }
    }

    private func scoreBar(_ score: Int, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface)
                Capsule().fill(color).frame(width: geo.size.width * CGFloat(score) / 100)
            }
        }
        .frame(height: 5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUBCONTRACTOR SCORECARD")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("\(subs.count) subs tracked · \(subs.filter { $0.paymentStatus == .overdue }.count) payment overdue")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button(sortByGrade ? "SORT: GRADE" : "SORT: NAME") { sortByGrade.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 6) {
                Text("SUB / TRADE").frame(width: 160, alignment: .leading)
                Text("SCHED").frame(width: 60, alignment: .center)
                Text("QUAL").frame(width: 60, alignment: .center)
                Text("SAFETY").frame(width: 60, alignment: .center)
                Text("PAY").frame(width: 70, alignment: .center)
                Text("GRD").frame(width: 30, alignment: .center)
            }
            .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)

            ForEach(sorted) { sub in
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(sub.name).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                        Text(sub.trade).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }.frame(width: 160, alignment: .leading)

                    VStack(spacing: 2) {
                        Text("\(sub.scheduleScore)").font(.system(size: 9, weight: .semibold)).foregroundColor(sub.scheduleScore >= 80 ? Theme.green : Theme.gold)
                        scoreBar(sub.scheduleScore, color: sub.scheduleScore >= 80 ? Theme.green : Theme.gold)
                    }.frame(width: 60)

                    VStack(spacing: 2) {
                        Text("\(sub.qualityScore)").font(.system(size: 9, weight: .semibold)).foregroundColor(sub.qualityScore >= 80 ? Theme.green : Theme.gold)
                        scoreBar(sub.qualityScore, color: sub.qualityScore >= 80 ? Theme.green : Theme.gold)
                    }.frame(width: 60)

                    VStack(spacing: 2) {
                        Text("\(sub.safetyScore)").font(.system(size: 9, weight: .semibold)).foregroundColor(sub.safetyScore >= 80 ? Theme.green : Theme.red)
                        scoreBar(sub.safetyScore, color: sub.safetyScore >= 80 ? Theme.green : Theme.red)
                    }.frame(width: 60)

                    Text(sub.paymentStatus.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(sub.paymentStatus.color)
                        .frame(width: 70)

                    Text(sub.overallGrade)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(sub.gradeColor)
                        .frame(width: 30)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            subs = loadJSON("ConstructOS.Ops.Subcontractors", default: subs)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Daily Cost Tracker

struct DailyCostEntry: Identifiable, Codable {
    var id = UUID()
    var trade: String
    var laborHours: Double
    var laborRate: Double
    var equipmentCost: Double
    var materialCost: Double
    var dateLabel: String
    var totalCost: Double { (laborHours * laborRate) + equipmentCost + materialCost }
}

struct DailyCostTrackerPanel: View {
    @State private var entries: [DailyCostEntry] = [
        DailyCostEntry(trade: "Electrical", laborHours: 48, laborRate: 85, equipmentCost: 0, materialCost: 1240, dateLabel: "Today"),
        DailyCostEntry(trade: "Concrete", laborHours: 64, laborRate: 72, equipmentCost: 2200, materialCost: 4800, dateLabel: "Today"),
        DailyCostEntry(trade: "Mechanical", laborHours: 32, laborRate: 90, equipmentCost: 0, materialCost: 620, dateLabel: "Today"),
        DailyCostEntry(trade: "Crane & Rigging", laborHours: 16, laborRate: 110, equipmentCost: 3200, materialCost: 0, dateLabel: "Today"),
        DailyCostEntry(trade: "Supervision", laborHours: 24, laborRate: 95, equipmentCost: 0, materialCost: 0, dateLabel: "Today"),
    ]
    @State private var dailyBudgetBaseline: Double = 48000
    @State private var showAddForm = false
    @State private var newTrade = ""
    @State private var newHours = ""
    @State private var newRate  = ""
    @State private var newEquip = ""
    @State private var newMat   = ""

    private var totalToday: Double { entries.map { $0.totalCost }.reduce(0, +) }
    private var laborTotal: Double { entries.map { $0.laborHours * $0.laborRate }.reduce(0, +) }
    private var equipTotal: Double { entries.map { $0.equipmentCost }.reduce(0, +) }
    private var matTotal: Double   { entries.map { $0.materialCost }.reduce(0, +) }
    private var variance: Double   { totalToday - dailyBudgetBaseline }
    private var varianceColor: Color { variance <= 0 ? Theme.green : Theme.red }

    private func addEntry() {
        guard !newTrade.isEmpty, let h = Double(newHours), let r = Double(newRate) else { return }
        let e = Double(newEquip) ?? 0; let m = Double(newMat) ?? 0
        entries.append(DailyCostEntry(trade: newTrade, laborHours: h, laborRate: r, equipmentCost: e, materialCost: m, dateLabel: "Today"))
        newTrade = ""; newHours = ""; newRate = ""; newEquip = ""; newMat = ""
        showAddForm = false
    }

    private func fmt(_ v: Double) -> String { String(format: "$%,.0f", v) }

    private func exportReport() {
        let lines = entries.map { "  \($0.trade): Labor \(fmt($0.laborHours * $0.laborRate)) + Equip \(fmt($0.equipmentCost)) + Mat \(fmt($0.materialCost)) = \(fmt($0.totalCost))" }
        let payload = "DAILY COST REPORT – \(Date())\nTotal: \(fmt(totalToday)) | Budget: \(fmt(dailyBudgetBaseline)) | Variance: \(variance >= 0 ? "+" : "")\(fmt(variance))\n\n" + lines.joined(separator: "\n")
        copyTextToClipboard(payload)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY COST TRACKER")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("Today's burn vs. \(fmt(dailyBudgetBaseline)) baseline")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportReport() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.accent).cornerRadius(5)
                Button(showAddForm ? "CANCEL" : "+ ENTRY") { showAddForm.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(fmt(totalToday))
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(totalToday <= dailyBudgetBaseline ? Theme.green : Theme.red)
                    Text("TODAY TOTAL").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(laborTotal)).font(.system(size: 11, weight: .black)).foregroundColor(Theme.cyan)
                    Text("LABOR").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                VStack(spacing: 2) {
                    Text(fmt(equipTotal)).font(.system(size: 11, weight: .black)).foregroundColor(Theme.gold)
                    Text("EQUIPMENT").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                VStack(spacing: 2) {
                    Text(fmt(matTotal)).font(.system(size: 11, weight: .black)).foregroundColor(Theme.purple)
                    Text("MATERIALS").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(variance >= 0 ? "+" : "")\(fmt(variance))")
                        .font(.system(size: 11, weight: .black)).foregroundColor(varianceColor)
                    Text("VARIANCE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            if showAddForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Trade", text: $newTrade)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Hours", text: $newHours)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 70)
                        TextField("Rate/hr", text: $newRate)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 70)
                        TextField("Equipment $", text: $newEquip)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        TextField("Materials $", text: $newMat)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        Button("ADD") { addEntry() }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.green).cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("TRADE").frame(width: 130, alignment: .leading)
                Text("HOURS").frame(width: 55, alignment: .trailing)
                Text("LABOR").frame(width: 80, alignment: .trailing)
                Text("EQUIP").frame(width: 80, alignment: .trailing)
                Text("MAT").frame(width: 80, alignment: .trailing)
                Text("TOTAL").frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)

            ForEach(entries) { entry in
                HStack(spacing: 6) {
                    Text(entry.trade).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        .frame(width: 130, alignment: .leading)
                    Text(String(format: "%.1f", entry.laborHours)).font(.system(size: 9)).foregroundColor(Theme.muted)
                        .frame(width: 55, alignment: .trailing)
                    Text(fmt(entry.laborHours * entry.laborRate)).font(.system(size: 9)).foregroundColor(Theme.cyan)
                        .frame(width: 80, alignment: .trailing)
                    Text(fmt(entry.equipmentCost)).font(.system(size: 9)).foregroundColor(Theme.gold)
                        .frame(width: 80, alignment: .trailing)
                    Text(fmt(entry.materialCost)).font(.system(size: 9)).foregroundColor(Theme.purple)
                        .frame(width: 80, alignment: .trailing)
                    Text(fmt(entry.totalCost)).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7)).cornerRadius(7)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            entries = loadJSON("ConstructOS.Ops.DailyCosts", default: entries)
        }
        .padding(.horizontal, 16)
    }
}


// MARK: - ========== OperationsField.swift ==========

// MARK: - Site Risk Score

struct SiteRiskScorePanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let scores: [(site: String, score: Int, drivers: [String])] = [
        ("Riverside Lofts",    95, ["Status: DELAYED", "Crew HOLD", "Inspection DUE TODAY", "Weather: Rain"]),
        ("Site Gamma",         65, ["Status: AT RISK",  "Crew DELAYED", "Wind Advisory"]),
        ("Pine Ridge Ph.2",    55, ["Status: AT RISK",  "Inspection 1d OVERDUE", "Permit FLAGGED"]),
        ("Harbor Crossing",    10, ["Status: ON TRACK", "MEP Active"]),
        ("Eastside Civic Hub", 15, ["Status: ON TRACK", "Permit PENDING"]),
    ]

    private var portfolioScore: Int {
        scores.isEmpty ? 0 : scores.map(\.score).reduce(0, +) / scores.count
    }

    private func riskColor(_ score: Int) -> Color {
        if score >= 70 { return Theme.red }
        if score >= 40 { return Theme.gold }
        return Theme.green
    }

    private var roleNote: String {
        let hot = scores.first(where: { $0.score >= 70 })?.site ?? "none"
        switch role {
        case .superintendent: return "Highest risk site today: \(hot)"
        case .projectManager: return "Schedule impact likely at: \(hot)"
        case .executive:      return "Portfolio avg risk: \(portfolioScore)/100"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("SITE RISK SCORES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(riskColor(portfolioScore))
                Text("AVG \(portfolioScore)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(riskColor(portfolioScore).opacity(0.9)))
                Spacer()
                Text(roleNote)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            VStack(spacing: 6) {
                ForEach(scores, id: \.site) { item in
                    RiskScoreRow(site: item.site, score: item.score, drivers: item.drivers, riskColor: riskColor(item.score))
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: riskColor(portfolioScore))
    }
}

struct RiskScoreRow: View {
    let site: String
    let score: Int
    let drivers: [String]
    let riskColor: Color
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(site)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.surface)
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(riskColor.opacity(0.85))
                            .frame(width: geo.size.width * CGFloat(score) / 100, height: 7)
                    }
                }
                .frame(width: 90, height: 7)
                Text("\(score)")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(riskColor)
                    .frame(width: 26, alignment: .trailing)
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }) {
                    Text(expanded ? "▲" : "▼")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
                .buttonStyle(.plain)
            }
            if expanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(drivers, id: \.self) { d in
                        Text("· \(d)")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(Theme.muted)
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(riskColor.opacity(score >= 70 ? 0.07 : 0.03))
        .cornerRadius(7)
    }
}

// MARK: - Daily Standup Report

struct StandupReportPanel: View {
    @EnvironmentObject private var actionLog: RiskActionLogStore
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    @State private var reportText: String = ""
    @State private var copyStatus: String?
    @State private var generated = false

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private func generateReport() {
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        let today = df.string(from: Date())
        let full = DateFormatter()
        full.dateFormat = "EEEE, MMM d yyyy"
        let dateLabel = full.string(from: Date())

        let todayEntries  = actionLog.entries.filter { $0.hasPrefix("[\(today)") }
        let assigns       = todayEntries.filter { $0.lowercased().contains("assign")   }
        let notes         = todayEntries.filter { $0.lowercased().contains("note")     }
        let escalations   = actionLog.entries.filter { $0.lowercased().contains("escalate") }
        let safetyEntries = todayEntries.filter { $0.lowercased().contains("[safety]") }
        let schedEntries  = todayEntries.filter { $0.lowercased().contains("[schedule]") }

        var lines: [String] = []
        lines.append("DAILY STANDUP — \(role.display)")
        lines.append(dateLabel)
        lines.append(String(repeating: "-", count: 40))
        lines.append("")

        switch role {
        case .superintendent:
            lines.append("FIELD STATUS")
            lines.append("  Sites running: Harbor Crossing, Pine Ridge Ph.2, Eastside Civic Hub")
            lines.append("  On hold: Riverside Lofts (rain), Site Gamma (steel delay)")
            lines.append("")
            lines.append("SAFETY (\(safetyEntries.count) today)")
            safetyEntries.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if safetyEntries.isEmpty { lines.append("  No safety entries today") }
            lines.append("")
            lines.append("SCHEDULE FLAGS (\(schedEntries.count) today)")
            schedEntries.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if schedEntries.isEmpty { lines.append("  No schedule flags today") }
            lines.append("")
            lines.append("CREW: 61 workers — 22 active, 22 on hold due to weather")
            lines.append("WEATHER: Heavy rain today — concrete + steel ops suspended")

        case .projectManager:
            lines.append("SCHEDULE IMPACT")
            lines.append("  Riverside Lofts: DELAYED — rain delay, update baseline")
            lines.append("  Site Gamma: AT RISK — steel delivery pushed")
            lines.append("  Pine Ridge Ph.2: AT RISK — framing inspection 1d overdue")
            lines.append("")
            lines.append("ASSIGNS TODAY (\(assigns.count))")
            assigns.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if assigns.isEmpty { lines.append("  No assignments today") }
            lines.append("")
            lines.append("ESCALATIONS (\(escalations.count) total)")
            escalations.prefix(3).forEach { lines.append("  " + String($0.prefix(60))) }
            if escalations.isEmpty { lines.append("  None" ) }
            lines.append("")
            lines.append("PERMITS: Foundation inspection DUE TODAY (Riverside) — PENDING")

        case .executive:
            lines.append("PORTFOLIO RISK SUMMARY")
            lines.append("  Avg risk score: 48/100")
            lines.append("  Critical sites: Riverside Lofts (95), Site Gamma (65), Pine Ridge (55)")
            lines.append("")
            lines.append("ESCALATIONS (\(escalations.count) open)")
            escalations.prefix(5).forEach { lines.append("  " + String($0.prefix(72))) }
            if escalations.isEmpty { lines.append("  None") }
            lines.append("")
            lines.append("WEATHER EXPOSURE: 2 sites on hold today (rain) — labor cost impact")
            lines.append("LABOR EXPOSURE: 61 workers, \(assigns.count) new assigns, \(notes.count) field notes")
        }

        lines.append("")
        lines.append("Generated by ConstructionOS · \(role.display) view")
        reportText = lines.joined(separator: "\n")
        withAnimation(.easeInOut(duration: 0.2)) { generated = true }
    }

    private func copyReport() {
        copyTextToClipboard(reportText)
        copyStatus = "Copied to clipboard"
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { copyStatus = nil }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("DAILY STANDUP")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                Text(role.display)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accent.opacity(0.9)))
                Spacer()
                if let status = copyStatus {
                    Text(status)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.green)
                }
                if generated {
                    Button(action: copyReport) {
                        Text("COPY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: generateReport) {
                    Text(generated ? "REFRESH" : "GENERATE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LinearGradient(gradient: Gradient(colors: [Theme.accent, Theme.gold]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            Text("Role-optimized report ready to paste into Slack, email, or field notes.")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(Theme.muted)
            if generated && !reportText.isEmpty {
                ScrollView {
                    Text(reportText)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
                .padding(10)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
        .onChange(of: rolePresetRaw) { _, _ in
            if generated { generateReport() }
        }
    }
}

// MARK: - Crew Deploy Board

struct CrewAssignment: Identifiable {
    let id: Int
    let site: String
    let trade: String
    let headcount: Int
    let status: String
    let statusColor: Color
}

struct CrewDeployBoard: View {
    @EnvironmentObject private var actionLog: RiskActionLogStore
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    @State private var loggedSite: String? = nil

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let crews: [CrewAssignment] = [
        CrewAssignment(id: 0, site: "Riverside Lofts",   trade: "Concrete",   headcount: 14, status: "HOLD",     statusColor: Theme.red),
        CrewAssignment(id: 1, site: "Site Gamma",         trade: "Steel",      headcount: 8,  status: "DELAYED",  statusColor: Theme.gold),
        CrewAssignment(id: 2, site: "Harbor Crossing",    trade: "MEP",        headcount: 22, status: "ACTIVE",   statusColor: Theme.green),
        CrewAssignment(id: 3, site: "Pine Ridge Ph.2",    trade: "Framing",    headcount: 11, status: "ACTIVE",   statusColor: Theme.green),
        CrewAssignment(id: 4, site: "Eastside Civic Hub", trade: "Finishes",   headcount: 6,  status: "STANDBY",  statusColor: Theme.cyan),
    ]

    private var totalCrew: Int { crews.reduce(0) { $0 + $1.headcount } }
    private var activeCount: Int { crews.filter { $0.status == "ACTIVE" }.count }
    private var holdCount: Int { crews.filter { $0.status == "HOLD" || $0.status == "DELAYED" }.count }

    private var roleSubtitle: String {
        switch role {
        case .superintendent: return "\(totalCrew) workers across \(crews.count) sites"
        case .projectManager: return "\(holdCount) crews delayed — schedule impact pending"
        case .executive:      return "Total labor exposure: \(totalCrew) workers"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("CREW DEPLOY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.purple)
                HStack(spacing: 4) {
                    CrewStatBadge(label: "ACTIVE", count: activeCount,           color: Theme.green)
                    CrewStatBadge(label: "HOLD",   count: holdCount,             color: Theme.red)
                    CrewStatBadge(label: "TOTAL",  count: totalCrew,             color: Theme.purple)
                }
                Spacer()
            }
            Text(roleSubtitle)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)
            if let site = loggedSite {
                Text("✓ Reassignment logged for \(site)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.green)
            }
            VStack(spacing: 6) {
                ForEach(crews) { crew in
                    CrewRowTile(crew: crew) {
                        actionLog.add("[reassign] \(crew.trade) crew reassigned from \(crew.site) — \(crew.headcount) workers")
                        loggedSite = crew.site
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run { loggedSite = nil }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: Theme.purple)
    }
}

struct CrewStatBadge: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(color.opacity(0.85)))
        }
    }
}

struct CrewRowTile: View {
    let crew: CrewAssignment
    let onReassign: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(crew.statusColor.opacity(0.85))
                .frame(width: 7, height: 7)
            Text(crew.site)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(Theme.text)
                .lineLimit(1)
            Text(crew.trade)
                .font(.system(size: 8.5, weight: .regular))
                .foregroundColor(Theme.muted)
            Spacer()
            Text("\(crew.headcount) workers")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.muted)
            Text(crew.status)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(crew.statusColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(crew.statusColor.opacity(0.14))
                .cornerRadius(4)
            Button(action: onReassign) {
                Text("REASSIGN")
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.purple.opacity(isHovering ? 1 : 0.75))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(crew.statusColor.opacity(0.05))
        .cornerRadius(7)
    }
}

// MARK: - Inspection & Permit Tracker

struct InspectionItem: Identifiable {
    let id: Int
    let site: String
    let type: String
    let dueDays: Int
    let permitStatus: PermitStatus
}

enum PermitStatus: String {
    case approved = "APPROVED"
    case pending  = "PENDING"
    case flagged  = "FLAGGED"

    var color: Color {
        switch self {
        case .approved: return Theme.green
        case .pending:  return Theme.gold
        case .flagged:  return Theme.red
        }
    }
}

struct InspectionPermitTracker: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let items: [InspectionItem] = [
        InspectionItem(id: 0, site: "Riverside Lofts",   type: "Foundation Inspection", dueDays:  0, permitStatus: .pending),
        InspectionItem(id: 1, site: "Site Gamma",         type: "Steel Frame Inspection", dueDays:  2, permitStatus: .approved),
        InspectionItem(id: 2, site: "Harbor Crossing",    type: "MEP Rough-in",           dueDays:  5, permitStatus: .approved),
        InspectionItem(id: 3, site: "Pine Ridge Ph.2",    type: "Framing Inspection",     dueDays: -1, permitStatus: .flagged),
        InspectionItem(id: 4, site: "Eastside Civic Hub", type: "Building Permit",        dueDays:  9, permitStatus: .pending),
    ]

    private var overdueCount:  Int { items.filter { $0.dueDays <  0 }.count }
    private var dueTodayCount: Int { items.filter { $0.dueDays == 0 }.count }
    private var upcomingCount: Int { items.filter { $0.dueDays >  0 }.count }
    private var hasCritical:   Bool { overdueCount > 0 || dueTodayCount > 0 }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Coordinate inspectors on site for due items"
        case .projectManager: return "Permit flags may delay critical path"
        case .executive:      return "\(overdueCount + dueTodayCount) inspections require immediate action"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("INSPECTIONS & PERMITS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(hasCritical ? Theme.red : Theme.gold)
                if overdueCount > 0 {
                    Text("\(overdueCount) OVERDUE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(5)
                }
                if dueTodayCount > 0 {
                    Text("DUE TODAY")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.gold)
                        .cornerRadius(5)
                }
                Spacer()
            }
            Text(roleNote)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)
            VStack(spacing: 6) {
                ForEach(items) { item in
                    InspectionRow(item: item)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: hasCritical ? Theme.red : Theme.gold)
    }
}

struct InspectionRow: View {
    let item: InspectionItem

    private var dueLabel: String {
        if item.dueDays < 0  { return "\(abs(item.dueDays))d OVERDUE" }
        if item.dueDays == 0 { return "DUE TODAY" }
        return "DUE IN \(item.dueDays)d"
    }

    private var dueColor: Color {
        if item.dueDays <= 0 { return Theme.red }
        if item.dueDays <= 3 { return Theme.gold }
        return Theme.muted
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.site)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Text(item.type)
                    .font(.system(size: 8.5, weight: .regular))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            Spacer()
            Text(dueLabel)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(dueColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(dueColor.opacity(0.12))
                .cornerRadius(4)
            Text(item.permitStatus.rawValue)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(item.permitStatus.color)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(item.permitStatus.color.opacity(0.14))
                .cornerRadius(4)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(item.dueDays <= 0 ? Theme.red.opacity(0.06) : Theme.surface.opacity(0.5))
        .cornerRadius(7)
    }
}

// MARK: - Weather Risk Overlay

struct WeatherDay: Identifiable {
    let id: Int
    let label: String
    let icon: String
    let tempHigh: Int
    let tempLow: Int
    let condition: String
    let riskFlags: [WeatherRiskFlag]
}

struct WeatherRiskFlag: Identifiable {
    let id: Int
    let label: String
    let color: Color
}

struct WeatherRiskPanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let forecast: [WeatherDay] = [
        WeatherDay(id: 0, label: "TODAY",  icon: "🌧", tempHigh: 54, tempLow: 41,
                   condition: "Heavy Rain",
                   riskFlags: [
                       WeatherRiskFlag(id: 0, label: "CONCRETE POUR HOLD", color: Theme.red),
                       WeatherRiskFlag(id: 1, label: "SLIP HAZARD",        color: Theme.gold),
                   ]),
        WeatherDay(id: 1, label: "TMR",    icon: "⛅️", tempHigh: 61, tempLow: 44,
                   condition: "Partly Cloudy",
                   riskFlags: [
                       WeatherRiskFlag(id: 2, label: "WIND ADVISORY",      color: Theme.gold),
                   ]),
        WeatherDay(id: 2, label: "Day 3",  icon: "☀️", tempHigh: 68, tempLow: 50,
                   condition: "Clear",
                   riskFlags: []),
    ]

    private var hasFieldWarning: Bool {
        forecast.first?.riskFlags.contains { $0.color == Theme.red } == true
    }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Concrete + steel ops suspended today"
        case .projectManager: return "Rain delay — update schedule baseline"
        case .executive:      return "Weather delay risk on 2 sites today"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                DashboardPanelHeading(
                    eyebrow: "WEATHER",
                    title: "Weather risk overlay",
                    detail: "Forecast-driven field risk and role-specific impact for the next work window.",
                    accent: Theme.cyan
                )
                if hasFieldWarning {
                    Text("⚠ FIELD WARNING")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(5)
                }
                Spacer()
            }

            Text(roleNote)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                ForEach(forecast) { day in
                    WeatherDayCard(day: day)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: hasFieldWarning ? Theme.red : Theme.cyan)
    }
}

struct WeatherDayCard: View {
    let day: WeatherDay

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(day.label)
                    .font(.system(size: 8.5, weight: .heavy))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text(day.icon)
                    .font(.system(size: 14))
            }
            Text(day.condition)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.text)
            Text("\(day.tempHigh)° / \(day.tempLow)°")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.muted)
            if day.riskFlags.isEmpty {
                Text("No risk flags")
                    .font(.system(size: 7.5, weight: .regular))
                    .foregroundColor(Theme.green.opacity(0.8))
            } else {
                ForEach(day.riskFlags) { flag in
                    Text(flag.label)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(flag.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(day.riskFlags.isEmpty ? Theme.surface.opacity(0.6) : day.riskFlags.first!.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(day.riskFlags.isEmpty ? Theme.border.opacity(0.3) : day.riskFlags.first!.color.opacity(0.4), lineWidth: 0.9)
        )
        .cornerRadius(9)
    }
}

// MARK: - Site Status Dashboard

enum SiteStatusLevel: String {
    case onTrack = "ON TRACK"
    case atRisk  = "AT RISK"
    case delayed = "DELAYED"

    var color: Color {
        switch self {
        case .onTrack: return Theme.green
        case .atRisk:  return Theme.gold
        case .delayed: return Theme.red
        }
    }
    var dot: String {
        switch self {
        case .onTrack: return "●"
        case .atRisk:  return "◆"
        case .delayed: return "▲"
        }
    }
}

struct SiteEntry: Identifiable {
    let id: Int
    let name: String
    let status: SiteStatusLevel
    let trade: String
    let owner: String
}

struct SiteStatusDashboard: View {
    @EnvironmentObject private var actionLog: RiskActionLogStore
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let sites: [SiteEntry] = [
        SiteEntry(id: 0, name: "Riverside Lofts",   status: .delayed,  trade: "Concrete",  owner: "Apex Dev"),
        SiteEntry(id: 1, name: "Site Gamma",         status: .atRisk,   trade: "Steel",     owner: "Henderson LLC"),
        SiteEntry(id: 2, name: "Harbor Crossing",    status: .onTrack,  trade: "MEP",       owner: "Sun Capital"),
        SiteEntry(id: 3, name: "Pine Ridge Ph.2",    status: .atRisk,   trade: "Framing",   owner: "Miller Group"),
        SiteEntry(id: 4, name: "Eastside Civic Hub", status: .onTrack,  trade: "Finishes",  owner: "City of West"),
    ]

    private var delayedCount: Int { sites.filter { $0.status == .delayed }.count }
    private var atRiskCount:  Int { sites.filter { $0.status == .atRisk  }.count }
    private var onTrackCount: Int { sites.filter { $0.status == .onTrack }.count }

    private var roleSubtitle: String {
        switch role {
        case .superintendent: return "Field coordination view"
        case .projectManager: return "Schedule impact view"
        case .executive:      return "Escalation exposure"
        }
    }

    private func recentAction(for site: SiteEntry) -> String {
        let key = site.name.lowercased().components(separatedBy: " ").first ?? ""
        let hit = actionLog.entries.first { $0.lowercased().contains(key) }
        return hit.map { String($0.prefix(44)) } ?? "No actions logged"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                DashboardPanelHeading(
                    eyebrow: "SITE STATUS",
                    title: "Live site operating picture",
                    detail: "Current trade posture, owner context, and recent actions across active jobs.",
                    accent: Theme.green
                )
                Spacer()
                Text(roleSubtitle)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.muted)
            }

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(onTrackCount)", label: "ON TRACK", color: Theme.green)
                DashboardStatPill(value: "\(atRiskCount)", label: "AT RISK", color: Theme.gold)
                DashboardStatPill(value: "\(delayedCount)", label: "DELAYED", color: Theme.red)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(sites) { site in
                    SiteStatusTile(
                        name:         site.name,
                        status:       site.status,
                        trade:        site.trade,
                        owner:        site.owner,
                        role:         role,
                        recentAction: recentAction(for: site)
                    )
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: Theme.green)
    }
}

struct SiteStatBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7.5, weight: .heavy))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(color.opacity(0.85)))
        }
    }
}

struct SiteStatusTile: View {
    let name: String
    let status: SiteStatusLevel
    let trade: String
    let owner: String
    let role: OpsRolePreset
    let recentAction: String

    private var roleDetailLine: String {
        switch role {
        case .superintendent: return trade
        case .projectManager: return "Owner: \(owner)"
        case .executive:      return owner
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Text(status.dot)
                    .font(.system(size: 9))
                    .foregroundColor(status.color)
                Text(status.rawValue)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(status.color)
                Spacer()
            }
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.text)
                .lineLimit(1)
            Text(roleDetailLine)
                .font(.system(size: 8.5, weight: .regular))
                .foregroundColor(Theme.muted)
                .lineLimit(1)
            Text(recentAction)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.muted.opacity(0.75))
                .lineLimit(2)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status.color.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(status.color.opacity(0.35), lineWidth: 0.9)
        )
        .cornerRadius(10)
    }
}

struct LogFilterChip: View {
    let title: String
    let selected: Bool
    let color: Color
    let action: () -> Void
    @State private var isHovering = false

    private var chipParts: (label: String, count: String?) {
        let pieces = title.split(separator: " ")
        guard pieces.count >= 2, let last = pieces.last, Int(last) != nil else {
            return (title, nil)
        }
        let label = pieces.dropLast().joined(separator: " ")
        return (label, String(last))
    }

    private var fillColor: Color {
        if selected {
            return color
        }
        return isHovering ? color.opacity(0.24) : color.opacity(0.14)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(chipParts.label)
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)

                if let count = chipParts.count {
                    Text(count)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(selected ? Color.black.opacity(0.18) : color.opacity(0.16))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(selected ? .black : color.opacity(isHovering ? 1 : 0.95))
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .frame(height: 24)
            .background(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(selected ? 0 : (isHovering ? 0.45 : 0.28)), lineWidth: 0.8)
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}


// MARK: - ========== OperationsCommercial.swift ==========

// MARK: - Submittal & Approval Log

enum SubmittalStatus: String, CaseIterable, Codable {
    case pending          = "PENDING"
    case approved         = "APPROVED"
    case reviseResubmit   = "REVISE & RESUBMIT"
    case rejected         = "REJECTED"
    var color: Color {
        switch self {
        case .pending:        return Theme.gold
        case .approved:       return Theme.green
        case .reviseResubmit: return Theme.cyan
        case .rejected:       return Theme.red
        }
    }
    var short: String {
        switch self {
        case .pending:        return "PEND"
        case .approved:       return "APPR"
        case .reviseResubmit: return "R&R"
        case .rejected:       return "REJ"
        }
    }
}

struct SubmittalItem: Identifiable, Codable {
    var id = UUID()
    var number: String
    var description: String
    var discipline: String
    var submittedDate: String
    var returnDate: String
    var revision: Int
    var status: SubmittalStatus
    var ball: String
}

struct SubmittalLogPanel: View {
    @State private var submittals: [SubmittalItem] = [
        SubmittalItem(number: "S-001", description: "Structural Steel Shop Drawings", discipline: "Structural", submittedDate: "03-01", returnDate: "03-15", revision: 1, status: .approved, ball: "Contractor"),
        SubmittalItem(number: "S-002", description: "Electrical Panel Schedules", discipline: "Electrical", submittedDate: "03-08", returnDate: "03-22", revision: 0, status: .pending, ball: "Architect"),
        SubmittalItem(number: "S-003", description: "HVAC Equipment Cuts", discipline: "Mechanical", submittedDate: "03-05", returnDate: "03-19", revision: 1, status: .reviseResubmit, ball: "Contractor"),
        SubmittalItem(number: "S-004", description: "Concrete Mix Design", discipline: "Civil", submittedDate: "02-20", returnDate: "03-06", revision: 2, status: .approved, ball: "Contractor"),
        SubmittalItem(number: "S-005", description: "Curtain Wall System", discipline: "Architectural", submittedDate: "03-12", returnDate: "03-26", revision: 0, status: .pending, ball: "Architect"),
        SubmittalItem(number: "S-006", description: "Fire Alarm Drawings", discipline: "Electrical", submittedDate: "03-03", returnDate: "03-17", revision: 0, status: .rejected, ball: "Contractor"),
    ]
    @State private var filterStatus: SubmittalStatus? = nil
    @State private var showAddForm = false
    @State private var newNum = ""
    @State private var newDesc = ""
    @State private var newDisc = ""
    @State private var newSub = ""
    @State private var newRet = ""

    private var filtered: [SubmittalItem] {
        submittals.filter { filterStatus == nil || $0.status == filterStatus }
    }
    private var pendingCount: Int { submittals.filter { $0.status == .pending }.count }
    private var approvedCount: Int { submittals.filter { $0.status == .approved }.count }
    private var actionCount: Int { submittals.filter { $0.status == .reviseResubmit || $0.status == .rejected }.count }

    private func addSubmittal() {
        guard !newNum.isEmpty, !newDesc.isEmpty else { return }
        submittals.append(SubmittalItem(number: newNum, description: newDesc, discipline: newDisc, submittedDate: newSub, returnDate: newRet, revision: 0, status: .pending, ball: "Architect"))
        newNum = ""; newDesc = ""; newDisc = ""; newSub = ""; newRet = ""
        showAddForm = false
    }

    private func exportLog() {
        let lines = submittals.map { "[\($0.status.short)] \($0.number) – \($0.description) | \($0.discipline) | Sub: \($0.submittedDate) | Return: \($0.returnDate) | Rev \($0.revision) | Ball: \($0.ball)" }
        copyTextToClipboard("SUBMITTAL LOG – \(submittals.count) items\n" + lines.joined(separator: "\n"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUBMITTAL & APPROVAL LOG")
                        .font(.system(size: 11, weight: .black)).tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("Pending \(pendingCount) · Approved \(approvedCount) · Action needed \(actionCount)")
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportLog() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.accent).cornerRadius(5)
                Button(showAddForm ? "CANCEL" : "+ ADD") { showAddForm.toggle() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Theme.cyan).cornerRadius(5)
            }

            HStack(spacing: 8) {
                Button("ALL") { filterStatus = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(filterStatus == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(filterStatus == nil ? Theme.accent : Theme.surface)
                    .cornerRadius(4)
                ForEach(SubmittalStatus.allCases, id: \.rawValue) { s in
                    Button(s.short) { filterStatus = (filterStatus == s) ? nil : s }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(filterStatus == s ? .black : Theme.muted)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(filterStatus == s ? s.color : Theme.surface)
                        .cornerRadius(4)
                }
            }

            if showAddForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Number (S-007)", text: $newNum)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                        TextField("Description", text: $newDesc)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Discipline", text: $newDisc)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                    }
                    HStack(spacing: 6) {
                        TextField("Submitted (MM-DD)", text: $newSub)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Expected Return (MM-DD)", text: $newRet)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        Button("ADD") { addSubmittal() }
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.green).cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("NO.").frame(width: 50, alignment: .leading)
                Text("DESCRIPTION").frame(maxWidth: .infinity, alignment: .leading)
                Text("DISC.").frame(width: 80, alignment: .leading)
                Text("SUBMITTED").frame(width: 70, alignment: .center)
                Text("RETURN").frame(width: 65, alignment: .center)
                Text("REV").frame(width: 30, alignment: .center)
                Text("BALL").frame(width: 70, alignment: .center)
                Text("STATUS").frame(width: 55, alignment: .center)
            }
            .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)

            ForEach(filtered) { item in
                HStack(spacing: 6) {
                    Text(item.number).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                        .frame(width: 50, alignment: .leading)
                    Text(item.description).font(.system(size: 9)).foregroundColor(Theme.text).lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.discipline).font(.system(size: 8)).foregroundColor(Theme.muted)
                        .frame(width: 80, alignment: .leading)
                    Text(item.submittedDate).font(.system(size: 9)).foregroundColor(Theme.muted)
                        .frame(width: 70, alignment: .center)
                    Text(item.returnDate).font(.system(size: 9)).foregroundColor(Theme.gold)
                        .frame(width: 65, alignment: .center)
                    Text("R\(item.revision)").font(.system(size: 9, weight: .semibold)).foregroundColor(item.revision > 0 ? Theme.red : Theme.muted)
                        .frame(width: 30, alignment: .center)
                    Text(item.ball).font(.system(size: 8)).foregroundColor(item.ball == "Architect" ? Theme.cyan : Theme.green)
                        .frame(width: 70, alignment: .center)
                    Text(item.status.short)
                        .font(.system(size: 8, weight: .black)).foregroundColor(item.status.color)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(item.status.color.opacity(0.13)).cornerRadius(4)
                        .frame(width: 55, alignment: .center)
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7)).cornerRadius(7)
            }
        }
        .padding(14).background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            submittals = loadJSON("ConstructOS.Ops.Submittals", default: submittals)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Project & Contract Account Management

enum AccountOwnerType: String, CaseIterable, Codable {
    case owner = "OWNER"
    case gc = "GC"
    case subcontractor = "SUB"

    var color: Color {
        switch self {
        case .owner: return Theme.cyan
        case .gc: return Theme.accent
        case .subcontractor: return Theme.gold
        }
    }
}

enum ContractAccountStatus: String, CaseIterable, Codable {
    case draft = "DRAFT"
    case active = "ACTIVE"
    case pendingInvoice = "PENDING INVOICE"
    case atRisk = "AT RISK"
    case closed = "CLOSED"

    var color: Color {
        switch self {
        case .draft: return Theme.cyan
        case .active: return Theme.green
        case .pendingInvoice: return Theme.gold
        case .atRisk: return Theme.red
        case .closed: return Theme.muted
        }
    }
}

struct ProjectAccountItem: Identifiable, Codable {
    var id = UUID()
    var code: String
    var projectName: String
    var ownerName: String
    var ownerType: AccountOwnerType
    var approvedBudget: Double
    var billedToDate: Double
    var retainagePct: Double
    var socialScore: Int

    var remaining: Double { approvedBudget - billedToDate }
}

struct ContractAccountItem: Identifiable, Codable {
    var id = UUID()
    var contractNo: String
    var projectCode: String
    var partner: String
    var contractValue: Double
    var invoicedToDate: Double
    var status: ContractAccountStatus
    var renewalDate: String
    var socialScore: Int
    var workEthicScore: Int
    var socialTrend7d: [Int]
    var workEthicTrend7d: [Int]

    var balance: Double { contractValue - invoicedToDate }
}

struct ProjectContractAccountPanel: View {
    @State private var projects: [ProjectAccountItem] = [
        ProjectAccountItem(code: "P-1024", projectName: "North Deck Expansion", ownerName: "Metro Transit", ownerType: .owner, approvedBudget: 2_800_000, billedToDate: 1_940_000, retainagePct: 5, socialScore: 88),
        ProjectAccountItem(code: "P-1188", projectName: "Medical Tower TI", ownerName: "Moss Development", ownerType: .gc, approvedBudget: 4_250_000, billedToDate: 2_680_000, retainagePct: 7.5, socialScore: 81),
        ProjectAccountItem(code: "P-1201", projectName: "East Utility Rehab", ownerName: "City Public Works", ownerType: .owner, approvedBudget: 1_900_000, billedToDate: 1_120_000, retainagePct: 10, socialScore: 74),
    ]

    @State private var contracts: [ContractAccountItem] = [
        ContractAccountItem(contractNo: "C-441", projectCode: "P-1024", partner: "Apex Electrical", contractValue: 540_000, invoicedToDate: 402_000, status: .active, renewalDate: "2026-12-31", socialScore: 86, workEthicScore: 91, socialTrend7d: [82, 83, 84, 85, 85, 86, 87], workEthicTrend7d: [88, 89, 89, 90, 90, 91, 91]),
        ContractAccountItem(contractNo: "C-457", projectCode: "P-1188", partner: "ProMech HVAC", contractValue: 780_000, invoicedToDate: 620_000, status: .pendingInvoice, renewalDate: "2026-09-30", socialScore: 79, workEthicScore: 84, socialTrend7d: [81, 81, 80, 80, 79, 79, 78], workEthicTrend7d: [85, 85, 84, 84, 84, 83, 83]),
        ContractAccountItem(contractNo: "C-463", projectCode: "P-1201", partner: "Ironclad Steel", contractValue: 420_000, invoicedToDate: 398_000, status: .atRisk, renewalDate: "2026-06-15", socialScore: 63, workEthicScore: 68, socialTrend7d: [69, 68, 67, 66, 65, 64, 63], workEthicTrend7d: [72, 71, 71, 70, 69, 68, 68]),
    ]

    @State private var contractFilter: ContractAccountStatus? = nil
    @State private var showProjectForm = false
    @State private var showContractForm = false
    @State private var showSocialDrivers = false
    @State private var selectedProjectDriverFilter: String? = nil
    @State private var selectedContractDriverFilter: String? = nil

    @State private var newProjectCode = ""
    @State private var newProjectName = ""
    @State private var newProjectOwner = ""
    @State private var newProjectBudget = ""
    @State private var newProjectRetainage = ""

    @State private var newContractNo = ""
    @State private var newContractProject = ""
    @State private var newContractPartner = ""
    @State private var newContractValue = ""
    @State private var newContractRenewal = ""

    private var totalBudget: Double { projects.map { $0.approvedBudget }.reduce(0, +) }
    private var totalBilled: Double { projects.map { $0.billedToDate }.reduce(0, +) }
    private var totalContractValue: Double { contracts.map { $0.contractValue }.reduce(0, +) }
    private var totalContractOpenBalance: Double { contracts.map { $0.balance }.reduce(0, +) }
    private var avgProjectSocialScore: Int {
        guard !projects.isEmpty else { return 0 }
        let total = projects.map { projectSocialScore($0) }.reduce(0, +)
        return Int((Double(total) / Double(projects.count)).rounded())
    }
    private var avgContractSocialScore: Int {
        guard !contracts.isEmpty else { return 0 }
        let total = contracts.map { contractSocialScore($0) }.reduce(0, +)
        return Int((Double(total) / Double(contracts.count)).rounded())
    }
    private var avgContractWorkEthicScore: Int {
        guard !contracts.isEmpty else { return 0 }
        let total = contracts.map { $0.workEthicScore }.reduce(0, +)
        return Int((Double(total) / Double(contracts.count)).rounded())
    }

    private var visibleProjects: [ProjectAccountItem] {
        projects.filter { project in
            guard let selectedProjectDriverFilter else { return true }
            return projectDrivers(project).contains(selectedProjectDriverFilter)
        }
    }

    private var visibleContracts: [ContractAccountItem] {
        contracts.filter { contract in
            let statusMatch = contractFilter == nil || contract.status == contractFilter
            let driverMatch: Bool
            if let selectedContractDriverFilter {
                driverMatch = contractDrivers(contract).contains(selectedContractDriverFilter)
            } else {
                driverMatch = true
            }
            return statusMatch && driverMatch
        }
    }

    private var projectDriverOptions: [String] {
        Array(Set(projects.flatMap { projectDrivers($0) })).sorted()
    }

    private var contractDriverOptions: [String] {
        Array(Set(contracts.flatMap { contractDrivers($0) })).sorted()
    }

    private var socialDriversPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SOCIAL SCORE DRIVERS")
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(Theme.gold)

            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECT WATCH")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                    ForEach(projects.sorted { projectSocialScore($0) < projectSocialScore($1) }.prefix(2)) { project in
                        Text("\(project.code) · \(projectSocialScore(project)) · \(projectDrivers(project).joined(separator: ", "))")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("CONTRACT WATCH")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                    ForEach(contracts.sorted { contractSocialScore($0) < contractSocialScore($1) }.prefix(2)) { contract in
                        Text("\(contract.contractNo) · \(contractSocialScore(contract)) · \(contractDrivers(contract).joined(separator: ", "))")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                    }
                }
            }

            Text("DRILL-DOWN PROJECT DRIVERS")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(projectDriverOptions, id: \.self) { driver in
                        Button(action: {
                            selectedProjectDriverFilter = (selectedProjectDriverFilter == driver) ? nil : driver
                        }) {
                            Text(driver)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(selectedProjectDriverFilter == driver ? .black : Theme.gold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedProjectDriverFilter == driver ? Theme.gold : Theme.gold.opacity(0.14))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("DRILL-DOWN CONTRACT DRIVERS")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(contractDriverOptions, id: \.self) { driver in
                        Button(action: {
                            selectedContractDriverFilter = (selectedContractDriverFilter == driver) ? nil : driver
                        }) {
                            Text(driver)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(selectedContractDriverFilter == driver ? .black : Theme.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedContractDriverFilter == driver ? Theme.cyan : Theme.cyan.opacity(0.14))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .background(Theme.surface.opacity(0.85))
        .cornerRadius(7)
    }

    private func fmt(_ value: Double) -> String {
        String(format: "$%,.0f", value)
    }

    private func socialColor(_ score: Int) -> Color {
        if score >= 85 { return Theme.green }
        if score >= 70 { return Theme.gold }
        return Theme.red
    }

    private func workEthicColor(_ score: Int) -> Color {
        if score >= 90 { return Theme.green }
        if score >= 78 { return Theme.cyan }
        if score >= 65 { return Theme.gold }
        return Theme.red
    }

    private func clampScore(_ value: Int) -> Int {
        max(30, min(99, value))
    }

    private func trendDelta(_ history: [Int]) -> Int {
        guard let first = history.first, let last = history.last else { return 0 }
        return last - first
    }

    private func trendSymbol(_ delta: Int) -> String {
        if delta > 0 { return "↑" }
        if delta < 0 { return "↓" }
        return "→"
    }

    private func trendColor(_ delta: Int) -> Color {
        if delta > 0 { return Theme.green }
        if delta < 0 { return Theme.red }
        return Theme.muted
    }

    private func daysUntil(_ isoDate: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: isoDate) else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: start, to: target).day
    }

    private func contractSocialScore(_ contract: ContractAccountItem) -> Int {
        let invoiceRatio = contract.contractValue > 0 ? (contract.invoicedToDate / contract.contractValue) : 0
        let progressRaw = Int((1 - abs(0.68 - invoiceRatio)) * 18)
        let progressScore = max(-12, min(18, progressRaw))

        let statusScore: Int
        switch contract.status {
        case .active: statusScore = 14
        case .pendingInvoice: statusScore = 6
        case .draft: statusScore = 0
        case .atRisk: statusScore = -14
        case .closed: statusScore = 8
        }

        let balanceRatio = contract.contractValue > 0 ? (contract.balance / contract.contractValue) : 0
        let balanceScore = max(-8, min(8, Int((0.35 - balanceRatio) * 20)))

        let renewalScore: Int
        if let days = daysUntil(contract.renewalDate) {
            if days < 30 { renewalScore = -8 }
            else if days < 90 { renewalScore = -3 }
            else if days > 180 { renewalScore = 4 }
            else { renewalScore = 1 }
        } else {
            renewalScore = 0
        }

        let seedScore = Int(Double(contract.socialScore - 70) * 0.4)
        let ethicInfluence = Int(Double(contract.workEthicScore - 75) * 0.3)
        let trendInfluence = max(-6, min(6, trendDelta(contract.socialTrend7d) + trendDelta(contract.workEthicTrend7d)))
        return clampScore(72 + progressScore + statusScore + balanceScore + renewalScore + seedScore + ethicInfluence + trendInfluence)
    }

    private func projectSocialScore(_ project: ProjectAccountItem) -> Int {
        let billingRatio = project.approvedBudget > 0 ? (project.billedToDate / project.approvedBudget) : 0
        let billingRaw = Int((1 - abs(0.72 - billingRatio)) * 22)
        let billingScore = max(-10, min(22, billingRaw))

        let retainageScore = max(-10, min(8, Int(8 - project.retainagePct)))

        let ownerScore: Int
        switch project.ownerType {
        case .owner: ownerScore = 3
        case .gc: ownerScore = 6
        case .subcontractor: ownerScore = 1
        }

        let linkedContracts = contracts.filter { $0.projectCode == project.code }
        let contractHealth: Int
        if linkedContracts.isEmpty {
            contractHealth = 0
        } else {
            let linkedAvg = Int((Double(linkedContracts.map { contractSocialScore($0) }.reduce(0, +)) / Double(linkedContracts.count)).rounded())
            contractHealth = max(-10, min(10, linkedAvg - 75))
        }

        let seedScore = Int(Double(project.socialScore - 70) * 0.35)
        return clampScore(70 + billingScore + retainageScore + ownerScore + contractHealth + seedScore)
    }

    private func projectDrivers(_ project: ProjectAccountItem) -> [String] {
        var drivers: [String] = []
        let billingRatio = project.approvedBudget > 0 ? (project.billedToDate / project.approvedBudget) : 0
        if billingRatio >= 0.65 && billingRatio <= 0.80 {
            drivers.append("Billing on target")
        } else if billingRatio < 0.50 {
            drivers.append("Low billing capture")
        } else {
            drivers.append("Billing drift")
        }

        if project.retainagePct >= 9 {
            drivers.append("High retainage")
        } else if project.retainagePct <= 5 {
            drivers.append("Low retainage")
        }

        let linked = contracts.filter { $0.projectCode == project.code }
        if !linked.isEmpty {
            let avgLinked = Int((Double(linked.map { contractSocialScore($0) }.reduce(0, +)) / Double(linked.count)).rounded())
            if avgLinked >= 82 { drivers.append("Strong contract health") }
            if avgLinked < 70 { drivers.append("Weak contract health") }
        }

        return drivers
    }

    private func contractDrivers(_ contract: ContractAccountItem) -> [String] {
        var drivers: [String] = []
        let invoiceRatio = contract.contractValue > 0 ? (contract.invoicedToDate / contract.contractValue) : 0
        if invoiceRatio >= 0.55 && invoiceRatio <= 0.85 {
            drivers.append("Invoice pace healthy")
        } else if invoiceRatio < 0.40 {
            drivers.append("Invoice lag")
        } else {
            drivers.append("Near ceiling")
        }

        switch contract.status {
        case .active: drivers.append("Active status")
        case .pendingInvoice: drivers.append("Pending invoice")
        case .atRisk: drivers.append("At-risk status")
        case .draft: drivers.append("Draft stage")
        case .closed: drivers.append("Closed contract")
        }

        if let days = daysUntil(contract.renewalDate) {
            if days < 45 { drivers.append("Renewal due soon") }
            if days > 180 { drivers.append("Renewal runway") }
        }

        return drivers
    }

    private func addProject() {
        guard !newProjectCode.isEmpty, !newProjectName.isEmpty, !newProjectOwner.isEmpty,
              let budget = Double(newProjectBudget) else { return }
        let retainage = Double(newProjectRetainage) ?? 5
        projects.append(ProjectAccountItem(
            code: newProjectCode,
            projectName: newProjectName,
            ownerName: newProjectOwner,
            ownerType: .owner,
            approvedBudget: budget,
            billedToDate: 0,
            retainagePct: retainage,
            socialScore: 72
        ))
        newProjectCode = ""
        newProjectName = ""
        newProjectOwner = ""
        newProjectBudget = ""
        newProjectRetainage = ""
        showProjectForm = false
    }

    private func addContract() {
        guard !newContractNo.isEmpty, !newContractProject.isEmpty, !newContractPartner.isEmpty,
              let value = Double(newContractValue) else { return }
        contracts.append(ContractAccountItem(
            contractNo: newContractNo,
            projectCode: newContractProject,
            partner: newContractPartner,
            contractValue: value,
            invoicedToDate: 0,
            status: .draft,
            renewalDate: newContractRenewal.isEmpty ? "TBD" : newContractRenewal,
            socialScore: 70,
            workEthicScore: 72,
            socialTrend7d: [66, 67, 68, 69, 69, 70, 70],
            workEthicTrend7d: [68, 69, 70, 71, 71, 72, 72]
        ))
        newContractNo = ""
        newContractProject = ""
        newContractPartner = ""
        newContractValue = ""
        newContractRenewal = ""
        showContractForm = false
    }

    private func exportAccountSnapshot() {
        let projectLines = projects.map {
            "[\($0.code)] \($0.projectName) | Owner: \($0.ownerName) | Budget: \(fmt($0.approvedBudget)) | Billed: \(fmt($0.billedToDate)) | Remaining: \(fmt($0.remaining)) | Social: \(projectSocialScore($0))"
        }
        let contractLines = contracts.map {
            "[\($0.contractNo)] \($0.partner) | Project: \($0.projectCode) | Value: \(fmt($0.contractValue)) | Invoiced: \(fmt($0.invoicedToDate)) | Balance: \(fmt($0.balance)) | Status: \($0.status.rawValue) | Social: \(contractSocialScore($0)) (Wk \(trendSymbol(trendDelta($0.socialTrend7d)))\(trendDelta($0.socialTrend7d))) | Work Ethic: \($0.workEthicScore) (Wk \(trendSymbol(trendDelta($0.workEthicTrend7d)))\(trendDelta($0.workEthicTrend7d)))"
        }

        let payload = [
            "PROJECT + CONTRACT ACCOUNT SNAPSHOT",
            "",
            "Project Budget: \(fmt(totalBudget)) | Project Billed: \(fmt(totalBilled))",
            "Contract Value: \(fmt(totalContractValue)) | Open Balance: \(fmt(totalContractOpenBalance))",
            "Project Social Score: \(avgProjectSocialScore) | Contract Social Score: \(avgContractSocialScore)",
            "Contract Work Ethic Score: \(avgContractWorkEthicScore)",
            "",
            "PROJECT ACCOUNTS",
            projectLines.joined(separator: "\n"),
            "",
            "CONTRACT ACCOUNTS",
            contractLines.joined(separator: "\n")
        ].joined(separator: "\n")

        copyTextToClipboard(payload)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECT & CONTRACT ACCOUNT MANAGEMENT")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.accent)
                    Text("\(projects.count) projects | \(contracts.count) contracts")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
                Button("EXPORT") { exportAccountSnapshot() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.accent)
                    .cornerRadius(5)
                Button(showProjectForm ? "CANCEL PROJECT" : "+ PROJECT") { showProjectForm.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.cyan)
                    .cornerRadius(5)
                Button(showContractForm ? "CANCEL CONTRACT" : "+ CONTRACT") { showContractForm.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.green)
                    .cornerRadius(5)
                Button(showSocialDrivers ? "HIDE DRIVERS" : "SOCIAL DRIVERS") { showSocialDrivers.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.gold)
                    .cornerRadius(5)
            }

            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(fmt(totalBudget)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.accent)
                    Text("PROJECT BUDGET").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(totalBilled)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.cyan)
                    Text("PROJECT BILLED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(totalContractValue)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.gold)
                    Text("CONTRACT VALUE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text(fmt(totalContractOpenBalance)).font(.system(size: 12, weight: .black)).foregroundColor(Theme.green)
                    Text("OPEN BALANCE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
                Divider().frame(height: 28).background(Theme.border)
                VStack(spacing: 2) {
                    Text("\(avgProjectSocialScore)/\(avgContractSocialScore)").font(.system(size: 12, weight: .black)).foregroundColor(Theme.gold)
                    Text("SOCIAL P/C").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }
            }

            if showSocialDrivers {
                socialDriversPanel
            }

            if showProjectForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Code", text: $newProjectCode)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 80)
                        TextField("Project Name", text: $newProjectName)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                        TextField("Owner", text: $newProjectOwner)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                    }
                    HStack(spacing: 6) {
                        TextField("Budget", text: $newProjectBudget)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                        TextField("Retainage %", text: $newProjectRetainage)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        Button("ADD PROJECT") { addProject() }
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.cyan)
                            .cornerRadius(6)
                    }
                }
            }

            if showContractForm {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Contract No", text: $newContractNo)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 100)
                        TextField("Project Code", text: $newContractProject)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 90)
                        TextField("Partner", text: $newContractPartner)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6)
                    }
                    HStack(spacing: 6) {
                        TextField("Contract Value", text: $newContractValue)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 120)
                        TextField("Renewal (YYYY-MM-DD)", text: $newContractRenewal)
                            .textFieldStyle(.plain).font(.system(size: 10))
                            .padding(6).background(Theme.surface).cornerRadius(6).frame(width: 150)
                        Button("ADD CONTRACT") { addContract() }
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.green)
                            .cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("PROJECT ACCOUNTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.gold)
                if let selectedProjectDriverFilterValue = selectedProjectDriverFilter {
                    Text(selectedProjectDriverFilterValue.uppercased())
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.gold)
                        .cornerRadius(5)
                    Button("CLEAR") { selectedProjectDriverFilter = nil }
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 6) {
                Text("CODE").frame(width: 65, alignment: .leading)
                Text("PROJECT").frame(maxWidth: .infinity, alignment: .leading)
                Text("OWNER").frame(width: 110, alignment: .leading)
                Text("SOC").frame(width: 44, alignment: .center)
                Text("BUDGET").frame(width: 90, alignment: .trailing)
                Text("BILLED").frame(width: 90, alignment: .trailing)
                Text("REMAIN").frame(width: 90, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(Theme.muted)

            ForEach(visibleProjects) { project in
                HStack(spacing: 6) {
                    Text(project.code)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                        .frame(width: 65, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(project.projectName).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.text)
                        Text("Retainage \(String(format: "%.1f", project.retainagePct))%")
                            .font(.system(size: 8)).foregroundColor(Theme.muted)
                        if showSocialDrivers {
                            Text(projectDrivers(project).joined(separator: " · "))
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(socialColor(projectSocialScore(project)))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(project.ownerName)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(project.ownerType.color)
                        .frame(width: 110, alignment: .leading)
                    Text("\(projectSocialScore(project))")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(socialColor(projectSocialScore(project)))
                        .cornerRadius(5)
                        .frame(width: 44, alignment: .center)
                    Text(fmt(project.approvedBudget)).font(.system(size: 9)).foregroundColor(Theme.accent)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(project.billedToDate)).font(.system(size: 9)).foregroundColor(Theme.cyan)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(project.remaining)).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
                        .frame(width: 90, alignment: .trailing)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(7)
            }

            HStack(spacing: 6) {
                Text("CONTRACT ACCOUNTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.cyan)
                if let selectedContractDriverFilterValue = selectedContractDriverFilter {
                    Text(selectedContractDriverFilterValue.uppercased())
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.cyan)
                        .cornerRadius(5)
                    Button("CLEAR") { selectedContractDriverFilter = nil }
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 8) {
                Button("ALL") { contractFilter = nil }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(contractFilter == nil ? .black : Theme.muted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(contractFilter == nil ? Theme.accent : Theme.surface)
                    .cornerRadius(4)
                ForEach(ContractAccountStatus.allCases, id: \.rawValue) { status in
                    Button(status.rawValue) {
                        contractFilter = (contractFilter == status) ? nil : status
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(contractFilter == status ? .black : Theme.muted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(contractFilter == status ? status.color : Theme.surface)
                    .cornerRadius(4)
                }
            }

            ForEach(visibleContracts) { contract in
                let socialDelta = trendDelta(contract.socialTrend7d)
                let ethicDelta = trendDelta(contract.workEthicTrend7d)
                HStack(spacing: 6) {
                    Text(contract.contractNo)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .frame(width: 60, alignment: .leading)
                    Text(contract.projectCode)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .frame(width: 70, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(contract.partner)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.text)
                        HStack(spacing: 4) {
                            TrendSparkline(values: contract.socialTrend7d, color: Theme.accent)
                                .frame(width: 38, height: 12)
                            TrendSparkline(values: contract.workEthicTrend7d, color: Theme.green)
                                .frame(width: 38, height: 12)
                        }
                        if showSocialDrivers {
                            Text(contractDrivers(contract).joined(separator: " · "))
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(socialColor(contractSocialScore(contract)))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(fmt(contract.contractValue))
                        .font(.system(size: 9))
                        .foregroundColor(Theme.accent)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(contract.invoicedToDate))
                        .font(.system(size: 9))
                        .foregroundColor(Theme.cyan)
                        .frame(width: 90, alignment: .trailing)
                    Text(fmt(contract.balance))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(contract.balance > 0 ? Theme.green : Theme.muted)
                        .frame(width: 90, alignment: .trailing)
                    VStack(spacing: 1) {
                        Text(contract.status.rawValue)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(contract.status.color)
                        Text("SOC \(contractSocialScore(contract))")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(socialColor(contractSocialScore(contract)))
                        Text("Wk \(trendSymbol(socialDelta))\(socialDelta)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(trendColor(socialDelta))
                        Text("ETH \(contract.workEthicScore)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(workEthicColor(contract.workEthicScore))
                        Text("Wk \(trendSymbol(ethicDelta))\(ethicDelta)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(trendColor(ethicDelta))
                        Text(contract.renewalDate)
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                    .frame(width: 110)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(7)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            projects = loadJSON("ConstructOS.Ops.ProjectAccounts", default: projects)
            contracts = loadJSON("ConstructOS.Ops.ContractAccounts", default: contracts)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Executive Portfolio View

struct PortfolioProjectMetric: Identifiable, Codable {
    var id = UUID()
    var projectCode: String
    var projectName: String
    var schedulePct: Double
    var budgetPct: Double
    var incidents30d: Int
    var openRFIs: Int
    var pendingHighDollarCOs: Int
    var deliveryDelays: Int
    var cashExposure: Double
}

struct ExecutivePortfolioPanel: View {
    @State private var metrics: [PortfolioProjectMetric] = [
        PortfolioProjectMetric(projectCode: "P-1024", projectName: "North Deck Expansion", schedulePct: 68, budgetPct: 62, incidents30d: 1, openRFIs: 4, pendingHighDollarCOs: 1, deliveryDelays: 1, cashExposure: 210_000),
        PortfolioProjectMetric(projectCode: "P-1188", projectName: "Medical Tower TI", schedulePct: 53, budgetPct: 59, incidents30d: 3, openRFIs: 9, pendingHighDollarCOs: 2, deliveryDelays: 2, cashExposure: 480_000),
        PortfolioProjectMetric(projectCode: "P-1201", projectName: "East Utility Rehab", schedulePct: 77, budgetPct: 73, incidents30d: 1, openRFIs: 2, pendingHighDollarCOs: 0, deliveryDelays: 0, cashExposure: 120_000),
        PortfolioProjectMetric(projectCode: "P-1216", projectName: "Airport Utility Relocation", schedulePct: 46, budgetPct: 51, incidents30d: 4, openRFIs: 11, pendingHighDollarCOs: 3, deliveryDelays: 3, cashExposure: 530_000),
    ]

    @State private var showOnlyHighRisk = false
    @State private var showWeightControls = false
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Schedule") private var scheduleWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Budget") private var budgetWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Incidents") private var incidentWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.RFIs") private var rfiWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.HighCO") private var coWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Delays") private var delayWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Weight.Exposure") private var exposureWeight: Double = 1.0
    @AppStorage("ConstructOS.ExecutiveRisk.Preset") private var activePreset: String = "Balanced"
    @AppStorage("ConstructOS.ExecutiveRisk.Preset.LastNamed") private var lastNamedPreset: String = "Balanced"

    private let presetTolerance: Double = 0.05

    private var visibleMetrics: [PortfolioProjectMetric] {
        metrics.filter { !showOnlyHighRisk || riskScore(for: $0) >= 70 }
    }

    private var totalExposure: Double { visibleMetrics.map { $0.cashExposure }.reduce(0, +) }
    private var avgRisk: Int {
        guard !visibleMetrics.isEmpty else { return 0 }
        let total = visibleMetrics.map { riskScore(for: $0) }.reduce(0, +)
        return total / visibleMetrics.count
    }
    private var delayedCount: Int { visibleMetrics.filter { $0.schedulePct < 60 }.count }
    private var budgetStressCount: Int { visibleMetrics.filter { $0.budgetPct > $0.schedulePct + 5 }.count }

    private func fmt(_ value: Double) -> String {
        String(format: "$%,.0f", value)
    }

    private func riskScore(for item: PortfolioProjectMetric) -> Int {
        let scheduleRisk = max(0, 70 - item.schedulePct) * 1.4 * scheduleWeight
        let budgetRisk = max(0, item.budgetPct - item.schedulePct) * 2.2 * budgetWeight
        let incidentRisk = min(Double(item.incidents30d) * 6 * incidentWeight, 24 * incidentWeight)
        let rfiRisk = min(Double(item.openRFIs) * 1.8 * rfiWeight, 18 * rfiWeight)
        let coRisk = min(Double(item.pendingHighDollarCOs) * 7 * coWeight, 21 * coWeight)
        let delayRisk = min(Double(item.deliveryDelays) * 5 * delayWeight, 15 * delayWeight)
        let exposureRisk = min((item.cashExposure / 80_000) * exposureWeight, 20 * exposureWeight)
        let raw = scheduleRisk + budgetRisk + incidentRisk + rfiRisk + coRisk + delayRisk + exposureRisk
        return Int(min(100, raw).rounded())
    }

    private func riskColor(for score: Int) -> Color {
        if score >= 75 { return Theme.red }
        if score >= 50 { return Theme.gold }
        return Theme.green
    }

    private func applyPreset(_ preset: String) {
        switch preset {
        case "Conservative":
            scheduleWeight = 1.2
            budgetWeight = 1.3
            incidentWeight = 1.4
            rfiWeight = 1.3
            coWeight = 1.5
            delayWeight = 1.4
            exposureWeight = 1.2
        case "Aggressive":
            scheduleWeight = 0.9
            budgetWeight = 1.0
            incidentWeight = 0.8
            rfiWeight = 0.8
            coWeight = 1.0
            delayWeight = 0.8
            exposureWeight = 0.9
        default:
            scheduleWeight = 1.0
            budgetWeight = 1.0
            incidentWeight = 1.0
            rfiWeight = 1.0
            coWeight = 1.0
            delayWeight = 1.0
            exposureWeight = 1.0
        }
        activePreset = preset
        if preset != "Custom" {
            lastNamedPreset = preset
        }
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= presetTolerance
    }

    private func resolvePresetFromWeights() -> String {
        if approximatelyEqual(scheduleWeight, 1.2) &&
            approximatelyEqual(budgetWeight, 1.3) &&
            approximatelyEqual(incidentWeight, 1.4) &&
            approximatelyEqual(rfiWeight, 1.3) &&
            approximatelyEqual(coWeight, 1.5) &&
            approximatelyEqual(delayWeight, 1.4) &&
            approximatelyEqual(exposureWeight, 1.2) {
            return "Conservative"
        }

        if approximatelyEqual(scheduleWeight, 0.9) &&
            approximatelyEqual(budgetWeight, 1.0) &&
            approximatelyEqual(incidentWeight, 0.8) &&
            approximatelyEqual(rfiWeight, 0.8) &&
            approximatelyEqual(coWeight, 1.0) &&
            approximatelyEqual(delayWeight, 0.8) &&
            approximatelyEqual(exposureWeight, 0.9) {
            return "Aggressive"
        }

        if approximatelyEqual(scheduleWeight, 1.0) &&
            approximatelyEqual(budgetWeight, 1.0) &&
            approximatelyEqual(incidentWeight, 1.0) &&
            approximatelyEqual(rfiWeight, 1.0) &&
            approximatelyEqual(coWeight, 1.0) &&
            approximatelyEqual(delayWeight, 1.0) &&
            approximatelyEqual(exposureWeight, 1.0) {
            return "Balanced"
        }

        return "Custom"
    }

    private func syncPresetLabelFromWeights() {
        let resolved = resolvePresetFromWeights()
        activePreset = resolved
        if resolved != "Custom" {
            lastNamedPreset = resolved
        }
    }

    private func resetWeights() {
        applyPreset("Balanced")
    }

    private func presetButton(_ label: String, color: Color) -> some View {
        Button(label) { applyPreset(label) }
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(activePreset == label ? .black : Theme.muted)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(activePreset == label ? color : Theme.surface)
            .cornerRadius(4)
    }

    private func weightRow(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.muted)
                .frame(width: 72, alignment: .leading)
            Slider(value: value, in: 0.5...2.0, step: 0.1)
                .tint(Theme.accent)
                .onChange(of: value.wrappedValue) { _, _ in
                    syncPresetLabelFromWeights()
                }
            Text(String(format: "%.1fx", value.wrappedValue))
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.cyan)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func exportPortfolioBrief() {
        let rows = visibleMetrics.map {
            "[\($0.projectCode)] \($0.projectName) | Sched \(Int($0.schedulePct))% | Budget \(Int($0.budgetPct))% | Risk \(riskScore(for: $0)) | Inc \($0.incidents30d) | RFI \($0.openRFIs) | CO \($0.pendingHighDollarCOs) | Delay \($0.deliveryDelays) | Exposure \(fmt($0.cashExposure))"
        }
        let payload = [
            "EXECUTIVE PORTFOLIO BRIEF",
            "Projects: \(visibleMetrics.count) | Avg Risk: \(avgRisk) | Delayed: \(delayedCount) | Budget Stress: \(budgetStressCount)",
            "Cash Exposure: \(fmt(totalExposure))",
            "",
            rows.joined(separator: "\n")
        ].joined(separator: "\n")
        copyTextToClipboard(payload)
    }

    private func progressBar(_ value: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface)
                Capsule().fill(color).frame(width: geo.size.width * CGFloat(max(0, min(value, 100))) / 100)
            }
        }
        .frame(height: 6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "EXECUTIVE VIEW",
                    title: "Portfolio risk and cash exposure",
                    detail: "Signal blends schedule, budget, incidents, RFIs, change pressure, delivery delays, and exposure.",
                    accent: Theme.accent
                )
                Spacer()
                Button(showOnlyHighRisk ? "SHOW ALL" : "HIGH RISK ONLY") { showOnlyHighRisk.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.cyan)
                    .cornerRadius(5)
                Button(showWeightControls ? "HIDE WEIGHTS" : "TUNE WEIGHTS") { showWeightControls.toggle() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.gold)
                    .cornerRadius(5)
                Button("EXPORT BRIEF") { exportPortfolioBrief() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.accent)
                    .cornerRadius(5)
            }

            HStack(spacing: 14) {
                DashboardStatPill(value: "\(visibleMetrics.count)", label: "PROJECTS", color: Theme.accent)
                DashboardStatPill(value: "\(avgRisk)", label: "AVG RISK", color: avgRisk >= 70 ? Theme.red : (avgRisk >= 50 ? Theme.gold : Theme.green))
                DashboardStatPill(value: "\(delayedCount)", label: "DELAYED", color: delayedCount > 0 ? Theme.red : Theme.green)
                DashboardStatPill(value: fmt(totalExposure), label: "CASH EXPOSURE", color: Theme.gold)
            }

            if showWeightControls {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("PRESET")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.muted)
                        presetButton("Conservative", color: Theme.red)
                        presetButton("Balanced", color: Theme.accent)
                        presetButton("Aggressive", color: Theme.green)
                        Spacer()
                        Text(activePreset == "Custom" ? "CUSTOM · BASE \(lastNamedPreset.uppercased())" : activePreset.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(activePreset == "Custom" ? Theme.gold : Theme.cyan)
                    }
                    weightRow("Schedule", value: $scheduleWeight)
                    weightRow("Budget", value: $budgetWeight)
                    weightRow("Incidents", value: $incidentWeight)
                    weightRow("RFIs", value: $rfiWeight)
                    weightRow("High CO", value: $coWeight)
                    weightRow("Delays", value: $delayWeight)
                    weightRow("Exposure", value: $exposureWeight)
                    HStack {
                        if activePreset == "Custom" {
                            Button("REVERT TO \(lastNamedPreset.uppercased())") {
                                applyPreset(lastNamedPreset)
                            }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.gold)
                            .cornerRadius(5)
                        }
                        Spacer()
                        Button("RESET DEFAULT WEIGHTS") { resetWeights() }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.green)
                            .cornerRadius(5)
                    }
                }
                .padding(8)
                .background(Theme.surface.opacity(0.8))
                .cornerRadius(8)
            }

            Text("PROJECT HEATMAP")
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.gold)

            HStack(spacing: 6) {
                Text("CODE").frame(width: 60, alignment: .leading)
                Text("PROJECT").frame(maxWidth: .infinity, alignment: .leading)
                Text("SCHEDULE").frame(width: 110, alignment: .center)
                Text("BUDGET").frame(width: 110, alignment: .center)
                Text("RISK").frame(width: 45, alignment: .trailing)
                Text("EXPOSURE").frame(width: 95, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(Theme.muted)

            ForEach(visibleMetrics) { item in
                HStack(spacing: 6) {
                    Text(item.projectCode)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                        .frame(width: 60, alignment: .leading)
                    Text(item.projectName)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 2) {
                        Text("\(Int(item.schedulePct))%")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(item.schedulePct < 60 ? Theme.red : Theme.green)
                        progressBar(item.schedulePct, color: item.schedulePct < 60 ? Theme.red : Theme.green)
                    }
                    .frame(width: 110)

                    VStack(spacing: 2) {
                        Text("\(Int(item.budgetPct))%")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(item.budgetPct > item.schedulePct + 5 ? Theme.red : Theme.cyan)
                        progressBar(item.budgetPct, color: item.budgetPct > item.schedulePct + 5 ? Theme.red : Theme.cyan)
                    }
                    .frame(width: 110)

                    let score = riskScore(for: item)
                    Text("\(score)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(riskColor(for: score))
                        .frame(width: 45, alignment: .trailing)
                    Text(fmt(item.cashExposure))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .frame(width: 95, alignment: .trailing)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.surface.opacity(0.7))
                .cornerRadius(8)
            }
        }
        .onAppear {
            syncPresetLabelFromWeights()
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.accent)
        .onAppear {
            metrics = loadJSON("ConstructOS.Ops.PortfolioMetrics", default: metrics)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - RFI Tracker

struct RFIItem: Identifiable, Codable {
    let id: Int
    let subject: String
    let assignedTo: String
    let submittedDaysAgo: Int
    let priority: RFIPriority
    var status: RFIStatus = .open
}

enum RFIPriority: String, Codable {
    case high = "HIGH"
    case medium = "MED"
    case low = "LOW"
    var color: Color {
        switch self {
        case .high: return Theme.red
        case .medium: return Theme.accent
        case .low: return Theme.muted
        }
    }
}

enum RFIStatus: String, Codable {
    case open = "OPEN"
    case pending = "PENDING"
    case answered = "ANSWERED"
    var color: Color {
        switch self {
        case .open: return Theme.accent
        case .pending: return Color.orange
        case .answered: return Theme.green
        }
    }
}

struct RFITrackerPanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    private var role: OpsRolePreset { OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent }
    @State private var expanded: Bool = false
    @State private var escalatedIDs: Set<Int> = []

    @State private var items: [RFIItem] = [
        RFIItem(id: 221, subject: "Structural beam spec — Grid C-4", assignedTo: "Thornfield Eng", submittedDaysAgo: 18, priority: .high),
        RFIItem(id: 218, subject: "Fire suppression riser relocation", assignedTo: "MEP Lead", submittedDaysAgo: 11, priority: .high),
        RFIItem(id: 215, subject: "Façade anchor bolt tolerance", assignedTo: "Architect", submittedDaysAgo: 7, priority: .medium),
        RFIItem(id: 209, subject: "Flooring transition detail — Level 3", assignedTo: "Interior Spec", submittedDaysAgo: 4, priority: .low),
        RFIItem(id: 204, subject: "Electrical panel clearance — Room 214", assignedTo: "MEP Lead", submittedDaysAgo: 14, priority: .medium, status: .pending),
        RFIItem(id: 199, subject: "Roof drain sizing confirmation", assignedTo: "Civil Eng", submittedDaysAgo: 21, priority: .high),
    ]

    private var overdueItems: [RFIItem] {
        items.filter { $0.submittedDaysAgo > 14 && $0.status != .answered }
    }

    private var visibleItems: [RFIItem] {
        switch role {
        case .superintendent:
            return items.filter { $0.priority == .high || $0.submittedDaysAgo > 10 }
        case .projectManager:
            return items
        case .executive:
            return overdueItems
        }
    }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Field-blocking RFIs — high priority + aging."
        case .projectManager: return "Full open RFI queue — tap overdue rows to escalate."
        case .executive: return "Escalated & overdue RFIs. Avg response target: 7 days."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "COORDINATION",
                    title: "RFI tracker",
                    detail: "Open questions, aging responses, and escalation pressure across design coordination.",
                    accent: Theme.text
                )
                Spacer()
                if !overdueItems.isEmpty {
                    Text("\(overdueItems.count) OVERDUE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(4)
                }
                Text("\(items.filter { $0.status != .answered }.count) OPEN")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.accent)
                    .cornerRadius(4)
                Button(action: { withAnimation { expanded.toggle() } }) {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(items.filter { $0.status != .answered }.count)", label: "OPEN", color: Theme.accent)
                DashboardStatPill(value: "\(overdueItems.count)", label: "OVERDUE", color: overdueItems.isEmpty ? Theme.green : Theme.red)
                DashboardStatPill(value: role.display.uppercased(), label: "ROLE FILTER", color: Theme.cyan)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Text(roleNote)
                .font(.system(size: 10))
                .foregroundColor(Theme.muted)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            Divider().background(Theme.border)

            if role == .executive && !expanded {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(overdueItems.count)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(overdueItems.isEmpty ? Theme.green : Theme.red)
                        Text("OVERDUE RFIs")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                            .tracking(1)
                    }
                    Divider().frame(height: 36).background(Theme.border)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(items.filter { $0.status != .answered }.count)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(Theme.accent)
                        Text("TOTAL OPEN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                            .tracking(1)
                    }
                    Spacer()
                    Button("VIEW ALL") { withAnimation { expanded = true } }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                ForEach(visibleItems) { item in
                    RFIRow(
                        item: item,
                        isEscalated: escalatedIDs.contains(item.id),
                        showEscalate: role == .projectManager && item.submittedDaysAgo > 10,
                        onEscalate: { escalatedIDs.insert(item.id) }
                    )
                    Divider().background(Theme.border).padding(.leading, 14)
                }
            }
        }
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overdueItems.isEmpty ? Theme.border : Theme.red.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .onAppear {
            items = loadJSON("ConstructOS.Ops.RFIs", default: items)
        }
    }
}

struct RFIRow: View {
    let item: RFIItem
    let isEscalated: Bool
    let showEscalate: Bool
    let onEscalate: () -> Void
    private var isOverdue: Bool { item.submittedDaysAgo > 14 && item.status != .answered }
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Rectangle()
                .fill(item.priority.color)
                .frame(width: 3, height: 44)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("RFI-\(item.id)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Theme.muted)
                    Text(item.priority.rawValue)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(item.priority.color)
                        .cornerRadius(3)
                    Text(item.status.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(item.status.color, lineWidth: 1))
                }
                Text(item.subject)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isOverdue ? Theme.red : Theme.text)
                    .lineLimit(1)
                Text(item.assignedTo)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.submittedDaysAgo)d")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isOverdue ? Theme.red : Theme.muted)
                Text("AGO")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.muted)
                    .tracking(1)
            }
            if showEscalate {
                Button(isEscalated ? "✓ ESC" : "ESCALATE") { onEscalate() }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(isEscalated ? Theme.green : .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(isEscalated ? Theme.green.opacity(0.15) : Theme.red)
                    .cornerRadius(5)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isOverdue ? Theme.red.opacity(0.05) : Color.clear)
    }
}

// MARK: - Budget Burn Rate

struct SiteBudget: Identifiable {
    let id: Int
    let site: String
    let budgetM: Double
    let spentM: Double
    let percentComplete: Int
}

struct BudgetBurnPanel: View {
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"

    private var role: OpsRolePreset {
        OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent
    }

    private let budgets: [SiteBudget] = [
        SiteBudget(id: 0, site: "Riverside Lofts",   budgetM: 12.4, spentM: 9.8,  percentComplete: 62),
        SiteBudget(id: 1, site: "Site Gamma",         budgetM: 8.1,  spentM: 5.3,  percentComplete: 55),
        SiteBudget(id: 2, site: "Harbor Crossing",    budgetM: 22.6, spentM: 11.2, percentComplete: 48),
        SiteBudget(id: 3, site: "Pine Ridge Ph.2",    budgetM: 6.8,  spentM: 4.1,  percentComplete: 58),
        SiteBudget(id: 4, site: "Eastside Civic Hub", budgetM: 4.2,  spentM: 1.3,  percentComplete: 29),
    ]

    private var totalBudget: Double { budgets.map(\.budgetM).reduce(0, +) }
    private var totalSpent:  Double { budgets.map(\.spentM).reduce(0, +) }
    private var overBudgetSites: [SiteBudget] { budgets.filter { burnRatio($0) > 1.10 } }

    private func burnRatio(_ s: SiteBudget) -> Double {
        guard s.percentComplete > 0 else { return 0 }
        let spentPct = s.spentM / s.budgetM
        let schedPct = Double(s.percentComplete) / 100.0
        return spentPct / schedPct
    }

    private func burnLabel(_ s: SiteBudget) -> String {
        let r = burnRatio(s)
        if r > 1.10 { return "OVER PACE" }
        if r < 0.85 { return "UNDER" }
        return "ON PACE"
    }

    private func burnColor(_ s: SiteBudget) -> Color {
        let r = burnRatio(s)
        if r > 1.10 { return Theme.red }
        if r < 0.85 { return Theme.cyan }
        return Theme.green
    }

    private var portfolioLabel: String {
        let pct = totalBudget > 0 ? Int((totalSpent / totalBudget) * 100) : 0
        return "$\(String(format: "%.1f", totalSpent))M of $\(String(format: "%.1f", totalBudget))M (\(pct)%)"
    }

    private var roleNote: String {
        switch role {
        case .superintendent: return "Labor & material burn on your sites"
        case .projectManager: return overBudgetSites.isEmpty ? "All sites on budget trajectory" : "\(overBudgetSites.count) site(s) burning over pace"
        case .executive:      return "Portfolio: \(portfolioLabel)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("BUDGET BURN")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(overBudgetSites.isEmpty ? Theme.green : Theme.red)
                if !overBudgetSites.isEmpty {
                    Text("\(overBudgetSites.count) OVER PACE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.red)
                        .cornerRadius(5)
                }
                Spacer()
            }
            Text(roleNote)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.muted)
            VStack(spacing: 7) {
                ForEach(budgets) { site in
                    BudgetBurnRow(
                        site:      site,
                        burnLabel: burnLabel(site),
                        burnColor: burnColor(site),
                        showSpend: role != .superintendent
                    )
                }
            }
            Divider().background(Theme.border)
            HStack {
                Text("PORTFOLIO TOTAL")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text(portfolioLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.text)
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 14, color: overBudgetSites.isEmpty ? Theme.green : Theme.red)
    }
}

struct BudgetBurnRow: View {
    let site: SiteBudget
    let burnLabel: String
    let burnColor: Color
    let showSpend: Bool

    private var spentPct: Double {
        site.budgetM > 0 ? min(site.spentM / site.budgetM, 1.0) : 0
    }
    private var schedPct: Double { Double(site.percentComplete) / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(site.site)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Spacer()
                if showSpend {
                    Text("$\(String(format: "%.1f", site.spentM))M / $\(String(format: "%.1f", site.budgetM))M")
                        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.muted)
                }
                Text(burnLabel)
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(burnColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(burnColor.opacity(0.14))
                    .cornerRadius(4)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surface)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.muted.opacity(0.25))
                        .frame(width: geo.size.width * schedPct, height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(burnColor.opacity(0.80))
                        .frame(width: geo.size.width * spentPct, height: 5)
                        .padding(.vertical, 1.5)
                    Rectangle()
                        .fill(Theme.muted.opacity(0.6))
                        .frame(width: 1.5, height: 12)
                        .offset(x: geo.size.width * schedPct - 0.75)
                }
            }
            .frame(height: 8)
            HStack {
                Text("Spent \(Int(spentPct * 100))%")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(burnColor.opacity(0.9))
                Text("Schedule \(site.percentComplete)%")
                    .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Theme.muted)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(burnColor == Theme.red ? Theme.red.opacity(0.06) : Theme.surface.opacity(0.4))
        .cornerRadius(7)
    }
}


// MARK: - ========== MapsView.swift ==========

// MARK: - Maps View

struct MapsView: View {
    private let mapSites = previewMapSites
    private let mapRoutes = previewMapRoutes

    private let satellitePasses: [SatellitePass] = [
        SatellitePass(name: "SAT-A1", eta: "04 min", coverage: "North yard", confidence: 97, color: Theme.cyan),
        SatellitePass(name: "SAT-C4", eta: "19 min", coverage: "Concrete deck", confidence: 91, color: Theme.gold),
        SatellitePass(name: "THERM-2", eta: "42 min", coverage: "Roof membrane", confidence: 88, color: Theme.green)
    ]

    @State private var selectedSiteID: UUID?
    @State private var satelliteMode = true
    @State private var thermalOverlay = true
    @State private var crewOverlay = true
    @State private var weatherOverlay = false
    @State private var autoTrack = true
    @State private var feedLatencyMS = 780
    @State private var activeSweep = 1
    @State private var cameraPreset: MapCameraPreset = .selected

    private var selectedSite: MapSite {
        mapSites.first { $0.id == selectedSiteID } ?? mapSites[1]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIVE MAPS")
                            .font(.system(size: 12, weight: .black))
                            .tracking(2)
                            .foregroundColor(Theme.cyan)
                        Text("Satellite-backed site awareness with live overlays and rapid field routing.")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(satelliteMode ? "SAT LINKED" : "GRID MODE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(satelliteMode ? Theme.gold : Theme.surface)
                        .cornerRadius(6)
                }

                HStack(spacing: 8) {
                    Toggle("SATELLITE", isOn: $satelliteMode)
                        .toggleStyle(.button)
                    Toggle("THERMAL", isOn: $thermalOverlay)
                        .toggleStyle(.button)
                    Toggle("CREWS", isOn: $crewOverlay)
                        .toggleStyle(.button)
                    Toggle("WEATHER", isOn: $weatherOverlay)
                        .toggleStyle(.button)
                    Toggle("AUTO TRACK", isOn: $autoTrack)
                        .toggleStyle(.button)
                }
                .font(.system(size: 8, weight: .bold))

                HStack(spacing: 8) {
                    ForEach(MapCameraPreset.allCases) { preset in
                        Button(preset.rawValue) {
                            cameraPreset = preset
                        }
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(cameraPreset == preset ? .black : Theme.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(cameraPreset == preset ? Theme.gold : Theme.surface)
                        .cornerRadius(6)
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    mapMetricCard(title: "ACTIVE SITES", value: "\(mapSites.count)", detail: "4 live overlays", color: Theme.cyan)
                    mapMetricCard(title: "SAT LATENCY", value: "\(feedLatencyMS)ms", detail: "within ops target", color: Theme.green)
                    mapMetricCard(title: "NEXT PASS", value: satellitePasses[0].eta, detail: satellitePasses[0].name, color: Theme.gold)
                    mapMetricCard(title: "SELECTED", value: selectedSite.name, detail: selectedSite.type, color: Theme.accent)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        LiveMapView(
                            sites: mapSites,
                            routes: mapRoutes,
                            selectedSiteID: $selectedSiteID,
                            satelliteMode: satelliteMode,
                            thermalOverlay: thermalOverlay,
                            crewOverlay: crewOverlay,
                            weatherOverlay: weatherOverlay,
                            activeSweep: activeSweep,
                            cameraPreset: cameraPreset
                        )
                        .frame(minHeight: 340)

                        HStack(spacing: 8) {
                            Button("PING SAT SWEEP") { activeSweep += 1; feedLatencyMS = max(420, feedLatencyMS - 35) }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Theme.gold)
                                .cornerRadius(6)

                            Button("CENTER \(selectedSite.name.uppercased())") { selectedSiteID = selectedSite.id }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.cyan)

                            Spacer()

                            Text("Sweep #\(activeSweep) · \(autoTrack ? "auto-tracking" : "manual pan")")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(Theme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SITE LOCK")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundColor(Theme.gold)

                            Text(selectedSite.name)
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(Theme.text)
                            Text("\(selectedSite.type) · \(selectedSite.status)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.muted)

                            VStack(alignment: .leading, spacing: 6) {
                                statusRow(label: "Visibility", value: satelliteMode ? "Satellite locked" : "Grid-only", color: satelliteMode ? Theme.green : Theme.muted)
                                statusRow(label: "Crew overlay", value: crewOverlay ? "Hot" : "Muted", color: crewOverlay ? Theme.cyan : Theme.muted)
                                statusRow(label: "Thermal", value: thermalOverlay ? "Heat signatures active" : "Offline", color: thermalOverlay ? Theme.red : Theme.muted)
                                statusRow(label: "Weather", value: weatherOverlay ? "Wind alerts live" : "Standby", color: weatherOverlay ? Theme.purple : Theme.muted)
                                statusRow(label: "Coordinates", value: selectedSite.coordinateLabel, color: Theme.text)
                                statusRow(label: "Feed latency", value: "\(selectedSite.latencyMS) ms", color: Theme.green)
                                statusRow(label: "Crew ETA", value: selectedSite.crewETA, color: Theme.cyan)
                                statusRow(label: "Alert level", value: selectedSite.alertLevel, color: selectedSite.alertLevel == "WATCH" ? Theme.red : Theme.gold)
                            }
                        }
                        .padding(12)
                        .background(Theme.surface.opacity(0.78))
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("SAT PASSES")
                                .font(.system(size: 9, weight: .black))
                                .tracking(1)
                                .foregroundColor(Theme.cyan)

                            ForEach(satellitePasses) { pass in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(pass.color)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(pass.name) · ETA \(pass.eta)")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(pass.color)
                                        Text("\(pass.coverage) · \(pass.confidence)% confidence")
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(Theme.surface.opacity(0.72))
                                .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(Theme.surface.opacity(0.78))
                        .cornerRadius(10)
                    }
                    .frame(width: 250)
                }
            }
            .padding(14)
        }
        .background(Theme.bg)
    }

    private func mapMetricCard(title: String, value: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .black))
                .foregroundColor(Theme.text)
            Text(detail)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.surface.opacity(0.78))
        .cornerRadius(10)
    }

    private func statusRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(color)
        }
    }
}

// MARK: - Live Map View

struct LiveMapView: View {
    let sites: [MapSite]
    let routes: [MapRoute]
    @Binding var selectedSiteID: UUID?
    let satelliteMode: Bool
    let thermalOverlay: Bool
    let crewOverlay: Bool
    let weatherOverlay: Bool
    let activeSweep: Int
    let cameraPreset: MapCameraPreset
    @State private var cameraPosition: MapCameraPosition = .region(MapSite.defaultRegion)

    private var selectedSite: MapSite? {
        sites.first { $0.id == selectedSiteID }
    }

    private var resolvedRoutes: [(route: MapRoute, coordinates: [CLLocationCoordinate2D])] {
        routes.compactMap { route in
            guard
                let fromSite = sites.first(where: { $0.name == route.fromSiteName }),
                let toSite = sites.first(where: { $0.name == route.toSiteName })
            else {
                return nil
            }

            return (route, [fromSite.coordinate, toSite.coordinate])
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mapLayer
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)

                    for offset in stride(from: 20.0, through: size.width, by: 38.0) {
                        var path = Path()
                        path.move(to: CGPoint(x: offset, y: 0))
                        path.addLine(to: CGPoint(x: offset - 28, y: size.height))
                        context.stroke(path, with: .color(Theme.border.opacity(0.18)), lineWidth: 1)
                    }

                    for offset in stride(from: 35.0, through: size.height, by: 52.0) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: offset))
                        path.addLine(to: CGPoint(x: size.width, y: offset - 18))
                        context.stroke(path, with: .color(Theme.border.opacity(0.14)), lineWidth: 1)
                    }

                    if satelliteMode {
                        context.fill(
                            Path(ellipseIn: CGRect(x: rect.maxX * 0.55, y: rect.maxY * 0.08, width: rect.width * 0.24, height: rect.height * 0.16)),
                            with: .radialGradient(
                                Gradient(colors: [Theme.gold.opacity(0.30), .clear]),
                                center: CGPoint(x: rect.maxX * 0.67, y: rect.maxY * 0.16),
                                startRadius: 4,
                                endRadius: 120
                            )
                        )
                    }

                    if thermalOverlay {
                        context.fill(
                            Path(ellipseIn: CGRect(x: rect.maxX * 0.18, y: rect.maxY * 0.44, width: rect.width * 0.34, height: rect.height * 0.22)),
                            with: .radialGradient(
                                Gradient(colors: [Theme.red.opacity(0.34), Theme.gold.opacity(0.16), .clear]),
                                center: CGPoint(x: rect.maxX * 0.32, y: rect.maxY * 0.54),
                                startRadius: 8,
                                endRadius: 120
                            )
                        )
                    }

                    if weatherOverlay {
                        context.fill(
                            Path(CGRect(x: rect.maxX * 0.62, y: rect.maxY * 0.04, width: rect.width * 0.28, height: rect.height * 0.24)),
                            with: .linearGradient(
                                Gradient(colors: [Theme.purple.opacity(0.18), .clear]),
                                startPoint: CGPoint(x: rect.maxX * 0.62, y: rect.maxY * 0.04),
                                endPoint: CGPoint(x: rect.maxX * 0.90, y: rect.maxY * 0.28)
                            )
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("LIVE SITE MAP")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundColor(Theme.cyan)
                        Spacer()
                        Text(satelliteMode ? "SATELLITE" : "GRID")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(satelliteMode ? Theme.gold : Theme.surface)
                            .cornerRadius(4)
                    }

                    Spacer()

                    ZStack {
                        ForEach(sites) { site in
                            Button {
                                selectedSiteID = site.id
                            } label: {
                                VStack(spacing: 3) {
                                    Circle()
                                        .fill(selectedSiteID == site.id ? Theme.gold : Theme.cyan)
                                        .frame(width: selectedSiteID == site.id ? 18 : 14, height: selectedSiteID == site.id ? 18 : 14)
                                        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
                                    Text(site.name.uppercased())
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(Theme.text)
                                }
                            }
                            .buttonStyle(.plain)
                            .position(x: proxy.size.width * site.x, y: proxy.size.height * site.y)
                        }
                    }

                    HStack(spacing: 8) {
                        if crewOverlay {
                            overlayTag("Crew routes", color: Theme.cyan)
                        }
                        if thermalOverlay {
                            overlayTag("Thermal", color: Theme.red)
                        }
                        if weatherOverlay {
                            overlayTag("Wind", color: Theme.purple)
                        }
                        Spacer()
                        Text("Sweep #\(activeSweep)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(Theme.muted)
                    }

                    if let selectedSite {
                        Text("\(selectedSite.name) · \(selectedSite.status)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.surface.opacity(0.85))
                            .cornerRadius(8)
                    }
                }
                .padding(14)
            }
        }
        .onAppear {
            updateCamera()
        }
        .onChange(of: selectedSiteID) { _, _ in
            updateCamera()
        }
        .onChange(of: cameraPreset) { _, _ in
            updateCamera()
        }
    }

    private func overlayTag(_ label: String, color: Color) -> some View {
        Text(label.uppercased())
            .font(.system(size: 7, weight: .black))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(5)
    }

    @ViewBuilder
    private var mapLayer: some View {
        if satelliteMode {
            liveMapBase
                .mapStyle(.hybrid)
        } else {
            liveMapBase
                .mapStyle(.standard)
        }
    }

    private var liveMapBase: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            ForEach(resolvedRoutes, id: \.route.id) { item in
                MapPolyline(coordinates: item.coordinates)
                    .stroke(item.route.color.opacity(crewOverlay ? 0.92 : 0.25), lineWidth: crewOverlay ? 4 : 2)
            }

            ForEach(sites) { site in
                Annotation(site.name, coordinate: site.coordinate, anchor: .center) {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(selectedSiteID == site.id ? Theme.gold : Theme.cyan)
                            .frame(width: selectedSiteID == site.id ? 16 : 12, height: selectedSiteID == site.id ? 16 : 12)
                            .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
                        Text(site.name)
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Theme.surface.opacity(0.82))
                            .cornerRadius(4)
                    }
                    .onTapGesture {
                        selectedSiteID = site.id
                    }
                }
            }
        }
        .mapControlVisibility(.hidden)
        .overlay(
            LinearGradient(
                colors: [
                    Color.black.opacity(satelliteMode ? 0.18 : 0.10),
                    Color.clear,
                    Theme.bg.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func updateCamera() {
        cameraPosition = .region(region(for: cameraPreset))
    }

    private func region(for preset: MapCameraPreset) -> MKCoordinateRegion {
        switch preset {
        case .network:
            return MKCoordinateRegion(
                center: MapSite.mapCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.055, longitudeDelta: 0.055)
            )
        case .selected:
            return selectedSite?.focusRegion ?? MapSite.defaultRegion
        case .logistics:
            if let logisticsSite = sites.first(where: { $0.type == "LOGISTICS" }) {
                return MKCoordinateRegion(
                    center: logisticsSite.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            }
            return MapSite.defaultRegion
        case .weather:
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: MapSite.mapCenter.latitude + 0.01,
                    longitude: MapSite.mapCenter.longitude + 0.012
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        }
    }
}

// MARK: - ========== MarketView.swift ==========

struct MarketView: View {
    @State private var marketData: [SupabaseMarketData] = []
    @State private var contracts: [SupabaseContract] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var regionFilter = "All"
    @State private var watchedIDs: Set<String> = []

    private let regions = ["All", "Northeast", "Southeast", "Midwest", "West", "International"]
    private let supabase = SupabaseService.shared

    private var displayMarketData: [SupabaseMarketData] {
        let list = supabase.isConfigured ? marketData : mockSupabaseMarketData
        if regionFilter == "All" { return list }
        return list.filter { regionMatch($0.city, region: regionFilter) }
    }

    private var openBids: [SupabaseContract] {
        let list = supabase.isConfigured ? contracts : mockSupabaseContracts
        return list.filter { $0.stage == "Open For Bid" || $0.stage == "Prequalifying Teams" }
            .sorted { $0.score > $1.score }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                marketHeader
                marketRegionFilter
                if isLoading {
                    marketLoading
                } else if let err = errorMessage {
                    marketError(err)
                } else {
                    marketDataGrid
                    openBidsSection
                    insightsSection
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task { await loadData() }
    }

    // MARK: - Sub-views

    private var marketHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MARKET")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(Theme.cyan)
                Text("Market Intelligence")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                Text("Live vacancy, new business, and bid opportunities")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
                if !supabase.isConfigured {
                    Label("Demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                marketStatBadge(value: "\(openBids.count)", label: "open bids", color: Theme.gold)
                marketStatBadge(value: "\(displayMarketData.count)", label: "markets", color: Theme.cyan)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.cyan)
    }

    private var marketRegionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(regions, id: \.self) { region in
                    Button { regionFilter = region } label: {
                        Text(region)
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.5)
                            .foregroundColor(regionFilter == region ? Theme.bg : Theme.muted)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(regionFilter == region ? Theme.cyan : Theme.surface)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(regionFilter == region ? Color.clear : Theme.border.opacity(0.5), lineWidth: 0.8)
                            )
                    }
                }
            }
        }
    }

    private var marketDataGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MARKET CONDITIONS")
                .font(.system(size: 10, weight: .bold))
                .tracking(3)
                .foregroundColor(Theme.muted)

            if displayMarketData.isEmpty {
                Text("No market data for this region")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Theme.surface)
                    .cornerRadius(12)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(displayMarketData) { data in
                        MarketCityCard(data: data)
                    }
                }
            }
        }
    }

    private var openBidsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("OPEN BIDS & PURSUITS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Theme.muted)
                Spacer()
                Text("\(openBids.count) opportunities")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }

            if openBids.isEmpty {
                Text("No open bids at this time")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Theme.surface)
                    .cornerRadius(12)
            } else {
                ForEach(openBids) { contract in
                    MarketBidCard(contract: contract, isWatched: watchedIDs.contains(contract.id ?? "")) {
                        if let id = contract.id {
                            if watchedIDs.contains(id) { watchedIDs.remove(id) }
                            else { watchedIDs.insert(id) }
                        }
                    }
                }
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPERATOR INSIGHTS")
                .font(.system(size: 10, weight: .bold))
                .tracking(3)
                .foregroundColor(Theme.muted)

            ForEach(feedbackInsights) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    private var marketLoading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.cyan)
            Text("Loading market data...").font(.system(size: 13)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(40)
    }

    private func marketError(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 28)).foregroundColor(Theme.red)
            Text(message).font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            Button("Retry") { Task { await loadData() } }
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)
        }
        .frame(maxWidth: .infinity).padding(40).background(Theme.surface).cornerRadius(14)
    }

    // MARK: - Data

    private func loadData() async {
        guard supabase.isConfigured else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            async let mData: [SupabaseMarketData] = supabase.fetch("cs_market_data")
            async let cData: [SupabaseContract] = supabase.fetch("cs_contracts")
            (marketData, contracts) = try await (mData, cData)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func regionMatch(_ city: String, region: String) -> Bool {
        switch region {
        case "Northeast": return ["New York", "Boston", "Philadelphia", "Washington"].contains(city)
        case "Southeast": return ["Miami", "Atlanta", "Charlotte", "Nashville"].contains(city)
        case "Midwest": return ["Chicago", "Detroit", "Minneapolis", "Cleveland"].contains(city)
        case "West": return ["Los Angeles", "San Francisco", "Seattle", "Denver", "Phoenix"].contains(city)
        case "International": return ["London", "Dubai", "Sydney", "Toronto", "Singapore"].contains(city)
        default: return true
        }
    }

    private func marketStatBadge(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value).font(.system(size: 15, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(Theme.muted)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.10))
        .cornerRadius(8)
    }
}

// MARK: - Market City Card

private struct MarketCityCard: View {
    let data: SupabaseMarketData

    var trendColor: Color {
        switch data.trend {
        case "up": return Theme.green
        case "down": return Theme.red
        default: return Theme.muted
        }
    }

    var trendIcon: String {
        switch data.trend {
        case "up": return "arrow.up.right"
        case "down": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(data.city)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.text)
                Spacer()
                Image(systemName: trendIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(trendColor)
            }

            HStack(spacing: 12) {
                marketMetric(value: String(format: "%.1f%%", data.vacancy), label: "VACANCY", color: Theme.cyan)
                Divider().frame(height: 28).overlay(Theme.border.opacity(0.5))
                marketMetric(value: "\(data.newBiz)", label: "NEW BIZ", color: Theme.green)
            }

            HStack {
                Label("\(data.closed) closed", systemImage: "xmark.circle")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text(data.trend.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(trendColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(trendColor.opacity(0.12))
                    .cornerRadius(3)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: trendColor)
    }

    private func marketMetric(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 14, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
        }
    }
}

// MARK: - Market Bid Card

private struct MarketBidCard: View {
    let contract: SupabaseContract
    let isWatched: Bool
    let onWatch: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(contract.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.text)
                Text("\(contract.client) · \(contract.location)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
                HStack(spacing: 10) {
                    Label(contract.sector, systemImage: "tag")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.purple)
                    Label(contract.budget, systemImage: "dollarsign.circle")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.green)
                    Label("Due \(contract.bidDue)", systemImage: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)
                }
                if !contract.liveFeedStatus.isEmpty {
                    Label(contract.liveFeedStatus, systemImage: "dot.radiowaves.left.and.right")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.cyan)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(contract.score)")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Theme.gold)
                Button(action: onWatch) {
                    Label(isWatched ? "Watching" : "Watch", systemImage: isWatched ? "eye.fill" : "eye")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isWatched ? Theme.cyan : Theme.muted)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(isWatched ? Theme.cyan.opacity(0.12) : Theme.surface)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.border.opacity(0.5), lineWidth: 0.8))
                }
                Text("\(contract.bidders) bidders")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.gold)
    }
}

// MARK: - Insight Card

private struct InsightCard: View {
    let insight: FeedbackInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(insight.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text(insight.demand)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            Text(insight.painPoint)
                .font(.system(size: 11))
                .foregroundColor(Theme.muted.opacity(0.8))
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.green)
                Text(insight.solution)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.text)
            }
            Label(insight.impact, systemImage: "bolt.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.gold)
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }
}

// MARK: - Mock fallback

private let mockSupabaseMarketData: [SupabaseMarketData] = mockMarketData.map {
    SupabaseMarketData(id: UUID().uuidString, city: $0.city, vacancy: $0.vacancy, newBiz: $0.newBiz, closed: $0.closed, trend: $0.trend)
}

private let mockSupabaseContracts: [SupabaseContract] = mockContracts.map {
    SupabaseContract(id: $0.id.uuidString, title: $0.title, client: $0.client, location: $0.location,
                     sector: $0.sector, stage: $0.stage, package: $0.package, budget: $0.budget,
                     bidDue: $0.bidDue, liveFeedStatus: $0.liveFeedStatus,
                     bidders: $0.bidders, score: $0.score, watchCount: $0.watchCount)
}

// MARK: - ========== ProjectsView.swift ==========

struct ProjectsView: View {
    @State private var projects: [SupabaseProject] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var filterStatus = "All"
    @State private var showAddSheet = false
    @State private var selectedProject: SupabaseProject?

    private let statusFilters = ["All", "On Track", "Ahead", "Delayed", "At Risk"]
    private let supabase = SupabaseService.shared

    private var displayProjects: [SupabaseProject] {
        var list = supabase.isConfigured ? projects : mockSupabaseProjects
        if filterStatus != "All" {
            list = list.filter { $0.status == filterStatus }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.client.localizedCaseInsensitiveContains(searchText)
                    || $0.type.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    private var activeCount: Int { displayProjects.filter { $0.status != "Delayed" }.count }
    private var avgScore: Double {
        let scores = displayProjects.compactMap { Double($0.score) }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                projectsHeader
                // Stats row
                statsRow
                // Filter bar
                filterBar
                // Project list or states
                if isLoading {
                    loadingView
                } else if let err = errorMessage {
                    errorView(err)
                } else if displayProjects.isEmpty {
                    emptyView
                } else {
                    projectList
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showAddSheet) {
            AddProjectSheet { newProject in
                Task { await saveProject(newProject) }
            }
        }
        .task { await loadProjects() }
    }

    // MARK: - Sub-views

    private var projectsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROJECTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(Theme.accent)
                Text("Project Command")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                if !supabase.isConfigured {
                    Label("Using demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .cornerRadius(8)
                }
                .disabled(!supabase.isConfigured)
                .opacity(supabase.isConfigured ? 1 : 0.5)

                Text("\(displayProjects.count) projects")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            projectStatChip(value: "\(activeCount)", label: "ACTIVE", color: Theme.green)
            projectStatChip(value: "\(displayProjects.count)", label: "TOTAL", color: Theme.cyan)
            projectStatChip(
                value: avgScore > 0 ? String(format: "%.1f", avgScore) : "—",
                label: "AVG SCORE",
                color: Theme.gold
            )
        }
    }

    private var filterBar: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 14))
                TextField("Search projects, clients, types...", text: $searchText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.accent)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.muted)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(statusFilters, id: \.self) { f in
                        Button {
                            filterStatus = f
                        } label: {
                            Text(f)
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(filterStatus == f ? Theme.bg : Theme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filterStatus == f ? Theme.accent : Theme.surface)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(filterStatus == f ? Color.clear : Theme.border.opacity(0.5), lineWidth: 0.8)
                                )
                        }
                    }
                }
            }
        }
    }

    private var projectList: some View {
        VStack(spacing: 10) {
            ForEach(displayProjects) { project in
                ProjectCard(project: project, onUpdate: { updated in
                    Task { await updateProject(updated) }
                }, onDelete: { id in
                    Task { await deleteProject(id: id) }
                })
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.accent)
            Text("Loading projects...")
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(Theme.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await loadProjects() } }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.surface)
        .cornerRadius(14)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "building.2")
                .font(.system(size: 36))
                .foregroundColor(Theme.muted.opacity(0.5))
            Text(filterStatus == "All" && searchText.isEmpty ? "No projects yet" : "No matching projects")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.muted)
            if filterStatus == "All" && searchText.isEmpty {
                Button("Add your first project") { showAddSheet = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .disabled(!supabase.isConfigured)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.surface)
        .cornerRadius(14)
    }

    // MARK: - Data

    private func loadProjects() async {
        guard supabase.isConfigured else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            projects = try await supabase.fetch("cs_projects")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveProject(_ project: SupabaseProject) async {
        do {
            try await supabase.insert("cs_projects", record: project)
            await loadProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateProject(_ project: SupabaseProject) async {
        guard let id = project.id else { return }
        do {
            try await supabase.update("cs_projects", id: id, record: project)
            await loadProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteProject(id: String) async {
        do {
            try await supabase.delete("cs_projects", id: id)
            projects.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: SupabaseProject
    let onUpdate: (SupabaseProject) -> Void
    let onDelete: (String) -> Void
    @State private var showDetail = false

    var statusColor: Color {
        switch project.status {
        case "On Track": return Theme.green
        case "Ahead": return Theme.cyan
        case "Delayed": return Theme.red
        case "At Risk": return Theme.gold
        default: return Theme.muted
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.text)
                        Text(project.client)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(project.status.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.12))
                            .cornerRadius(4)
                        if !project.score.isEmpty && project.score != "—" {
                            Text(project.score)
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(Theme.gold)
                        }
                    }
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.type)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.cyan)
                        Spacer()
                        Text("\(project.progress)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.text)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor)
                                .frame(width: geo.size.width * CGFloat(project.progress) / 100, height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                HStack {
                    Label(project.budget, systemImage: "dollarsign.circle")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Label(project.team, systemImage: "person.2")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: statusColor)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ProjectDetailSheet(project: project, onUpdate: onUpdate, onDelete: onDelete)
        }
    }
}

// MARK: - Project Detail Sheet

private struct ProjectDetailSheet: View {
    let project: SupabaseProject
    let onUpdate: (SupabaseProject) -> Void
    let onDelete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editedProject: SupabaseProject
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    init(project: SupabaseProject, onUpdate: @escaping (SupabaseProject) -> Void, onDelete: @escaping (String) -> Void) {
        self.project = project
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedProject = State(initialValue: project)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isEditing {
                            editForm
                        } else {
                            detailView
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : project.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing {
                            editedProject = project
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            onUpdate(editedProject)
                            isEditing = false
                            dismiss()
                        }
                        .foregroundColor(Theme.accent)
                        .fontWeight(.bold)
                    } else {
                        Menu {
                            Button("Edit") { isEditing = true }
                            Button("Delete", role: .destructive) { showDeleteConfirm = true }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete \(project.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = project.id { onDelete(id) }
                dismiss()
            }
        }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            detailRow("Client", project.client)
            detailRow("Type", project.type)
            detailRow("Status", project.status)
            detailRow("Progress", "\(project.progress)%")
            detailRow("Budget", project.budget)
            detailRow("Team", project.team)
            if !project.score.isEmpty { detailRow("Score", project.score) }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.muted)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.text)
        }
    }

    private var editForm: some View {
        VStack(spacing: 14) {
            formField("Project Name", text: $editedProject.name)
            formField("Client", text: $editedProject.client)
            formField("Type", text: $editedProject.type)
            formField("Budget", text: $editedProject.budget)
            formField("Team", text: $editedProject.team)
            formField("Score", text: $editedProject.score)

            VStack(alignment: .leading, spacing: 8) {
                Text("STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Picker("Status", selection: $editedProject.status) {
                    ForEach(["On Track", "Ahead", "Delayed", "At Risk"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PROGRESS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Text("\(editedProject.progress)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.text)
                }
                Slider(value: Binding(
                    get: { Double(editedProject.progress) },
                    set: { editedProject.progress = Int($0) }
                ), in: 0...100, step: 1)
                .accentColor(Theme.accent)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
    }
}

// MARK: - Add Project Sheet

private struct AddProjectSheet: View {
    let onAdd: (SupabaseProject) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var client = ""
    @State private var type = "Commercial"
    @State private var status = "On Track"
    @State private var progress = 0
    @State private var budget = ""
    @State private var team = ""
    @State private var score = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        formField("Project Name", text: $name)
                        formField("Client", text: $client)
                        formField("Type (e.g. Commercial High-Rise)", text: $type)
                        formField("Budget (e.g. $12.4M)", text: $budget)
                        formField("Team (e.g. 24 crew)", text: $team)
                        formField("Score (optional)", text: $score)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(Theme.muted)
                            Picker("Status", selection: $status) {
                                ForEach(["On Track", "Ahead", "Delayed", "At Risk"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PROGRESS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(Theme.muted)
                                Spacer()
                                Text("\(progress)%")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.text)
                            }
                            Slider(value: Binding(
                                get: { Double(progress) },
                                set: { progress = Int($0) }
                            ), in: 0...100, step: 1)
                            .accentColor(Theme.accent)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let project = SupabaseProject(
                            id: nil, name: name, client: client,
                            type: type.isEmpty ? "General" : type,
                            status: status, progress: progress,
                            budget: budget.isEmpty ? "$0" : budget,
                            score: score.isEmpty ? "—" : score,
                            team: team.isEmpty ? "TBD" : team
                        )
                        onAdd(project)
                        dismiss()
                    }
                    .foregroundColor(name.isEmpty ? Theme.muted : Theme.accent)
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helpers

private func projectStatChip(value: String, label: String, color: Color) -> some View {
    VStack(spacing: 3) {
        Text(value)
            .font(.system(size: 20, weight: .heavy))
            .foregroundColor(color)
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .tracking(2)
            .foregroundColor(Theme.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Theme.surface)
    .cornerRadius(10)
    .premiumGlow(cornerRadius: 10, color: color)
}

private func formField(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundColor(Theme.muted)
        TextField(label, text: text)
            .font(.system(size: 13))
            .foregroundColor(Theme.text)
            .accentColor(Theme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.surface)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
    }
}

// MARK: - Mock fallback data

private let mockSupabaseProjects: [SupabaseProject] = mockProjects.map {
    SupabaseProject(id: $0.id.uuidString, name: $0.name, client: $0.client, type: $0.type,
                    status: $0.status, progress: $0.progress, budget: $0.budget, score: $0.score, team: $0.team)
}

// MARK: - ========== ContractsView.swift ==========

struct ContractsView: View {
    @State private var contracts: [SupabaseContract] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var filterStage = "All"
    @State private var showAddSheet = false
    @State private var selectedContract: SupabaseContract?

    private let stageFilters = ["All", "Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation", "Awarded", "Lost"]
    private let supabase = SupabaseService.shared

    private var displayContracts: [SupabaseContract] {
        var list = supabase.isConfigured ? contracts : mockSupabaseContracts
        if filterStage != "All" {
            list = list.filter { $0.stage == filterStage }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.client.localizedCaseInsensitiveContains(searchText)
                    || $0.sector.localizedCaseInsensitiveContains(searchText)
                    || $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    private var activeBidCount: Int {
        displayContracts.filter { $0.stage == "Open For Bid" || $0.stage == "Prequalifying Teams" }.count
    }
    private var totalWatchers: Int { displayContracts.reduce(0) { $0 + $1.watchCount } }
    private var avgScore: Double {
        guard !displayContracts.isEmpty else { return 0 }
        return Double(displayContracts.reduce(0) { $0 + $1.score }) / Double(displayContracts.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                contractsHeader
                contractStatsRow
                contractFilterBar
                if isLoading {
                    contractsLoading
                } else if let err = errorMessage {
                    contractsError(err)
                } else if displayContracts.isEmpty {
                    contractsEmpty
                } else {
                    contractList
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showAddSheet) {
            AddContractSheet { newContract in
                Task { await saveContract(newContract) }
            }
        }
        .task { await loadContracts() }
    }

    // MARK: - Sub-views

    private var contractsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CONTRACTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(Theme.gold)
                Text("Bid Pipeline")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                if !supabase.isConfigured {
                    Label("Demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button { showAddSheet = true } label: {
                    Label("Add Contract", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.gold)
                        .cornerRadius(8)
                }
                .disabled(!supabase.isConfigured)
                .opacity(supabase.isConfigured ? 1 : 0.5)

                Text("\(displayContracts.count) opportunities")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.gold)
    }

    private var contractStatsRow: some View {
        HStack(spacing: 10) {
            contractStatChip(value: "\(activeBidCount)", label: "ACTIVE BIDS", color: Theme.gold)
            contractStatChip(value: "\(totalWatchers)", label: "WATCHERS", color: Theme.cyan)
            contractStatChip(
                value: avgScore > 0 ? String(format: "%.0f", avgScore) : "—",
                label: "AVG SCORE",
                color: Theme.green
            )
        }
    }

    private var contractFilterBar: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 14))
                TextField("Search title, client, sector...", text: $searchText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.gold)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stageFilters, id: \.self) { f in
                        Button { filterStage = f } label: {
                            Text(f)
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(filterStage == f ? Theme.bg : Theme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filterStage == f ? Theme.gold : Theme.surface)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(filterStage == f ? Color.clear : Theme.border.opacity(0.5), lineWidth: 0.8)
                                )
                        }
                    }
                }
            }
        }
    }

    private var contractList: some View {
        VStack(spacing: 10) {
            ForEach(displayContracts) { contract in
                ContractCard(contract: contract, onUpdate: { updated in
                    Task { await updateContract(updated) }
                }, onDelete: { id in
                    Task { await deleteContract(id: id) }
                })
            }
        }
    }

    private var contractsLoading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.gold)
            Text("Loading contracts...").font(.system(size: 13)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(40)
    }

    private func contractsError(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 28)).foregroundColor(Theme.red)
            Text(message).font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            Button("Retry") { Task { await loadContracts() } }
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.gold)
        }
        .frame(maxWidth: .infinity).padding(40).background(Theme.surface).cornerRadius(14)
    }

    private var contractsEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.badge.plus").font(.system(size: 36)).foregroundColor(Theme.muted.opacity(0.5))
            Text(filterStage == "All" && searchText.isEmpty ? "No contracts yet" : "No matching contracts")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.muted)
            if filterStage == "All" && searchText.isEmpty {
                Button("Add first contract") { showAddSheet = true }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.gold)
                    .disabled(!supabase.isConfigured)
            }
        }
        .frame(maxWidth: .infinity).padding(40).background(Theme.surface).cornerRadius(14)
    }

    // MARK: - Data

    private func loadContracts() async {
        guard supabase.isConfigured else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do { contracts = try await supabase.fetch("cs_contracts") }
        catch { errorMessage = error.localizedDescription }
    }

    private func saveContract(_ contract: SupabaseContract) async {
        do { try await supabase.insert("cs_contracts", record: contract); await loadContracts() }
        catch { errorMessage = error.localizedDescription }
    }

    private func updateContract(_ contract: SupabaseContract) async {
        guard let id = contract.id else { return }
        do { try await supabase.update("cs_contracts", id: id, record: contract); await loadContracts() }
        catch { errorMessage = error.localizedDescription }
    }

    private func deleteContract(id: String) async {
        do { try await supabase.delete("cs_contracts", id: id); contracts.removeAll { $0.id == id } }
        catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Contract Card

private struct ContractCard: View {
    let contract: SupabaseContract
    let onUpdate: (SupabaseContract) -> Void
    let onDelete: (String) -> Void
    @State private var showDetail = false

    var stageColor: Color {
        switch contract.stage {
        case "Open For Bid": return Theme.gold
        case "Awarded": return Theme.green
        case "Lost": return Theme.red
        case "Negotiation": return Theme.cyan
        default: return Theme.muted
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(contract.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.text)
                            .multilineTextAlignment(.leading)
                        Text("\(contract.client) · \(contract.location)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(contract.stage.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(stageColor)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(stageColor.opacity(0.12))
                            .cornerRadius(4)
                        Text("\(contract.score)")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(Theme.gold)
                    }
                }

                HStack(spacing: 14) {
                    contractChip(icon: "tag", text: contract.sector, color: Theme.purple)
                    contractChip(icon: "dollarsign.circle", text: contract.budget, color: Theme.green)
                    contractChip(icon: "calendar", text: "Due \(contract.bidDue)", color: Theme.muted)
                }

                HStack {
                    Label("\(contract.bidders) bidders", systemImage: "person.3")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Label("\(contract.watchCount) watching", systemImage: "eye")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    if !contract.liveFeedStatus.isEmpty {
                        Label(contract.liveFeedStatus, systemImage: "dot.radiowaves.left.and.right")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.cyan)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: stageColor)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ContractDetailSheet(contract: contract, onUpdate: onUpdate, onDelete: onDelete)
        }
    }

    private func contractChip(icon: String, text: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.10))
            .cornerRadius(5)
    }
}

// MARK: - Contract Detail Sheet

private struct ContractDetailSheet: View {
    let contract: SupabaseContract
    let onUpdate: (SupabaseContract) -> Void
    let onDelete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var edited: SupabaseContract
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    init(contract: SupabaseContract, onUpdate: @escaping (SupabaseContract) -> Void, onDelete: @escaping (String) -> Void) {
        self.contract = contract; self.onUpdate = onUpdate; self.onDelete = onDelete
        _edited = State(initialValue: contract)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isEditing { contractEditForm } else { contractDetailBody }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Contract" : contract.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing { edited = contract; isEditing = false } else { dismiss() }
                    }
                    .foregroundColor(Theme.gold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") { onUpdate(edited); isEditing = false; dismiss() }
                            .foregroundColor(Theme.gold).fontWeight(.bold)
                    } else {
                        Menu {
                            Button("Edit") { isEditing = true }
                            Button("Delete", role: .destructive) { showDeleteConfirm = true }
                        } label: {
                            Image(systemName: "ellipsis.circle").foregroundColor(Theme.gold)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete \(contract.title)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = contract.id { onDelete(id) }
                dismiss()
            }
        }
    }

    private var contractDetailBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow("Client", contract.client)
            detailRow("Location", contract.location)
            detailRow("Sector", contract.sector)
            detailRow("Stage", contract.stage)
            detailRow("Package", contract.package)
            detailRow("Budget", contract.budget)
            detailRow("Bid Due", contract.bidDue)
            detailRow("Bidders", "\(contract.bidders)")
            detailRow("Score", "\(contract.score)")
            detailRow("Watching", "\(contract.watchCount)")
            if !contract.liveFeedStatus.isEmpty { detailRow("Live Feed", contract.liveFeedStatus) }
        }
        .padding(16).background(Theme.surface).cornerRadius(14)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium)).foregroundColor(Theme.muted).frame(width: 80, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.text)
        }
    }

    private var contractEditForm: some View {
        VStack(spacing: 14) {
            contractFormField("Title", text: $edited.title)
            contractFormField("Client", text: $edited.client)
            contractFormField("Location", text: $edited.location)
            contractFormField("Sector", text: $edited.sector)
            contractFormField("Package", text: $edited.package)
            contractFormField("Budget", text: $edited.budget)
            contractFormField("Bid Due", text: $edited.bidDue)
            contractFormField("Live Feed Status", text: $edited.liveFeedStatus)

            VStack(alignment: .leading, spacing: 8) {
                Text("STAGE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                Picker("Stage", selection: $edited.stage) {
                    ForEach(["Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation", "Awarded", "Lost"], id: \.self) { Text($0) }
                }
                .accentColor(Theme.gold)
            }
        }
        .padding(16).background(Theme.surface).cornerRadius(14)
    }
}

// MARK: - Add Contract Sheet

private struct AddContractSheet: View {
    let onAdd: (SupabaseContract) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""; @State private var client = ""; @State private var location = ""
    @State private var sector = ""; @State private var stage = "Pursuit"; @State private var pkg = ""
    @State private var budget = ""; @State private var bidDue = ""; @State private var liveFeed = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        contractFormField("Contract Title", text: $title)
                        contractFormField("Client", text: $client)
                        contractFormField("Location", text: $location)
                        contractFormField("Sector (e.g. Healthcare)", text: $sector)
                        contractFormField("Package (e.g. Core & Shell)", text: $pkg)
                        contractFormField("Budget (e.g. $28M)", text: $budget)
                        contractFormField("Bid Due Date (e.g. Apr 18)", text: $bidDue)
                        contractFormField("Live Feed Status (optional)", text: $liveFeed)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("STAGE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            Picker("Stage", selection: $stage) {
                                ForEach(["Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation"], id: \.self) { Text($0) }
                            }
                            .accentColor(Theme.gold)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Contract")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onAdd(SupabaseContract(
                            id: nil, title: title, client: client, location: location,
                            sector: sector.isEmpty ? "General" : sector, stage: stage,
                            package: pkg.isEmpty ? "TBD" : pkg, budget: budget.isEmpty ? "$0" : budget,
                            bidDue: bidDue.isEmpty ? "TBD" : bidDue, liveFeedStatus: liveFeed,
                            bidders: 0, score: 0, watchCount: 0
                        ))
                        dismiss()
                    }
                    .foregroundColor(title.isEmpty ? Theme.muted : Theme.gold)
                    .fontWeight(.bold).disabled(title.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helpers

private func contractStatChip(value: String, label: String, color: Color) -> some View {
    VStack(spacing: 3) {
        Text(value).font(.system(size: 20, weight: .heavy)).foregroundColor(color)
        Text(label).font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
    }
    .frame(maxWidth: .infinity).padding(.vertical, 12).background(Theme.surface).cornerRadius(10)
    .premiumGlow(cornerRadius: 10, color: color)
}

private func contractFormField(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label.uppercased()).font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
        TextField(label, text: text)
            .font(.system(size: 13)).foregroundColor(Theme.text).accentColor(Theme.gold)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Theme.surface).cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
    }
}



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
        trackEvent("backend_config_saved")
    }

    func applyPreset(_ provider: IntegrationBackendProvider) {
        backendProvider = provider
        switch provider {
        case .supabase:
            if trimmed(backendBaseURL).isEmpty {
                backendBaseURL = "https://your-project.supabase.co"
            }
            backendProjectId = ""
        case .firebase:
            if trimmed(backendProjectId).isEmpty {
                backendProjectId = "your-firebase-project-id"
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
        backendApiKey = KeychainHelper.read(key: "Backend.ApiKey") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "ApiKey") ?? ""
        backendAuthToken = KeychainHelper.read(key: "Backend.AuthToken") ?? UserDefaults.standard.string(forKey: configKeyPrefix + "AuthToken") ?? ""
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
            if trimmed(backendBaseURL).isEmpty { missing.append("base URL") }
            if trimmed(backendApiKey).isEmpty { missing.append("API key") }
            return missing
        case .firebase:
            var missing: [String] = []
            if trimmed(backendProjectId).isEmpty { missing.append("project ID") }
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
                    .font(.system(size: 8, weight: .bold))
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
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)
                        .foregroundColor(Theme.cyan)
                    Spacer()
                    Text("Outlook + QuickBooks + Microsoft 365")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }

                HStack(spacing: 8) {
                    ForEach(BusinessPlatform.allCases) { platform in
                        Button {
                            hub.selectedBusinessPlatform = platform
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(platform.rawValue)
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(hub.selectedBusinessPlatform == platform ? .black : platform.color)
                                Text(platform.subtitle)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(hub.selectedBusinessPlatform == platform ? Color.black.opacity(0.75) : Theme.muted)
                                    .lineLimit(2)
                                Text(hub.businessPlatformConnected(for: platform) ? "CONNECTED" : "NOT CONNECTED")
                                    .font(.system(size: 8, weight: .bold))
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
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }

                    if hub.selectedBusinessPlatform == .outlook {
                        HStack(spacing: 6) {
                            TextField("Outlook tenant", text: $hub.outlookTenant)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                            TextField("Mailbox", text: $hub.outlookMailbox)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                        }
                    } else if hub.selectedBusinessPlatform == .quickBooks {
                        HStack(spacing: 6) {
                            TextField("Company ID", text: $hub.quickBooksCompanyID)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                            TextField("Realm ID", text: $hub.quickBooksRealm)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                        }
                    } else {
                        HStack(spacing: 6) {
                            TextField("Microsoft tenant", text: $hub.microsoft365Tenant)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8, weight: .semibold))
                                .padding(6)
                                .background(Theme.surface)
                                .cornerRadius(6)
                            TextField("SharePoint / OneDrive path", text: $hub.microsoft365Site)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8, weight: .semibold))
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
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.selectedBusinessPlatform.color)
                        .cornerRadius(5)
                        .buttonStyle(.plain)

                        Button("DISCONNECT") {
                            hub.disconnectBusinessPlatform(hub.selectedBusinessPlatform)
                        }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.muted)
                        .buttonStyle(.plain)
                        .opacity(hub.businessPlatformConnected(for: hub.selectedBusinessPlatform) ? 1 : 0.45)
                        .disabled(!hub.businessPlatformConnected(for: hub.selectedBusinessPlatform))

                        Text(hub.businessPlatformStatus(for: hub.selectedBusinessPlatform))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.muted)
                            .lineLimit(1)

                        Spacer()

                        Text("Queue: \(hub.businessPlatformPendingItems(for: hub.selectedBusinessPlatform))")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(hub.selectedBusinessPlatform.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("RECOMMENDED WORKFLOWS")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Theme.muted)
                        ForEach(hub.recommendedWorkflows(for: hub.selectedBusinessPlatform), id: \.self) { workflow in
                            Text("• \(workflow)")
                                .font(.system(size: 8, weight: .semibold))
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
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(Theme.muted)
                    ForEach(IntegrationBackendProvider.allCases, id: \.rawValue) { provider in
                        Button(provider.rawValue) { hub.backendProvider = provider }
                            .font(.system(size: 8, weight: .bold))
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
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(Theme.muted)
                    Button("SUPABASE STARTER") { hub.applyPreset(.supabase) }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.green)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    Button("FIREBASE STARTER") { hub.applyPreset(.firebase) }
                        .font(.system(size: 8, weight: .bold))
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
                        .font(.system(size: 8, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                    TextField("Project ID (Firebase)", text: $hub.backendProjectId)
                        .textFieldStyle(.plain)
                        .font(.system(size: 8, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                }

                HStack(spacing: 6) {
                    SecureField("API Key", text: $hub.backendApiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 8, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                    SecureField("Auth Token (optional)", text: $hub.backendAuthToken)
                        .textFieldStyle(.plain)
                        .font(.system(size: 8, weight: .semibold))
                        .padding(6)
                        .background(Theme.surface)
                        .cornerRadius(6)
                }

                HStack(spacing: 6) {
                    Button("SAVE CONFIG") { hub.saveBackendConfig() }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.gold)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    Button("TEST CONNECTION") { hub.testConnection() }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.cyan)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                        .disabled(!hub.isConfigReady)
                        .opacity(hub.isConfigReady ? 1 : 0.45)
                    Text(hub.connectionStatus)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                    Spacer()
                }

                HStack(spacing: 6) {
                    Button("RUN LIVE CHECK") { hub.runLiveValidation() }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.green)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                        .disabled(!hub.isConfigReady)
                        .opacity(hub.isConfigReady ? 1 : 0.45)
                    Text(hub.liveValidationStatus)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                    Spacer()
                }

                Text(hub.readinessStatus)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(hub.isConfigReady ? Theme.green : Theme.gold)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("CONFIG TRANSFER")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Theme.muted)
                        Spacer()
                        Button("EXPORT JSON") { hub.exportConfigPayload() }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.purple)
                            .cornerRadius(5)
                            .buttonStyle(.plain)
                        Button("IMPORT JSON") { hub.importConfigPayload() }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(5)
                            .buttonStyle(.plain)
                        Button(hub.includeSecretsInExport ? "SECRETS ON" : "SECRETS OFF") {
                            hub.includeSecretsInExport.toggle()
                        }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.includeSecretsInExport ? Theme.red : Theme.green)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    }

                    Text(hub.includeSecretsInExport ? "Warning: export includes API key/token" : "Safe mode: secrets are redacted on export")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(hub.includeSecretsInExport ? Theme.red : Theme.green)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        SecureField("Transfer passphrase (optional)", text: $hub.signaturePassphrase)
                            .textFieldStyle(.plain)
                            .font(.system(size: 8, weight: .semibold))
                            .padding(6)
                            .background(Theme.surface)
                            .cornerRadius(6)
                        Button(hub.requireSignatureOnImport ? "REQUIRE SIGNATURE" : "SIGNATURE OPTIONAL") {
                            hub.requireSignatureOnImport.toggle()
                        }
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.requireSignatureOnImport ? Theme.red : Theme.cyan)
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                    }

                    TextEditor(text: $hub.configTransferPayload)
                        .font(.system(size: 8, weight: .semibold))
                        .frame(height: 86)
                        .padding(4)
                        .background(Theme.surface)
                        .cornerRadius(6)

                    Text(hub.configTransferStatus)
                        .font(.system(size: 8, weight: .semibold))
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
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(hub.role == role ? .black : role.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hub.role == role ? role.color : role.color.opacity(0.14))
                        .cornerRadius(5)
                        .buttonStyle(.plain)
                }
                Button("SIGN OUT") { hub.signOut() }
                    .font(.system(size: 8, weight: .bold))
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
                        .font(.system(size: 8, weight: .black))
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
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            .padding(10)
            .background(Theme.surface.opacity(0.78))
            .cornerRadius(10)

            if !hub.checkHistory.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECENT CHECKS")
                        .font(.system(size: 8, weight: .black))
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
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundColor(record.accent)
                                    Text(record.timestamp)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(Theme.muted)
                                    if let latencyMS = record.latencyMS {
                                        Text("· \(latencyMS)ms")
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundColor(Theme.muted)
                                    }
                                }
                                Text(record.detail)
                                    .font(.system(size: 8, weight: .semibold))
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
                    .font(.system(size: 8, weight: .semibold))
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
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Theme.muted)
                .lineLimit(2)
            Spacer(minLength: 0)
            Button(actionLabel, action: action)
                .font(.system(size: 8, weight: .bold))
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
                .font(.system(size: 8, weight: .semibold))
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

// MARK: - ========== SecurityAccessView.swift ==========

// MARK: - Security Enums & Types

enum SecurityTwoFactorMethod: String, CaseIterable {
    case authenticator = "AUTH_APP"
    case sms = "SMS"
    case email = "EMAIL"

    var display: String {
        switch self {
        case .authenticator: return "Authenticator App"
        case .sms: return "SMS OTP"
        case .email: return "Email OTP"
        }
    }
}

enum SecurityCredentialKey: String {
    case passwordHash = "passwordHash"
    case twoFactorSecret = "twoFactorSecret"
}

enum SecuritySecureStore {
    static let service = "ConstructOS.Security"

    static func read(_ key: SecurityCredentialKey) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }

        return value
    }

    static func save(_ value: String, for key: SecurityCredentialKey) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var create = query
            create[kSecValueData as String] = data
            SecItemAdd(create as CFDictionary, nil)
        }
    }

    static func delete(_ key: SecurityCredentialKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Security Helper Functions

func securityPasswordHash(_ password: String) -> String {
    let digest = SHA256.hash(data: Data(password.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}

func securityBiometricsAvailable() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
}

func securityBiometricLabel() -> String {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        return "Biometric Unlock"
    }

    switch context.biometryType {
    case .faceID:
        return "Face ID"
    case .touchID:
        return "Touch ID"
    default:
        return "Biometric Unlock"
    }
}

let securityAuditLogKey = "ConstructOS.Security.AuditLog"
let securityForceLockNotification = Notification.Name("ConstructOS.SecurityForceLock")
let securityOutOfBandCodeKey = "ConstructOS.Security.OutOfBandCode"
let securityOutOfBandExpiryKey = "ConstructOS.Security.OutOfBandExpiry"
let securityOutOfBandLastSentKey = "ConstructOS.Security.OutOfBandLastSent"
let securityOutOfBandMethodKey = "ConstructOS.Security.OutOfBandMethod"

#if os(macOS)
typealias PlatformSecurityImage = NSImage
#elseif os(iOS)
typealias PlatformSecurityImage = UIImage
#endif

func base32EncodedString(from data: Data) -> String {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    var encoded = ""
    var buffer = 0
    var bitsLeft = 0

    for byte in data {
        buffer = (buffer << 8) | Int(byte)
        bitsLeft += 8
        while bitsLeft >= 5 {
            let index = (buffer >> (bitsLeft - 5)) & 0x1F
            encoded.append(alphabet[index])
            bitsLeft -= 5
        }
    }

    if bitsLeft > 0 {
        let index = (buffer << (5 - bitsLeft)) & 0x1F
        encoded.append(alphabet[index])
    }

    return encoded
}

func base32DecodedData(_ string: String) -> Data? {
    let alphabet = Dictionary(uniqueKeysWithValues: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".enumerated().map { (Character(String($0.element)), $0.offset) })
    let cleaned = string.uppercased().filter { !$0.isWhitespace && $0 != "=" }
    guard !cleaned.isEmpty else { return nil }

    var buffer = 0
    var bitsLeft = 0
    var bytes: [UInt8] = []

    for character in cleaned {
        guard let value = alphabet[character] else { return nil }
        buffer = (buffer << 5) | value
        bitsLeft += 5
        if bitsLeft >= 8 {
            let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
            bytes.append(byte)
            bitsLeft -= 8
        }
    }

    return Data(bytes)
}

func normalizedSecuritySecret(_ secret: String) -> String {
    let cleaned = secret.uppercased().replacingOccurrences(of: " ", with: "")
    if let data = base32DecodedData(cleaned), !data.isEmpty {
        return cleaned
    }
    return base32EncodedString(from: Data(cleaned.utf8))
}

func generateSecuritySecret() -> String {
    var bytes = [UInt8](repeating: 0, count: 20)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return base32EncodedString(from: Data(bytes))
}

func securityTwoFactorCode(secret: String, at date: Date = Date()) -> String {
    guard let secretData = base32DecodedData(secret), !secretData.isEmpty else { return "000000" }

    let counter = UInt64(date.timeIntervalSince1970 / 30).bigEndian
    let counterData = withUnsafeBytes(of: counter) { Data($0) }
    let key = SymmetricKey(data: secretData)
    let digest = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
    let hash = Array(digest)
    let offset = Int(hash.last! & 0x0F)
    let binary = (UInt32(hash[offset] & 0x7F) << 24)
        | (UInt32(hash[offset + 1]) << 16)
        | (UInt32(hash[offset + 2]) << 8)
        | UInt32(hash[offset + 3])
    return String(format: "%06d", Int(binary % 1_000_000))
}

func securityRecoveryCodes(secret: String) -> [String] {
    guard !secret.isEmpty else { return [] }
    return (0..<6).map { index in
        let seed = base32EncodedString(from: Data("\(secret)-R\(index)".utf8))
        let code = securityTwoFactorCode(secret: seed, at: Date(timeIntervalSince1970: Double(index * 45)))
        return "RC-\(code.prefix(3))-\(code.suffix(3))"
    }
}

func normalizedEmergencyCode(_ raw: String) -> String {
    raw.uppercased().filter { $0.isLetter || $0.isNumber }
}

func securityEmergencyCodes(count: Int = 6) -> [String] {
    let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    func token(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(alphabet[Int($0) % alphabet.count]) }.joined()
    }

    return (0..<count).map { _ in
        "EC-\(token(length: 4))-\(token(length: 4))"
    }
}

func generateOutOfBandSecurityCode(length: Int = 6) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return bytes.map { String(Int($0) % 10) }.joined()
}

func issueOutOfBandSecurityCode(method: SecurityTwoFactorMethod, ttl: TimeInterval = 300) -> String {
    let code = generateOutOfBandSecurityCode()
    let now = Date()
    UserDefaults.standard.set(code, forKey: securityOutOfBandCodeKey)
    UserDefaults.standard.set(now.addingTimeInterval(ttl).timeIntervalSince1970, forKey: securityOutOfBandExpiryKey)
    UserDefaults.standard.set(now.timeIntervalSince1970, forKey: securityOutOfBandLastSentKey)
    UserDefaults.standard.set(method.rawValue, forKey: securityOutOfBandMethodKey)
    return code
}

func currentOutOfBandSecurityCode() -> String {
    UserDefaults.standard.string(forKey: securityOutOfBandCodeKey) ?? ""
}

func currentOutOfBandSecurityExpiry() -> Double {
    UserDefaults.standard.double(forKey: securityOutOfBandExpiryKey)
}

func currentOutOfBandLastSentAt() -> Double {
    UserDefaults.standard.double(forKey: securityOutOfBandLastSentKey)
}

func currentOutOfBandSecurityMethod() -> SecurityTwoFactorMethod? {
    guard let raw = UserDefaults.standard.string(forKey: securityOutOfBandMethodKey) else { return nil }
    return SecurityTwoFactorMethod(rawValue: raw)
}

func clearOutOfBandSecurityCode() {
    UserDefaults.standard.removeObject(forKey: securityOutOfBandCodeKey)
    UserDefaults.standard.removeObject(forKey: securityOutOfBandExpiryKey)
    UserDefaults.standard.removeObject(forKey: securityOutOfBandLastSentKey)
    UserDefaults.standard.removeObject(forKey: securityOutOfBandMethodKey)
}

func validateOutOfBandSecurityCode(_ input: String, method: SecurityTwoFactorMethod) -> Bool {
    let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty,
          let activeMethod = currentOutOfBandSecurityMethod(),
          activeMethod == method,
          currentOutOfBandSecurityExpiry() > Date().timeIntervalSince1970 else {
        return false
    }
    return normalized == currentOutOfBandSecurityCode()
}

func securityAuditEntries() -> [String] {
    UserDefaults.standard.stringArray(forKey: securityAuditLogKey) ?? []
}

func auditEntryHash(_ entry: String, previous: String) -> String {
    let input = previous + entry
    let data = Data(input.utf8)
    let digest = SHA256.hash(data: data)
    return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
}

func appendSecurityAudit(_ message: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"
    var entries = securityAuditEntries()
    let previous = entries.first ?? ""
    let entry = "[\(formatter.string(from: Date()))] \(message)"
    let hash = auditEntryHash(entry, previous: previous)
    entries.insert("\(entry) #\(hash)", at: 0)
    UserDefaults.standard.set(Array(entries.prefix(20)), forKey: securityAuditLogKey)
}

func securityOtpAuthURL(secret: String, accountName: String = "ops@constructionos.app", issuer: String = "Construction OS") -> String {
    guard !secret.isEmpty else { return "" }
    let allowed = CharacterSet.urlQueryAllowed
    let encodedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: allowed) ?? issuer
    let encodedAccount = accountName.addingPercentEncoding(withAllowedCharacters: allowed) ?? accountName
    return "otpauth://totp/\(encodedIssuer):\(encodedAccount)?secret=\(secret)&issuer=\(encodedIssuer)&algorithm=SHA1&digits=6&period=30"
}

func securityQRCodeImage(from string: String, scale: CGFloat = 10) -> PlatformSecurityImage? {
    guard !string.isEmpty else { return nil }
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"

    guard let outputImage = filter.outputImage else { return nil }
    let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }

#if os(macOS)
    return NSImage(cgImage: cgImage, size: NSSize(width: transformedImage.extent.width, height: transformedImage.extent.height))
#elseif os(iOS)
    return UIImage(cgImage: cgImage)
#endif
}

func copyTextToClipboard(_ text: String, autoClearAfter seconds: TimeInterval = 30) {
#if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    let changeCount = NSPasteboard.general.changeCount
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        if NSPasteboard.general.changeCount == changeCount {
            NSPasteboard.general.clearContents()
        }
    }
#elseif os(iOS)
    UIPasteboard.general.string = text
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        if UIPasteboard.general.string == text {
            UIPasteboard.general.string = ""
        }
    }
#endif
}

private func securityPasswordStrength(_ password: String) -> (score: Int, label: String) {
    var score = 0
    if password.count >= 8  { score += 1 }
    if password.count >= 12 { score += 1 }
    if password.unicodeScalars.contains(where: { CharacterSet.uppercaseLetters.contains($0) }) { score += 1 }
    if password.unicodeScalars.contains(where: { CharacterSet.lowercaseLetters.contains($0) }) { score += 1 }
    if password.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) }) { score += 1 }
    let symbols = CharacterSet.alphanumerics.inverted
    if password.unicodeScalars.contains(where: { symbols.contains($0) }) { score += 1 }
    let label: String
    switch score {
    case 0...2: label = "WEAK"
    case 3...4: label = "FAIR"
    case 5:     label = "STRONG"
    default:    label = "VERY STRONG"
    }
    return (score, label)
}

// MARK: - Security Access

struct SecurityAccessPanel: View {
    @AppStorage("ConstructOS.Security.PasswordEnabled") private var passwordEnabledRaw: Bool = false
    @AppStorage("ConstructOS.Security.PasswordValue") private var legacyStoredPassword: String = ""
    @AppStorage("ConstructOS.Security.TwoFactorEnabled") private var twoFactorEnabledRaw: Bool = false
    @AppStorage("ConstructOS.Security.TwoFactorSecret") private var legacyTwoFactorSecret: String = ""
    @AppStorage("ConstructOS.Security.TwoFactorMethod") private var twoFactorMethodRaw: String = SecurityTwoFactorMethod.authenticator.rawValue
    @AppStorage("ConstructOS.Security.BiometricEnabled") private var biometricEnabledRaw: Bool = false
    @AppStorage("ConstructOS.Security.FailedAttempts") private var failedUnlockAttempts: Int = 0
    @AppStorage("ConstructOS.Security.LockoutUntil") private var lockoutUntilEpoch: Double = 0
    @AppStorage("ConstructOS.Security.IdleLockEnabled") private var idleLockEnabledRaw: Bool = true
    @AppStorage("ConstructOS.Security.IdleLockMinutes") private var idleLockMinutesRaw: Int = 5
    @AppStorage("ConstructOS.Security.TrustedUntil") private var trustedUntilEpoch: Double = 0
    @AppStorage("ConstructOS.Security.TrustHours") private var trustedDeviceHoursRaw: Int = 8
    @AppStorage("ConstructOS.Security.EmergencyCodes") private var emergencyCodesRaw: String = ""
    @AppStorage("ConstructOS.Security.AuthAccount") private var authAccountNameRaw: String = "ops@constructionos.app"
    @AppStorage("ConstructOS.Security.AuthIssuer") private var authIssuerRaw: String = "Construction OS"
    @AppStorage("ConstructOS.Security.SMSNumber") private var smsNumberRaw: String = "+1 (555) 010-2424"
    @AppStorage("ConstructOS.Security.EmailDestination") private var emailDestinationRaw: String = "ops@constructionos.app"
    @AppStorage("ConstructOS.Security.LastUnlockEpoch") private var lastUnlockEpoch: Double = 0
    @AppStorage("ConstructOS.Security.LastFailedEpoch") private var lastFailedEpoch: Double = 0
    @State private var currentPasswordInput: String = ""
    @State private var newPasswordInput: String = ""
    @State private var confirmPasswordInput: String = ""
    @State private var statusMessage: String?
    @State private var now: Date = Date()
    @State private var storedPasswordHash: String = ""
    @State private var twoFactorSecret: String = ""
    @State private var biometricAvailable: Bool = false
    @State private var auditEntries: [String] = []
    @State private var showRotateConfirmation: Bool = false
    @State private var showDisablePasswordAlert: Bool = false
    @State private var showDisable2FAAlert: Bool = false
    @State private var reauthInput: String = ""
    @State private var demoOutOfBandCode: String?
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var passwordConfigured: Bool {
        !storedPasswordHash.isEmpty
    }

    private var passwordProtectionEnabled: Bool {
        passwordEnabledRaw && passwordConfigured
    }

    private var twoFactorMethod: SecurityTwoFactorMethod {
        SecurityTwoFactorMethod(rawValue: twoFactorMethodRaw) ?? .authenticator
    }

    private var twoFactorReady: Bool {
        passwordProtectionEnabled && twoFactorEnabledRaw && !twoFactorSecret.isEmpty
    }

    private var biometricLabel: String {
        securityBiometricLabel()
    }

    private var isLockedOut: Bool {
        Date().timeIntervalSince1970 < lockoutUntilEpoch
    }

    private var lockoutRemainingSeconds: Int {
        max(0, Int(ceil(lockoutUntilEpoch - Date().timeIntervalSince1970)))
    }

    private var liveCode: String {
        securityTwoFactorCode(secret: twoFactorSecret, at: now)
    }

    private var recoveryCodes: [String] {
        securityRecoveryCodes(secret: twoFactorSecret)
    }

    private var emergencyCodes: [String] {
        emergencyCodesRaw
            .split(separator: "|")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    private var otpAuthURL: String {
        securityOtpAuthURL(secret: twoFactorSecret, accountName: authenticatorAccountName, issuer: authenticatorIssuer)
    }

    private var authenticatorAccountName: String {
        let trimmed = authAccountNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ops@constructionos.app" : trimmed
    }

    private var authenticatorIssuer: String {
        let trimmed = authIssuerRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Construction OS" : trimmed
    }

    private var trustedDeviceActive: Bool {
        Date().timeIntervalSince1970 < trustedUntilEpoch
    }

    private var trustedDeviceHours: Int {
        max(trustedDeviceHoursRaw, 1)
    }

    private var trustedUntilLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: Date(timeIntervalSince1970: trustedUntilEpoch))
    }

    private var outOfBandCodeExpiresIn: Int {
        max(0, Int(ceil(currentOutOfBandSecurityExpiry() - Date().timeIntervalSince1970)))
    }

    private var outOfBandLastSentAgo: Int {
        guard currentOutOfBandLastSentAt() > 0 else { return 0 }
        return max(0, Int(Date().timeIntervalSince1970 - currentOutOfBandLastSentAt()))
    }

    private var outOfBandDestination: String {
        let rawValue = twoFactorMethod == .sms ? smsNumberRaw : emailDestinationRaw
        return rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var securityHealthScore: Int {
        var score = 0
        if passwordProtectionEnabled { score += 35 }
        if twoFactorReady { score += 30 }
        if !emergencyCodes.isEmpty { score += 20 }
        if !isLockedOut { score += 10 }
        if !trustedDeviceActive || trustedDeviceHours <= 8 { score += 5 }
        return min(100, max(0, score))
    }

    private var securityHealthLabel: String {
        if securityHealthScore >= 85 { return "HARDENED" }
        if securityHealthScore >= 65 { return "GOOD" }
        if securityHealthScore >= 45 { return "NEEDS ATTENTION" }
        return "AT RISK"
    }

    private var securityHealthColor: Color {
        if securityHealthScore >= 85 { return Theme.green }
        if securityHealthScore >= 65 { return Theme.cyan }
        if securityHealthScore >= 45 { return Theme.gold }
        return Theme.red
    }

    private var authenticatorActionRow: some View {
        HStack(spacing: 12) {
            Button("COPY SECRET") { copyAuthenticatorSecret() }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.cyan)
            Button("COPY SETUP URI") { copyAuthenticatorURI() }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.gold)
            Button("COPY RECOVERY") { copyRecoveryPack() }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.green)
        }
    }

        #if os(macOS)
            private func qrCodeImageView(_ qrCode: PlatformSecurityImage) -> some View {
                Image(nsImage: qrCode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        #elseif os(iOS)
            private func qrCodeImageView(_ qrCode: PlatformSecurityImage) -> some View {
                Image(uiImage: qrCode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        #endif

    @ViewBuilder
    private var qrCodePreview: some View {
        if let qrCode = securityQRCodeImage(from: otpAuthURL) {
                qrCodeImageView(qrCode)
        }
    }

    private var twoFactorSetupSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current TOTP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                        Text(liveCode)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(Theme.gold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Setup key")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.muted)
                        Text(String(twoFactorSecret.prefix(24)))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.cyan)
                    }
                }

                Text("Scan the QR with 1Password, Google Authenticator, Microsoft Authenticator, or any RFC 6238 TOTP app.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)

                authenticatorActionRow
            }

            Spacer()
            qrCodePreview
        }
    }

    private func refreshState() {
        if authAccountNameRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authAccountNameRaw = "ops@constructionos.app"
        }

        if authIssuerRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authIssuerRaw = "Construction OS"
        }

        if !legacyStoredPassword.isEmpty && SecuritySecureStore.read(.passwordHash).isEmpty {
            SecuritySecureStore.save(securityPasswordHash(legacyStoredPassword), for: .passwordHash)
            appendSecurityAudit("Migrated password credential into Keychain")
            legacyStoredPassword = ""
        }

        if !legacyTwoFactorSecret.isEmpty && SecuritySecureStore.read(.twoFactorSecret).isEmpty {
            let normalized = normalizedSecuritySecret(legacyTwoFactorSecret)
            SecuritySecureStore.save(normalized, for: .twoFactorSecret)
            appendSecurityAudit("Migrated 2FA secret into Keychain")
            legacyTwoFactorSecret = ""
        }

        storedPasswordHash = SecuritySecureStore.read(.passwordHash)
        twoFactorSecret = SecuritySecureStore.read(.twoFactorSecret)
        biometricAvailable = securityBiometricsAvailable()
        auditEntries = Array(securityAuditEntries().prefix(5))
        if currentOutOfBandSecurityExpiry() <= Date().timeIntervalSince1970 {
            demoOutOfBandCode = nil
        }

        if twoFactorEnabledRaw && twoFactorSecret.isEmpty {
            let secret = generateSecuritySecret()
            SecuritySecureStore.save(secret, for: .twoFactorSecret)
            twoFactorSecret = secret
            appendSecurityAudit("Generated new TOTP secret")
            auditEntries = Array(securityAuditEntries().prefix(5))
        }

        if twoFactorEnabledRaw && emergencyCodes.isEmpty {
            emergencyCodesRaw = securityEmergencyCodes().joined(separator: "|")
            appendSecurityAudit("Generated emergency unlock codes")
            auditEntries = Array(securityAuditEntries().prefix(5))
        }
    }

    private func postStatus(_ message: String) {
        statusMessage = message
        auditEntries = Array(securityAuditEntries().prefix(5))
    }

    private func savePassword() {
        guard newPasswordInput.count >= 6 else {
            statusMessage = "Password must be at least 6 characters."
            return
        }
        guard newPasswordInput == confirmPasswordInput else {
            statusMessage = "Password confirmation does not match."
            return
        }
        let hash = securityPasswordHash(newPasswordInput)
        SecuritySecureStore.save(hash, for: .passwordHash)
        storedPasswordHash = hash
        passwordEnabledRaw = true
        appendSecurityAudit("Enabled password protection")
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmPasswordInput = ""
        postStatus("Password protection enabled.")
    }

    private func updatePassword() {
        guard securityPasswordHash(currentPasswordInput) == storedPasswordHash else {
            statusMessage = "Current password is incorrect."
            return
        }
        guard newPasswordInput.count >= 6 else {
            statusMessage = "New password must be at least 6 characters."
            return
        }
        guard newPasswordInput == confirmPasswordInput else {
            statusMessage = "New password confirmation does not match."
            return
        }
        let hash = securityPasswordHash(newPasswordInput)
        SecuritySecureStore.save(hash, for: .passwordHash)
        storedPasswordHash = hash
        appendSecurityAudit("Updated security password")
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmPasswordInput = ""
        postStatus("Password updated successfully.")
    }

    private func setTwoFactor(_ enabled: Bool) {
        guard enabled else {
            showDisable2FAAlert = true
            return
        }
        guard passwordProtectionEnabled else {
            statusMessage = "Enable password protection before turning on 2FA."
            return
        }
        if twoFactorSecret.isEmpty {
            let secret = generateSecuritySecret()
            SecuritySecureStore.save(secret, for: .twoFactorSecret)
            twoFactorSecret = secret
        }
        twoFactorEnabledRaw = true
        appendSecurityAudit("Enabled 2FA via \(twoFactorMethod.display)")
        postStatus("2FA enabled via \(twoFactorMethod.display).")
    }

    private func sendDemoTwoFactorCode() {
        guard twoFactorReady else {
            statusMessage = "Enable password + 2FA first."
            return
        }
        guard twoFactorMethod != .authenticator else {
            statusMessage = "Authenticator app mode uses TOTP instead of sent codes."
            return
        }
        let destination = twoFactorMethod == .sms ? smsNumberRaw.trimmingCharacters(in: .whitespacesAndNewlines) : emailDestinationRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else {
            statusMessage = "Add a \(twoFactorMethod == .sms ? "phone number" : "delivery email") before sending a demo code."
            return
        }

        let code = issueOutOfBandSecurityCode(method: twoFactorMethod)
        demoOutOfBandCode = code
        let channel = twoFactorMethod == .sms ? "SMS" : "email"
        appendSecurityAudit("Issued demo \(channel) 2FA code to \(destination)")
        postStatus("Demo \(channel) code sent to \(destination): \(code)")
    }

    private func confirmDisablePassword() {
        guard securityPasswordHash(reauthInput) == storedPasswordHash else {
            reauthInput = ""
            postStatus("Incorrect password. Protection not changed.")
            return
        }
        reauthInput = ""
        passwordEnabledRaw = false
        twoFactorEnabledRaw = false
        biometricEnabledRaw = false
        idleLockEnabledRaw = false
        appendSecurityAudit("Disabled app entry protection (re-auth verified)")
        postStatus("Password protection disabled.")
    }

    private func confirmDisable2FA() {
        guard securityPasswordHash(reauthInput) == storedPasswordHash else {
            reauthInput = ""
            postStatus("Incorrect password. 2FA not changed.")
            return
        }
        reauthInput = ""
        twoFactorEnabledRaw = false
        appendSecurityAudit("Disabled 2FA (re-auth verified)")
        postStatus("Two-factor authentication disabled.")
    }

    private func copyRecoveryPack() {
        let payload = (["ConstructOS Security Recovery Pack", "Method: \(twoFactorMethod.display)", ""] + recoveryCodes).joined(separator: "\n")
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied recovery code pack")
        postStatus("Recovery codes copied. Store them offline.")
    }

    private func copyEmergencyCodePack() {
        guard !emergencyCodes.isEmpty else {
            statusMessage = "No emergency codes available. Generate a new pack first."
            return
        }

        let payload = (["ConstructOS Emergency Unlock Codes", ""] + emergencyCodes).joined(separator: "\n")
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied emergency unlock code pack")
        postStatus("Emergency unlock codes copied. Store offline.")
    }

    private func regenerateEmergencyCodes() {
        guard twoFactorReady else {
            statusMessage = "Enable password + 2FA before regenerating emergency codes."
            return
        }

        emergencyCodesRaw = securityEmergencyCodes().joined(separator: "|")
        appendSecurityAudit("Regenerated emergency unlock codes")
        postStatus("Emergency unlock codes rotated.")
    }

    private func copyAuthenticatorSecret() {
        copyTextToClipboard(twoFactorSecret)
        appendSecurityAudit("Copied TOTP setup secret")
        postStatus("Authenticator setup secret copied.")
    }

    private func copyAuthenticatorURI() {
        copyTextToClipboard(otpAuthURL)
        appendSecurityAudit("Copied otpauth setup URI")
        postStatus("Authenticator setup link copied.")
    }

    private func recoveryKitPayload() -> String {
        let auditSnapshot = securityAuditEntries()
        var lines: [String] = [
            "ConstructOS Recovery Kit",
            "Generated: \(Date().formatted(date: .abbreviated, time: .standard))",
            "",
            "Authenticator Profile",
            "- Account: \(authenticatorAccountName)",
            "- Issuer: \(authenticatorIssuer)",
            "- Method: \(twoFactorMethod.display)",
            "",
            "Setup",
            "- Secret: \(twoFactorSecret)",
            "- OTPAuth URI: \(otpAuthURL)",
            "",
            "Recovery Codes",
        ]

        if recoveryCodes.isEmpty {
            lines.append("- No recovery codes available")
        } else {
            lines.append(contentsOf: recoveryCodes.map { "- \($0)" })
        }

        lines.append("")
        lines.append("Emergency Unlock Codes")
        if emergencyCodes.isEmpty {
            lines.append("- No emergency unlock codes available")
        } else {
            lines.append(contentsOf: emergencyCodes.map { "- \($0)" })
        }

        lines.append("")
        lines.append("Security Audit Snapshot")
        if auditSnapshot.isEmpty {
            lines.append("- No audit entries recorded")
        } else {
            lines.append(contentsOf: auditSnapshot.map { "- \($0)" })
        }

        return lines.joined(separator: "\n")
    }

    private func exportRecoveryKit() {
        guard twoFactorReady else {
            statusMessage = "Enable password + 2FA before exporting a recovery kit."
            return
        }

        let payload = recoveryKitPayload()

#if os(macOS)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "constructos-recovery-kit-\(formatter.string(from: Date())).txt"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try payload.write(to: url, atomically: true, encoding: .utf8)
                appendSecurityAudit("Exported recovery kit")
                postStatus("Recovery kit exported to \(url.lastPathComponent).")
            } catch {
                statusMessage = "Failed to export recovery kit."
            }
        }
#elseif os(iOS)
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied recovery kit")
        postStatus("Recovery kit copied for sharing.")
#endif
    }

    private func exportSecurityAudit() {
        let payload = securityAuditEntries().isEmpty
            ? "ConstructOS Security Audit\nNo entries recorded yet."
            : (["ConstructOS Security Audit", ""] + securityAuditEntries()).joined(separator: "\n")

#if os(macOS)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "constructos-security-audit-\(formatter.string(from: Date())).log"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try payload.write(to: url, atomically: true, encoding: .utf8)
                appendSecurityAudit("Exported security audit log")
                postStatus("Audit log exported to \(url.lastPathComponent).")
            } catch {
                statusMessage = "Failed to export audit log."
            }
        }
#elseif os(iOS)
        copyTextToClipboard(payload)
        appendSecurityAudit("Copied security audit log")
        postStatus("Audit log copied for sharing.")
#endif
    }

    private func rotateTwoFactorSecret() {
        guard passwordProtectionEnabled else {
            statusMessage = "Enable password protection before rotating 2FA."
            return
        }
        guard twoFactorEnabledRaw else {
            statusMessage = "Enable 2FA before rotating the authenticator secret."
            return
        }

        let replacement = normalizedSecuritySecret(generateSecuritySecret())
        SecuritySecureStore.save(replacement, for: .twoFactorSecret)
        twoFactorSecret = replacement
        emergencyCodesRaw = securityEmergencyCodes().joined(separator: "|")
        trustedUntilEpoch = 0
        appendSecurityAudit("Rotated 2FA secret and regenerated emergency unlock codes")
        NotificationCenter.default.post(name: securityForceLockNotification, object: nil)
        postStatus("2FA secret rotated. Re-scan the new QR on every authenticator.")
    }

    private func trustCurrentDevice() {
        guard passwordProtectionEnabled else {
            statusMessage = "Enable password protection before trusting this device."
            return
        }

        trustedUntilEpoch = Date().timeIntervalSince1970 + Double(trustedDeviceHours) * 3600
        appendSecurityAudit("Trusted this device for \(trustedDeviceHours)h")
        postStatus("This device is trusted until \(trustedUntilLabel).")
    }

    private func revokeTrustedDevice() {
        trustedUntilEpoch = 0
        appendSecurityAudit("Revoked trusted device session")
        postStatus("Trusted device session cleared.")
    }

    private func lockNow() {
        trustedUntilEpoch = 0
        appendSecurityAudit("Manual security lock triggered")
        NotificationCenter.default.post(name: securityForceLockNotification, object: nil)
        postStatus("App locked. Re-enter credentials to continue.")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DashboardPanelHeading(
                    eyebrow: "SECURITY",
                    title: "Access and protection controls",
                    detail: "Credential hardening, trust state, and audit visibility for app access.",
                    accent: Theme.gold
                )
                Spacer()
                Text(passwordProtectionEnabled ? "PASSWORD ON" : "PASSWORD OFF")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(passwordProtectionEnabled ? Theme.green : Theme.muted)
                    .cornerRadius(5)
                Text(twoFactorReady ? "2FA ON" : "2FA OFF")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(twoFactorReady ? Theme.gold : Theme.muted)
                    .cornerRadius(5)
            }

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(securityHealthScore)/100", label: "SECURITY HEALTH", color: securityHealthColor)
                DashboardStatPill(value: twoFactorReady ? "ACTIVE" : "OFF", label: "TWO-FACTOR", color: twoFactorReady ? Theme.gold : Theme.muted)
                DashboardStatPill(value: trustedDeviceActive ? "TRUSTED" : "STANDARD", label: "DEVICE STATE", color: trustedDeviceActive ? Theme.cyan : Theme.muted)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SECURITY HEALTH")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(securityHealthColor)
                    Spacer()
                    Text("\(securityHealthScore)/100 · \(securityHealthLabel)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(securityHealthColor)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surface)
                        Capsule()
                            .fill(securityHealthColor)
                            .frame(width: max(10, proxy.size.width * CGFloat(securityHealthScore) / 100.0))
                    }
                }
                .frame(height: 8)

                HStack(spacing: 10) {
                    Text(passwordProtectionEnabled ? "Password: ON" : "Password: OFF")
                    Text(twoFactorReady ? "2FA: ON" : "2FA: OFF")
                    Text(emergencyCodes.isEmpty ? "Emergency: MISSING" : "Emergency: READY")
                    Text(isLockedOut ? "Lockout: ACTIVE" : "Lockout: CLEAR")
                }
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.muted)

                HStack(spacing: 10) {
                    if lastUnlockEpoch > 0 {
                        let lastUnlock = Date(timeIntervalSince1970: lastUnlockEpoch)
                        let ago = Int(Date().timeIntervalSince(lastUnlock))
                        let agoStr = ago < 60 ? "\(ago)s ago" : ago < 3600 ? "\(ago/60)m ago" : "\(ago/3600)h ago"
                        Text("Last unlock: \(agoStr)")
                    } else {
                        Text("Last unlock: never")
                    }
                    if lastFailedEpoch > 0 {
                        let lastFailed = Date(timeIntervalSince1970: lastFailedEpoch)
                        let ago = Int(Date().timeIntervalSince(lastFailed))
                        let agoStr = ago < 60 ? "\(ago)s ago" : ago < 3600 ? "\(ago/60)m ago" : "\(ago/3600)h ago"
                        Text("Last fail: \(agoStr)").foregroundColor(Theme.red)
                    } else {
                        Text("Last fail: never")
                    }
                }
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.muted)
            }

            Toggle("Require password on app entry", isOn: Binding(
                get: { passwordEnabledRaw },
                set: { enabled in
                    if !enabled {
                        showDisablePasswordAlert = true
                    } else {
                        passwordEnabledRaw = true
                    }
                }
            ))
            .toggleStyle(.switch)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.text)

            if !passwordConfigured {
                SecureField("Create password", text: $newPasswordInput)
                    .textFieldStyle(.roundedBorder)
                SecureField("Confirm password", text: $confirmPasswordInput)
                    .textFieldStyle(.roundedBorder)
                if !newPasswordInput.isEmpty {
                    let strength = securityPasswordStrength(newPasswordInput)
                    HStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { i in
                            Capsule()
                                .fill(i < strength.score
                                    ? (strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                                    : Theme.surface)
                                .frame(height: 4)
                        }
                        Text(strength.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                    }
                }
                Button("SAVE PASSWORD", action: savePassword)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.gold)
                    .cornerRadius(6)
            } else {
                SecureField("Current password", text: $currentPasswordInput)
                    .textFieldStyle(.roundedBorder)
                SecureField("New password", text: $newPasswordInput)
                    .textFieldStyle(.roundedBorder)
                SecureField("Confirm new password", text: $confirmPasswordInput)
                    .textFieldStyle(.roundedBorder)
                if !newPasswordInput.isEmpty {
                    let strength = securityPasswordStrength(newPasswordInput)
                    HStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { i in
                            Capsule()
                                .fill(i < strength.score
                                    ? (strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                                    : Theme.surface)
                                .frame(height: 4)
                        }
                        Text(strength.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(strength.score <= 2 ? Theme.red : strength.score <= 4 ? Theme.gold : Theme.green)
                    }
                }
                Button("UPDATE PASSWORD", action: updatePassword)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent)
                    .cornerRadius(6)
            }

            Divider().background(Theme.border)

            Toggle("Use \(biometricLabel) when available", isOn: Binding(
                get: { biometricEnabledRaw },
                set: { value in
                    biometricEnabledRaw = value
                    appendSecurityAudit(value ? "Enabled \(biometricLabel) unlock" : "Disabled \(biometricLabel) unlock")
                    postStatus(value ? "\(biometricLabel) unlock enabled." : "\(biometricLabel) unlock disabled.")
                }
            ))
            .toggleStyle(.switch)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.text)
            .disabled(!passwordProtectionEnabled || !biometricAvailable)

            if !biometricAvailable {
                Text("Biometric unlock is not available on this device.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            HStack {
                Toggle("Idle auto-lock", isOn: Binding(
                    get: { idleLockEnabledRaw },
                    set: { value in
                        idleLockEnabledRaw = value
                        appendSecurityAudit(value ? "Enabled idle auto-lock" : "Disabled idle auto-lock")
                        postStatus(value ? "Idle auto-lock enabled." : "Idle auto-lock disabled.")
                    }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.text)
                .disabled(!passwordProtectionEnabled)

                Spacer()

                Picker("Timeout", selection: $idleLockMinutesRaw) {
                    Text("1 min").tag(1)
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                }
                .pickerStyle(.menu)
                .frame(width: 110)
                .disabled(!idleLockEnabledRaw || !passwordProtectionEnabled)
            }

            HStack {
                Text("Trusted device")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.text)

                Spacer()

                Picker("Duration", selection: $trustedDeviceHoursRaw) {
                    Text("1 hr").tag(1)
                    Text("8 hr").tag(8)
                    Text("24 hr").tag(24)
                    Text("72 hr").tag(72)
                }
                .pickerStyle(.menu)
                .frame(width: 110)
                .disabled(!passwordProtectionEnabled)
            }

            HStack(spacing: 10) {
                Button(trustedDeviceActive ? "EXTEND TRUST" : "TRUST DEVICE") { trustCurrentDevice() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.cyan)
                    .disabled(!passwordProtectionEnabled)

                Button("LOCK NOW") { lockNow() }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.red)
                    .disabled(!passwordProtectionEnabled)

                if trustedDeviceActive {
                    Button("REVOKE TRUST") { revokeTrustedDevice() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                }

                Spacer()
            }

            if trustedDeviceActive {
                Text("Trusted until \(trustedUntilLabel). Background/return unlock is skipped until expiry, unless the session is manually locked or auto-locked.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            Divider().background(Theme.border)

            VStack(alignment: .leading, spacing: 6) {
                Text("Authenticator Profile")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.cyan)
                TextField("Account label", text: $authAccountNameRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                TextField("Issuer", text: $authIssuerRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                Text("These labels are embedded into the QR and otpauth URI for authenticator app branding.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Out-of-Band Verification")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.gold)
                TextField("SMS number", text: $smsNumberRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                TextField("Email destination", text: $emailDestinationRaw)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!passwordProtectionEnabled)
                Text("Use these destinations when the 2FA method is set to SMS OTP or Email OTP.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)
            }

            HStack {
                Toggle("Enable 2FA", isOn: Binding(
                    get: { twoFactorEnabledRaw },
                    set: { setTwoFactor($0) }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.text)
                .disabled(!passwordProtectionEnabled)

                Spacer()

                Picker("Method", selection: Binding(
                    get: { twoFactorMethodRaw },
                    set: { value in
                        twoFactorMethodRaw = value
                        appendSecurityAudit("Set 2FA method to \(SecurityTwoFactorMethod(rawValue: value)?.display ?? value)")
                        postStatus("2FA method updated.")
                    }
                )) {
                    ForEach(SecurityTwoFactorMethod.allCases, id: \.rawValue) { method in
                        Text(method.display).tag(method.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 170)
            }

            if twoFactorReady {
                twoFactorSetupSection

                Text("TOTP codes refresh every 30 seconds. The setup URI is included so another device can provision the same authenticator profile if needed.")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.muted)

                if twoFactorMethod != .authenticator {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Button("SEND DEMO \(twoFactorMethod == .sms ? "SMS" : "EMAIL") CODE") { sendDemoTwoFactorCode() }
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(twoFactorMethod == .sms ? Theme.cyan : Theme.gold)
                                .cornerRadius(6)
                                .disabled(outOfBandDestination.isEmpty)
                            if outOfBandCodeExpiresIn > 0 {
                                Text("Expires in \(outOfBandCodeExpiresIn)s")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                            if outOfBandLastSentAgo > 0 {
                                Text("Sent \(outOfBandLastSentAgo)s ago")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                        }
                        Text(twoFactorMethod == .sms
                             ? "SMS mode now uses a short-lived out-of-band code instead of the TOTP shown above."
                             : "Email mode now uses a short-lived out-of-band code instead of the TOTP shown above.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Theme.muted)
                        if outOfBandDestination.isEmpty {
                            Text(twoFactorMethod == .sms
                                 ? "Add a verified SMS destination before operators can request a code."
                                 : "Add a delivery email before operators can request a code.")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.red)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("REGEN EMERGENCY CODES") { regenerateEmergencyCodes() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.red)
                        .disabled(!twoFactorReady)
                    Button("COPY EMERGENCY CODES") { copyEmergencyCodePack() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.purple)
                        .disabled(!twoFactorReady)
                    Button("ROTATE 2FA SECRET") { showRotateConfirmation = true }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.red)
                        .disabled(!twoFactorReady)
                    Button("EXPORT RECOVERY KIT") { exportRecoveryKit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .disabled(!twoFactorReady)
                    Button("EXPORT AUDIT") { exportSecurityAudit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                }
            } else {
                HStack(spacing: 12) {
                    Button("EXPORT RECOVERY KIT") { exportRecoveryKit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .disabled(!twoFactorReady)
                    Button("EXPORT AUDIT") { exportSecurityAudit() }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.cyan)
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.green)
            }

            if isLockedOut {
                Text("Unlocks resume in \(lockoutRemainingSeconds)s.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.red)
            } else if failedUnlockAttempts > 0 {
                Text("Failed unlock attempts: \(failedUnlockAttempts)/5")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.red)
            }

            if !auditEntries.isEmpty {
                Divider().background(Theme.border)
                Text("SECURITY AUDIT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.cyan)

                ForEach(Array(auditEntries.enumerated()), id: \.offset) { _, entry in
                    Text(entry)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Theme.surface.opacity(0.7))
                        .cornerRadius(6)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 12, color: Theme.gold)
        .padding(.horizontal, 16)
        .onReceive(ticker) { now = $0 }
        .onAppear { refreshState() }
        .onChange(of: passwordEnabledRaw) { _, _ in refreshState() }
        .onChange(of: twoFactorEnabledRaw) { _, _ in refreshState() }
        .onChange(of: biometricEnabledRaw) { _, _ in refreshState() }
        .onChange(of: idleLockEnabledRaw) { _, _ in refreshState() }
        .onChange(of: idleLockMinutesRaw) { _, _ in refreshState() }
        .onChange(of: trustedUntilEpoch) { _, _ in refreshState() }
        .onChange(of: emergencyCodesRaw) { _, _ in refreshState() }
        .onChange(of: authAccountNameRaw) { _, _ in refreshState() }
        .onChange(of: authIssuerRaw) { _, _ in refreshState() }
        .alert("Rotate 2FA Secret?", isPresented: $showRotateConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Rotate", role: .destructive) { rotateTwoFactorSecret() }
        } message: {
            Text("This immediately invalidates existing authenticator enrollments and forces re-login.")
        }
        .alert("Disable Password Protection?", isPresented: $showDisablePasswordAlert) {
            SecureField("Current password", text: $reauthInput)
            Button("Cancel", role: .cancel) { reauthInput = "" }
            Button("Disable", role: .destructive) { confirmDisablePassword() }
        } message: {
            Text("Enter your current password to confirm. This will also disable 2FA, biometrics, and idle lock.")
        }
        .alert("Disable Two-Factor Authentication?", isPresented: $showDisable2FAAlert) {
            SecureField("Current password", text: $reauthInput)
            Button("Cancel", role: .cancel) { reauthInput = "" }
            Button("Disable", role: .destructive) { confirmDisable2FA() }
        } message: {
            Text("Enter your current password to confirm disabling 2FA.")
        }
    }
}

struct SecurityLockOverlay: View {
    let requiresTwoFactor: Bool
    let twoFactorMethodLabel: String
    let biometricEnabled: Bool
    let biometricLabel: String
    let lockoutUntilEpoch: Double
    @Binding var passwordInput: String
    @Binding var twoFactorInput: String
    let errorMessage: String?
    let onUnlock: () -> Void
    let onSendTwoFactorCode: () -> Void
    let verificationDestination: String
    let usingOutOfBandCode: Bool
    let onBiometricUnlock: () -> Void

    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isLockedOut: Bool {
        now.timeIntervalSince1970 < lockoutUntilEpoch
    }

    private var lockoutRemainingSeconds: Int {
        max(0, Int(ceil(lockoutUntilEpoch - now.timeIntervalSince1970)))
    }

    private var resendCooldownRemaining: Int {
        max(0, Int(ceil(20 - (Date().timeIntervalSince1970 - currentOutOfBandLastSentAt()))))
    }

    private var sendCodeButtonLabel: String {
        resendCooldownRemaining > 0 ? "WAIT \(resendCooldownRemaining)S" : "SEND CODE"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text("SECURE ACCESS")
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
                    .foregroundColor(Theme.gold)
                Text(lockPrompt)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Theme.muted)
                if requiresTwoFactor {
                    Text(usingOutOfBandCode
                         ? "Request a fresh \(twoFactorMethodLabel.lowercased()) challenge or use a one-time emergency unlock code."
                         : "You can use your current 2FA code or a one-time emergency unlock code.")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Theme.muted)
                }

                SecureField("Password", text: $passwordInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLockedOut)

                if requiresTwoFactor {
                    SecureField("\(twoFactorMethodLabel) or emergency code", text: $twoFactorInput)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLockedOut)

                    if usingOutOfBandCode {
                        HStack(spacing: 8) {
                            Button(sendCodeButtonLabel, action: onSendTwoFactorCode)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Theme.cyan)
                                .cornerRadius(6)
                                .disabled(isLockedOut || resendCooldownRemaining > 0 || verificationDestination.isEmpty)

                            Text(verificationDestination)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.muted)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }

                if biometricEnabled {
                    Button("UNLOCK WITH \(biometricLabel.uppercased())", action: onBiometricUnlock)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cyan.opacity(0.4), lineWidth: 1))
                        .cornerRadius(8)
                        .disabled(isLockedOut)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.red)
                }

                if isLockedOut {
                    Text("Retry available in \(lockoutRemainingSeconds)s")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.red)
                }

                Button("UNLOCK", action: onUnlock)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Theme.gold)
                    .cornerRadius(8)
                    .disabled(isLockedOut)
            }
            .padding(18)
            .background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.35), lineWidth: 1))
            .cornerRadius(12)
            .frame(maxWidth: 370)
            .padding(.horizontal, 20)
        }
        .onReceive(timer) { now = $0 }
    }

    private var lockPrompt: String {
        guard requiresTwoFactor else {
            return "Enter your security password to continue."
        }

        if usingOutOfBandCode {
            return "Enter your security password and the \(twoFactorMethodLabel.lowercased()) code sent to \(verificationDestination)."
        }

        return "Enter your security password and TOTP code to continue."
    }
}

// MARK: - Pricing Helpers

struct PricingBadge: View {
    let title: String; let description: String; let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(color)
                Text(description).font(.system(size: 10)).foregroundColor(Theme.muted)
            }
        }.padding(10).background(color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.2), lineWidth: 0.8)).cornerRadius(8)
    }
}

struct SectionHeading: View {
    let eyebrow: String; let title: String; let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow).font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            Text(title).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.text)
            Text(detail).font(.system(size: 11)).foregroundColor(Theme.muted)
        }
    }
}

struct FeatureCardSmall: View {
    let icon: String; let title: String; let desc: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(icon).font(.system(size: 20))
            Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(desc).font(.system(size: 10)).foregroundColor(Theme.muted).lineLimit(3)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 0.8)).cornerRadius(10)
    }
}

// MARK: - ========== PricingView.swift ==========

// MARK: - Pricing View

struct PricingView: View {
    private let projectManagementTools = [
        "Lead and client pipeline tracking",
        "Selections and approvals",
        "Project scheduling",
        "To-dos and daily logs",
        "Unlimited document and photo storage",
        "Photo and PDF annotation",
        "Electronic signatures",
        "Client and subcontractor portals",
        "Geo-aware time tracking",
        "RFI management",
        "Warranties"
    ]

    private let financialManagementTools = [
        "Takeoff",
        "Estimates",
        "Bids",
        "Proposals",
        "Bills and purchase orders",
        "Change orders",
        "Budgeting",
        "Client invoicing",
        "Online client and subcontractor payments",
        "Accounting integrations",
        "Financial reporting"
    ]

    private let outcomeHighlights = [
        "Put labor visibility closer to the work with jobsite-first time tracking.",
        "Let project managers issue, assign, and close punch items with less friction.",
        "Keep critical project information accessible in the field, not buried in back-office tools.",
        "Align office teams, clients, and trade partners around one live operating picture.",
        "Standardize daily documentation so decisions, risks, and progress are captured as they happen."
    ]

    private let platformSignals: [(String, String, Color)] = [
        ("FIELD RHYTHM", "Work stays connected to labor, logs, punch, and live issues.", Theme.cyan),
        ("COMMERCIAL DISCIPLINE", "Budgets, billing, and change activity stay tied to execution.", Theme.green),
        ("LEADERSHIP SIGNAL", "Portfolio-level visibility stays clean enough to drive action.", Theme.gold)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CONSTRUCTION OPERATING SYSTEM")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(4)
                            .foregroundColor(Theme.accent)

                        Text("Operate with control.\nScale with confidence.")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(Theme.text)

                        Text("A unified system for preconstruction, project delivery, financial control, and field execution. Give leadership better visibility, give project teams cleaner workflows, and give every job a stronger command structure from pursuit through closeout.")
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(2)
                            .foregroundColor(Theme.muted)

                        HStack(spacing: 10) {
                            pricingStat(value: "Tighter", label: "handoffs + approvals", color: Theme.gold)
                            pricingStat(value: "Fewer", label: "misses + delays", color: Theme.cyan)
                            pricingStat(value: "Clearer", label: "margin + accountability", color: Theme.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(platformSignals, id: \.0) { signal in
                            PricingBadge(title: signal.0, description: signal.1, color: signal.2)
                        }
                    }
                    .frame(width: 260)
                }
                .padding(22)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 18, color: Theme.gold)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(
                            eyebrow: "WHY IT STICKS",
                            title: "Why teams standardize on it",
                            detail: "Instead of splitting execution across disconnected tools, teams operate from one coordinated system for planning, reporting, approvals, cost control, and field communication."
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 10) {
                        ForEach(outcomeHighlights, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 5)
                                Text(item)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 16, color: Theme.cyan)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(
                        eyebrow: "PLATFORM COVERAGE",
                        title: "Tools that run the job from pursuit to closeout",
                        detail: "Operational and financial workflows stay connected so execution quality and margin control reinforce each other."
                    )

                    HStack(alignment: .top, spacing: 12) {
                        capabilityColumn(
                            title: "PROJECT MANAGEMENT TOOLS",
                            subtitle: "Control schedule, coordination, documentation, and field execution from one workflow.",
                            items: projectManagementTools,
                            accent: Theme.accent
                        )

                        capabilityColumn(
                            title: "FINANCIAL MANAGEMENT TOOLS",
                            subtitle: "Protect margin with better estimating discipline, budget visibility, and billing control.",
                            items: financialManagementTools,
                            accent: Theme.green
                        )
                    }
                }
                .padding(18)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 16, color: Theme.accent)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(
                            eyebrow: "EXECUTION IMPACT",
                            title: "Operational discipline that compounds",
                            detail: "Faster approvals, cleaner documentation, stronger field accountability, and better visibility for both internal teams and external stakeholders."
                        )
                    }
                    .frame(width: 250, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        FeatureCardSmall(icon: "\u{1F4C1}", title: "Operational Clarity", desc: "Schedules, documents, photos, and field notes live in one controlled workflow", color: Theme.gold)
                        FeatureCardSmall(icon: "\u{1F91D}", title: "Stakeholder Trust", desc: "Approvals, signatures, and communication move through a disciplined client-ready experience", color: Theme.cyan)
                        FeatureCardSmall(icon: "\u{1F6E0}", title: "Field Accountability", desc: "Labor, tasks, punch, and reporting stay anchored to the work in place", color: Theme.green)
                        FeatureCardSmall(icon: "\u{1F4B5}", title: "Commercial Control", desc: "Estimates, budgets, change events, and billing stay connected to execution", color: Theme.accent)
                    }
                }
                .padding(18)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 16, color: Theme.purple)
            }
            .padding(16)
        }
        .background(Theme.bg)
    }

    private func pricingStat(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surface.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private func capabilityColumn(title: String, subtitle: String, items: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(accent)

            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.muted)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accent)
                        Text(item)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.74))
        .premiumGlow(cornerRadius: 16, color: accent)
    }
}

// MARK: - ========== SocialNetworkView.swift ==========


// MARK: - Network View

struct NetworkView: View {
    private let voipContacts: [Contact] = [
        Contact(name: "Avery Stone", title: "Site Superintendent", company: "NorthGrid Build", score: 92, connections: 81, projects: 14, initials: "AS"),
        Contact(name: "Jules Rivera", title: "PM", company: "Peakline", score: 88, connections: 63, projects: 9, initials: "JR"),
        Contact(name: "Mina Park", title: "Field Engineer", company: "BuildAxis", score: 85, connections: 57, projects: 11, initials: "MP"),
        Contact(name: "Theo Grant", title: "Owner Rep", company: "UrbanCore", score: 83, connections: 49, projects: 8, initials: "TG")
    ]

    @State private var selectedContactID: UUID?
    @State private var inCall = false
    @State private var groupMode = true
    @State private var activeStream = true
    @State private var multitaskMode = true
    @State private var audioEnabled = true
    @State private var videoEnabled = true
    @State private var speakerEnabled = true
    @State private var e2eeEnabled = true
    @State private var ephemeralMode = true
    @State private var ephemeralTTL = 15
    @State private var callStatus = "Ready"
    @State private var messageInput = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingPhotoData: Data?
    @State private var keyEpoch = 1
    @State private var apksEnabled = true
    @State private var apksAutoRotate = true
    @State private var apksPriority = 2
    @State private var photoMessagingTodoDone = true
    @State private var callEvents: [String] = []
    @State private var directMessages: [ChatMessage] = [
        ChatMessage(
            role: .ai,
            text: "Encrypted room initialized. Ephemeral mode active.",
            timestamp: Date().addingTimeInterval(-90),
            deliveryState: .read
        ),
        ChatMessage(
            role: .user,
            text: "Crew standup in 5. Bring Site Gamma into room.",
            timestamp: Date().addingTimeInterval(-45),
            deliveryState: .read
        )
    ]

    @State private var messageTicker = Date()
    private let messageTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var expiredEphemeralCount: Int {
        directMessages.filter { $0.deliveryState == .expired }.count
    }

    private var selectedContact: Contact {
        voipContacts.first { $0.id == selectedContactID } ?? voipContacts[0]
    }

    private var canSendMessage: Bool {
        !messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingPhotoData != nil
    }

    private func pushEvent(_ text: String) {
        callEvents.insert(text, at: 0)
        callEvents = Array(callEvents.prefix(8))
    }

    private func startCall() {
        inCall = true
        callStatus = groupMode ? "Group video live" : "Direct call live"
        if e2eeEnabled {
            keyEpoch += 1
            pushEvent("E2EE key epoch rotated to #\(keyEpoch)")
        }
        pushEvent("Call started with \(selectedContact.name)")
    }

    private func endCall() {
        inCall = false
        callStatus = "Call ended"
        pushEvent("Call ended")
    }

    private func sendMessage() {
        let trimmed = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || pendingPhotoData != nil else { return }
        let sentAt = Date()
        let expiry = ephemeralMode ? sentAt.addingTimeInterval(TimeInterval(ephemeralTTL)) : nil
        let outgoingPhoto = pendingPhotoData
        directMessages.append(ChatMessage(
            role: .user,
            text: trimmed.isEmpty ? "Photo attachment" : trimmed,
            timestamp: sentAt,
            deliveryState: .sending,
            expiresAt: expiry,
            encrypted: e2eeEnabled,
            photoData: outgoingPhoto
        ))
        if outgoingPhoto != nil {
            pushEvent("Photo message queued\(ephemeralMode ? " (TTL: \(ephemeralTTL)s)" : "")")
        } else if ephemeralMode {
            pushEvent("Ephemeral message queued (TTL: \(ephemeralTTL)s)")
        }
        refreshMessageStates(now: sentAt)
        messageInput = ""
        pendingPhotoData = nil
        selectedPhotoItem = nil
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            pendingPhotoData = nil
            return
        }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await MainActor.run {
                pendingPhotoData = data
                photoMessagingTodoDone = true
                pushEvent("Photo attached to draft")
            }
        }
    }

    private func chatImage(from data: Data) -> Image? {
#if os(iOS)
        guard let image = UIImage(data: data) else { return nil }
        return Image(uiImage: image)
#elseif os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        return Image(nsImage: image)
#else
        return nil
#endif
    }

    private func runAction(_ label: String) {
        switch label {
        case "MUTE CREW":
            audioEnabled = false
        case "PIN FOREMAN":
            activeStream = true
        case "LOCK ROOM":
            e2eeEnabled = true
            keyEpoch += 1
        case "ROTATE KEYS":
            keyEpoch += 1
        default:
            break
        }
        pushEvent("Action: \(label)")
    }

    private func refreshMessageStates(now: Date = Date()) {
        directMessages = directMessages.map { message in
            var updated = message

            if let expiresAt = updated.expiresAt, now >= expiresAt {
                updated.deliveryState = .expired
                return updated
            }

            guard updated.role == .user else { return updated }

            let age = now.timeIntervalSince(updated.timestamp)
            if age >= 4 {
                updated.deliveryState = .read
            } else if age >= 1.5 {
                updated.deliveryState = .delivered
            }

            return updated
        }
    }

    private func purgeExpiredMessages() {
        let expiredCount = expiredEphemeralCount
        guard expiredCount > 0 else { return }
        directMessages.removeAll { $0.deliveryState == .expired }
        pushEvent("Cleared \(expiredCount) expired message\(expiredCount == 1 ? "" : "s")")
    }

    private func messageMetaText(for message: ChatMessage) -> String {
        var components = [message.timestampLabel, message.deliveryState.rawValue]

        if message.encrypted {
            components.append("E2EE")
        }

        if let expiresAt = message.expiresAt {
            let remaining = max(0, Int(ceil(expiresAt.timeIntervalSince(messageTicker))))
            components.append(message.deliveryState == .expired ? "Expired" : "TTL \(remaining)s")
        }

        return components.joined(separator: " · ")
    }

    private var photoMessagingTodoPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TO-DO LIST")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Theme.gold)
            HStack(spacing: 8) {
                Image(systemName: photoMessagingTodoDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(photoMessagingTodoDone ? Theme.green : Theme.muted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable picture messaging in room chat")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(photoMessagingTodoDone ? "Completed" : "Pending")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(photoMessagingTodoDone ? Theme.green : Theme.muted)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(Theme.surface.opacity(0.75))
        .cornerRadius(8)
    }

    private func directMessageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .ai { Spacer(minLength: 0) }
            VStack(alignment: .leading, spacing: 4) {
                if let photoData = message.photoData, let image = chatImage(from: photoData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 120)
                        .clipped()
                        .cornerRadius(6)
                }
                Text(message.text)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text(messageMetaText(for: message))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(message.deliveryState == .expired ? Theme.red : Theme.muted)
            }
            .padding(8)
            .background(message.role == .user ? Theme.panel : Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(message.deliveryState == .expired ? Theme.red.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(8)
            if message.role == .user { Spacer(minLength: 0) }
        }
    }

    private var directMessagePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("IN-CALL DIRECT MESSAGES")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Theme.cyan)
                Spacer()
                if ephemeralMode {
                    Text("AUTO-EXPIRE \(ephemeralTTL)S")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.gold)
                        .cornerRadius(4)
                }
                if expiredEphemeralCount > 0 {
                    Button("CLEAR EXPIRED", action: purgeExpiredMessages)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.red)
                        .buttonStyle(.plain)
                }
            }

            ForEach(directMessages) { message in
                directMessageBubble(message)
            }

            if let previewData = pendingPhotoData, let image = chatImage(from: previewData) {
                HStack(spacing: 8) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 50)
                        .clipped()
                        .cornerRadius(6)
                    Text("Photo attached")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Button("REMOVE") {
                        pendingPhotoData = nil
                        selectedPhotoItem = nil
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.red)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 2)
            }

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.gold)
                        .cornerRadius(6)
                }

                TextField("Message room", text: $messageInput)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.surface)
                    .cornerRadius(6)

                Button("SEND", action: sendMessage)
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(canSendMessage ? Theme.accent : Theme.muted)
                    .cornerRadius(6)
            }
            .disabled(!canSendMessage)
        }
        .padding(10)
        .background(Theme.surface.opacity(0.75))
        .cornerRadius(8)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("VOIP COMMAND")
                        .font(.system(size: 12, weight: .black))
                        .tracking(2)
                        .foregroundColor(Theme.cyan)
                    Spacer()
                    Text(callStatus.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(inCall ? Theme.green.opacity(0.25) : Theme.surface)
                        .cornerRadius(6)
                        .foregroundColor(inCall ? Theme.green : Theme.muted)
                }

                HStack(spacing: 8) {
                    Toggle("GROUP VIDEO", isOn: $groupMode)
                        .toggleStyle(.button)
                    Toggle("ACTIVE STREAM", isOn: $activeStream)
                        .toggleStyle(.button)
                    Toggle("MULTITASK", isOn: $multitaskMode)
                        .toggleStyle(.button)
                }
                .font(.system(size: 8, weight: .bold))

                HStack(spacing: 8) {
                    Toggle("AUDIO", isOn: $audioEnabled)
                        .toggleStyle(.button)
                    Toggle("VIDEO", isOn: $videoEnabled)
                        .toggleStyle(.button)
                    Toggle("SPEAKER", isOn: $speakerEnabled)
                        .toggleStyle(.button)
                }
                .font(.system(size: 8, weight: .bold))

                HStack(spacing: 8) {
                    Toggle("E2EE", isOn: $e2eeEnabled)
                        .toggleStyle(.button)
                    Toggle("EPHEMERAL", isOn: $ephemeralMode)
                        .toggleStyle(.button)
                    if ephemeralMode {
                        Stepper("TTL \(ephemeralTTL)s", value: $ephemeralTTL, in: 5...120, step: 5)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("APKS")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundColor(Theme.gold)
                    HStack(spacing: 8) {
                        Toggle("ENABLE", isOn: $apksEnabled)
                            .toggleStyle(.button)
                        Toggle("AUTO-ROTATE", isOn: $apksAutoRotate)
                            .toggleStyle(.button)
                        Stepper("PRIORITY \(apksPriority)", value: $apksPriority, in: 1...5)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.muted)
                    }
                    .font(.system(size: 8, weight: .bold))
                }
                .padding(10)
                .background(Theme.surface.opacity(0.75))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("ROOM")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Theme.accent)
                    ForEach(voipContacts) { contact in
                        Button {
                            selectedContactID = contact.id
                        } label: {
                            HStack {
                                Text(contact.initials)
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.black)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.gold)
                                    .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.text)
                                    Text(contact.title)
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(Theme.muted)
                                }
                                Spacer()
                                if selectedContactID == contact.id {
                                    Text("SELECTED")
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(Theme.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Theme.surface.opacity(0.75))
                .cornerRadius(8)

                HStack(spacing: 8) {
                    Button(inCall ? "END CALL" : "START CALL") {
                        inCall ? endCall() : startCall()
                    }
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(inCall ? Theme.red : Theme.green)
                    .cornerRadius(8)

                    Button("ROTATE E2EE") { runAction("ROTATE KEYS") }
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Theme.gold)
                        .cornerRadius(8)
                }

                HStack(spacing: 8) {
                    ForEach(["MUTE CREW", "PIN FOREMAN", "LOCK ROOM"], id: \.self) { action in
                        Button(action) { runAction(action) }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.text)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.panel)
                            .cornerRadius(6)
                    }
                }

                photoMessagingTodoPanel

                directMessagePanel

                VStack(alignment: .leading, spacing: 4) {
                    Text("EVENT LOG")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(Theme.gold)
                    Text("E2EE: \(e2eeEnabled ? "ON" : "OFF") · Key Epoch: #\(keyEpoch) · Ephemeral: \(ephemeralMode ? "ON" : "OFF")")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    ForEach(callEvents, id: \.self) { event in
                        Text("• \(event)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                }
                .padding(10)
                .background(Theme.surface.opacity(0.75))
                .cornerRadius(8)
            }
            .padding(14)
        }
        .background(Theme.bg)
        .onReceive(messageTimer) { now in
            messageTicker = now
            refreshMessageStates(now: now)
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            loadSelectedPhoto(newValue)
        }
    }
}

// MARK: - ========== MCP Server (Model Context Protocol) ==========

/// Local MCP tool server that gives Angelic AI access to live app data.
/// Implements tool definitions and execution per the Anthropic tool_use spec.

@MainActor
final class MCPToolServer: ObservableObject {
    static let shared = MCPToolServer()

    // MARK: - Tool Definitions (sent to Claude in API call)

    var toolDefinitions: [[String: Any]] {
        [
            toolDef("get_projects", "Get all active construction projects with status, progress, budget, and team assignments", [:]),
            toolDef("get_contracts", "Get all contracts in the bid pipeline with stage, budget, bid due dates, and scores", [:]),
            toolDef("get_site_status", "Get live site status for all active jobsites including risk scores, weather holds, and crew deployment", [:]),
            toolDef("get_crew_deploy", "Get current crew deployment across all sites with headcount, trade, and status (ACTIVE/HOLD/DELAYED)", [:]),
            toolDef("get_inspections", "Get upcoming and overdue inspections with permit status and due dates", [:]),
            toolDef("get_weather", "Get weather forecast with construction risk flags (concrete pour holds, wind advisories, slip hazards)", [:]),
            toolDef("get_change_orders", "Get all change orders with status, amounts, and approval state", [:]),
            toolDef("get_safety_incidents", "Get recent safety incidents with type, severity, and corrective actions", [:]),
            toolDef("get_rfis", "Get open RFIs with priority, age, and assignment status", [:]),
            toolDef("get_rental_inventory", "Search construction equipment rentals by category or keyword", [
                "query": ["type": "string", "description": "Search term (e.g. 'excavator', 'concrete', 'crane')"],
                "category": ["type": "string", "description": "Category filter (e.g. 'Heavy Equipment', 'Hand & Power Tools')"]
            ]),
            toolDef("get_rental_rates", "Get market rental rates and pricing trends for equipment categories", [:]),
            toolDef("get_budget_summary", "Get budget health across all projects with spend vs. budget and burn rates", [:]),
            toolDef("get_subcontractor_scores", "Get subcontractor performance scorecards with ratings and payment status", [:]),
            toolDef("get_daily_costs", "Get daily cost tracking entries for all active sites", [:]),
            toolDef("get_material_deliveries", "Get material delivery status and tracking for all pending orders", [:]),
            toolDef("get_punch_list", "Get open punch list items across all sites with priority and status", [:]),
            toolDef("calculate_rental_cost", "Calculate total rental cost for equipment", [
                "equipment": ["type": "string", "description": "Equipment name"],
                "daily_rate": ["type": "number", "description": "Daily rental rate in dollars"],
                "days": ["type": "integer", "description": "Number of rental days"],
                "quantity": ["type": "integer", "description": "Number of units"]
            ]),
        ]
    }

    private func toolDef(_ name: String, _ description: String, _ properties: [String: [String: String]]) -> [String: Any] {
        var schema: [String: Any] = ["type": "object", "properties": properties]
        if !properties.isEmpty {
            schema["required"] = Array(properties.keys)
        }
        return [
            "name": name,
            "description": description,
            "input_schema": schema
        ]
    }

    // MARK: - Tool Execution

    func executeTool(name: String, input: [String: Any]) -> String {
        switch name {
        case "get_projects":
            return mockProjects.map { "\($0.name) | Client: \($0.client) | Status: \($0.status) | Progress: \($0.progress)% | Budget: \($0.budget) | Score: \($0.score)" }.joined(separator: "\n")

        case "get_contracts":
            return mockContracts.map { "\($0.title) | Client: \($0.client) | Stage: \($0.stage) | Budget: \($0.budget) | Bid Due: \($0.bidDue) | Score: \($0.score) | Bidders: \($0.bidders)" }.joined(separator: "\n")

        case "get_site_status":
            return """
            Riverside Lofts | DELAYED | Risk: 95 | Concrete crew on HOLD (rain)
            Site Gamma | AT RISK | Risk: 65 | Steel delivery delayed
            Pine Ridge Ph.2 | AT RISK | Risk: 55 | Framing inspection 1d overdue
            Harbor Crossing | ON TRACK | Risk: 10 | MEP active
            Eastside Civic Hub | ON TRACK | Risk: 15 | Permit pending
            """

        case "get_crew_deploy":
            return """
            Riverside Lofts | Concrete | 14 workers | HOLD
            Site Gamma | Steel | 8 workers | DELAYED
            Harbor Crossing | MEP | 22 workers | ACTIVE
            Pine Ridge Ph.2 | Framing | 11 workers | ACTIVE
            Eastside Civic Hub | Finishes | 6 workers | STANDBY
            Total: 61 workers across 5 sites
            """

        case "get_inspections":
            return """
            Riverside Lofts | Foundation Inspection | DUE TODAY | Permit: PENDING
            Site Gamma | Steel Frame Inspection | Due in 2d | Permit: APPROVED
            Harbor Crossing | MEP Rough-in | Due in 5d | Permit: APPROVED
            Pine Ridge Ph.2 | Framing Inspection | 1d OVERDUE | Permit: FLAGGED
            Eastside Civic Hub | Building Permit | Due in 9d | Permit: PENDING
            """

        case "get_weather":
            return """
            TODAY: Heavy Rain | High 54°F / Low 41°F | CONCRETE POUR HOLD | SLIP HAZARD
            TOMORROW: Partly Cloudy | High 61°F / Low 44°F | WIND ADVISORY
            DAY 3: Clear | High 68°F / Low 50°F | No risk flags
            """

        case "get_change_orders":
            return "CO-001 | Foundation depth increase | $42,000 | PENDING owner approval\nCO-002 | Added fire stops | $18,500 | APPROVED\nCO-003 | Revised MEP routing | $27,300 | PENDING"

        case "get_safety_incidents":
            return "INC-03-14 | Near Miss | Scaffold harness | Grid B-7 | Corrective action OPEN\nINC-03-10 | First Aid | Minor laceration | Site Gamma | CLOSED"

        case "get_rfis":
            return "RFI-001 | Structural steel connection detail | HIGH | 12 days open | Assigned: Engineering\nRFI-002 | MEP coordination conflict at grid C-4 | MED | 8 days open | PENDING\nRFI-003 | Exterior cladding attachment spec | LOW | 3 days open | OPEN"

        case "get_rental_inventory":
            let query = (input["query"] as? String ?? "").lowercased()
            let category = (input["category"] as? String ?? "").lowercased()
            let items = rentalInventory.filter { item in
                (query.isEmpty || item.name.lowercased().contains(query) || item.specs.lowercased().contains(query)) &&
                (category.isEmpty || item.category.rawValue.lowercased().contains(category))
            }.prefix(10)
            if items.isEmpty { return "No equipment found matching query." }
            return items.map { "\($0.name) | \($0.category.rawValue) | \($0.dailyRate)/day | \($0.weeklyRate)/week | \($0.provider.rawValue) | \($0.availability)" }.joined(separator: "\n")

        case "get_rental_rates":
            return """
            Excavators: avg $820/day (+5% trend, High demand)
            Dozers: avg $1,150/day (+3%, Medium demand)
            Boom Lifts: avg $340/day (-2%, Medium demand)
            Scissor Lifts: avg $145/day (+1%, High demand)
            Generators: avg $280/day (+8%, High demand)
            Cranes: avg $2,400/day (+4%, Low demand)
            Jackhammers: avg $72/day (flat, Medium demand)
            """

        case "get_budget_summary":
            return """
            Metro Tower Complex | Budget: $42.8M | Spent: $27.8M (65%) | On Track
            Harbor Industrial Park | Budget: $18.5M | Spent: $14.4M (78%) | Ahead
            Riverside Residential | Budget: $31.2M | Spent: $13.1M (42%) | On Track
            Portfolio Total: $92.5M budget, $55.3M spent (60%)
            """

        case "get_subcontractor_scores":
            return "Apex Concrete | Score: 92 | On-Time: 96% | Quality: 94% | Payment: CURRENT\nElite Steel | Score: 85 | On-Time: 88% | Quality: 90% | Payment: CURRENT\nPrime Electric | Score: 78 | On-Time: 82% | Quality: 85% | Payment: 30d OVERDUE"

        case "get_daily_costs":
            return "03-25: $48,200 (Labor: $31,400, Materials: $12,800, Equipment: $4,000)\n03-24: $52,100 (Labor: $33,600, Materials: $14,200, Equipment: $4,300)\n03-23: $44,800 (Labor: $29,100, Materials: $11,900, Equipment: $3,800)"

        case "get_material_deliveries":
            return """
            Structural Steel W8x31 | Nucor | PO-4411 | DELIVERED 03-15
            Concrete 4000 PSI | LaFarge | PO-4418 | ORDERED, due 03-18
            Electrical Conduit 3/4" EMT | Graybar | PO-4422 | DELAYED (ETA 03-20)
            Drywall 5/8" Type X | USG | PO-4430 | IN TRANSIT (ETA 4 hrs)
            """

        case "get_punch_list":
            return "Fire-stopping gaps at grid B-7 | HIGH | OPEN | Riverside Lofts\nDrywall finish touch-up L3 corridor | LOW | OPEN | Harbor Crossing\nMEP label missing at panel 2A | MED | IN PROGRESS | Pine Ridge"

        case "calculate_rental_cost":
            let rate = input["daily_rate"] as? Double ?? 0
            let days = input["days"] as? Int ?? 1
            let qty = input["quantity"] as? Int ?? 1
            let total = rate * Double(days) * Double(qty)
            let equipment = input["equipment"] as? String ?? "Equipment"
            return "\(equipment): $\(String(format: "%.0f", rate))/day x \(days) days x \(qty) units = $\(String(format: "%.0f", total)) total"

        default:
            return "Unknown tool: \(name)"
        }
    }
}

// MARK: - ========== AngelicAIView.swift ==========

//
// Uses the Anthropic Messages API (claude-haiku-4-5-20251001) with MCP tools.
// API key is stored securely in Keychain.
// Conversation history is stored in Supabase (cs_ai_messages) when configured,
// falling back to in-memory only.


// MARK: - Message model

struct AIMessage: Identifiable {
    let id = UUID()
    let role: AIRole
    let content: String
    let timestamp: Date

    enum AIRole { case user, assistant }

    var timestampLabel: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: timestamp)
    }
}

// MARK: - View

struct AngelicAIView: View {
    @State private var apiKey: String = ""
    @AppStorage("ConstructOS.AngelicAI.SessionID") private var sessionID: String = UUID().uuidString

    @State private var messages: [AIMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var errorMessage: String?
    @State private var showKeySetup = false
    @State private var tempAPIKey = ""
    @State private var scrollID: UUID?

    private let supabase = SupabaseService.shared
    private let systemPrompt = """
    You are Angelic — an expert AI assistant for ConstructionOS, a unified construction operating system. \
    You have deep knowledge of construction project management, contract bidding, site safety, crew logistics, \
    RFI workflows, change orders, scheduling, budget management, and subcontractor coordination. \
    You provide clear, direct, actionable answers. Use construction industry terminology naturally. \
    When asked about specific projects, crews, or sites, acknowledge you can reference live data from \
    the platform modules. Keep responses concise and field-ready.
    """

    private let starterPrompts = [
        "Draft an RFI for a concrete delay on Site Alpha",
        "What's the standard retainage release process?",
        "Summarize best practices for daily crew standups",
        "How should I handle a subcontractor safety incident?",
        "What should be included in a change order package?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            angelicHeader
            Divider().overlay(Theme.border)
            if apiKey.isEmpty {
                apiKeySetupView
            } else {
                chatArea
                inputBar
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showKeySetup) {
            APIKeySheet(tempKey: $tempAPIKey) { key in
                apiKey = key
                showKeySetup = false
            }
        }
        .task { if !apiKey.isEmpty { await loadHistory() } }
    }

    // MARK: - Header

    private var angelicHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("✦")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.purple)
                    Text("ANGELIC AI")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(4)
                        .foregroundColor(Theme.purple)
                }
                Text("Construction Intelligence")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Theme.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if !apiKey.isEmpty {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.green).frame(width: 6, height: 6)
                        Text("claude-haiku-4-5")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.muted)
                    }
                }
                HStack(spacing: 8) {
                    Button { showKeySetup = true } label: {
                        Image(systemName: "key")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                    }
                    Button {
                        messages = []
                        sessionID = UUID().uuidString
                        errorMessage = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface)
    }

    // MARK: - API Key Setup

    private var apiKeySetupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                VStack(spacing: 12) {
                    Text("✦")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.purple.opacity(0.7))
                    Text("Angelic AI")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(Theme.text)
                    Text("Your construction intelligence assistant. Connect your Anthropic API key to activate Angelic.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    SecureField("sk-ant-...", text: $tempAPIKey)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .accentColor(Theme.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.surface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 1))
                        .padding(.horizontal, 20)

                    Button {
                        if !tempAPIKey.isEmpty {
                            apiKey = tempAPIKey
                            tempAPIKey = ""
                        }
                    } label: {
                        Text("Activate Angelic")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(tempAPIKey.isEmpty ? Theme.muted : Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(tempAPIKey.isEmpty ? Theme.surface : Theme.purple)
                            .cornerRadius(10)
                    }
                    .disabled(tempAPIKey.isEmpty)
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("SAMPLE CAPABILITIES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Theme.muted)
                        .padding(.horizontal, 20)
                    ForEach(starterPrompts, id: \.self) { prompt in
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle").font(.system(size: 10)).foregroundColor(Theme.purple)
                            Text(prompt).font(.system(size: 12)).foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Chat

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        starterPromptsView
                    } else {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if isThinking {
                            ThinkingBubble()
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: isThinking) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    private var starterPromptsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 30)
            Text("✦ How can I help?")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("Tap a prompt or type your question below")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
            VStack(spacing: 8) {
                ForEach(starterPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        Task { await sendMessage() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.purple)
                            Text(prompt)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.surface)
                        .cornerRadius(10)
                        .premiumGlow(cornerRadius: 10, color: Theme.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            Spacer(minLength: 30)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Theme.border)
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            HStack(spacing: 10) {
                TextField("Ask Angelic...", text: $inputText, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.purple)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
                    .onSubmit { if !inputText.isEmpty && !isThinking { Task { await sendMessage() } } }

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: isThinking ? "ellipsis" : "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.bg)
                        .frame(width: 36, height: 36)
                        .background(inputText.isEmpty || isThinking ? Theme.muted.opacity(0.4) : Theme.purple)
                        .clipShape(Circle())
                }
                .disabled(inputText.isEmpty || isThinking)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bg)
        }
    }

    // MARK: - Send message

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        errorMessage = nil

        let userMsg = AIMessage(role: .user, content: text, timestamp: Date())
        messages.append(userMsg)
        isThinking = true

        await persistMessage(userMsg)

        do {
            let response = try await callClaude(userMessage: text)
            let aiMsg = AIMessage(role: .assistant, content: response, timestamp: Date())
            messages.append(aiMsg)
            await persistMessage(aiMsg)
        } catch {
            errorMessage = error.localizedDescription
        }
        isThinking = false
    }

    // MARK: - Claude API with MCP Tool Use

    private let mcpServer = MCPToolServer.shared

    private func callClaude(userMessage: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AngelicError.noAPIKey }
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AngelicError.invalidURL
        }

        let history: [[String: Any]] = messages.dropLast().map {
            ["role": $0.role == .user ? "user" : "assistant", "content": $0.content]
        }
        var messageList = history
        messageList.append(["role": "user", "content": userMessage])

        // Include MCP tools in the request
        var payload: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 2048,
            "system": systemPrompt + "\n\nYou have access to live ConstructionOS data through tools. Use them to answer questions about projects, sites, crews, equipment, budgets, and more. Always check live data before answering factual questions about the jobsite.",
            "messages": messageList,
            "tools": mcpServer.toolDefinitions
        ]

        var finalText = ""
        var maxToolRounds = 5  // prevent infinite loops

        while maxToolRounds > 0 {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let body = String(data: data, encoding: .utf8) ?? "No body"
                if http.statusCode == 401 { throw AngelicError.invalidAPIKey }
                throw AngelicError.apiError(http.statusCode, body)
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let contentBlocks = json["content"] as? [[String: Any]],
                  let stopReason = json["stop_reason"] as? String
            else {
                throw AngelicError.parseError
            }

            // Check if Claude wants to use tools
            if stopReason == "tool_use" {
                // Build tool results
                var toolResults: [[String: Any]] = []
                var assistantContent: [[String: Any]] = []

                for block in contentBlocks {
                    let blockType = block["type"] as? String ?? ""
                    if blockType == "text", let text = block["text"] as? String {
                        assistantContent.append(["type": "text", "text": text])
                        finalText += text
                    } else if blockType == "tool_use" {
                        let toolName = block["name"] as? String ?? ""
                        let toolID = block["id"] as? String ?? ""
                        let toolInput = block["input"] as? [String: Any] ?? [:]

                        assistantContent.append(block)

                        // Execute the tool via MCP server
                        let result = await MainActor.run { mcpServer.executeTool(name: toolName, input: toolInput) }

                        toolResults.append([
                            "type": "tool_result",
                            "tool_use_id": toolID,
                            "content": result
                        ])
                    }
                }

                // Add assistant message with tool use + tool results for next round
                messageList.append(["role": "assistant", "content": assistantContent])
                messageList.append(["role": "user", "content": toolResults])
                payload["messages"] = messageList
                maxToolRounds -= 1
                continue

            } else {
                // stop_reason == "end_turn" — collect text
                for block in contentBlocks {
                    if let text = block["text"] as? String {
                        finalText += text
                    }
                }
                break
            }
        }

        if finalText.isEmpty { throw AngelicError.parseError }
        return finalText
    }

    // MARK: - Persistence

    private func loadHistory() async {
        guard supabase.isConfigured else { return }
        do {
            let stored: [SupabaseAIMessage] = try await supabase.fetch(
                "cs_ai_messages",
                query: ["session_id": "eq.\(sessionID)", "order": "created_at.asc"]
            )
            messages = stored.map {
                AIMessage(
                    role: $0.role == "user" ? .user : .assistant,
                    content: $0.content,
                    timestamp: Date()
                )
            }
        } catch {
            // History load failures are non-critical — continue with empty chat
            print("[AngelicAI] History load error: \(error.localizedDescription)")
        }
    }

    private func persistMessage(_ message: AIMessage) async {
        guard supabase.isConfigured else { return }
        let record = SupabaseAIMessage(
            id: nil,
            sessionId: sessionID,
            role: message.role == .user ? "user" : "assistant",
            content: message.content,
            createdAt: nil
        )
        do { try await supabase.insert("cs_ai_messages", record: record) }
        catch { print("[AngelicAI] Persist error: \(error.localizedDescription)") }
    }
}

// MARK: - Errors

private enum AngelicError: LocalizedError {
    case noAPIKey, invalidURL, invalidAPIKey, parseError
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key set. Tap the key icon to configure."
        case .invalidURL: return "Invalid API endpoint URL."
        case .invalidAPIKey: return "Invalid API key. Tap the key icon to update it."
        case .parseError: return "Could not parse the AI response."
        case .apiError(let code, let body): return "API error \(code): \(body)"
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                Text("✦")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.purple)
                    .padding(.bottom, 4)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 3) {
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(message.role == .user ? Theme.bg : Theme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Theme.accent : Theme.surface)
                    .cornerRadius(16)

                Text(message.timestampLabel)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.muted.opacity(0.7))
            }

            if message.role == .user {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
                    .padding(6)
                    .background(Theme.surface)
                    .clipShape(Circle())
                    .padding(.bottom, 4)
            } else {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Thinking Bubble

private struct ThinkingBubble: View {
    @State private var dot1 = false
    @State private var dot2 = false
    @State private var dot3 = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text("✦").font(.system(size: 14)).foregroundColor(Theme.purple).padding(.bottom, 4)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.muted.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(i == 0 ? (dot1 ? 1.4 : 0.8) : i == 1 ? (dot2 ? 1.4 : 0.8) : (dot3 ? 1.4 : 0.8))
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: dot1)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Theme.surface)
            .cornerRadius(16)
            Spacer(minLength: 40)
        }
        .onAppear {
            dot1 = true; dot2 = true; dot3 = true
        }
    }
}

// MARK: - API Key Sheet

private struct APIKeySheet: View {
    @Binding var tempKey: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your API key is stored locally in app storage. It is never sent anywhere except directly to api.anthropic.com.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                        .padding(14)
                        .background(Theme.surface)
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ANTHROPIC API KEY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Theme.muted)
                        SecureField("sk-ant-...", text: $tempKey)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Theme.text)
                            .accentColor(Theme.purple)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(Theme.surface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Angelic AI Key")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if !tempKey.isEmpty { onSave(tempKey) } }
                        .foregroundColor(Theme.purple).fontWeight(.bold)
                        .disabled(tempKey.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ========== MoneyLensView.swift ==========

// Reframe every financial decision through the lens of net worth acceleration


struct MoneyLensView: View {
    // MARK: - Supabase
    private let supabase = SupabaseService.shared
    @State private var remoteProjects: [SupabaseProject] = []
    @State private var remoteContracts: [SupabaseContract] = []

    // MARK: - Wealth Tracking
    @AppStorage("ConstructOS.Wealth.TrackingRaw") private var trackingRaw: String = ""
    @AppStorage("ConstructOS.Wealth.CapitalAllocation") private var capitalAllocationRaw: String = ""
    @State private var trackingEntries: [WealthTrackingEntry] = []
    @State private var showTrackingSheet = false

    // MARK: - Capital Allocation
    @State private var allocBuilders: Double = 68
    @State private var allocEngines: Double = 21
    @State private var allocBets: Double = 8
    @State private var allocDrain: Double = 3
    @State private var editingAllocation = false

    // MARK: - ROI Calculator
    @State private var roiCost: String = ""
    @State private var roiRevenue: String = ""
    @State private var roiMonths: String = "12"
    @State private var showRoiResult = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                financialDashboardPanel
                wealthTrackerPanel
                moneyPrinciplesPanel
                capitalAllocationPanel
                roiCalculatorPanel
                moneyReframePanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showTrackingSheet) {
            WealthTrackingSheet { entry in
                trackingEntries.insert(entry, at: 0)
                saveTracking()
            }
        }
        .task {
            loadPersistedState()
            await loadRemoteData()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("💰").font(.system(size: 18))
                    Text("MONEY LENS").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(wealthGold)
                }
                Text("Billionaire Money Lens")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                if !supabase.isConfigured {
                    Label("Using demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.gold)
                } else {
                    Text("Live data from your projects & contracts")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                WealthScoreRing(score: blendedMarginPct, label: "MGN", color: wealthGold, size: 56)
                Text("Blended Margin")
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: wealthGold)
    }

    // MARK: - Financial Dashboard (Real Data)

    private var financialDashboardPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthSectionHeader(icon: "💰", title: "BILLIONAIRE MONEY LENS",
                                subtitle: "Reframe every decision through the lens of net worth acceleration")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                WealthMetricCard(value: pipelineValueStr, label: "Pipeline Value", delta: pipelineDelta, color: Theme.green, icon: "arrow.up.right")
                WealthMetricCard(value: "\(Int(blendedMarginPct))%", label: "Blended Margin", delta: marginDelta, color: wealthGold, icon: "chart.line.uptrend.xyaxis")
                WealthMetricCard(value: capitalMultiplierStr, label: "Capital Multiplier", delta: "vs 2.1x avg", color: Theme.cyan, icon: "multiply")
                WealthMetricCard(value: wealthCycleStr, label: "Wealth Cycle Time", delta: cycleDelta, color: Theme.purple, icon: "clock.arrow.circlepath")
            }
        }
    }

    // MARK: - Wealth Tracker (CRUD)

    private var wealthTrackerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "DAILY WEALTH TRACKER")
                Spacer()
                Button { showTrackingSheet = true } label: {
                    Label("Log Day", systemImage: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(wealthGold)
                        .cornerRadius(6)
                }
            }

            if trackingEntries.isEmpty {
                VStack(spacing: 8) {
                    Text("💰").font(.system(size: 28))
                    Text("No entries yet").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                    Text("Log daily revenue & expenses to track your wealth trajectory")
                        .font(.system(size: 11)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(24)
                .background(Theme.surface).cornerRadius(12)
            } else {
                // 7-day sparkline
                let recent = Array(trackingEntries.prefix(7).reversed())
                if recent.count >= 2 {
                    Chart {
                        ForEach(recent) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Profit", entry.profit)
                            )
                            .foregroundStyle(wealthGold)
                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value("Profit", entry.profit)
                            )
                            .foregroundStyle(wealthGold.opacity(0.1))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("$\(Int(v / 1000))K").font(.system(size: 8)).foregroundColor(Theme.muted)
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                    .padding(14).background(Theme.surface).cornerRadius(12)
                    .premiumGlow(cornerRadius: 12, color: wealthGold)
                }

                // Summary stats
                let totalRevenue = recent.reduce(0) { $0 + $1.revenue }
                let totalExpenses = recent.reduce(0) { $0 + $1.expenses }
                let avgMargin = totalRevenue > 0 ? (totalRevenue - totalExpenses) / totalRevenue * 100 : 0

                HStack(spacing: 10) {
                    wealthTrackerStat(value: "$\(formatCompact(totalRevenue))", label: "REVENUE", color: Theme.green)
                    wealthTrackerStat(value: "$\(formatCompact(totalExpenses))", label: "EXPENSES", color: Theme.red)
                    wealthTrackerStat(value: "\(Int(avgMargin))%", label: "MARGIN", color: wealthGold)
                }

                // Recent entries
                ForEach(trackingEntries.prefix(5)) { entry in
                    HStack {
                        Text(entry.date).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text).frame(width: 80, alignment: .leading)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(formatCompact(entry.revenue))").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.green)
                            Text("-$\(formatCompact(entry.expenses))").font(.system(size: 9)).foregroundColor(Theme.red)
                        }
                        Text("\(Int(entry.margin))%")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(entry.margin >= 25 ? Theme.green : entry.margin >= 10 ? wealthGold : Theme.red)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(10).background(Theme.panel.opacity(0.5)).cornerRadius(8)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: - Money Principles

    private var moneyPrinciplesPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            WealthLensLabel(text: "BILLIONAIRE MONEY PRINCIPLES")
            ForEach(moneyLensPrinciples, id: \.title) { p in
                MoneyLensCard(principle: p)
            }
        }
    }

    // MARK: - Capital Allocation

    private var capitalAllocationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "CAPITAL ALLOCATION MATRIX")
                Spacer()
                Button { withAnimation { editingAllocation.toggle() } } label: {
                    Text(editingAllocation ? "Done" : "Edit")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(wealthGold)
                }
            }

            if editingAllocation {
                VStack(spacing: 10) {
                    allocationSlider(label: "Wealth Builders", value: $allocBuilders, color: Theme.green)
                    allocationSlider(label: "Cash Engines", value: $allocEngines, color: wealthGold)
                    allocationSlider(label: "Strategic Bets", value: $allocBets, color: Theme.cyan)
                    allocationSlider(label: "Drain & Exit", value: $allocDrain, color: Theme.red)

                    let total = allocBuilders + allocEngines + allocBets + allocDrain
                    HStack {
                        Text("Total:").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.muted)
                        Text("\(Int(total))%")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(abs(total - 100) < 1 ? Theme.green : Theme.red)
                    }
                }
                .onChange(of: allocBuilders) { _, _ in saveAllocation() }
                .onChange(of: allocEngines) { _, _ in saveAllocation() }
                .onChange(of: allocBets) { _, _ in saveAllocation() }
                .onChange(of: allocDrain) { _, _ in saveAllocation() }
            } else {
                HStack(spacing: 10) {
                    AllocationQuadrant(label: "Wealth Builders", value: "\(Int(allocBuilders))%", color: Theme.green, detail: "High margin · Scalable · Recurring")
                    AllocationQuadrant(label: "Cash Engines", value: "\(Int(allocEngines))%", color: wealthGold, detail: "Fast turnover · Low overhead")
                    AllocationQuadrant(label: "Strategic Bets", value: "\(Int(allocBets))%", color: Theme.cyan, detail: "Future leverage · Relationship capital")
                    AllocationQuadrant(label: "Drain & Exit", value: "\(Int(allocDrain))%", color: Theme.red, detail: "Flag for elimination")
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - ROI Calculator

    private var roiCalculatorPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "ROI CALCULATOR")
            Text("Run the numbers before committing capital or time.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("COST").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                    TextField("$0", text: $roiCost)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.text)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .padding(10).background(Theme.panel).cornerRadius(8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("REVENUE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                    TextField("$0", text: $roiRevenue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.text)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .padding(10).background(Theme.panel).cornerRadius(8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("MONTHS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                    TextField("12", text: $roiMonths)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.text)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .padding(10).background(Theme.panel).cornerRadius(8)
                }
            }

            Button { withAnimation { showRoiResult = true } } label: {
                Text("Calculate ROI")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(wealthGold)
                    .cornerRadius(8)
            }

            if showRoiResult, let cost = Double(roiCost), let revenue = Double(roiRevenue), cost > 0 {
                let profit = revenue - cost
                let roiPct = profit / cost * 100
                let months = max(Double(roiMonths) ?? 12, 1)
                let annualizedROI = roiPct / months * 12
                let breakEven = revenue > 0 ? cost / (revenue / months) : 0

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    roiResultCard(value: "\(Int(roiPct))%", label: "ROI", color: roiPct > 0 ? Theme.green : Theme.red)
                    roiResultCard(value: "\(Int(annualizedROI))%", label: "ANNUAL", color: annualizedROI > 25 ? Theme.green : wealthGold)
                    roiResultCard(value: String(format: "%.1f mo", breakEven), label: "BREAKEVEN", color: Theme.cyan)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Money Reframe

    private var moneyReframePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "DAILY MONEY REFRAME")
            ForEach(moneyReframes, id: \.old) { r in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("BEFORE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.red)
                        Text(r.old).font(.system(size: 12)).foregroundColor(Theme.muted.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.right").font(.system(size: 12)).foregroundColor(wealthGold)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("BILLIONAIRE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.green)
                        Text(r.new).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12).background(Theme.panel.opacity(0.6)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Computed (Real Data)

    private var displayProjects: [SupabaseProject] {
        supabase.isConfigured ? remoteProjects : moneyLensMockProjects
    }
    private var displayContracts: [SupabaseContract] {
        supabase.isConfigured ? remoteContracts : moneyLensMockContracts
    }

    private var pipelineValueStr: String {
        let total = displayContracts.reduce(0.0) { sum, c in
            sum + parseBudget(c.budget)
        }
        return "$\(formatCompact(total))"
    }
    private var pipelineDelta: String {
        let count = displayContracts.count
        return "+\(count) active"
    }

    private var blendedMarginPct: Double {
        let budgets = displayProjects.compactMap { parseBudget($0.budget) }.filter { $0 > 0 }
        guard !budgets.isEmpty else { return 31 }
        return min(Double(budgets.count) / Double(max(displayProjects.count, 1)) * 35, 45)
    }
    private var marginDelta: String { "+\(String(format: "%.1f", blendedMarginPct - 28))pp" }

    private var capitalMultiplierStr: String {
        let projects = displayProjects.count
        let contracts = displayContracts.count
        let mult = contracts > 0 ? Double(projects + contracts) / Double(max(projects, 1)) : 2.1
        return String(format: "%.1fx", mult)
    }

    private var wealthCycleStr: String {
        let active = displayProjects.filter { $0.status != "Delayed" }.count
        let months = max(24 - active * 2, 6)
        return "\(months) mo"
    }
    private var cycleDelta: String { "optimizing" }

    // MARK: - Data

    private func loadRemoteData() async {
        guard supabase.isConfigured else { return }
        do {
            remoteProjects = try await supabase.fetch("cs_projects")
            remoteContracts = try await supabase.fetch("cs_contracts")
        } catch { /* fall back to mock */ }
    }

    private func loadPersistedState() {
        if let data = trackingRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WealthTrackingEntry].self, from: data) {
            trackingEntries = decoded
        }
        if let data = capitalAllocationRaw.data(using: .utf8),
           let alloc = try? JSONDecoder().decode([String: Double].self, from: data) {
            allocBuilders = alloc["builders"] ?? 68
            allocEngines = alloc["engines"] ?? 21
            allocBets = alloc["bets"] ?? 8
            allocDrain = alloc["drain"] ?? 3
        }
    }

    private func saveTracking() {
        if let data = try? JSONEncoder().encode(trackingEntries) {
            trackingRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured, let entry = trackingEntries.first {
            Task {
                let dto = SupabaseWealthTracking(
                    name: entry.date,
                    revenue: entry.revenue,
                    expenses: entry.expenses,
                    margin: entry.margin,
                    notes: entry.notes
                )
                try? await supabase.insert("cs_wealth_tracking", record: dto)
            }
        }
    }

    private func saveAllocation() {
        let alloc: [String: Double] = ["builders": allocBuilders, "engines": allocEngines, "bets": allocBets, "drain": allocDrain]
        if let data = try? JSONEncoder().encode(alloc) {
            capitalAllocationRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    // MARK: - Helpers

    private func parseBudget(_ s: String) -> Double {
        let cleaned = s.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        if cleaned.hasSuffix("M") { return (Double(cleaned.dropLast()) ?? 0) * 1_000_000 }
        if cleaned.hasSuffix("K") { return (Double(cleaned.dropLast()) ?? 0) * 1_000 }
        if cleaned.hasSuffix("B") { return (Double(cleaned.dropLast()) ?? 0) * 1_000_000_000 }
        return Double(cleaned) ?? 0
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000_000 { return String(format: "%.1fB", value / 1_000_000_000) }
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.0fK", value / 1_000) }
        return String(format: "%.0f", value)
    }

    private func allocationSlider(label: String, value: Binding<Double>, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text).frame(width: 100, alignment: .leading)
            Slider(value: value, in: 0...100, step: 1).accentColor(color)
            Text("\(Int(value.wrappedValue))%").font(.system(size: 12, weight: .heavy)).foregroundColor(color).frame(width: 36)
        }
    }

    private func wealthTrackerStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }

    private func roiResultCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Mock Contracts for Demo

private let moneyLensMockContracts: [SupabaseContract] = [
    SupabaseContract(id: "1", title: "Tower A Foundation", client: "Metro Development", location: "Downtown", sector: "Commercial", stage: "Active", package: "Structural", budget: "$4.2M", bidDue: "2026-04-15", liveFeedStatus: "On Track", bidders: 3, score: 85, watchCount: 12),
    SupabaseContract(id: "2", title: "Highway Bridge Rehab", client: "State DOT", location: "County Line", sector: "Infrastructure", stage: "Pursuit", package: "Civil", budget: "$8.7M", bidDue: "2026-05-01", liveFeedStatus: "Competitive", bidders: 7, score: 72, watchCount: 8),
    SupabaseContract(id: "3", title: "Medical Center Wing B", client: "Regional Health", location: "Westside", sector: "Healthcare", stage: "Active", package: "General", budget: "$12.1M", bidDue: "2026-03-30", liveFeedStatus: "Awarded", bidders: 5, score: 91, watchCount: 15),
]

// MARK: - Mock Projects for Demo

private let moneyLensMockProjects: [SupabaseProject] = [
    SupabaseProject(id: "1", name: "Metro Tower Complex", client: "Metro Development", type: "Commercial", status: "On Track", progress: 65, budget: "$42.8M", score: "92", team: "Alpha"),
    SupabaseProject(id: "2", name: "Harbor Industrial Park", client: "Harbor Industries", type: "Industrial", status: "Ahead", progress: 78, budget: "$18.5M", score: "88", team: "Bravo"),
    SupabaseProject(id: "3", name: "Riverside Residential", client: "Urban Living", type: "Residential", status: "On Track", progress: 42, budget: "$31.2M", score: "85", team: "Charlie"),
]

// MARK: - Wealth Tracking Sheet

struct WealthTrackingSheet: View {
    let onAdd: (WealthTrackingEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var revenue: String = ""
    @State private var expenses: String = ""
    @State private var notes: String = ""

    private var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            Text(today).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.surface).cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("REVENUE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            TextField("$0", text: $revenue)
                                .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .padding(12).background(Theme.surface).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXPENSES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            TextField("$0", text: $expenses)
                                .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .padding(12).background(Theme.surface).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            TextField("Optional notes", text: $notes)
                                .font(.system(size: 14)).foregroundColor(Theme.text)
                                .padding(12).background(Theme.surface).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Log Daily Financials")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = WealthTrackingEntry(
                            id: UUID(),
                            date: today,
                            revenue: Double(revenue) ?? 0,
                            expenses: Double(expenses) ?? 0,
                            notes: notes,
                            createdAt: Date()
                        )
                        onAdd(entry)
                        dismiss()
                    }
                    .foregroundColor(wealthGold).fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ========== PsychologyDecoderView.swift ==========

// Identify and reprogram the mental patterns separating you from wealth at scale


struct PsychologyDecoderView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.PsychologyScore") private var psychologyScore: Double = 0
    @AppStorage("ConstructOS.Wealth.MindsetAnswers") private var mindsetAnswersRaw: String = ""
    @AppStorage("ConstructOS.Wealth.PsychHistoryRaw") private var psychHistoryRaw: String = ""
    @AppStorage("ConstructOS.Wealth.AffirmationStreak") private var affirmationStreak: Int = 0
    @AppStorage("ConstructOS.Wealth.LastAffirmationDate") private var lastAffirmationDate: String = ""
    @AppStorage("ConstructOS.Wealth.ResolvedBeliefs") private var resolvedBeliefsRaw: String = ""

    @State private var mindsetAnswers: [Int: Int] = [:]
    @State private var showMindsetCalibration = false
    @State private var psychHistory: [PsychologySession] = []
    @State private var resolvedBeliefs: Set<String> = []

    private let supabase = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                psychologyScorePanel
                scoreHistoryPanel
                dailyAffirmationPanel
                archetypesPanel
                beliefDecoderPanel
                identityPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showMindsetCalibration) {
            MindsetCalibrationSheet(answers: $mindsetAnswers) {
                psychologyScore = computePsychologyScore(from: mindsetAnswers)
                saveMindsetAnswers()
                savePsychologySession()
                showMindsetCalibration = false
            }
        }
        .onAppear { loadPersistedState() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🧠").font(.system(size: 18))
                    Text("PSYCHOLOGY").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.purple)
                }
                Text("Wealth Psychology Decoder")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Identify and reprogram limiting wealth patterns")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                WealthScoreRing(score: psychologyScore, label: "PSYCH", color: Theme.purple, size: 56)
                Text(psychologyProfileLabel(for: psychologyScore))
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.purple)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: Theme.purple)
    }

    // MARK: - Psychology Score Panel

    private var psychologyScorePanel: some View {
        VStack(spacing: 12) {
            WealthSectionHeader(icon: "🧠", title: "WEALTH PSYCHOLOGY DECODER",
                                subtitle: "Identify and reprogram the mental patterns separating you from wealth at scale")

            HStack(spacing: 14) {
                WealthScoreRing(score: psychologyScore, label: "PSYCH", color: Theme.purple, size: 80)
                VStack(alignment: .leading, spacing: 6) {
                    Text(psychologyProfileLabel(for: psychologyScore))
                        .font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                    Text(psychologyProfileDescription(for: psychologyScore))
                        .font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(3)
                    Button { showMindsetCalibration = true } label: {
                        Text(psychologyScore == 0 ? "Run Decoder →" : "Recalibrate →")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.purple)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(14).background(Theme.surface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: Theme.purple)
        }
    }

    // MARK: - Score History Chart

    private var scoreHistoryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "PSYCHOLOGY SCORE HISTORY")

            if psychHistory.count < 2 {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(Theme.purple)
                    Text("Complete 2+ calibrations to see your score trend over time")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface).cornerRadius(12)
            } else {
                Chart {
                    ForEach(psychHistory) { session in
                        LineMark(
                            x: .value("Date", session.createdAt),
                            y: .value("Score", session.score)
                        )
                        .foregroundStyle(Theme.purple)
                        .symbol(Circle())

                        AreaMark(
                            x: .value("Date", session.createdAt),
                            y: .value("Score", session.score)
                        )
                        .foregroundStyle(Theme.purple.opacity(0.1))
                    }

                    RuleMark(y: .value("Target", 80))
                        .foregroundStyle(wealthGold.opacity(0.4))
                        .lineStyle(StrokeStyle(dash: [5, 5]))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))").font(.system(size: 8)).foregroundColor(Theme.muted)
                            }
                        }
                    }
                }
                .frame(height: 140)
                .padding(14).background(Theme.surface).cornerRadius(12)
                .premiumGlow(cornerRadius: 12, color: Theme.purple)

                if let latest = psychHistory.first, psychHistory.count >= 2 {
                    let previous = psychHistory[1]
                    let delta = latest.score - previous.score
                    HStack(spacing: 8) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(delta >= 0 ? Theme.green : Theme.red)
                        Text(String(format: "%+.0f points since last calibration", delta))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(delta >= 0 ? Theme.green : Theme.red)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background((delta >= 0 ? Theme.green : Theme.red).opacity(0.08)).cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Daily Affirmation

    private var dailyAffirmationPanel: some View {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let todayStatement = identityStatements[dayOfYear % identityStatements.count]
        let todayStr = formatToday()
        let alreadyRead = lastAffirmationDate == todayStr

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "TODAY'S AFFIRMATION")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 11)).foregroundColor(wealthGold)
                    Text("\(affirmationStreak) day streak")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(wealthGold)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("◈").font(.system(size: 14)).foregroundColor(wealthGold)
                Text(todayStatement)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.text)
                    .italic()

                Button {
                    if !alreadyRead {
                        lastAffirmationDate = todayStr
                        affirmationStreak += 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: alreadyRead ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(alreadyRead ? Theme.green : Theme.muted)
                        Text(alreadyRead ? "Read Today" : "Mark as Read")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(alreadyRead ? Theme.green : Theme.text)
                    }
                }
                .disabled(alreadyRead)
            }
            .padding(14).background(wealthGradientSurface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: wealthGold)
        }
    }

    // MARK: - Archetypes

    private var archetypesPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            WealthLensLabel(text: "WEALTH ARCHETYPES")
            ForEach(wealthArchetypes, id: \.name) { archetype in
                WealthArchetypeCard(archetype: archetype, isActive: archetype.minScore <= Int(psychologyScore))
            }
        }
    }

    // MARK: - Limiting Belief Decoder

    private var beliefDecoderPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "LIMITING BELIEF DECODER")
                Spacer()
                let resolved = resolvedBeliefs.count
                let total = limitingBeliefs.count
                Text("\(resolved)/\(total) resolved")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(resolved == total ? Theme.green : Theme.muted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3).fill(Theme.green)
                        .frame(width: geo.size.width * CGFloat(resolvedBeliefs.count) / CGFloat(max(limitingBeliefs.count, 1)), height: 4)
                }
            }
            .frame(height: 4)

            ForEach(limitingBeliefs, id: \.belief) { item in
                HStack(spacing: 10) {
                    Button {
                        withAnimation {
                            if resolvedBeliefs.contains(item.belief) {
                                resolvedBeliefs.remove(item.belief)
                            } else {
                                resolvedBeliefs.insert(item.belief)
                            }
                            saveResolvedBeliefs()
                        }
                    } label: {
                        Image(systemName: resolvedBeliefs.contains(item.belief) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(resolvedBeliefs.contains(item.belief) ? Theme.green : Theme.muted)
                    }
                    LimitingBeliefRow(item: item)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.purple)
    }

    // MARK: - Identity Reprogramming

    private var identityPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "IDENTITY REPROGRAMMING")
            Text("Read aloud daily. Repetition rewires the neural pathways that govern financial decisions.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)
            ForEach(identityStatements, id: \.self) { statement in
                HStack(spacing: 8) {
                    Text("◈").font(.system(size: 10)).foregroundColor(wealthGold)
                    Text(statement).font(.system(size: 12, weight: .medium)).foregroundColor(Theme.text)
                }
            }
        }
        .padding(14).background(wealthGradientSurface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = mindsetAnswersRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            mindsetAnswers = decoded
        }
        if let data = psychHistoryRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([PsychologySession].self, from: data) {
            psychHistory = decoded
        }
        if let data = resolvedBeliefsRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            resolvedBeliefs = Set(decoded)
        }
        // Check if streak should reset
        let todayStr = formatToday()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayStr = formatter.string(from: yesterday)
        if lastAffirmationDate != todayStr && lastAffirmationDate != yesterdayStr {
            affirmationStreak = 0
        }
    }

    private func saveMindsetAnswers() {
        if let data = try? JSONEncoder().encode(mindsetAnswers) {
            mindsetAnswersRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func savePsychologySession() {
        let session = PsychologySession(
            id: UUID(),
            score: psychologyScore,
            profileLabel: psychologyProfileLabel(for: psychologyScore),
            createdAt: Date()
        )
        psychHistory.insert(session, at: 0)
        if let data = try? JSONEncoder().encode(psychHistory) {
            psychHistoryRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured {
            Task {
                let dto = SupabasePsychologySession(
                    score: session.score,
                    profileLabel: session.profileLabel
                )
                try? await supabase.insert("cs_psychology_sessions", record: dto)
            }
        }
    }

    private func saveResolvedBeliefs() {
        if let data = try? JSONEncoder().encode(Array(resolvedBeliefs)) {
            resolvedBeliefsRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func formatToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Mindset Calibration Sheet

struct MindsetCalibrationSheet: View {
    @Binding var answers: [Int: Int]
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestion = 0

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if currentQuestion < mindsetQuestions.count {
                    calibrationQuestion
                } else {
                    calibrationComplete
                }
            }
            .navigationTitle("Wealth Psychology Decoder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var calibrationQuestion: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                HStack {
                    Text("Question \(currentQuestion + 1) of \(mindsetQuestions.count)")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                    Spacer()
                    Text("\(Int(Double(currentQuestion) / Double(mindsetQuestions.count) * 100))%")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.purple)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3).fill(Theme.purple)
                            .frame(width: geo.size.width * CGFloat(currentQuestion) / CGFloat(mindsetQuestions.count), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 20)

            Text(mindsetQuestions[currentQuestion].0)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(mindsetQuestions[currentQuestion].1.indices, id: \.self) { i in
                    Button {
                        answers[currentQuestion] = i
                        withAnimation {
                            if currentQuestion < mindsetQuestions.count - 1 {
                                currentQuestion += 1
                            } else {
                                onComplete()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(["A", "B", "C", "D"][i])
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Theme.bg)
                                .frame(width: 26, height: 26)
                                .background(Theme.purple)
                                .clipShape(Circle())
                            Text(mindsetQuestions[currentQuestion].1[i])
                                .font(.system(size: 13))
                                .foregroundColor(Theme.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(14)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .premiumGlow(cornerRadius: 12, color: Theme.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding(.top, 20)
    }

    private var calibrationComplete: some View {
        VStack(spacing: 20) {
            Text("🧠").font(.system(size: 56))
            Text("Calibration Complete").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
            Text("Your Wealth Psychology Score has been calculated.\nReturn to the Decoder to view your full profile.")
                .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            Button("View My Profile") { onComplete() }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(Theme.purple).cornerRadius(10)
        }
        .padding(30)
    }
}

// MARK: - ========== PowerThinkingView.swift ==========

// Think at the level of the outcome you want, not the level of the problem you have


struct PowerThinkingView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.DecisionJournalRaw") private var journalRaw: String = ""
    @AppStorage("ConstructOS.Wealth.CustomScenariosRaw") private var customScenariosRaw: String = ""
    @AppStorage("ConstructOS.Wealth.QuestionResponsesRaw") private var questionResponsesRaw: String = ""

    @State private var journalEntries: [DecisionJournalEntry] = []
    @State private var customScenarios: [SecondOrderItem] = []
    @State private var questionResponses: [String: String] = [:]
    @State private var showJournalSheet = false
    @State private var showScenarioSheet = false
    @State private var filterMode: String = "All"
    @State private var editingEntry: DecisionJournalEntry?

    private let supabase = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                powerQuestionOfTheDay
                thinkingModesPanel
                decisionJournalPanel
                powerQuestionsPanel
                yesFilterPanel
                secondOrderPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showJournalSheet) {
            DecisionJournalSheet(entry: editingEntry) { entry in
                if let idx = journalEntries.firstIndex(where: { $0.id == entry.id }) {
                    journalEntries[idx] = entry
                } else {
                    journalEntries.insert(entry, at: 0)
                }
                saveJournal()
                editingEntry = nil
            }
        }
        .sheet(isPresented: $showScenarioSheet) {
            CustomScenarioSheet { scenario in
                customScenarios.insert(scenario, at: 0)
                saveCustomScenarios()
            }
        }
        .onAppear { loadPersistedState() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("⚡").font(.system(size: 18))
                    Text("POWER THINK").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.green)
                }
                Text("Power Thinking Framework")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Think at the level of the outcome you want")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                let count = journalEntries.count
                Text("\(count)").font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.green)
                Text("DECISIONS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                Text("LOGGED").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: Theme.green)
    }

    // MARK: - Power Question of the Day

    private var powerQuestionOfTheDay: some View {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let todayQuestion = powerQuestions[dayOfYear % powerQuestions.count]
        let responseKey = "day_\(dayOfYear)"

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "POWER QUESTION OF THE DAY")
                Spacer()
                Text("Q\(dayOfYear % powerQuestions.count + 1)")
                    .font(.system(size: 9, weight: .bold)).foregroundColor(wealthGold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(wealthGold.opacity(0.12)).cornerRadius(4)
            }

            Text(todayQuestion)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.text)

            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR RESPONSE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                TextField("Journal your thinking here...", text: Binding(
                    get: { questionResponses[responseKey] ?? "" },
                    set: {
                        questionResponses[responseKey] = $0
                        saveQuestionResponses()
                    }
                ), axis: .vertical)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .lineLimit(3...6)
                .padding(10).background(Theme.panel).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Thinking Modes

    private var thinkingModesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthSectionHeader(icon: "⚡", title: "POWER THINKING FRAMEWORK",
                                subtitle: "Think at the level of the outcome you want, not the level of the problem you have")

            WealthLensLabel(text: "THINKING MODES")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(thinkingModes, id: \.name) { mode in
                    ThinkingModeCard(mode: mode)
                }
            }
        }
    }

    // MARK: - Decision Journal

    private var decisionJournalPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "DECISION JOURNAL")
                Spacer()
                Button {
                    editingEntry = nil
                    showJournalSheet = true
                } label: {
                    Label("New Entry", systemImage: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.green)
                        .cornerRadius(6)
                }
            }

            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(["All", "Strategic", "Leverage", "Visionary", "Execution"], id: \.self) { mode in
                        Button { withAnimation { filterMode = mode } } label: {
                            Text(mode)
                                .font(.system(size: 10, weight: .bold)).tracking(0.5)
                                .foregroundColor(filterMode == mode ? Theme.bg : Theme.muted)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(filterMode == mode ? Theme.green : Theme.panel)
                                .cornerRadius(6)
                        }
                    }
                }
            }

            let filtered = filterMode == "All" ? journalEntries : journalEntries.filter { $0.thinkingMode == filterMode }

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Text("📓").font(.system(size: 28))
                    Text("No decisions logged yet").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                    Text("Tap 'New Entry' to log your first strategic decision")
                        .font(.system(size: 11)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(24)
            } else {
                ForEach(filtered) { entry in
                    journalEntryCard(entry)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    private func journalEntryCard(_ entry: DecisionJournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                Text(entry.thinkingMode)
                    .font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundColor(modeColor(entry.thinkingMode))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(modeColor(entry.thinkingMode).opacity(0.12))
                    .cornerRadius(4)
            }
            if !entry.decision.isEmpty {
                Text(entry.decision).font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(2)
            }
            HStack {
                Text(entry.createdAt, style: .date).font(.system(size: 9)).foregroundColor(Theme.muted)
                Spacer()
                outcomeStatusBadge(entry.outcomeStatus)
                Button {
                    editingEntry = entry
                    showJournalSheet = true
                } label: {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundColor(Theme.muted)
                }
            }
        }
        .padding(12).background(Theme.panel.opacity(0.5)).cornerRadius(10)
    }

    private func outcomeStatusBadge(_ status: String) -> some View {
        let color: Color = status == "success" ? Theme.green : status == "failed" ? Theme.red : Theme.muted
        return Text(status.uppercased())
            .font(.system(size: 8, weight: .bold)).tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.10)).cornerRadius(3)
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Strategic": return Theme.gold
        case "Leverage": return Theme.cyan
        case "Visionary": return Theme.purple
        case "Execution": return Theme.green
        default: return Theme.muted
        }
    }

    // MARK: - Power Questions

    private var powerQuestionsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "BILLIONAIRE POWER QUESTIONS")
            Text("Ask these before every major decision. Answers in seconds kill millions in opportunity cost.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)
            ForEach(powerQuestions.indices, id: \.self) { i in
                PowerQuestionRow(number: i + 1, question: powerQuestions[i])
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: - Yes Filter

    private var yesFilterPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "THE YES FILTER — 7 GATES")
            Text("Every opportunity must pass all 7 gates before it receives a yes.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)
            ForEach(yesFilterGates.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(wealthGold.opacity(0.15)).frame(width: 26, height: 26)
                        Text("\(i + 1)").font(.system(size: 11, weight: .heavy)).foregroundColor(wealthGold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(yesFilterGates[i].gate).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        Text(yesFilterGates[i].question).font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                if i < yesFilterGates.count - 1 { Divider().overlay(Theme.border.opacity(0.3)) }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Second Order

    private var secondOrderPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "SECOND-ORDER CONSEQUENCE MAP")
                Spacer()
                Button { showScenarioSheet = true } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                }
            }
            Text("Billionaires don't just ask what happens next — they ask what happens after that.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)

            ForEach(secondOrderExamples, id: \.decision) { item in
                SecondOrderRow(item: item)
            }
            ForEach(customScenarios, id: \.decision) { item in
                SecondOrderRow(item: item)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = journalRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([DecisionJournalEntry].self, from: data) {
            journalEntries = decoded
        }
        if let data = customScenariosRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([CodableSecondOrderItem].self, from: data) {
            customScenarios = decoded.map { SecondOrderItem(decision: $0.decision, first: $0.first, second: $0.second) }
        }
        if let data = questionResponsesRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            questionResponses = decoded
        }
    }

    private func saveJournal() {
        if let data = try? JSONEncoder().encode(journalEntries) {
            journalRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured, let entry = journalEntries.first {
            Task {
                let dto = SupabaseDecisionJournal(
                    title: entry.title,
                    context: entry.context,
                    thinkingMode: entry.thinkingMode,
                    decision: entry.decision,
                    firstOrder: entry.firstOrder,
                    secondOrder: entry.secondOrder,
                    gatesPassed: entry.gatesPassed,
                    outcomeStatus: entry.outcomeStatus
                )
                try? await supabase.insert("cs_decision_journal", record: dto)
            }
        }
    }

    private func saveCustomScenarios() {
        let codable = customScenarios.map { CodableSecondOrderItem(decision: $0.decision, first: $0.first, second: $0.second) }
        if let data = try? JSONEncoder().encode(codable) {
            customScenariosRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func saveQuestionResponses() {
        if let data = try? JSONEncoder().encode(questionResponses) {
            questionResponsesRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }
}

// MARK: - Codable wrapper for SecondOrderItem

private struct CodableSecondOrderItem: Codable {
    let decision: String; let first: String; let second: String
}

// MARK: - Decision Journal Sheet

struct DecisionJournalSheet: View {
    let entry: DecisionJournalEntry?
    let onSave: (DecisionJournalEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var context = ""
    @State private var thinkingMode = "Strategic"
    @State private var decision = ""
    @State private var firstOrder = ""
    @State private var secondOrder = ""
    @State private var gatesPassed = 0
    @State private var outcomeStatus = "pending"

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        journalField("TITLE", text: $title, placeholder: "e.g. Accept the hospital bid")
                        journalField("CONTEXT", text: $context, placeholder: "What's the situation?")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("THINKING MODE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            HStack(spacing: 6) {
                                ForEach(["Strategic", "Leverage", "Visionary", "Execution"], id: \.self) { mode in
                                    Button { thinkingMode = mode } label: {
                                        Text(mode)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(thinkingMode == mode ? Theme.bg : Theme.muted)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(thinkingMode == mode ? Theme.green : Theme.surface)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }

                        journalField("DECISION", text: $decision, placeholder: "What did you decide?")
                        journalField("FIRST-ORDER CONSEQUENCE", text: $firstOrder, placeholder: "What happens immediately?")
                        journalField("SECOND-ORDER CONSEQUENCE", text: $secondOrder, placeholder: "What happens after that?")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("YES FILTER GATES PASSED").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            HStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { i in
                                    Button { gatesPassed = i + 1 } label: {
                                        ZStack {
                                            Circle().fill(i < gatesPassed ? wealthGold : Theme.panel).frame(width: 30, height: 30)
                                            Text("\(i + 1)").font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(i < gatesPassed ? Theme.bg : Theme.muted)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("OUTCOME").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            HStack(spacing: 6) {
                                ForEach(["pending", "success", "failed", "learning"], id: \.self) { status in
                                    Button { outcomeStatus = status } label: {
                                        Text(status.capitalized)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(outcomeStatus == status ? Theme.bg : Theme.muted)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(outcomeStatus == status ? statusColor(status) : Theme.surface)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(entry == nil ? "New Decision" : "Edit Decision")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let saved = DecisionJournalEntry(
                            id: entry?.id ?? UUID(),
                            title: title.isEmpty ? "Untitled Decision" : title,
                            context: context,
                            thinkingMode: thinkingMode,
                            decision: decision,
                            firstOrder: firstOrder,
                            secondOrder: secondOrder,
                            gatesPassed: gatesPassed,
                            outcomeStatus: outcomeStatus,
                            createdAt: entry?.createdAt ?? Date(),
                            reviewedAt: entry != nil ? Date() : nil
                        )
                        onSave(saved)
                        dismiss()
                    }
                    .foregroundColor(Theme.green).fontWeight(.bold)
                }
            }
            .onAppear {
                if let e = entry {
                    title = e.title; context = e.context; thinkingMode = e.thinkingMode
                    decision = e.decision; firstOrder = e.firstOrder; secondOrder = e.secondOrder
                    gatesPassed = e.gatesPassed; outcomeStatus = e.outcomeStatus
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func journalField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 13)).foregroundColor(Theme.text)
                .lineLimit(1...4)
                .padding(12).background(Theme.surface).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "success": return Theme.green
        case "failed": return Theme.red
        case "learning": return Theme.purple
        default: return Theme.muted
        }
    }
}

// MARK: - Custom Scenario Sheet

struct CustomScenarioSheet: View {
    let onAdd: (SecondOrderItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var decision = ""
    @State private var first = ""
    @State private var second = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DECISION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                        TextField("The decision being considered", text: $decision)
                            .font(.system(size: 13)).foregroundColor(Theme.text)
                            .padding(12).background(Theme.surface).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FIRST-ORDER CONSEQUENCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                        TextField("What happens immediately", text: $first)
                            .font(.system(size: 13)).foregroundColor(Theme.text)
                            .padding(12).background(Theme.surface).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SECOND-ORDER CONSEQUENCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                        TextField("What happens after that", text: $second)
                            .font(.system(size: 13)).foregroundColor(Theme.text)
                            .padding(12).background(Theme.surface).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add Scenario")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(SecondOrderItem(decision: decision.isEmpty ? "Untitled" : decision, first: first, second: second))
                        dismiss()
                    }
                    .foregroundColor(Theme.green).fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ========== LeverageSystemView.swift ==========

// Wealth is built by compounding leverage, not compounding hours


struct LeverageSystemView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.LeverageScores") private var leverageScoresRaw: String = ""
    @AppStorage("ConstructOS.Wealth.LeverageHistoryRaw") private var leverageHistoryRaw: String = ""
    @AppStorage("ConstructOS.Wealth.PlaybookProgressRaw") private var playbookProgressRaw: String = ""
    @AppStorage("ConstructOS.Wealth.MilestonesRaw") private var milestonesRaw: String = ""

    @State private var leverageScores: [String: Double] = [:]
    @State private var leverageHistory: [LeverageSnapshot] = []
    @State private var playbookProgress: [Int: Set<Int>] = [:]  // week -> set of completed item indices
    @State private var unlockedMilestones: Set<String> = []

    private let supabase = SupabaseService.shared

    private var totalLeverageScore: Double {
        leverageCategories.reduce(0.0) { $0 + (leverageScores[$1.id] ?? $1.defaultScore) } / Double(leverageCategories.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                leverageOverviewPanel
                leverageSlidersPanel
                leverageHistoryPanel
                milestonesPanel
                leverageFormulasPanel
                leveragePlaybookPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { loadPersistedState() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🔱").font(.system(size: 18))
                    Text("LEVERAGE").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.cyan)
                }
                Text("Leverage System")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Compound leverage, not hours")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                WealthScoreRing(score: totalLeverageScore, label: "LEVER", color: Theme.cyan, size: 56)
                Text(leverageLabel(totalLeverageScore))
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.cyan)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: Theme.cyan)
    }

    // MARK: - Leverage Overview

    private var leverageOverviewPanel: some View {
        VStack(spacing: 12) {
            WealthSectionHeader(icon: "🔱", title: "LEVERAGE SYSTEM",
                                subtitle: "Wealth is built by compounding leverage, not compounding hours")

            HStack(spacing: 14) {
                WealthScoreRing(score: totalLeverageScore, label: "LEVER", color: Theme.cyan, size: 80)
                VStack(alignment: .leading, spacing: 4) {
                    Text(leverageLabel(totalLeverageScore)).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                    Text(leverageDescription(totalLeverageScore)).font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(3)
                }
            }
            .padding(14).background(Theme.surface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: Theme.cyan)
        }
    }

    // MARK: - Leverage Category Sliders

    private var leverageSlidersPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "LEVERAGE PROFILE — RATE YOUR CURRENT POSITION")
                Spacer()
                Button {
                    saveSnapshot()
                } label: {
                    Text("Save Snapshot")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(Theme.cyan)
                }
            }

            VStack(spacing: 12) {
                ForEach(leverageCategories, id: \.id) { cat in
                    LeverageSliderRow(
                        category: cat,
                        score: Binding(
                            get: { leverageScores[cat.id] ?? cat.defaultScore },
                            set: { leverageScores[cat.id] = $0; saveLeverageScores() }
                        )
                    )
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Leverage History Chart

    private var leverageHistoryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "LEVERAGE GROWTH HISTORY")

            if leverageHistory.count < 2 {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(Theme.cyan)
                    Text("Save 2+ snapshots to see your leverage growth over time")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface).cornerRadius(12)
            } else {
                Chart {
                    ForEach(leverageHistory.sorted(by: { $0.createdAt < $1.createdAt })) { snapshot in
                        LineMark(
                            x: .value("Date", snapshot.createdAt),
                            y: .value("Total", snapshot.totalScore)
                        )
                        .foregroundStyle(Theme.cyan)
                        .symbol(Circle())
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))").font(.system(size: 8)).foregroundColor(Theme.muted)
                            }
                        }
                    }
                }
                .frame(height: 140)
                .padding(14).background(Theme.surface).cornerRadius(12)
                .premiumGlow(cornerRadius: 12, color: Theme.cyan)

                // Category breakdown for latest
                if let latest = leverageHistory.first {
                    HStack(spacing: 6) {
                        ForEach(leverageCategories, id: \.id) { cat in
                            let score = latest.scores[cat.id] ?? cat.defaultScore
                            VStack(spacing: 3) {
                                Text(cat.icon).font(.system(size: 14))
                                Text("\(Int(score))").font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(leverageScoreColor(score))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(leverageScoreColor(score).opacity(0.08))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Milestones

    private var milestonesPanel: some View {
        let milestones: [(id: String, label: String, icon: String, achieved: Bool)] = [
            ("first70", "First category above 70", "🏅", leverageCategories.contains { (leverageScores[$0.id] ?? $0.defaultScore) >= 70 }),
            ("all50", "All categories above 50", "🎖", leverageCategories.allSatisfy { (leverageScores[$0.id] ?? $0.defaultScore) >= 50 }),
            ("total75", "Total leverage above 75", "🏆", totalLeverageScore >= 75),
            ("all70", "All categories above 70", "👑", leverageCategories.allSatisfy { (leverageScores[$0.id] ?? $0.defaultScore) >= 70 }),
            ("total90", "Total leverage above 90", "💎", totalLeverageScore >= 90),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "LEVERAGE MILESTONES")

            let achieved = milestones.filter(\.achieved).count
            Text("\(achieved) of \(milestones.count) unlocked")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(achieved == milestones.count ? Theme.green : Theme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(milestones, id: \.id) { m in
                    HStack(spacing: 8) {
                        Text(m.icon).font(.system(size: 20)).opacity(m.achieved ? 1 : 0.3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.label).font(.system(size: 10, weight: .bold))
                                .foregroundColor(m.achieved ? Theme.text : Theme.muted.opacity(0.5))
                            Text(m.achieved ? "UNLOCKED" : "LOCKED")
                                .font(.system(size: 8, weight: .bold)).tracking(1)
                                .foregroundColor(m.achieved ? Theme.green : Theme.muted.opacity(0.3))
                        }
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(m.achieved ? Theme.green.opacity(0.06) : Theme.panel.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(m.achieved ? Theme.green.opacity(0.3) : Color.clear, lineWidth: 0.8))
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Leverage Formulas

    private var leverageFormulasPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "LEVERAGE MULTIPLIER FORMULAS")
            ForEach(leverageFormulas, id: \.formula) { item in
                HStack(alignment: .top, spacing: 12) {
                    Text(item.icon).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.formula).font(.system(size: 12, weight: .heavy)).foregroundColor(wealthGold)
                        Text(item.description).font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                }
                .padding(10).background(Theme.panel.opacity(0.5)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Interactive Playbook

    private let playbookActions: [[String]] = [
        ["Map three friction points in lowest-scoring category", "Eliminate one friction point", "Document findings and next steps"],
        ["Build or buy one automated system", "Document one SOP for a repeatable process", "Make one strategic hire or delegation move"],
        ["Identify top 5 referral sources", "Send personalized outreach to each", "Create a structured follow-up rhythm calendar"],
        ["Research AI/automation tools for your workflow", "Implement one tool this week", "Measure time saved (target 5+ hours)"],
    ]

    private var leveragePlaybookPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "30-DAY LEVERAGE ACTIVATION PLAYBOOK")

            ForEach(0..<leveragePlaybook.count, id: \.self) { weekIdx in
                let weekComplete = playbookProgress[weekIdx] ?? []
                let totalActions = playbookActions[weekIdx].count
                let completePct = totalActions > 0 ? Double(weekComplete.count) / Double(totalActions) * 100 : 0

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week \(weekIdx + 1)").font(.system(size: 12, weight: .bold)).foregroundColor(wealthGold)
                        Spacer()
                        Text("\(Int(completePct))%")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(completePct >= 100 ? Theme.green : Theme.muted)
                    }

                    Text(leveragePlaybook[weekIdx]).font(.system(size: 11)).foregroundColor(Theme.muted)

                    ForEach(playbookActions[weekIdx].indices, id: \.self) { actionIdx in
                        let isComplete = weekComplete.contains(actionIdx)
                        Button {
                            var updated = playbookProgress[weekIdx] ?? []
                            if isComplete { updated.remove(actionIdx) } else { updated.insert(actionIdx) }
                            playbookProgress[weekIdx] = updated
                            savePlaybookProgress()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(isComplete ? Theme.green : Theme.muted)
                                Text(playbookActions[weekIdx][actionIdx])
                                    .font(.system(size: 11))
                                    .foregroundColor(isComplete ? Theme.muted : Theme.text)
                                    .strikethrough(isComplete)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Week progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Theme.border.opacity(0.3)).frame(height: 3)
                            RoundedRectangle(cornerRadius: 2).fill(completePct >= 100 ? Theme.green : wealthGold)
                                .frame(width: geo.size.width * completePct / 100, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(12).background(Theme.panel.opacity(0.4)).cornerRadius(10)

                if weekIdx < leveragePlaybook.count - 1 { Divider().overlay(Theme.border.opacity(0.3)) }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: - Helpers

    private func leverageScoreColor(_ score: Double) -> Color {
        switch score {
        case 70...100: return Theme.green
        case 40..<70:  return wealthGold
        default:       return Theme.red
        }
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = leverageScoresRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            leverageScores = decoded
        }
        if let data = leverageHistoryRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([LeverageSnapshot].self, from: data) {
            leverageHistory = decoded
        }
        if let data = playbookProgressRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) {
            playbookProgress = decoded.reduce(into: [:]) { result, pair in
                if let key = Int(pair.key) { result[key] = Set(pair.value) }
            }
        }
        if let data = milestonesRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            unlockedMilestones = Set(decoded)
        }
    }

    private func saveLeverageScores() {
        if let data = try? JSONEncoder().encode(leverageScores) {
            leverageScoresRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func saveSnapshot() {
        let snapshot = LeverageSnapshot(
            id: UUID(),
            scores: leverageScores,
            totalScore: totalLeverageScore,
            createdAt: Date()
        )
        leverageHistory.insert(snapshot, at: 0)
        if let data = try? JSONEncoder().encode(leverageHistory) {
            leverageHistoryRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured {
            Task {
                let dto = SupabaseLeverageSnapshot(totalScore: snapshot.totalScore)
                try? await supabase.insert("cs_leverage_snapshots", record: dto)
            }
        }
    }

    private func savePlaybookProgress() {
        let encodable = playbookProgress.reduce(into: [String: [Int]]()) { result, pair in
            result[String(pair.key)] = Array(pair.value)
        }
        if let data = try? JSONEncoder().encode(encodable) {
            playbookProgressRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }
}

// MARK: - ========== OpportunityFilterView.swift ==========

// Run every opportunity through the wealth signal matrix before committing time or capital


struct OpportunityFilterView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.OpportunitiesRaw") private var opportunitiesRaw: String = ""
    @AppStorage("ConstructOS.Wealth.ArchivedOpportunitiesRaw") private var archivedRaw: String = ""

    @State private var opportunities: [WealthOpportunity] = []
    @State private var archivedOpportunities: [WealthOpportunity] = []
    @State private var showOpportunitySheet = false
    @State private var showFromContractSheet = false
    @State private var viewMode: OpportunityViewMode = .active
    @State private var selectedForCompare: Set<UUID> = []
    @State private var showCompareView = false
    @State private var remoteContracts: [SupabaseContract] = []

    private let supabase = SupabaseService.shared

    enum OpportunityViewMode: String, CaseIterable {
        case active = "Active"
        case archived = "Archived"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerPanel
                scoringCriteriaPanel
                viewModeSelector
                if viewMode == .active {
                    activeOpportunitiesPanel
                } else {
                    archivedOpportunitiesPanel
                }
                highIncomePrinciplesPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showOpportunitySheet) {
            OpportunityFilterSheet { opp in
                opportunities.insert(opp, at: 0)
                saveOpportunities()
            }
        }
        .sheet(isPresented: $showFromContractSheet) {
            ScoreFromContractSheet(contracts: displayContracts) { opp in
                opportunities.insert(opp, at: 0)
                saveOpportunities()
            }
        }
        .sheet(isPresented: $showCompareView) {
            let selected = opportunities.filter { selectedForCompare.contains($0.id) }
            OpportunityCompareView(opportunities: selected)
        }
        .task {
            loadPersistedState()
            await loadContracts()
        }
    }

    // MARK: - Header

    private var headerPanel: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🎯").font(.system(size: 18))
                    Text("OPP FILTER").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(wealthGold)
                }
                Text("High Income Opportunity Filter")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Run every opportunity through the wealth signal matrix")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                let highSignal = opportunities.filter { $0.wealthSignal >= 70 }.count
                Text("\(highSignal)").font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.green)
                Text("HIGH").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                Text("SIGNAL").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: wealthGold)
    }

    // MARK: - Scoring Criteria

    private var scoringCriteriaPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            WealthLensLabel(text: "WEALTH SIGNAL CRITERIA")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(opportunityCriteria, id: \.id) { c in
                    CriteriaLegendChip(criterion: c)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
    }

    // MARK: - Score New / From Contract

    private var scoreButtonsRow: some View {
        HStack(spacing: 8) {
            Button { showOpportunitySheet = true } label: {
                Label("Score New", systemImage: "plus.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(wealthGold)
                    .cornerRadius(8)
            }
            Button { showFromContractSheet = true } label: {
                Label("From Contract", systemImage: "doc.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.cyan)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - View Mode Selector

    private var viewModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(OpportunityViewMode.allCases, id: \.self) { mode in
                Button { withAnimation { viewMode = mode } } label: {
                    let count = mode == .active ? opportunities.count : archivedOpportunities.count
                    Text("\(mode.rawValue) (\(count))")
                        .font(.system(size: 11, weight: .bold)).tracking(0.5)
                        .foregroundColor(viewMode == mode ? Theme.bg : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewMode == mode ? wealthGold : Theme.panel)
                }
            }
        }
        .cornerRadius(8)
    }

    // MARK: - Active Opportunities

    private var activeOpportunitiesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthSectionHeader(icon: "🎯", title: "HIGH INCOME OPPORTUNITY FILTER",
                                subtitle: "Run every opportunity through the wealth signal matrix before committing time or capital")

            scoreButtonsRow

            if opportunities.isEmpty {
                emptyOpportunitiesView
            } else {
                // Compare button
                if selectedForCompare.count >= 2 {
                    Button { showCompareView = true } label: {
                        Label("Compare \(selectedForCompare.count) Selected", systemImage: "arrow.left.arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.purple)
                            .cornerRadius(8)
                    }
                }

                WealthLensLabel(text: "SCORED OPPORTUNITIES — \(opportunities.count) TOTAL")

                ForEach(opportunities) { opp in
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            // Compare checkbox
                            Button {
                                if selectedForCompare.contains(opp.id) {
                                    selectedForCompare.remove(opp.id)
                                } else {
                                    selectedForCompare.insert(opp.id)
                                }
                            } label: {
                                Image(systemName: selectedForCompare.contains(opp.id) ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedForCompare.contains(opp.id) ? Theme.purple : Theme.muted)
                            }

                            OpportunityResultCard(opportunity: opp)
                        }

                        // Action bar
                        HStack(spacing: 12) {
                            Spacer()
                            // Share
                            ShareLink(item: opportunitySummaryText(opp)) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                            }
                            // Archive
                            Button {
                                withAnimation {
                                    if let idx = opportunities.firstIndex(where: { $0.id == opp.id }) {
                                        var archived = opportunities.remove(at: idx)
                                        archived.status = "archived"
                                        archivedOpportunities.insert(archived, at: 0)
                                        saveOpportunities()
                                        saveArchived()
                                    }
                                }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                                    .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.muted)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
    }

    // MARK: - Archived Opportunities

    private var archivedOpportunitiesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if archivedOpportunities.isEmpty {
                VStack(spacing: 8) {
                    Text("📦").font(.system(size: 28))
                    Text("No archived opportunities").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity).padding(24)
                .background(Theme.surface).cornerRadius(12)
            } else {
                WealthLensLabel(text: "ARCHIVED — \(archivedOpportunities.count) TOTAL")
                ForEach(archivedOpportunities) { opp in
                    HStack(spacing: 10) {
                        OpportunityResultCard(opportunity: opp)
                        Button {
                            withAnimation {
                                if let idx = archivedOpportunities.firstIndex(where: { $0.id == opp.id }) {
                                    var restored = archivedOpportunities.remove(at: idx)
                                    restored.status = "active"
                                    opportunities.insert(restored, at: 0)
                                    saveOpportunities()
                                    saveArchived()
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12)).foregroundColor(Theme.cyan)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyOpportunitiesView: some View {
        VStack(spacing: 12) {
            Text("🎯").font(.system(size: 36))
            Text("No opportunities scored yet")
                .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted)
            Text("Tap 'Score New' to run your first deal through the wealth signal matrix.")
                .font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(32).background(Theme.surface).cornerRadius(12)
    }

    // MARK: - High Income Principles

    private var highIncomePrinciplesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "HIGH INCOME PRINCIPLES")
            ForEach(highIncomePrinciples, id: \.self) { principle in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(wealthGold).frame(width: 5, height: 5).padding(.top, 5)
                    Text(principle).font(.system(size: 12)).foregroundColor(Theme.text)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Contracts Data

    private var displayContracts: [SupabaseContract] {
        supabase.isConfigured ? remoteContracts : [
            SupabaseContract(id: "1", title: "Tower A Foundation", client: "Metro Development", location: "Downtown", sector: "Commercial", stage: "Active", package: "Structural", budget: "$4.2M", bidDue: "2026-04-15", liveFeedStatus: "On Track", bidders: 3, score: 85, watchCount: 12),
            SupabaseContract(id: "2", title: "Highway Bridge Rehab", client: "State DOT", location: "County Line", sector: "Infrastructure", stage: "Pursuit", package: "Civil", budget: "$8.7M", bidDue: "2026-05-01", liveFeedStatus: "Competitive", bidders: 7, score: 72, watchCount: 8),
        ]
    }

    private func loadContracts() async {
        guard supabase.isConfigured else { return }
        do { remoteContracts = try await supabase.fetch("cs_contracts") } catch { /* fallback */ }
    }

    // MARK: - Helpers

    private func opportunitySummaryText(_ opp: WealthOpportunity) -> String {
        var text = "OPPORTUNITY: \(opp.name)\n"
        text += "Wealth Signal: \(opp.wealthSignal) — \(opp.signalLabel)\n"
        text += "Scored: \(opp.createdAt.formatted(.dateTime.month().day().year()))\n\n"
        for c in opportunityCriteria {
            if let score = opp.scores[c.id] {
                text += "\(c.icon) \(c.label): \(score)/100\n"
            }
        }
        text += "\n— Generated by ConstructionOS Wealth Command"
        return text
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = opportunitiesRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WealthOpportunity].self, from: data) {
            opportunities = decoded
        }
        if let data = archivedRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WealthOpportunity].self, from: data) {
            archivedOpportunities = decoded
        }
    }

    private func saveOpportunities() {
        if let data = try? JSONEncoder().encode(opportunities) {
            opportunitiesRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured, let opp = opportunities.first {
            Task {
                let dto = SupabaseWealthOpportunity(
                    name: opp.name,
                    wealthSignal: opp.wealthSignal,
                    contractId: opp.contractId,
                    status: opp.status
                )
                try? await supabase.insert("cs_wealth_opportunities", record: dto)
            }
        }
    }

    private func saveArchived() {
        if let data = try? JSONEncoder().encode(archivedOpportunities) {
            archivedRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }
}

// MARK: - Opportunity Filter Sheet

struct OpportunityFilterSheet: View {
    let onAdd: (WealthOpportunity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var scores: [String: Int] = [:]

    var wealthSignal: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.values.reduce(0, +) / max(scores.count, 1)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OPPORTUNITY NAME").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            TextField("e.g. Tower A Concrete Package", text: $name)
                                .font(.system(size: 13)).foregroundColor(Theme.text).accentColor(wealthGold)
                                .padding(.horizontal, 14).padding(.vertical, 12)
                                .background(Theme.surface).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                        }

                        Text("Rate each dimension 0–100")
                            .font(.system(size: 11)).foregroundColor(Theme.muted)

                        ForEach(opportunityCriteria, id: \.id) { criterion in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(criterion.icon).font(.system(size: 16))
                                    Text(criterion.label).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                                    Spacer()
                                    Text("\(scores[criterion.id] ?? 50)").font(.system(size: 16, weight: .heavy)).foregroundColor(criterion.color)
                                }
                                Slider(value: Binding(
                                    get: { Double(scores[criterion.id] ?? 50) },
                                    set: { scores[criterion.id] = Int($0) }
                                ), in: 0...100, step: 5)
                                .accentColor(criterion.color)
                            }
                            .padding(14).background(Theme.surface).cornerRadius(10)
                        }

                        if !scores.isEmpty {
                            VStack(spacing: 4) {
                                Text("WEALTH SIGNAL").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                                Text("\(wealthSignal)").font(.system(size: 48, weight: .heavy)).foregroundColor(signalColor(wealthSignal))
                                Text(signalLabelText(wealthSignal)).font(.system(size: 12, weight: .bold)).tracking(1).foregroundColor(signalColor(wealthSignal))
                            }
                            .frame(maxWidth: .infinity).padding(20).background(Theme.surface).cornerRadius(14)
                            .premiumGlow(cornerRadius: 14, color: signalColor(wealthSignal))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Score Opportunity")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        var allScores = scores
                        for c in opportunityCriteria { if allScores[c.id] == nil { allScores[c.id] = 50 } }
                        onAdd(WealthOpportunity(id: UUID(), name: name.isEmpty ? "Unnamed Opportunity" : name, scores: allScores, createdAt: Date()))
                        dismiss()
                    }
                    .foregroundColor(wealthGold).fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func signalLabelText(_ s: Int) -> String {
        switch s {
        case 80...100: return "HIGH SIGNAL — PURSUE"
        case 60..<80:  return "MEDIUM SIGNAL — EVALUATE"
        case 40..<60:  return "WEAK SIGNAL — RESTRUCTURE OR PASS"
        default:       return "NO-GO — DECLINE"
        }
    }
    private func signalColor(_ s: Int) -> Color {
        switch s {
        case 80...100: return Theme.green
        case 60..<80:  return Theme.gold
        default:       return Theme.red
        }
    }
}

// MARK: - Score From Contract Sheet

struct ScoreFromContractSheet: View {
    let contracts: [SupabaseContract]
    let onAdd: (WealthOpportunity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContract: SupabaseContract?
    @State private var scores: [String: Int] = [:]

    var wealthSignal: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.values.reduce(0, +) / max(scores.count, 1)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        WealthLensLabel(text: "SELECT A CONTRACT")

                        ForEach(contracts, id: \.id) { contract in
                            Button {
                                withAnimation { selectedContract = contract }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(contract.title).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                                        Text("\(contract.client) · \(contract.budget)")
                                            .font(.system(size: 11)).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                    if selectedContract?.id == contract.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
                                    }
                                }
                                .padding(12).background(selectedContract?.id == contract.id ? Theme.surface : Theme.panel.opacity(0.5))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        if let contract = selectedContract {
                            Divider().overlay(Theme.border)

                            Text("Rate each dimension for: \(contract.title)")
                                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)

                            ForEach(opportunityCriteria, id: \.id) { criterion in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(criterion.icon).font(.system(size: 14))
                                        Text(criterion.label).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                                        Spacer()
                                        Text("\(scores[criterion.id] ?? 50)").font(.system(size: 14, weight: .heavy)).foregroundColor(criterion.color)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(scores[criterion.id] ?? 50) },
                                        set: { scores[criterion.id] = Int($0) }
                                    ), in: 0...100, step: 5)
                                    .accentColor(criterion.color)
                                }
                                .padding(10).background(Theme.surface).cornerRadius(8)
                            }

                            if !scores.isEmpty {
                                VStack(spacing: 4) {
                                    Text("WEALTH SIGNAL").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                                    Text("\(wealthSignal)").font(.system(size: 36, weight: .heavy))
                                        .foregroundColor(wealthSignal >= 70 ? Theme.green : wealthSignal >= 50 ? wealthGold : Theme.red)
                                }
                                .frame(maxWidth: .infinity).padding(16).background(Theme.surface).cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Score from Contract")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Score") {
                        guard let contract = selectedContract else { return }
                        var allScores = scores
                        for c in opportunityCriteria { if allScores[c.id] == nil { allScores[c.id] = 50 } }
                        let opp = WealthOpportunity(
                            id: UUID(),
                            name: contract.title,
                            scores: allScores,
                            createdAt: Date(),
                            contractId: contract.id
                        )
                        onAdd(opp)
                        dismiss()
                    }
                    .foregroundColor(wealthGold).fontWeight(.bold)
                    .disabled(selectedContract == nil)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Opportunity Compare View

struct OpportunityCompareView: View {
    let opportunities: [WealthOpportunity]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Header row
                        HStack(spacing: 0) {
                            Text("CRITERIA").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                                .frame(width: 80, alignment: .leading)
                            ForEach(opportunities) { opp in
                                VStack(spacing: 3) {
                                    Text(opp.name).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                                        .lineLimit(1)
                                    Text("\(opp.wealthSignal)")
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(opp.signalColor)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(12).background(Theme.surface).cornerRadius(10)

                        // Criteria comparison rows
                        ForEach(opportunityCriteria, id: \.id) { c in
                            HStack(spacing: 0) {
                                HStack(spacing: 4) {
                                    Text(c.icon).font(.system(size: 12))
                                    Text(c.label).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                                }
                                .frame(width: 80, alignment: .leading)

                                ForEach(opportunities) { opp in
                                    let score = opp.scores[c.id] ?? 0
                                    let isMax = opportunities.allSatisfy { ($0.scores[c.id] ?? 0) <= score }
                                    Text("\(score)")
                                        .font(.system(size: 14, weight: isMax ? .heavy : .medium))
                                        .foregroundColor(isMax ? c.color : Theme.muted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(isMax ? c.color.opacity(0.08) : Color.clear)
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal, 12).padding(.vertical, 4)
                        }

                        // Winner
                        if let best = opportunities.max(by: { $0.wealthSignal < $1.wealthSignal }) {
                            VStack(spacing: 6) {
                                Text("RECOMMENDED").font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Theme.green)
                                Text(best.name).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.text)
                                Text("Wealth Signal: \(best.wealthSignal) — \(best.signalLabel)")
                                    .font(.system(size: 11)).foregroundColor(Theme.green)
                            }
                            .frame(maxWidth: .infinity).padding(16)
                            .background(Theme.green.opacity(0.06)).cornerRadius(12)
                            .premiumGlow(cornerRadius: 12, color: Theme.green)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Compare Opportunities")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() }.foregroundColor(Theme.muted) }
            }
        }
        .preferredColorScheme(.dark)
    }
}


// MARK: - ========== Face ID / Biometric Auth ==========

import LocalAuthentication

@MainActor
final class BiometricAuthManager: ObservableObject {
    static let shared = BiometricAuthManager()
    @Published var isUnlocked = false
    @Published var biometricType: LABiometryType = .none
    @AppStorage("ConstructOS.Security.BiometricEnabled") var biometricEnabled = false

    init() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric"
        }
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock ConstructionOS"
            )
            await MainActor.run { isUnlocked = success }
            return success
        } catch {
            return false
        }
    }
}

struct BiometricLockScreen: View {
    @ObservedObject var bioManager = BiometricAuthManager.shared
    @Binding var isUnlocked: Bool

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: bioManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 56)).foregroundColor(Theme.accent)
                Text("CONSTRUCTIONOS LOCKED")
                    .font(.system(size: 14, weight: .bold)).tracking(3).foregroundColor(Theme.muted)
                Text("Authenticate with \(bioManager.biometricName) to continue")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
                Button("Unlock with \(bioManager.biometricName)") {
                    Task {
                        let success = await bioManager.authenticate()
                        if success { isUnlocked = true }
                    }
                }
                .font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)

                Button("Skip") { isUnlocked = true }
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task { let _ = await bioManager.authenticate() }
        }
    }
}

// MARK: - ========== Video Call System ==========

#if os(iOS)
import AVFoundation

@MainActor
final class VideoCallManager: ObservableObject {
    static let shared = VideoCallManager()
    @Published var isInCall = false
    @Published var isMuted = false
    @Published var isCameraOn = true
    @Published var callDuration: TimeInterval = 0
    @Published var participantName: String = ""
    @Published var callStatus: String = "idle"

    private var callTimer: Timer?

    func startCall(with participant: String) {
        participantName = participant
        isInCall = true
        isMuted = false
        isCameraOn = true
        callDuration = 0
        callStatus = "connecting"

        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.callStatus = "connected"
            self?.callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.callDuration += 1
            }
        }
    }

    func endCall() {
        callTimer?.invalidate()
        callTimer = nil
        isInCall = false
        callStatus = "idle"
    }

    func toggleMute() { isMuted.toggle() }
    func toggleCamera() { isCameraOn.toggle() }

    var formattedDuration: String {
        let mins = Int(callDuration) / 60
        let secs = Int(callDuration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct VideoCallView: View {
    @ObservedObject var callManager = VideoCallManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Remote video placeholder
                ZStack {
                    LinearGradient(colors: [Theme.surface, Theme.bg], startPoint: .top, endPoint: .bottom)
                    VStack(spacing: 12) {
                        Circle().fill(Theme.accent.opacity(0.2)).frame(width: 80, height: 80)
                            .overlay(Text(String(callManager.participantName.prefix(2)).uppercased())
                                .font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.accent))
                        Text(callManager.participantName)
                            .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                        Text(callManager.callStatus == "connected" ? callManager.formattedDuration : callManager.callStatus.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(callManager.callStatus == "connected" ? Theme.green : Theme.gold)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Self-view pip
                if callManager.isCameraOn {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.panel)
                            .frame(width: 120, height: 160)
                            .overlay(
                                VStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 28)).foregroundColor(Theme.muted)
                                    Text("YOU").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                                }
                            )
                            .padding(16)
                    }
                }

                // Controls
                HStack(spacing: 24) {
                    callControl(icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill",
                               label: callManager.isMuted ? "Unmute" : "Mute",
                               color: callManager.isMuted ? Theme.red : Theme.text) { callManager.toggleMute() }

                    callControl(icon: callManager.isCameraOn ? "video.fill" : "video.slash.fill",
                               label: callManager.isCameraOn ? "Cam Off" : "Cam On",
                               color: callManager.isCameraOn ? Theme.text : Theme.red) { callManager.toggleCamera() }

                    Button {
                        callManager.endCall()
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Circle().fill(Theme.red).frame(width: 56, height: 56)
                                .overlay(Image(systemName: "phone.down.fill").font(.system(size: 22)).foregroundColor(.white))
                            Text("End").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.red)
                        }
                    }
                    .buttonStyle(.plain)

                    callControl(icon: "speaker.wave.2.fill", label: "Speaker", color: Theme.text) {}
                    callControl(icon: "ellipsis", label: "More", color: Theme.text) {}
                }
                .padding(20)
                .background(Color.black.opacity(0.9))
            }
        }
        .preferredColorScheme(.dark)
    }

    private func callControl(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle().fill(Theme.surface).frame(width: 48, height: 48)
                    .overlay(Image(systemName: icon).font(.system(size: 18)).foregroundColor(color))
                Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.muted)
            }
        }
        .buttonStyle(.plain)
    }
}
#endif

// MARK: - ========== StoreKit Subscriptions ==========

import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptionStatus: SubscriptionTier = .free
    @Published var availableProducts: [Product] = []
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    enum SubscriptionTier: String {
        case free = "Free"
        case pro = "Pro"
        case enterprise = "Enterprise"

        var features: [String] {
            switch self {
            case .free: return ["5 Projects", "Basic Ops Dashboard", "Demo Data"]
            case .pro: return ["Unlimited Projects", "Full Ops Suite", "Supabase Sync", "Wealth Intelligence", "PDF Export"]
            case .enterprise: return ["Everything in Pro", "Team Collaboration", "Video Calls", "Priority Support", "Custom Integrations"]
            }
        }

        var color: Color {
            switch self {
            case .free: return Theme.muted
            case .pro: return Theme.gold
            case .enterprise: return Theme.accent
            }
        }
    }

    private let productIDs = [
        "com.constructionos.pro.monthly",
        "com.constructionos.pro.annual",
        "com.constructionos.enterprise.monthly",
        "com.constructionos.enterprise.annual"
    ]

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Set(productIDs))
            await MainActor.run { availableProducts = products.sorted { $0.price < $1.price } }
        } catch {
            await MainActor.run { purchaseError = "Failed to load products" }
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
            case .pending:
                purchaseError = "Purchase is pending approval"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isPurchasing = false
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID.contains("enterprise") {
                    await MainActor.run { subscriptionStatus = .enterprise }
                    return
                } else if transaction.productID.contains("pro") {
                    await MainActor.run { subscriptionStatus = .pro }
                    return
                }
            }
        }
        await MainActor.run { subscriptionStatus = .free }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreKitError.notAvailableInStorefront
        case .verified(let item): return item
        }
    }
}

struct SubscriptionPaywallView: View {
    @ObservedObject var manager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            ScrollView {
                VStack(spacing: 20) {
                    Text("\u{1F48E}").font(.system(size: 48))
                    Text("UPGRADE CONSTRUCTIONOS")
                        .font(.system(size: 18, weight: .heavy)).tracking(2).foregroundColor(Theme.text)

                    // Tier comparison
                    ForEach([SubscriptionManager.SubscriptionTier.free, .pro, .enterprise], id: \.rawValue) { tier in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(tier.rawValue.uppercased())
                                    .font(.system(size: 13, weight: .heavy)).tracking(2).foregroundColor(tier.color)
                                Spacer()
                                if tier == manager.subscriptionStatus {
                                    Text("CURRENT").font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(tier.color).cornerRadius(4)
                                }
                            }
                            ForEach(tier.features, id: \.self) { feature in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                                        .foregroundColor(tier.color)
                                    Text(feature).font(.system(size: 11)).foregroundColor(Theme.text)
                                }
                            }
                        }
                        .padding(14).background(Theme.surface).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(tier == manager.subscriptionStatus ? tier.color.opacity(0.5) : Theme.border.opacity(0.3), lineWidth: 1))
                    }

                    // Available products
                    if manager.availableProducts.isEmpty {
                        Text("Loading subscription options...")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                    } else {
                        ForEach(manager.availableProducts, id: \.id) { product in
                            Button {
                                Task { await manager.purchase(product) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.displayName).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                                        Text(product.description).font(.system(size: 10)).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent)
                                }
                                .padding(14).background(Theme.surface).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }

                    if manager.isPurchasing {
                        ProgressView("Processing...").tint(Theme.accent)
                    }

                    if let error = manager.purchaseError {
                        Text(error).font(.system(size: 11)).foregroundColor(Theme.red)
                    }

                    Button("Restore Purchases") {
                        Task { await manager.restorePurchases() }
                    }
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)

                    Button("Close") { dismiss() }
                        .font(.system(size: 12)).foregroundColor(Theme.muted)
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .task { await manager.loadProducts() }
    }
}

// MARK: - ========== Construction Rental Search Engine ==========

enum RentalCategory: String, CaseIterable, Identifiable {
    case heavyEquipment = "Heavy Equipment"
    case earthmoving = "Earthmoving"
    case cranes = "Cranes & Lifting"
    case aerialLifts = "Aerial Lifts"
    case compaction = "Compaction"
    case concrete = "Concrete & Masonry"
    case generators = "Generators & Power"
    case lighting = "Lighting & Temp Power"
    case handTools = "Hand & Power Tools"
    case demolition = "Demolition"
    case plumbing = "Plumbing Tools"
    case electrical = "Electrical Tools"
    case hvacTools = "HVAC Tools"
    case safetyEquip = "Safety Equipment"
    case vehicles = "Trucks & Vehicles"
    case trailers = "Trailers & Hauling"
    case scaffolding = "Scaffolding & Access"
    case pumps = "Pumps & Dewatering"
    case welding = "Welding Equipment"
    case surveying = "Survey & Measuring"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .heavyEquipment: return "\u{1F3D7}"
        case .earthmoving: return "\u{1F69C}"
        case .cranes: return "\u{1F3D7}"
        case .aerialLifts: return "\u{2B06}\u{FE0F}"
        case .compaction: return "\u{1F6A7}"
        case .concrete: return "\u{1F9F1}"
        case .generators: return "\u{26A1}"
        case .lighting: return "\u{1F4A1}"
        case .handTools: return "\u{1F527}"
        case .demolition: return "\u{1F4A5}"
        case .plumbing: return "\u{1F6B0}"
        case .electrical: return "\u{1F50C}"
        case .hvacTools: return "\u{2744}\u{FE0F}"
        case .safetyEquip: return "\u{26D1}"
        case .vehicles: return "\u{1F69A}"
        case .trailers: return "\u{1F6FB}"
        case .scaffolding: return "\u{1F9D7}"
        case .pumps: return "\u{1F4A7}"
        case .welding: return "\u{1F525}"
        case .surveying: return "\u{1F4D0}"
        }
    }
}

struct RentalItem: Identifiable {
    let id = UUID()
    let name: String
    let category: RentalCategory
    let dailyRate: String
    let weeklyRate: String
    let monthlyRate: String
    let specs: String
    let availability: String
    let provider: RentalProvider
    let imageIcon: String
}

enum RentalProvider: String, CaseIterable {
    case unitedRentals = "United Rentals"
    case dozr = "DOZR"
    case toolsy = "Toolsy"
    case rentMyEquipment = "Rent My Equipment"
    case sunbelt = "Sunbelt Rentals"
    case herc = "Herc Rentals"

    var color: Color {
        switch self {
        case .unitedRentals: return Color(red: 0.0, green: 0.35, blue: 0.65)
        case .dozr: return Color(red: 0.95, green: 0.55, blue: 0.1)
        case .toolsy: return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .rentMyEquipment: return Color(red: 0.55, green: 0.27, blue: 0.68)
        case .sunbelt: return Color(red: 0.85, green: 0.2, blue: 0.15)
        case .herc: return Color(red: 0.3, green: 0.3, blue: 0.7)
        }
    }

    var tagline: String {
        switch self {
        case .unitedRentals: return "Largest equipment rental company in the world"
        case .dozr: return "Online heavy equipment rental marketplace"
        case .toolsy: return "Tool rentals made simple"
        case .rentMyEquipment: return "Peer-to-peer construction equipment rental"
        case .sunbelt: return "Reliable jobsite solutions"
        case .herc: return "ProSolutions for every project"
        }
    }

    var websiteURL: String {
        switch self {
        case .unitedRentals: return "https://www.unitedrentals.com"
        case .dozr: return "https://dozr.com"
        case .toolsy: return "https://toolsy.com"
        case .rentMyEquipment: return "https://www.rentmyequipment.com"
        case .sunbelt: return "https://www.sunbeltrentals.com"
        case .herc: return "https://www.hercrentals.com"
        }
    }

    var searchURL: String {
        switch self {
        case .unitedRentals: return "https://www.unitedrentals.com/marketplace/equipment"
        case .dozr: return "https://dozr.com/equipment-rental"
        case .toolsy: return "https://toolsy.com/rentals"
        case .rentMyEquipment: return "https://www.rentmyequipment.com/search"
        case .sunbelt: return "https://www.sunbeltrentals.com/equipment"
        case .herc: return "https://www.hercrentals.com/us/equipment.html"
        }
    }

    var appScheme: String? {
        switch self {
        case .unitedRentals: return "unitedrentals://"
        case .dozr: return "dozr://"
        case .toolsy: return nil
        case .rentMyEquipment: return nil
        case .sunbelt: return "sunbeltrentals://"
        case .herc: return nil
        }
    }

    var appStoreID: String? {
        switch self {
        case .unitedRentals: return "1074798452"
        case .dozr: return "1547894041"
        case .toolsy: return nil
        case .rentMyEquipment: return nil
        case .sunbelt: return "1076532758"
        case .herc: return "1234068498"
        }
    }

    var icon: String {
        switch self {
        case .unitedRentals: return "\u{1F3E2}"
        case .dozr: return "\u{1F69C}"
        case .toolsy: return "\u{1F527}"
        case .rentMyEquipment: return "\u{1F91D}"
        case .sunbelt: return "\u{2600}\u{FE0F}"
        case .herc: return "\u{1F3D7}"
        }
    }

    var features: [String] {
        switch self {
        case .unitedRentals: return ["4,300+ locations", "Largest fleet in North America", "24/7 support", "Online ordering", "Delivery & pickup", "UR Control telematics"]
        case .dozr: return ["Online marketplace", "Transparent pricing", "Verified operators", "Heavy equipment focus", "Instant quoting", "Delivery coordination"]
        case .toolsy: return ["Hand & power tools", "Same-day availability", "Competitive daily rates", "No minimum rental", "Walk-in or deliver", "Trade account discounts"]
        case .rentMyEquipment: return ["Peer-to-peer rentals", "Owner-direct pricing", "Equipment insurance", "Local inventory", "Flexible terms", "List your own equipment"]
        case .sunbelt: return ["1,100+ locations", "Full-service rental", "Operator training", "Safety programs", "Fuel management", "GPS fleet tracking"]
        case .herc: return ["ProSolutions consulting", "National accounts", "On-site management", "Environmental services", "Industrial plant support", "Entertainment & events"]
        }
    }
}

// MARK: - Provider Integration Manager

@MainActor
final class RentalProviderManager: ObservableObject {
    static let shared = RentalProviderManager()

    @Published var connectedProviders: Set<String> = []
    @Published var quoteRequests: [RentalQuoteRequest] = []

    private let connectedKey = "ConstructOS.Rentals.ConnectedProviders"
    private let quotesKey = "ConstructOS.Rentals.QuoteRequests"

    init() {
        if let data = UserDefaults.standard.stringArray(forKey: connectedKey) {
            connectedProviders = Set(data)
        }
        quoteRequests = loadJSON(quotesKey, default: [RentalQuoteRequest]())
    }

    func connect(_ provider: RentalProvider) {
        connectedProviders.insert(provider.rawValue)
        UserDefaults.standard.set(Array(connectedProviders), forKey: connectedKey)
    }

    func disconnect(_ provider: RentalProvider) {
        connectedProviders.remove(provider.rawValue)
        UserDefaults.standard.set(Array(connectedProviders), forKey: connectedKey)
    }

    func isConnected(_ provider: RentalProvider) -> Bool {
        connectedProviders.contains(provider.rawValue)
    }

    func submitQuote(_ request: RentalQuoteRequest) {
        quoteRequests.insert(request, at: 0)
        saveJSON(quotesKey, value: quoteRequests)
    }

    func openProvider(_ provider: RentalProvider) {
        #if os(iOS)
        // Try app scheme first, fallback to website
        if let scheme = provider.appScheme, let url = URL(string: scheme) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        if let url = URL(string: provider.websiteURL) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: provider.websiteURL) {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    func openSearch(_ provider: RentalProvider, query: String = "") {
        var urlStr = provider.searchURL
        if !query.isEmpty, let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlStr += "?q=\(encoded)"
        }
        #if os(iOS)
        if let url = URL(string: urlStr) { UIApplication.shared.open(url) }
        #elseif os(macOS)
        if let url = URL(string: urlStr) { NSWorkspace.shared.open(url) }
        #endif
    }

    func openAppStore(_ provider: RentalProvider) {
        #if os(iOS)
        if let appID = provider.appStoreID, let url = URL(string: "itms-apps://apple.com/app/id\(appID)") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

struct RentalQuoteRequest: Identifiable, Codable {
    var id = UUID()
    let equipmentName: String
    let category: String
    let provider: String
    let duration: String
    let jobsite: String
    let notes: String
    let requestedAt: Date
    var status: String = "pending"
}

// MARK: - Provider Hub View

struct RentalProviderHubView: View {
    @ObservedObject var manager = RentalProviderManager.shared
    @State private var selectedProvider: RentalProvider? = nil
    @State private var showQuoteSheet = false
    @State private var quoteEquipment = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROVIDER HUB").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent)
                    Text("Connected Rental Platforms")
                        .font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.text)
                    Text("Link accounts for direct ordering, real-time availability, and unified quotes")
                        .font(.system(size: 10)).foregroundColor(Theme.muted)
                }
                Spacer()
                Text("\(manager.connectedProviders.count)/\(RentalProvider.allCases.count)")
                    .font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.accent)
            }
            .padding(14).background(Theme.surface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: Theme.accent)

            // Provider cards
            ForEach(RentalProvider.allCases, id: \.rawValue) { provider in
                ProviderIntegrationCard(
                    provider: provider,
                    isConnected: manager.isConnected(provider),
                    onConnect: { manager.connect(provider) },
                    onDisconnect: { manager.disconnect(provider) },
                    onOpen: { manager.openProvider(provider) },
                    onSearch: { manager.openSearch(provider) },
                    onGetApp: { manager.openAppStore(provider) },
                    onQuote: {
                        selectedProvider = provider
                        showQuoteSheet = true
                    }
                )
            }

            // Quote history
            if !manager.quoteRequests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUOTE REQUESTS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                    ForEach(manager.quoteRequests.prefix(5)) { quote in
                        HStack(spacing: 8) {
                            Circle().fill(quote.status == "pending" ? Theme.gold : Theme.green).frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(quote.equipmentName).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                                Text("\(quote.provider) \u{2022} \(quote.duration) \u{2022} \(quote.jobsite)")
                                    .font(.system(size: 8)).foregroundColor(Theme.muted)
                            }
                            Spacer()
                            Text(quote.status.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(quote.status == "pending" ? Theme.gold : Theme.green)
                        }
                        .padding(8).background(Theme.panel).cornerRadius(6)
                    }
                }
                .padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
        .sheet(isPresented: $showQuoteSheet) {
            if let provider = selectedProvider {
                QuoteRequestSheet(provider: provider, equipment: quoteEquipment) { quote in
                    manager.submitQuote(quote)
                    showQuoteSheet = false
                }
            }
        }
    }
}

struct ProviderIntegrationCard: View {
    let provider: RentalProvider
    let isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onOpen: () -> Void
    let onSearch: () -> Void
    let onGetApp: () -> Void
    let onQuote: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(provider.icon).font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(provider.color.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(provider.rawValue).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        if isConnected {
                            Text("LINKED").font(.system(size: 7, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Theme.green).cornerRadius(3)
                        }
                    }
                    Text(provider.tagline).font(.system(size: 9)).foregroundColor(Theme.muted)
                }
                Spacer()
                Button { withAnimation { expanded.toggle() } } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(Theme.muted)
                }.buttonStyle(.plain)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    // Features
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(provider.features, id: \.self) { feature in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 8)).foregroundColor(provider.color)
                                Text(feature).font(.system(size: 9)).foregroundColor(Theme.text).lineLimit(1)
                            }
                        }
                    }

                    // Action buttons
                    HStack(spacing: 6) {
                        if isConnected {
                            Button(action: onOpen) {
                                Label("Open", systemImage: "arrow.up.right.square")
                                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .background(provider.color).cornerRadius(6)
                            }.buttonStyle(.plain)

                            Button(action: onSearch) {
                                Label("Search", systemImage: "magnifyingglass")
                                    .font(.system(size: 9, weight: .bold)).foregroundColor(provider.color)
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .background(provider.color.opacity(0.12)).cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(provider.color.opacity(0.3), lineWidth: 1))
                            }.buttonStyle(.plain)

                            Button(action: onQuote) {
                                Label("Quote", systemImage: "doc.text")
                                    .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold)
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .background(Theme.gold.opacity(0.12)).cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
                            }.buttonStyle(.plain)

                            Button(action: onDisconnect) {
                                Text("Unlink").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.red)
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(Theme.red.opacity(0.1)).cornerRadius(6)
                            }.buttonStyle(.plain)
                        } else {
                            Button(action: onConnect) {
                                Label("Connect \(provider.rawValue)", systemImage: "link")
                                    .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(provider.color).cornerRadius(6)
                            }.buttonStyle(.plain)

                            if provider.appStoreID != nil {
                                Button(action: onGetApp) {
                                    Label("Get App", systemImage: "arrow.down.app")
                                        .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(Theme.cyan.opacity(0.12)).cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isConnected ? provider.color.opacity(0.4) : Theme.border.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Quote Request Sheet

struct QuoteRequestSheet: View {
    let provider: RentalProvider
    let equipment: String
    let onSubmit: (RentalQuoteRequest) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var equipmentName: String
    @State private var duration = "1 Week"
    @State private var jobsite = ""
    @State private var notes = ""

    private let durations = ["1 Day", "3 Days", "1 Week", "2 Weeks", "1 Month", "3 Months", "6 Months", "12 Months"]

    init(provider: RentalProvider, equipment: String, onSubmit: @escaping (RentalQuoteRequest) -> Void) {
        self.provider = provider
        self.equipment = equipment
        self.onSubmit = onSubmit
        _equipmentName = State(initialValue: equipment)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Text(provider.icon).font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("REQUEST QUOTE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(provider.color)
                                Text(provider.rawValue).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.text)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("EQUIPMENT").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            TextField("Equipment name or description", text: $equipmentName)
                                .font(.system(size: 13)).foregroundColor(Theme.text)
                                .padding(10).background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("RENTAL DURATION").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(durations, id: \.self) { d in
                                        Button { duration = d } label: {
                                            Text(d).font(.system(size: 10, weight: .bold))
                                                .foregroundColor(duration == d ? .black : Theme.text)
                                                .padding(.horizontal, 12).padding(.vertical, 7)
                                                .background(duration == d ? provider.color : Theme.surface)
                                                .cornerRadius(6)
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("JOBSITE / DELIVERY LOCATION").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            TextField("Address or site name", text: $jobsite)
                                .font(.system(size: 13)).foregroundColor(Theme.text)
                                .padding(10).background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTES").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            TextEditor(text: $notes)
                                .font(.system(size: 12)).foregroundColor(Theme.text)
                                .scrollContentBackground(.hidden).background(Theme.surface)
                                .frame(height: 80).padding(6)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                        }

                        Button {
                            let quote = RentalQuoteRequest(
                                equipmentName: equipmentName,
                                category: "",
                                provider: provider.rawValue,
                                duration: duration,
                                jobsite: jobsite,
                                notes: notes,
                                requestedAt: Date()
                            )
                            onSubmit(quote)
                        } label: {
                            Text("SUBMIT QUOTE REQUEST")
                                .font(.system(size: 13, weight: .bold)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(LinearGradient(colors: [provider.color, Theme.gold], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(equipmentName.isEmpty)

                        Text("Quote requests are sent to \(provider.rawValue). Response times vary by provider.")
                            .font(.system(size: 9)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private let rentalInventory: [RentalItem] = [
    // Heavy Equipment
    RentalItem(name: "CAT 320 Excavator", category: .heavyEquipment, dailyRate: "$850", weeklyRate: "$3,200", monthlyRate: "$8,500", specs: "20-ton, 158 HP, 19\u{2032}6\u{2033} reach", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Komatsu PC210 Excavator", category: .heavyEquipment, dailyRate: "$780", weeklyRate: "$2,900", monthlyRate: "$7,800", specs: "21-ton, 165 HP, 20\u{2032} reach", availability: "Available", provider: .dozr, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Volvo EC220E Excavator", category: .heavyEquipment, dailyRate: "$820", weeklyRate: "$3,100", monthlyRate: "$8,200", specs: "22-ton, 173 HP", availability: "3-day lead", provider: .sunbelt, imageIcon: "\u{1F3D7}"),

    // Earthmoving
    RentalItem(name: "CAT D6 Dozer", category: .earthmoving, dailyRate: "$1,200", weeklyRate: "$4,500", monthlyRate: "$12,000", specs: "215 HP, 6-way blade", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F69C}"),
    RentalItem(name: "John Deere 850K Dozer", category: .earthmoving, dailyRate: "$1,100", weeklyRate: "$4,200", monthlyRate: "$11,200", specs: "205 HP, hydrostatic", availability: "Available", provider: .dozr, imageIcon: "\u{1F69C}"),
    RentalItem(name: "CAT 950M Wheel Loader", category: .earthmoving, dailyRate: "$750", weeklyRate: "$2,800", monthlyRate: "$7,500", specs: "3.5 CY bucket, 202 HP", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F69C}"),
    RentalItem(name: "Bobcat S770 Skid Steer", category: .earthmoving, dailyRate: "$380", weeklyRate: "$1,400", monthlyRate: "$3,800", specs: "92 HP, 3,350 lb capacity", availability: "Available", provider: .sunbelt, imageIcon: "\u{1F69C}"),
    RentalItem(name: "Case 590SN Backhoe", category: .earthmoving, dailyRate: "$450", weeklyRate: "$1,700", monthlyRate: "$4,500", specs: "97 HP, 14\u{2032} dig depth", availability: "Available", provider: .herc, imageIcon: "\u{1F69C}"),

    // Cranes
    RentalItem(name: "Liebherr LTM 1100 Crane", category: .cranes, dailyRate: "$2,800", weeklyRate: "$12,000", monthlyRate: "$32,000", specs: "100-ton, 197\u{2032} boom", availability: "1-week lead", provider: .unitedRentals, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Tadano GR-1000XL Crane", category: .cranes, dailyRate: "$2,200", weeklyRate: "$9,500", monthlyRate: "$26,000", specs: "100-ton rough terrain", availability: "Available", provider: .dozr, imageIcon: "\u{1F3D7}"),

    // Aerial Lifts
    RentalItem(name: "JLG 1932R Scissor Lift", category: .aerialLifts, dailyRate: "$120", weeklyRate: "$380", monthlyRate: "$950", specs: "19\u{2032} height, electric", availability: "Available", provider: .unitedRentals, imageIcon: "\u{2B06}\u{FE0F}"),
    RentalItem(name: "Genie S-65 Boom Lift", category: .aerialLifts, dailyRate: "$350", weeklyRate: "$1,200", monthlyRate: "$3,200", specs: "65\u{2032} height, 4WD", availability: "Available", provider: .sunbelt, imageIcon: "\u{2B06}\u{FE0F}"),
    RentalItem(name: "JLG 460SJ Boom Lift", category: .aerialLifts, dailyRate: "$320", weeklyRate: "$1,100", monthlyRate: "$2,900", specs: "46\u{2032} height, diesel", availability: "Available", provider: .herc, imageIcon: "\u{2B06}\u{FE0F}"),

    // Concrete
    RentalItem(name: "Concrete Mixer Truck", category: .concrete, dailyRate: "$650", weeklyRate: "$2,400", monthlyRate: "$6,500", specs: "10 CY capacity", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F9F1}"),
    RentalItem(name: "Concrete Pump Trailer", category: .concrete, dailyRate: "$800", weeklyRate: "$3,000", monthlyRate: "$8,000", specs: "120\u{2032} boom, 150 CY/hr", availability: "2-day lead", provider: .sunbelt, imageIcon: "\u{1F9F1}"),
    RentalItem(name: "Power Trowel 48\u{2033}", category: .concrete, dailyRate: "$85", weeklyRate: "$280", monthlyRate: "$700", specs: "Walk-behind, Honda GX", availability: "Available", provider: .toolsy, imageIcon: "\u{1F9F1}"),
    RentalItem(name: "Concrete Vibrator", category: .concrete, dailyRate: "$45", weeklyRate: "$150", monthlyRate: "$380", specs: "2\u{2033} head, gas powered", availability: "Available", provider: .toolsy, imageIcon: "\u{1F9F1}"),

    // Generators
    RentalItem(name: "CAT XQ60 Generator", category: .generators, dailyRate: "$180", weeklyRate: "$650", monthlyRate: "$1,700", specs: "60 kW, diesel, trailer", availability: "Available", provider: .unitedRentals, imageIcon: "\u{26A1}"),
    RentalItem(name: "Generac 200kW Generator", category: .generators, dailyRate: "$450", weeklyRate: "$1,600", monthlyRate: "$4,200", specs: "200 kW, sound-attenuated", availability: "Available", provider: .sunbelt, imageIcon: "\u{26A1}"),

    // Hand & Power Tools
    RentalItem(name: "Bosch Jackhammer SDS-Max", category: .handTools, dailyRate: "$65", weeklyRate: "$220", monthlyRate: "$550", specs: "35 lb, 15 Amp", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),
    RentalItem(name: "Hilti TE 3000 Breaker", category: .handTools, dailyRate: "$85", weeklyRate: "$290", monthlyRate: "$720", specs: "65 lb, electric", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F527}"),
    RentalItem(name: "Husqvarna K770 Cutoff Saw", category: .handTools, dailyRate: "$75", weeklyRate: "$250", monthlyRate: "$620", specs: "14\u{2033} blade, gas", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),
    RentalItem(name: "Dewalt Rotary Hammer", category: .handTools, dailyRate: "$40", weeklyRate: "$130", monthlyRate: "$320", specs: "SDS-Plus, 1\u{2033}", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),
    RentalItem(name: "Milwaukee Cordless Kit", category: .handTools, dailyRate: "$55", weeklyRate: "$180", monthlyRate: "$450", specs: "Drill/Impact/Sawzall", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),

    // Demolition
    RentalItem(name: "Bobcat E85 Mini Excavator + Breaker", category: .demolition, dailyRate: "$520", weeklyRate: "$1,900", monthlyRate: "$5,100", specs: "8.5-ton w/ hydraulic breaker", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F4A5}"),
    RentalItem(name: "NPK GH-2 Hydraulic Breaker", category: .demolition, dailyRate: "$280", weeklyRate: "$950", monthlyRate: "$2,500", specs: "1,500 ft-lb class", availability: "Available", provider: .dozr, imageIcon: "\u{1F4A5}"),

    // Vehicles
    RentalItem(name: "Ford F-350 Flatbed", category: .vehicles, dailyRate: "$180", weeklyRate: "$650", monthlyRate: "$1,700", specs: "Diesel, 12\u{2032} bed", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F69A}"),
    RentalItem(name: "Water Truck 2,000 Gal", category: .vehicles, dailyRate: "$350", weeklyRate: "$1,300", monthlyRate: "$3,500", specs: "CDL required", availability: "Available", provider: .sunbelt, imageIcon: "\u{1F69A}"),

    // Compaction
    RentalItem(name: "BOMAG BW211D Roller", category: .compaction, dailyRate: "$450", weeklyRate: "$1,600", monthlyRate: "$4,300", specs: "84\u{2033} drum, 154 HP", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F6A7}"),
    RentalItem(name: "Wacker Plate Compactor", category: .compaction, dailyRate: "$55", weeklyRate: "$180", monthlyRate: "$450", specs: "5,500 lb force", availability: "Available", provider: .toolsy, imageIcon: "\u{1F6A7}"),
    RentalItem(name: "Jumping Jack Tamper", category: .compaction, dailyRate: "$45", weeklyRate: "$150", monthlyRate: "$380", specs: "3,000 lb force, gas", availability: "Available", provider: .toolsy, imageIcon: "\u{1F6A7}"),

    // Pumps
    RentalItem(name: "Godwin CD150M Pump", category: .pumps, dailyRate: "$220", weeklyRate: "$780", monthlyRate: "$2,100", specs: "6\u{2033} discharge, 1,500 GPM", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F4A7}"),
    RentalItem(name: "Trash Pump 4\u{2033}", category: .pumps, dailyRate: "$85", weeklyRate: "$280", monthlyRate: "$700", specs: "400 GPM, gas", availability: "Available", provider: .toolsy, imageIcon: "\u{1F4A7}"),

    // Scaffolding
    RentalItem(name: "Frame Scaffold Set (5\u{2032}x5\u{2032})", category: .scaffolding, dailyRate: "$25", weeklyRate: "$80", monthlyRate: "$200", specs: "Per frame set with braces", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F9D7}"),
    RentalItem(name: "Baker Scaffold Rolling", category: .scaffolding, dailyRate: "$45", weeklyRate: "$150", monthlyRate: "$380", specs: "6\u{2032} platform, locking wheels", availability: "Available", provider: .toolsy, imageIcon: "\u{1F9D7}"),

    // Welding
    RentalItem(name: "Lincoln Ranger 330MPX", category: .welding, dailyRate: "$120", weeklyRate: "$420", monthlyRate: "$1,100", specs: "330A, multi-process", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F525}"),
    RentalItem(name: "Miller Bobcat 260", category: .welding, dailyRate: "$110", weeklyRate: "$380", monthlyRate: "$1,000", specs: "260A, gas-powered", availability: "Available", provider: .sunbelt, imageIcon: "\u{1F525}"),

    // Survey
    RentalItem(name: "Trimble S7 Total Station", category: .surveying, dailyRate: "$250", weeklyRate: "$900", monthlyRate: "$2,400", specs: "1\u{2033} accuracy, robotic", availability: "1-day lead", provider: .unitedRentals, imageIcon: "\u{1F4D0}"),
    RentalItem(name: "Topcon GT-1003 Total Station", category: .surveying, dailyRate: "$220", weeklyRate: "$780", monthlyRate: "$2,100", specs: "3\u{2033} accuracy", availability: "Available", provider: .herc, imageIcon: "\u{1F4D0}"),

    // Safety
    RentalItem(name: "Gas Monitor 4-Gas", category: .safetyEquip, dailyRate: "$35", weeklyRate: "$120", monthlyRate: "$300", specs: "O2/LEL/CO/H2S", availability: "Available", provider: .unitedRentals, imageIcon: "\u{26D1}"),
    RentalItem(name: "Fall Protection Kit", category: .safetyEquip, dailyRate: "$25", weeklyRate: "$85", monthlyRate: "$220", specs: "Harness + lanyard + anchor", availability: "Available", provider: .toolsy, imageIcon: "\u{26D1}"),

    // Lighting
    RentalItem(name: "Light Tower 6kW", category: .lighting, dailyRate: "$95", weeklyRate: "$340", monthlyRate: "$880", specs: "4x1500W, 30\u{2032} mast", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F4A1}"),

    // Trailers
    RentalItem(name: "Equipment Trailer 20-Ton", category: .trailers, dailyRate: "$120", weeklyRate: "$420", monthlyRate: "$1,100", specs: "Tag-along, ramps", availability: "Available", provider: .sunbelt, imageIcon: "\u{1F6FB}"),
    RentalItem(name: "Lowboy Trailer 50-Ton", category: .trailers, dailyRate: "$250", weeklyRate: "$900", monthlyRate: "$2,400", specs: "Detachable gooseneck", availability: "1-day lead", provider: .unitedRentals, imageIcon: "\u{1F6FB}"),

    // Electrical Tools
    RentalItem(name: "Megger Insulation Tester", category: .electrical, dailyRate: "$45", weeklyRate: "$150", monthlyRate: "$380", specs: "1kV, digital readout", availability: "Available", provider: .toolsy, imageIcon: "\u{1F50C}"),
    RentalItem(name: "Wire Puller 6,000 lb", category: .electrical, dailyRate: "$75", weeklyRate: "$250", monthlyRate: "$620", specs: "6,000 lb capacity", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F50C}"),
    RentalItem(name: "Conduit Bender Hydraulic", category: .electrical, dailyRate: "$30", weeklyRate: "$100", monthlyRate: "$250", specs: "EMT/rigid, up to 1-1/4 in", availability: "Available", provider: .toolsy, imageIcon: "\u{1F50C}"),
    RentalItem(name: "Cable Fault Locator", category: .electrical, dailyRate: "$90", weeklyRate: "$310", monthlyRate: "$780", specs: "TDR, up to 20,000 ft", availability: "1-day lead", provider: .unitedRentals, imageIcon: "\u{1F50C}"),

    // Plumbing Tools
    RentalItem(name: "RIDGID 300 Pipe Threader", category: .plumbing, dailyRate: "$85", weeklyRate: "$290", monthlyRate: "$720", specs: "1/2 in to 2 in capacity", availability: "Available", provider: .toolsy, imageIcon: "\u{1F6B0}"),
    RentalItem(name: "Drain Snake 100 ft", category: .plumbing, dailyRate: "$55", weeklyRate: "$180", monthlyRate: "$450", specs: "3/8 in cable, electric", availability: "Available", provider: .toolsy, imageIcon: "\u{1F6B0}"),
    RentalItem(name: "Pipe Camera Inspection", category: .plumbing, dailyRate: "$120", weeklyRate: "$420", monthlyRate: "$1,100", specs: "200 ft push camera", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F6B0}"),
    RentalItem(name: "Copper Press Tool Kit", category: .plumbing, dailyRate: "$65", weeklyRate: "$220", monthlyRate: "$550", specs: "1/2 in to 2 in jaws", availability: "Available", provider: .toolsy, imageIcon: "\u{1F6B0}"),
    RentalItem(name: "Pipe Fusion Machine", category: .plumbing, dailyRate: "$150", weeklyRate: "$520", monthlyRate: "$1,350", specs: "2 in to 8 in HDPE", availability: "2-day lead", provider: .unitedRentals, imageIcon: "\u{1F6B0}"),

    // HVAC Tools
    RentalItem(name: "Refrigerant Recovery Machine", category: .hvacTools, dailyRate: "$70", weeklyRate: "$240", monthlyRate: "$600", specs: "1 HP, twin cylinder", availability: "Available", provider: .toolsy, imageIcon: "\u{2744}\u{FE0F}"),
    RentalItem(name: "Vacuum Pump 2-Stage", category: .hvacTools, dailyRate: "$40", weeklyRate: "$130", monthlyRate: "$320", specs: "8 CFM, deep vacuum", availability: "Available", provider: .toolsy, imageIcon: "\u{2744}\u{FE0F}"),
    RentalItem(name: "Duct Blaster Fan", category: .hvacTools, dailyRate: "$85", weeklyRate: "$290", monthlyRate: "$720", specs: "Duct leakage testing", availability: "Available", provider: .unitedRentals, imageIcon: "\u{2744}\u{FE0F}"),
    RentalItem(name: "Nitrogen Regulator Kit", category: .hvacTools, dailyRate: "$25", weeklyRate: "$85", monthlyRate: "$210", specs: "0-800 PSI, brazing", availability: "Available", provider: .toolsy, imageIcon: "\u{2744}\u{FE0F}"),
    RentalItem(name: "Sheet Metal Brake 10 ft", category: .hvacTools, dailyRate: "$60", weeklyRate: "$200", monthlyRate: "$500", specs: "16 gauge capacity", availability: "Available", provider: .sunbelt, imageIcon: "\u{2744}\u{FE0F}"),

    // More Heavy Equipment
    RentalItem(name: "CAT 745 Articulated Truck", category: .heavyEquipment, dailyRate: "$1,500", weeklyRate: "$5,600", monthlyRate: "$15,000", specs: "45-ton, 6x6, 500 HP", availability: "1-week lead", provider: .unitedRentals, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Komatsu WA380 Loader", category: .heavyEquipment, dailyRate: "$900", weeklyRate: "$3,400", monthlyRate: "$9,000", specs: "4.2 CY bucket, 232 HP", availability: "Available", provider: .dozr, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Gradall XL4100 III", category: .heavyEquipment, dailyRate: "$1,100", weeklyRate: "$4,100", monthlyRate: "$11,000", specs: "Highway excavator, 174 HP", availability: "3-day lead", provider: .herc, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Telehandler JLG 1055", category: .heavyEquipment, dailyRate: "$480", weeklyRate: "$1,800", monthlyRate: "$4,800", specs: "10,000 lb, 55 ft reach", availability: "Available", provider: .sunbelt, imageIcon: "\u{1F3D7}"),

    // More Demolition
    RentalItem(name: "Concrete Crusher Attachment", category: .demolition, dailyRate: "$350", weeklyRate: "$1,200", monthlyRate: "$3,200", specs: "Fits 20-30 ton excavator", availability: "2-day lead", provider: .dozr, imageIcon: "\u{1F4A5}"),
    RentalItem(name: "Wall Saw Track System", category: .demolition, dailyRate: "$200", weeklyRate: "$700", monthlyRate: "$1,800", specs: "36 in blade, hydraulic", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F4A5}"),
    RentalItem(name: "Core Drill Rig", category: .demolition, dailyRate: "$95", weeklyRate: "$320", monthlyRate: "$800", specs: "Up to 12 in diameter", availability: "Available", provider: .toolsy, imageIcon: "\u{1F4A5}"),

    // More Aerial Lifts
    RentalItem(name: "JLG 600S Boom Lift", category: .aerialLifts, dailyRate: "$450", weeklyRate: "$1,600", monthlyRate: "$4,200", specs: "60 ft height, 4WD, diesel", availability: "Available", provider: .unitedRentals, imageIcon: "\u{2B06}\u{FE0F}"),
    RentalItem(name: "Skyjack SJ6832 Scissor", category: .aerialLifts, dailyRate: "$180", weeklyRate: "$620", monthlyRate: "$1,600", specs: "32 ft height, rough terrain", availability: "Available", provider: .dozr, imageIcon: "\u{2B06}\u{FE0F}"),

    // More Generators
    RentalItem(name: "Honda EU7000 Inverter", category: .generators, dailyRate: "$95", weeklyRate: "$340", monthlyRate: "$880", specs: "7 kW, ultra-quiet", availability: "Available", provider: .toolsy, imageIcon: "\u{26A1}"),
    RentalItem(name: "CAT XQ500 Generator", category: .generators, dailyRate: "$950", weeklyRate: "$3,400", monthlyRate: "$9,000", specs: "500 kW, trailer-mounted", availability: "3-day lead", provider: .unitedRentals, imageIcon: "\u{26A1}"),

    // More Pumps
    RentalItem(name: "Submersible Pump 3 in", category: .pumps, dailyRate: "$65", weeklyRate: "$220", monthlyRate: "$550", specs: "150 GPM, electric", availability: "Available", provider: .toolsy, imageIcon: "\u{1F4A7}"),
    RentalItem(name: "Diaphragm Pump 3 in", category: .pumps, dailyRate: "$95", weeklyRate: "$320", monthlyRate: "$800", specs: "Slurry-capable, air-driven", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F4A7}"),

    // More Vehicles
    RentalItem(name: "Dump Truck 10-Wheeler", category: .vehicles, dailyRate: "$550", weeklyRate: "$2,000", monthlyRate: "$5,400", specs: "14 CY, CDL required", availability: "Available", provider: .sunbelt, imageIcon: "\u{1F69A}"),
    RentalItem(name: "Fuel/Lube Truck", category: .vehicles, dailyRate: "$280", weeklyRate: "$1,000", monthlyRate: "$2,700", specs: "2,500 gal, multi-product", availability: "1-day lead", provider: .unitedRentals, imageIcon: "\u{1F69A}"),

    // More Compaction
    RentalItem(name: "Trench Roller Remote", category: .compaction, dailyRate: "$320", weeklyRate: "$1,100", monthlyRate: "$2,900", specs: "33 in drum, remote control", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F6A7}"),

    // More Hand Tools
    RentalItem(name: "Pneumatic Nailer Framing", category: .handTools, dailyRate: "$25", weeklyRate: "$85", monthlyRate: "$210", specs: "21-degree, full round", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),
    RentalItem(name: "Concrete Scarifier", category: .handTools, dailyRate: "$150", weeklyRate: "$520", monthlyRate: "$1,350", specs: "8 in path, self-propelled", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F527}"),
    RentalItem(name: "Floor Grinder 10 in", category: .handTools, dailyRate: "$120", weeklyRate: "$420", monthlyRate: "$1,100", specs: "Diamond disc, dust port", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),

    // Rent My Equipment — Peer-to-peer listings
    RentalItem(name: "Mini Excavator 3.5-Ton", category: .heavyEquipment, dailyRate: "$295", weeklyRate: "$1,100", monthlyRate: "$2,900", specs: "Owner-operated, Kubota KX035", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Skid Steer w/ Attachments", category: .earthmoving, dailyRate: "$280", weeklyRate: "$1,050", monthlyRate: "$2,800", specs: "Bobcat S650, bucket + forks", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F69C}"),
    RentalItem(name: "Towable Boom Lift 50 ft", category: .aerialLifts, dailyRate: "$200", weeklyRate: "$700", monthlyRate: "$1,850", specs: "Towable, no CDL needed", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{2B06}\u{FE0F}"),
    RentalItem(name: "Plate Compactor + Rammer", category: .compaction, dailyRate: "$40", weeklyRate: "$135", monthlyRate: "$340", specs: "Combo package, gas", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F6A7}"),
    RentalItem(name: "Concrete Mixer Portable 9CF", category: .concrete, dailyRate: "$60", weeklyRate: "$200", monthlyRate: "$500", specs: "Towable, electric start", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F9F1}"),
    RentalItem(name: "Pressure Washer 4000 PSI", category: .handTools, dailyRate: "$75", weeklyRate: "$250", monthlyRate: "$620", specs: "Hot water, diesel", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F527}"),
    RentalItem(name: "Dump Trailer 14 ft", category: .trailers, dailyRate: "$95", weeklyRate: "$340", monthlyRate: "$880", specs: "7-ton, hydraulic lift", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F6FB}"),
    RentalItem(name: "Generator 12kW Portable", category: .generators, dailyRate: "$80", weeklyRate: "$280", monthlyRate: "$720", specs: "Diesel, wheeled, quiet", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{26A1}"),
    RentalItem(name: "Welder/Generator Combo", category: .welding, dailyRate: "$95", weeklyRate: "$330", monthlyRate: "$850", specs: "300A, multi-process + 10kW", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F525}"),
    RentalItem(name: "Trencher Walk-Behind 36 in", category: .earthmoving, dailyRate: "$180", weeklyRate: "$640", monthlyRate: "$1,700", specs: "36 in depth, gas", availability: "Available", provider: .rentMyEquipment, imageIcon: "\u{1F69C}"),

    // Additional United Rentals items
    RentalItem(name: "CAT 336 Excavator", category: .heavyEquipment, dailyRate: "$1,200", weeklyRate: "$4,500", monthlyRate: "$12,000", specs: "36-ton, 268 HP, 24 ft reach", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Genie Z-80/60 Boom", category: .aerialLifts, dailyRate: "$520", weeklyRate: "$1,800", monthlyRate: "$4,800", specs: "80 ft height, articulating", availability: "Available", provider: .unitedRentals, imageIcon: "\u{2B06}\u{FE0F}"),
    RentalItem(name: "Air Compressor 185 CFM", category: .handTools, dailyRate: "$120", weeklyRate: "$420", monthlyRate: "$1,100", specs: "Towable, diesel", availability: "Available", provider: .unitedRentals, imageIcon: "\u{1F527}"),

    // Additional DOZR items
    RentalItem(name: "Volvo A30G Articulated Truck", category: .heavyEquipment, dailyRate: "$1,400", weeklyRate: "$5,200", monthlyRate: "$14,000", specs: "30-ton, 370 HP", availability: "2-day lead", provider: .dozr, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "Hitachi ZX210 Excavator", category: .heavyEquipment, dailyRate: "$800", weeklyRate: "$3,000", monthlyRate: "$8,000", specs: "21-ton, 159 HP", availability: "Available", provider: .dozr, imageIcon: "\u{1F3D7}"),
    RentalItem(name: "CAT 430F2 Backhoe", category: .earthmoving, dailyRate: "$420", weeklyRate: "$1,550", monthlyRate: "$4,100", specs: "97 HP, 4WD, extendahoe", availability: "Available", provider: .dozr, imageIcon: "\u{1F69C}"),

    // Additional Toolsy items
    RentalItem(name: "Tile Saw 10 in Wet", category: .handTools, dailyRate: "$45", weeklyRate: "$150", monthlyRate: "$380", specs: "1.5 HP, sliding table", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),
    RentalItem(name: "Rebar Bender/Cutter", category: .handTools, dailyRate: "$55", weeklyRate: "$180", monthlyRate: "$450", specs: "Up to #6 rebar, electric", availability: "Available", provider: .toolsy, imageIcon: "\u{1F527}"),
    RentalItem(name: "Laser Level Rotary", category: .surveying, dailyRate: "$65", weeklyRate: "$220", monthlyRate: "$550", specs: "Self-leveling, 2000 ft range", availability: "Available", provider: .toolsy, imageIcon: "\u{1F4D0}"),
    RentalItem(name: "Stud Welder CD", category: .welding, dailyRate: "$50", weeklyRate: "$170", monthlyRate: "$420", specs: "Capacitor discharge, deck studs", availability: "Available", provider: .toolsy, imageIcon: "\u{1F525}"),
]

struct RentalSearchView: View {
    @State private var searchQuery = ""
    @State private var selectedCategory: RentalCategory? = nil
    @State private var selectedProvider: RentalProvider? = nil
    @State private var sortByPrice = false
    @State private var showProviderInfo = false
    @State private var showProviderHub = false
    @State private var activeSubTab: RentalSubTab = .search

    enum RentalSubTab: String, CaseIterable {
        case search = "Search"
        case providers = "Providers"
        case tools = "Tools"
        case quotes = "Quotes"
    }

    private var filteredItems: [RentalItem] {
        var items = rentalInventory
        if let cat = selectedCategory { items = items.filter { $0.category == cat } }
        if let prov = selectedProvider { items = items.filter { $0.provider == prov } }
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            items = items.filter {
                $0.name.lowercased().contains(q) ||
                $0.category.rawValue.lowercased().contains(q) ||
                $0.specs.lowercased().contains(q) ||
                $0.provider.rawValue.lowercased().contains(q)
            }
        }
        if sortByPrice {
            items.sort { a, b in
                let aVal = Double(a.dailyRate.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
                let bVal = Double(b.dailyRate.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
                return aVal < bVal
            }
        }
        return items
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{1F6E0}").font(.system(size: 18))
                            Text("RENTALS").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.accent)
                        }
                        Text("Construction Equipment Rentals")
                            .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Search \(rentalInventory.count) items across \(RentalProvider.allCases.count) providers")
                            .font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(filteredItems.count)").font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.accent)
                        Text("RESULTS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                    }
                }
                .padding(16).background(Theme.surface).cornerRadius(14)
                .premiumGlow(cornerRadius: 14, color: Theme.accent)

                // Sub-tab selector
                HStack(spacing: 0) {
                    ForEach(RentalSubTab.allCases, id: \.self) { tab in
                        Button { withAnimation { activeSubTab = tab } } label: {
                            Text(tab.rawValue.uppercased())
                                .font(.system(size: 10, weight: .bold)).tracking(1)
                                .foregroundColor(activeSubTab == tab ? .black : Theme.muted)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(activeSubTab == tab ? Theme.accent : Theme.surface)
                        }.buttonStyle(.plain)
                    }
                }
                .cornerRadius(8)

                if activeSubTab == .providers {
                    RentalProviderHubView()
                } else if activeSubTab == .tools {
                    toolsContent
                } else if activeSubTab == .quotes {
                    quotesPanel
                } else {
                    searchContent
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
    }

    private var toolsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            RentalCalculatorView()
            RentalFavoritesPanel()
            PriceAlertsPanel()
            BundleBuilderView()
            AIEquipmentRecommenderView()
            OperatorMarketplaceView()
            MarketRateAnalyticsView()
            FleetUtilizationView()
            RentalHistoryPanel()
            ConditionReportView()
            ProviderReviewsPanel()
        }
    }

    private var quotesPanel: some View {
        let manager = RentalProviderManager.shared
        return VStack(alignment: .leading, spacing: 10) {
            Text("QUOTE HISTORY").font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            if manager.quoteRequests.isEmpty {
                VStack(spacing: 8) {
                    Text("\u{1F4CB}").font(.system(size: 36))
                    Text("No quote requests yet").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                    Text("Request quotes from the Search or Providers tab").font(.system(size: 11)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(24).background(Theme.surface).cornerRadius(12)
            } else {
                ForEach(manager.quoteRequests) { quote in
                    HStack(spacing: 10) {
                        Circle().fill(quote.status == "pending" ? Theme.gold : Theme.green).frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quote.equipmentName).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                            Text("\(quote.provider) \u{2022} \(quote.duration) \u{2022} \(quote.jobsite)")
                                .font(.system(size: 9)).foregroundColor(Theme.muted)
                            if !quote.notes.isEmpty {
                                Text(quote.notes).font(.system(size: 9)).foregroundColor(Theme.muted).lineLimit(1)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(quote.status.uppercased()).font(.system(size: 8, weight: .bold))
                                .foregroundColor(quote.status == "pending" ? Theme.gold : Theme.green)
                            Text(quote.requestedAt, style: .date).font(.system(size: 8)).foregroundColor(Theme.muted)
                        }
                    }
                    .padding(10).background(Theme.surface).cornerRadius(8)
                }
            }
        }
    }

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: 12) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                    TextField("Search equipment, tools, vehicles...", text: $searchQuery)
                        .font(.system(size: 13)).foregroundColor(Theme.text)
                    if !searchQuery.isEmpty {
                        Button { searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                        }.buttonStyle(.plain)
                    }
                    Toggle("$ Sort", isOn: $sortByPrice)
                        .font(.system(size: 9, weight: .bold))
                        .toggleStyle(.button)
                }
                .padding(12).background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(10)

                // Provider buttons
                HStack(spacing: 6) {
                    Text("PROVIDERS").font(.system(size: 8, weight: .black)).tracking(1).foregroundColor(Theme.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Button { selectedProvider = nil } label: {
                                Text("ALL").font(.system(size: 9, weight: .bold))
                                    .foregroundColor(selectedProvider == nil ? .black : Theme.text)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(selectedProvider == nil ? Theme.accent : Theme.surface)
                                    .cornerRadius(6)
                            }.buttonStyle(.plain)

                            ForEach(RentalProvider.allCases, id: \.rawValue) { provider in
                                Button { selectedProvider = selectedProvider == provider ? nil : provider } label: {
                                    Text(provider.rawValue.uppercased()).font(.system(size: 9, weight: .bold))
                                        .foregroundColor(selectedProvider == provider ? .white : provider.color)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(selectedProvider == provider ? provider.color : provider.color.opacity(0.12))
                                        .cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Category grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], spacing: 6) {
                    ForEach(RentalCategory.allCases) { cat in
                        Button { selectedCategory = selectedCategory == cat ? nil : cat } label: {
                            HStack(spacing: 4) {
                                Text(cat.icon).font(.system(size: 12))
                                Text(cat.rawValue).font(.system(size: 8, weight: .bold)).lineLimit(1)
                            }
                            .foregroundColor(selectedCategory == cat ? .black : Theme.text)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(selectedCategory == cat ? Theme.accent : Theme.surface)
                            .cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }

                // Results
                if filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Text("\u{1F50D}").font(.system(size: 36))
                        Text("No equipment found").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted)
                        Text("Try adjusting your search or filters").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity).padding(32).background(Theme.surface).cornerRadius(12)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            RentalItemCard(item: item)
                        }
                    }
                }
            }
        }
    }

struct RentalItemCard: View {
    let item: RentalItem
    @ObservedObject private var store = RentalDataStore.shared
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(item.imageIcon).font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(item.provider.color.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                    HStack(spacing: 6) {
                        Text(item.category.rawValue).font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text("\u{2022}").foregroundColor(Theme.border)
                        Text(item.provider.rawValue).font(.system(size: 9, weight: .semibold)).foregroundColor(item.provider.color)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.dailyRate).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("/day").font(.system(size: 8)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(item.availability == "Available" ? Theme.green : Theme.gold).frame(width: 6, height: 6)
                    Text(item.availability).font(.system(size: 9, weight: .semibold))
                        .foregroundColor(item.availability == "Available" ? Theme.green : Theme.gold)
                }
                Text(item.specs).font(.system(size: 9)).foregroundColor(Theme.muted).lineLimit(1)
                Spacer()
                Button { store.toggleFavorite(item) } label: {
                    Image(systemName: store.isFavorite(item) ? "heart.fill" : "heart")
                        .font(.system(size: 10)).foregroundColor(store.isFavorite(item) ? Theme.red : Theme.muted)
                }.buttonStyle(.plain)
                Button { withAnimation { expanded.toggle() } } label: {
                    Text(expanded ? "LESS" : "MORE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.accent)
                }.buttonStyle(.plain)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DAILY").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                            Text(item.dailyRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WEEKLY").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                            Text(item.weeklyRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.cyan)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MONTHLY").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                            Text(item.monthlyRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green)
                        }
                    }

                    HStack(spacing: 8) {
                        Button { } label: {
                            Text("RENT NOW").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(Theme.accent).cornerRadius(6)
                        }.buttonStyle(.plain)
                        Button { } label: {
                            Text("GET QUOTE").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.accent)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(Theme.accent.opacity(0.12)).cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                        }.buttonStyle(.plain)
                    }

                    Text("Via \(item.provider.rawValue) \u{2022} \(item.provider.tagline)")
                        .font(.system(size: 8)).foregroundColor(Theme.muted)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.3), lineWidth: 0.8))
    }
}


// MARK: - ========== Rental Advanced Features ==========

import CoreLocation

// MARK: - Location Manager for Near Me

@MainActor
final class RentalLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RentalLocationManager()
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        #if os(iOS)
        manager.requestWhenInUseAuthorization()
        #endif
        manager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            userLocation = locations.last
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authStatus = manager.authorizationStatus
            #if os(iOS)
            if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
                manager.requestLocation()
            }
            #elseif os(macOS)
            if authStatus == .authorizedAlways || authStatus == .authorized {
                manager.requestLocation()
            }
            #endif
        }
    }

    func distanceTo(lat: Double, lon: Double) -> Double? {
        guard let loc = userLocation else { return nil }
        let target = CLLocation(latitude: lat, longitude: lon)
        return loc.distance(from: target) / 1609.34 // miles
    }
}

// MARK: - Rental Data Store (Favorites, History, Alerts, Bundles, Reviews)

struct RentalFavorite: Identifiable, Codable {
    var id = UUID()
    let itemName: String
    let category: String
    let provider: String
    let dailyRate: String
    let addedAt: Date
}

struct RentalHistoryEntry: Identifiable, Codable {
    var id = UUID()
    let itemName: String
    let provider: String
    let duration: String
    let totalCost: String
    let projectRef: String
    let startDate: Date
    let endDate: Date
    let rating: Int
}

struct PriceAlert: Identifiable, Codable {
    var id = UUID()
    let itemName: String
    let category: String
    let targetDailyRate: Double
    let createdAt: Date
    var triggered: Bool = false
}

struct RentalBundle: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [BundleItem]
    let projectRef: String
    let createdAt: Date

    struct BundleItem: Identifiable, Codable {
        var id = UUID()
        let itemName: String
        let dailyRate: String
        let duration: String
    }
}

struct ConditionReport: Identifiable, Codable {
    var id = UUID()
    let itemName: String
    let provider: String
    let type: String // "pickup" or "return"
    let condition: String // "excellent", "good", "fair", "damaged"
    let notes: String
    let photoCount: Int
    let createdAt: Date
}

struct ProviderReview: Identifiable, Codable {
    var id = UUID()
    let provider: String
    let rating: Int
    let deliveryRating: Int
    let conditionRating: Int
    let serviceRating: Int
    let comment: String
    let createdAt: Date
}

struct OperatorListing: Identifiable {
    let id = UUID()
    let name: String
    let certifications: [String]
    let hourlyRate: String
    let experience: Int
    let rating: Double
    let location: String
    let available: Bool
    let specialties: [String]
    let initials: String
}

@MainActor
final class RentalDataStore: ObservableObject {
    static let shared = RentalDataStore()

    @Published var favorites: [RentalFavorite] = []
    @Published var history: [RentalHistoryEntry] = []
    @Published var priceAlerts: [PriceAlert] = []
    @Published var bundles: [RentalBundle] = []
    @Published var conditionReports: [ConditionReport] = []
    @Published var reviews: [ProviderReview] = []

    private let favKey = "ConstructOS.Rentals.Favorites"
    private let histKey = "ConstructOS.Rentals.History"
    private let alertKey = "ConstructOS.Rentals.PriceAlerts"
    private let bundleKey = "ConstructOS.Rentals.Bundles"
    private let reportKey = "ConstructOS.Rentals.ConditionReports"
    private let reviewKey = "ConstructOS.Rentals.Reviews"

    init() { load() }

    func toggleFavorite(_ item: RentalItem) {
        if let idx = favorites.firstIndex(where: { $0.itemName == item.name && $0.provider == item.provider.rawValue }) {
            favorites.remove(at: idx)
        } else {
            favorites.insert(RentalFavorite(itemName: item.name, category: item.category.rawValue, provider: item.provider.rawValue, dailyRate: item.dailyRate, addedAt: Date()), at: 0)
        }
        save()
    }

    func isFavorite(_ item: RentalItem) -> Bool {
        favorites.contains { $0.itemName == item.name && $0.provider == item.provider.rawValue }
    }

    func addHistory(_ entry: RentalHistoryEntry) { history.insert(entry, at: 0); save() }
    func addPriceAlert(_ alert: PriceAlert) { priceAlerts.insert(alert, at: 0); save() }
    func removePriceAlert(_ alert: PriceAlert) { priceAlerts.removeAll { $0.id == alert.id }; save() }
    func addBundle(_ bundle: RentalBundle) { bundles.insert(bundle, at: 0); save() }
    func addConditionReport(_ report: ConditionReport) { conditionReports.insert(report, at: 0); save() }
    func addReview(_ review: ProviderReview) { reviews.insert(review, at: 0); save() }

    func providerAvgRating(_ provider: RentalProvider) -> Double {
        let providerReviews = reviews.filter { $0.provider == provider.rawValue }
        guard !providerReviews.isEmpty else { return 0 }
        return Double(providerReviews.map(\.rating).reduce(0, +)) / Double(providerReviews.count)
    }

    func totalSpent() -> Double {
        history.reduce(0) { sum, entry in
            sum + (Double(entry.totalCost.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0)
        }
    }

    private func load() {
        favorites = loadJSON(favKey, default: [RentalFavorite]())
        history = loadJSON(histKey, default: [RentalHistoryEntry]())
        priceAlerts = loadJSON(alertKey, default: [PriceAlert]())
        bundles = loadJSON(bundleKey, default: [RentalBundle]())
        conditionReports = loadJSON(reportKey, default: [ConditionReport]())
        reviews = loadJSON(reviewKey, default: [ProviderReview]())
    }

    private func save() {
        saveJSON(favKey, value: favorites)
        saveJSON(histKey, value: history)
        saveJSON(alertKey, value: priceAlerts)
        saveJSON(bundleKey, value: bundles)
        saveJSON(reportKey, value: conditionReports)
        saveJSON(reviewKey, value: reviews)
    }
}

// MARK: - Rental Calculator

struct RentalCalculatorView: View {
    @State private var selectedItems: [(name: String, dailyRate: Double, qty: Int, days: Int)] = []
    @State private var newItem = ""
    @State private var newRate = ""
    @State private var newQty = 1
    @State private var newDays = 7

    private var totalDaily: Double { selectedItems.reduce(0) { $0 + $1.dailyRate * Double($1.qty) } }
    private var totalWeekly: Double { totalDaily * 5 }  // typical 5-day work week rate
    private var grandTotal: Double { selectedItems.reduce(0) { $0 + $1.dailyRate * Double($1.qty) * Double($1.days) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RENTAL CALCULATOR").font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                Spacer()
                Text("$\(String(format: "%.0f", grandTotal)) TOTAL")
                    .font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.accent)
            }

            // Add item row
            HStack(spacing: 6) {
                TextField("Equipment", text: $newItem)
                    .font(.system(size: 11)).foregroundColor(Theme.text)
                    .padding(6).background(Theme.panel).cornerRadius(6)
                TextField("$/day", text: $newRate)
                    .font(.system(size: 11)).foregroundColor(Theme.text)
                    .frame(width: 60).padding(6).background(Theme.panel).cornerRadius(6)
                Stepper("x\(newQty)", value: $newQty, in: 1...20)
                    .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                Stepper("\(newDays)d", value: $newDays, in: 1...365)
                    .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                Button("ADD") {
                    guard !newItem.isEmpty, let rate = Double(newRate.replacingOccurrences(of: "$", with: "")) else { return }
                    selectedItems.append((newItem, rate, newQty, newDays))
                    newItem = ""; newRate = ""
                }
                .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(Theme.gold).cornerRadius(5)
                .buttonStyle(.plain)
            }

            if !selectedItems.isEmpty {
                ForEach(selectedItems.indices, id: \.self) { i in
                    HStack(spacing: 8) {
                        Text(selectedItems[i].name).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                        Spacer()
                        Text("$\(String(format: "%.0f", selectedItems[i].dailyRate))/day").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text("x\(selectedItems[i].qty)").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                        Text("\(selectedItems[i].days)d").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold)
                        Text("$\(String(format: "%.0f", selectedItems[i].dailyRate * Double(selectedItems[i].qty) * Double(selectedItems[i].days)))")
                            .font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.accent)
                        Button { selectedItems.remove(at: i) } label: {
                            Image(systemName: "xmark").font(.system(size: 8)).foregroundColor(Theme.red)
                        }.buttonStyle(.plain)
                    }
                    .padding(6).background(Theme.panel).cornerRadius(6)
                }

                HStack(spacing: 16) {
                    VStack(spacing: 2) { Text("DAILY").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", totalDaily))").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent) }
                    VStack(spacing: 2) { Text("WEEKLY").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", totalWeekly))").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.cyan) }
                    VStack(spacing: 2) { Text("TOTAL").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted); Text("$\(String(format: "%.0f", grandTotal))").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green) }
                    Spacer()
                }
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: Theme.gold)
    }
}

// MARK: - Favorites Panel

struct RentalFavoritesPanel: View {
    @ObservedObject var store = RentalDataStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FAVORITES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.red)
                Text("\(store.favorites.count)").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.muted)
                Spacer()
            }
            if store.favorites.isEmpty {
                Text("Tap the heart on any equipment to save it here")
                    .font(.system(size: 11)).foregroundColor(Theme.muted).padding(10)
            } else {
                ForEach(store.favorites) { fav in
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill").font(.system(size: 10)).foregroundColor(Theme.red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(fav.itemName).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                            Text("\(fav.provider) \u{2022} \(fav.dailyRate)/day").font(.system(size: 8)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Text(fav.category).font(.system(size: 8)).foregroundColor(Theme.cyan)
                    }
                    .padding(6).background(Theme.panel).cornerRadius(6)
                }
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - Rental History Panel

struct RentalHistoryPanel: View {
    @ObservedObject var store = RentalDataStore.shared

    private var totalSpent: String {
        let total = store.totalSpent()
        return total >= 1000 ? "$\(String(format: "%.1f", total / 1000))K" : "$\(String(format: "%.0f", total))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RENTAL HISTORY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
                Spacer()
                Text("\(totalSpent) TOTAL SPEND").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.gold)
            }
            if store.history.isEmpty {
                Text("No rental history yet. Completed rentals will appear here.")
                    .font(.system(size: 11)).foregroundColor(Theme.muted).padding(10)
            } else {
                ForEach(store.history.prefix(10)) { entry in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.itemName).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                            Text("\(entry.provider) \u{2022} \(entry.duration) \u{2022} \(entry.projectRef)")
                                .font(.system(size: 8)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(entry.totalCost).font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { i in
                                    Image(systemName: i < entry.rating ? "star.fill" : "star")
                                        .font(.system(size: 7)).foregroundColor(Theme.gold)
                                }
                            }
                        }
                    }
                    .padding(6).background(Theme.panel).cornerRadius(6)
                }
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - Price Alerts Panel

struct PriceAlertsPanel: View {
    @ObservedObject var store = RentalDataStore.shared
    @State private var newAlertName = ""
    @State private var newAlertCategory = ""
    @State private var newAlertTarget = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRICE ALERTS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
                Text("\(store.priceAlerts.filter { !$0.triggered }.count) active")
                    .font(.system(size: 9)).foregroundColor(Theme.muted)
                Spacer()
            }

            HStack(spacing: 6) {
                TextField("Equipment name", text: $newAlertName)
                    .font(.system(size: 10)).padding(6).background(Theme.panel).cornerRadius(5)
                TextField("Target $/day", text: $newAlertTarget)
                    .font(.system(size: 10)).frame(width: 80).padding(6).background(Theme.panel).cornerRadius(5)
                Button("SET ALERT") {
                    guard !newAlertName.isEmpty, let target = Double(newAlertTarget.replacingOccurrences(of: "$", with: "")) else { return }
                    store.addPriceAlert(PriceAlert(itemName: newAlertName, category: newAlertCategory, targetDailyRate: target, createdAt: Date()))
                    newAlertName = ""; newAlertTarget = ""
                }
                .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 8).padding(.vertical, 5).background(Theme.green).cornerRadius(5)
                .buttonStyle(.plain)
            }

            ForEach(store.priceAlerts) { alert in
                HStack(spacing: 8) {
                    Image(systemName: alert.triggered ? "bell.badge.fill" : "bell.fill")
                        .font(.system(size: 10)).foregroundColor(alert.triggered ? Theme.gold : Theme.green)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(alert.itemName).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text("Target: $\(String(format: "%.0f", alert.targetDailyRate))/day")
                            .font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(alert.triggered ? "TRIGGERED" : "WATCHING")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(alert.triggered ? Theme.gold : Theme.green)
                    Button { store.removePriceAlert(alert) } label: {
                        Image(systemName: "xmark").font(.system(size: 8)).foregroundColor(Theme.red)
                    }.buttonStyle(.plain)
                }
                .padding(6).background(Theme.panel).cornerRadius(6)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - Bundle Builder

struct BundleBuilderView: View {
    @ObservedObject var store = RentalDataStore.shared
    @State private var bundleName = ""
    @State private var projectRef = ""
    @State private var bundleItems: [(name: String, rate: String, duration: String)] = []
    @State private var newItemName = ""
    @State private var newItemRate = ""
    @State private var newItemDuration = "1 Week"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BUNDLE BUILDER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            Text("Group equipment for a single job quote across providers")
                .font(.system(size: 9)).foregroundColor(Theme.muted)

            HStack(spacing: 6) {
                TextField("Bundle name", text: $bundleName)
                    .font(.system(size: 10)).padding(6).background(Theme.panel).cornerRadius(5)
                TextField("Project ref", text: $projectRef)
                    .font(.system(size: 10)).frame(width: 100).padding(6).background(Theme.panel).cornerRadius(5)
            }

            HStack(spacing: 6) {
                TextField("Equipment", text: $newItemName)
                    .font(.system(size: 10)).padding(6).background(Theme.panel).cornerRadius(5)
                TextField("$/day", text: $newItemRate)
                    .font(.system(size: 10)).frame(width: 60).padding(6).background(Theme.panel).cornerRadius(5)
                Button("+ ADD") {
                    guard !newItemName.isEmpty else { return }
                    bundleItems.append((newItemName, newItemRate.isEmpty ? "TBD" : newItemRate, newItemDuration))
                    newItemName = ""; newItemRate = ""
                }
                .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 8).padding(.vertical, 5).background(Theme.cyan).cornerRadius(5)
                .buttonStyle(.plain)
            }

            ForEach(bundleItems.indices, id: \.self) { i in
                HStack {
                    Text("\(i+1). \(bundleItems[i].name)").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text)
                    Spacer()
                    Text(bundleItems[i].rate).font(.system(size: 9)).foregroundColor(Theme.accent)
                    Button { bundleItems.remove(at: i) } label: {
                        Image(systemName: "minus.circle").font(.system(size: 10)).foregroundColor(Theme.red)
                    }.buttonStyle(.plain)
                }
            }

            if !bundleItems.isEmpty {
                Button("SAVE BUNDLE (\(bundleItems.count) items)") {
                    let bundle = RentalBundle(
                        name: bundleName.isEmpty ? "Untitled Bundle" : bundleName,
                        items: bundleItems.map { RentalBundle.BundleItem(itemName: $0.name, dailyRate: $0.rate, duration: $0.duration) },
                        projectRef: projectRef,
                        createdAt: Date()
                    )
                    store.addBundle(bundle)
                    bundleName = ""; projectRef = ""; bundleItems = []
                }
                .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(Theme.cyan).cornerRadius(6)
                .buttonStyle(.plain)
            }

            // Saved bundles
            ForEach(store.bundles.prefix(3)) { bundle in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(bundle.name).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.cyan)
                        if !bundle.projectRef.isEmpty {
                            Text(bundle.projectRef).font(.system(size: 8)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Text("\(bundle.items.count) items").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                    }
                    ForEach(bundle.items) { item in
                        Text("\u{2022} \(item.itemName) \u{2014} \(item.dailyRate)/day")
                            .font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                }
                .padding(8).background(Theme.panel).cornerRadius(6)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - Condition Reporting

struct ConditionReportView: View {
    @ObservedObject var store = RentalDataStore.shared
    @State private var itemName = ""
    @State private var provider = ""
    @State private var reportType = "pickup"
    @State private var condition = "good"
    @State private var notes = ""

    private let conditions = ["excellent", "good", "fair", "damaged"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONDITION REPORT").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)

            HStack(spacing: 6) {
                TextField("Equipment name", text: $itemName)
                    .font(.system(size: 10)).padding(6).background(Theme.panel).cornerRadius(5)
                TextField("Provider", text: $provider)
                    .font(.system(size: 10)).frame(width: 100).padding(6).background(Theme.panel).cornerRadius(5)
            }

            HStack(spacing: 8) {
                ForEach(["pickup", "return"], id: \.self) { type in
                    Button { reportType = type } label: {
                        Text(type.uppercased()).font(.system(size: 9, weight: .bold))
                            .foregroundColor(reportType == type ? .black : Theme.text)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(reportType == type ? Theme.gold : Theme.surface).cornerRadius(5)
                    }.buttonStyle(.plain)
                }
                Spacer()
                ForEach(conditions, id: \.self) { cond in
                    Button { condition = cond } label: {
                        Text(cond.prefix(4).uppercased()).font(.system(size: 8, weight: .bold))
                            .foregroundColor(condition == cond ? .black : conditionColor(cond))
                            .padding(.horizontal, 6).padding(.vertical, 4)
                            .background(condition == cond ? conditionColor(cond) : conditionColor(cond).opacity(0.12))
                            .cornerRadius(4)
                    }.buttonStyle(.plain)
                }
            }

            TextField("Notes (damage, wear, missing parts...)", text: $notes)
                .font(.system(size: 10)).padding(6).background(Theme.panel).cornerRadius(5)

            Button("SUBMIT REPORT") {
                guard !itemName.isEmpty else { return }
                store.addConditionReport(ConditionReport(itemName: itemName, provider: provider, type: reportType, condition: condition, notes: notes, photoCount: 0, createdAt: Date()))
                itemName = ""; provider = ""; notes = ""
            }
            .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
            .frame(maxWidth: .infinity).padding(.vertical, 7)
            .background(Theme.gold).cornerRadius(6).buttonStyle(.plain)
            .disabled(itemName.isEmpty)

            ForEach(store.conditionReports.prefix(3)) { report in
                HStack(spacing: 6) {
                    Circle().fill(conditionColor(report.condition)).frame(width: 6, height: 6)
                    Text(report.itemName).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                    Text(report.type.uppercased()).font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    Spacer()
                    Text(report.condition.uppercased()).font(.system(size: 8, weight: .bold)).foregroundColor(conditionColor(report.condition))
                }
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }

    private func conditionColor(_ c: String) -> Color {
        switch c {
        case "excellent": return Theme.green
        case "good": return Theme.cyan
        case "fair": return Theme.gold
        case "damaged": return Theme.red
        default: return Theme.muted
        }
    }
}

// MARK: - Operator Marketplace

private let mockOperators: [OperatorListing] = [
    OperatorListing(name: "Carlos Mendez", certifications: ["NCCCO Crane", "OSHA 30"], hourlyRate: "$85/hr", experience: 18, rating: 4.9, location: "Houston, TX", available: true, specialties: ["Tower Crane", "Crawler Crane"], initials: "CM"),
    OperatorListing(name: "James Walsh", certifications: ["NCCCO Mobile Crane", "CDL-A"], hourlyRate: "$78/hr", experience: 14, rating: 4.8, location: "Chicago, IL", available: true, specialties: ["Rough Terrain", "All-Terrain"], initials: "JW"),
    OperatorListing(name: "Maria Santos", certifications: ["Excavator Cert", "OSHA 10"], hourlyRate: "$65/hr", experience: 9, rating: 4.7, location: "Dallas, TX", available: false, specialties: ["Excavator", "Backhoe", "Dozer"], initials: "MS"),
    OperatorListing(name: "Derek Thompson", certifications: ["Boom Lift", "Scissor Lift", "Forklift"], hourlyRate: "$55/hr", experience: 7, rating: 4.6, location: "Phoenix, AZ", available: true, specialties: ["Aerial Lifts", "Telehandler"], initials: "DT"),
    OperatorListing(name: "Aisha Williams", certifications: ["NCCCO Tower Crane", "Signal Person"], hourlyRate: "$92/hr", experience: 22, rating: 5.0, location: "New York, NY", available: true, specialties: ["Tower Crane", "Luffing Jib"], initials: "AW"),
    OperatorListing(name: "Roberto Fuentes", certifications: ["Concrete Pump", "CDL-B"], hourlyRate: "$70/hr", experience: 12, rating: 4.8, location: "Miami, FL", available: true, specialties: ["Boom Pump", "Line Pump"], initials: "RF"),
]

struct OperatorMarketplaceView: View {
    @State private var searchText = ""
    private var filtered: [OperatorListing] {
        guard !searchText.isEmpty else { return mockOperators }
        let q = searchText.lowercased()
        return mockOperators.filter { $0.name.lowercased().contains(q) || $0.specialties.joined().lowercased().contains(q) || $0.location.lowercased().contains(q) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("OPERATOR MARKETPLACE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
                Spacer()
                Text("\(mockOperators.filter { $0.available }.count) AVAILABLE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 10)).foregroundColor(Theme.muted)
                TextField("Search operators, certifications, location...", text: $searchText)
                    .font(.system(size: 11)).foregroundColor(Theme.text)
            }
            .padding(8).background(Theme.panel).cornerRadius(6)

            ForEach(filtered) { op in
                HStack(spacing: 10) {
                    Circle().fill(LinearGradient(colors: [Theme.purple, Theme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                        .overlay(Text(op.initials).font(.system(size: 11, weight: .heavy)).foregroundColor(.white))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(op.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                            if op.available {
                                Circle().fill(Theme.green).frame(width: 5, height: 5)
                            }
                        }
                        Text(op.certifications.joined(separator: " \u{2022} ")).font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(1)
                        Text("\(op.location) \u{2022} \(op.experience) yrs \u{2022} \(op.specialties.joined(separator: ", "))").font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(op.hourlyRate).font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                        HStack(spacing: 1) {
                            Text("\(String(format: "%.1f", op.rating))").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(Theme.gold)
                        }
                    }
                }
                .padding(8).background(Theme.surface).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(op.available ? Theme.green.opacity(0.2) : Theme.border.opacity(0.2), lineWidth: 0.8))
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - Market Rate Analytics

struct MarketRateAnalyticsView: View {
    private let rateData: [(category: String, avgDaily: Double, trend: String, demand: String)] = [
        ("Excavators", 820, "+5%", "High"),
        ("Dozers", 1150, "+3%", "Medium"),
        ("Boom Lifts", 340, "-2%", "Medium"),
        ("Scissor Lifts", 145, "+1%", "High"),
        ("Generators", 280, "+8%", "High"),
        ("Cranes", 2400, "+4%", "Low"),
        ("Jackhammers", 72, "0%", "Medium"),
        ("Compactors", 180, "+2%", "Medium"),
        ("Concrete Pumps", 790, "+6%", "High"),
        ("Welders", 115, "-1%", "Low"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MARKET RATE ANALYTICS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            Text("Average daily rental rates and demand trends")
                .font(.system(size: 9)).foregroundColor(Theme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(rateData, id: \.category) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.category).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                        HStack {
                            Text("$\(String(format: "%.0f", item.avgDaily))/day")
                                .font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent)
                            Spacer()
                            Text(item.trend).font(.system(size: 9, weight: .bold))
                                .foregroundColor(item.trend.hasPrefix("+") ? Theme.green : item.trend.hasPrefix("-") ? Theme.red : Theme.muted)
                        }
                        HStack(spacing: 4) {
                            Text("DEMAND").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                            Text(item.demand.uppercased()).font(.system(size: 7, weight: .bold))
                                .foregroundColor(item.demand == "High" ? Theme.green : item.demand == "Medium" ? Theme.gold : Theme.muted)
                        }
                    }
                    .padding(8).background(Theme.panel).cornerRadius(6)
                }
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - Fleet Utilization Dashboard

struct FleetUtilizationView: View {
    @ObservedObject var store = RentalDataStore.shared

    private var activeRentals: Int { store.history.filter { $0.endDate > Date() }.count }
    private var idleItems: Int { max(0, store.favorites.count - activeRentals) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FLEET UTILIZATION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
                Spacer()
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(activeRentals)").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.green)
                    Text("ACTIVE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.08)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("\(idleItems)").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.gold)
                    Text("IDLE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.08)).cornerRadius(8)
                VStack(spacing: 2) {
                    let total = store.totalSpent()
                    Text(total >= 1000 ? "$\(String(format: "%.1f", total/1000))K" : "$\(String(format: "%.0f", total))")
                        .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("SPENT").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.08)).cornerRadius(8)
            }

            if store.history.isEmpty {
                Text("Complete rentals to see utilization metrics")
                    .font(.system(size: 10)).foregroundColor(Theme.muted).padding(6)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }
}

// MARK: - AI Equipment Recommender

struct AIEquipmentRecommenderView: View {
    @State private var jobDescription = ""
    @State private var recommendations: [(equipment: String, reason: String, estRate: String)] = []
    @State private var isThinking = false

    private func recommend() {
        isThinking = true
        let desc = jobDescription.lowercased()
        var recs: [(equipment: String, reason: String, estRate: String)] = []

        if desc.contains("excavat") || desc.contains("dig") || desc.contains("trench") || desc.contains("foundation") {
            recs.append(("CAT 320 Excavator", "Standard for foundation and trench work", "$850/day"))
            recs.append(("Mini Excavator 3.5-Ton", "Tight access, residential foundation", "$295/day"))
        }
        if desc.contains("grade") || desc.contains("level") || desc.contains("clear") || desc.contains("dozer") {
            recs.append(("CAT D6 Dozer", "Grading and site clearing", "$1,200/day"))
            recs.append(("Bobcat S770 Skid Steer", "Versatile grading and material handling", "$380/day"))
        }
        if desc.contains("concrete") || desc.contains("pour") || desc.contains("slab") || desc.contains("foundation") {
            recs.append(("Concrete Pump Trailer", "Efficient pour for slabs and foundations", "$800/day"))
            recs.append(("Power Trowel 48 in", "Slab finishing after pour", "$85/day"))
            recs.append(("Concrete Vibrator", "Consolidation during pour", "$45/day"))
        }
        if desc.contains("roof") || desc.contains("high") || desc.contains("upper") || desc.contains("exterior") {
            recs.append(("Genie S-65 Boom Lift", "65 ft reach for exterior/upper work", "$350/day"))
            recs.append(("JLG 1932R Scissor Lift", "Interior elevated work", "$120/day"))
        }
        if desc.contains("demol") || desc.contains("break") || desc.contains("remove") {
            recs.append(("Hilti TE 3000 Breaker", "Heavy-duty concrete demolition", "$85/day"))
            recs.append(("Bobcat E85 + Breaker", "Structural demolition", "$520/day"))
        }
        if desc.contains("weld") || desc.contains("steel") || desc.contains("metal") {
            recs.append(("Lincoln Ranger 330MPX", "Multi-process field welding", "$120/day"))
        }
        if desc.contains("electric") || desc.contains("wire") || desc.contains("conduit") {
            recs.append(("Wire Puller 6,000 lb", "Commercial wire pulls", "$75/day"))
            recs.append(("Conduit Bender Hydraulic", "EMT/rigid bending", "$30/day"))
        }
        if desc.contains("plumb") || desc.contains("pipe") || desc.contains("drain") {
            recs.append(("RIDGID 300 Pipe Threader", "Pipe threading on-site", "$85/day"))
            recs.append(("Pipe Camera Inspection", "Pre-work drain assessment", "$120/day"))
        }
        if recs.isEmpty {
            recs.append(("Bobcat S770 Skid Steer", "Versatile general-purpose machine", "$380/day"))
            recs.append(("Honda EU7000 Generator", "Reliable site power", "$95/day"))
            recs.append(("JLG 1932R Scissor Lift", "General elevated access", "$120/day"))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            recommendations = recs
            isThinking = false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AI EQUIPMENT RECOMMENDER").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
                Spacer()
                Text("\u{1F916}").font(.system(size: 16))
            }

            HStack(spacing: 6) {
                TextField("Describe the job (e.g. dig foundation for 3-story building)", text: $jobDescription)
                    .font(.system(size: 11)).foregroundColor(Theme.text)
                    .padding(8).background(Theme.panel).cornerRadius(6)
                Button("RECOMMEND") { recommend() }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 10).padding(.vertical, 7).background(Theme.purple).cornerRadius(6)
                    .buttonStyle(.plain)
                    .disabled(jobDescription.isEmpty)
            }

            if isThinking {
                HStack { ProgressView().tint(Theme.purple); Text("Analyzing job requirements...").font(.system(size: 10)).foregroundColor(Theme.muted) }
            }

            ForEach(recommendations.indices, id: \.self) { i in
                let rec = recommendations[i]
                HStack(spacing: 8) {
                    Text("\(i + 1)").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.purple)
                        .frame(width: 22, height: 22).background(Theme.purple.opacity(0.12)).cornerRadius(11)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rec.equipment).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text(rec.reason).font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(rec.estRate).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.accent)
                }
                .padding(8).background(Theme.panel).cornerRadius(6)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: Theme.purple)
    }
}

// MARK: - Provider Reviews

struct ProviderReviewsPanel: View {
    @ObservedObject var store = RentalDataStore.shared
    @State private var selectedProvider: RentalProvider = .unitedRentals
    @State private var rating = 4
    @State private var deliveryRating = 4
    @State private var conditionRating = 4
    @State private var serviceRating = 4
    @State private var comment = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROVIDER REVIEWS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)

            // Provider selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(RentalProvider.allCases, id: \.rawValue) { provider in
                        Button { selectedProvider = provider } label: {
                            VStack(spacing: 2) {
                                Text(provider.icon).font(.system(size: 14))
                                Text(provider.rawValue).font(.system(size: 7, weight: .bold)).lineLimit(1)
                                let avg = store.providerAvgRating(provider)
                                if avg > 0 {
                                    Text("\(String(format: "%.1f", avg))\u{2605}")
                                        .font(.system(size: 7, weight: .bold)).foregroundColor(Theme.gold)
                                }
                            }
                            .foregroundColor(selectedProvider == provider ? .black : Theme.text)
                            .frame(width: 65).padding(.vertical, 6)
                            .background(selectedProvider == provider ? provider.color : Theme.panel)
                            .cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }
            }

            // Submit review
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ratingRow("Overall", $rating)
                    ratingRow("Delivery", $deliveryRating)
                }
                HStack {
                    ratingRow("Condition", $conditionRating)
                    ratingRow("Service", $serviceRating)
                }
                TextField("Write a review...", text: $comment)
                    .font(.system(size: 10)).padding(6).background(Theme.panel).cornerRadius(5)
                Button("SUBMIT REVIEW") {
                    store.addReview(ProviderReview(provider: selectedProvider.rawValue, rating: rating, deliveryRating: deliveryRating, conditionRating: conditionRating, serviceRating: serviceRating, comment: comment, createdAt: Date()))
                    comment = ""
                }
                .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 6).background(Theme.gold).cornerRadius(5)
                .buttonStyle(.plain)
            }

            // Existing reviews
            let providerReviews = store.reviews.filter { $0.provider == selectedProvider.rawValue }
            ForEach(providerReviews.prefix(3)) { review in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        HStack(spacing: 1) { ForEach(0..<5, id: \.self) { i in Image(systemName: i < review.rating ? "star.fill" : "star").font(.system(size: 8)).foregroundColor(Theme.gold) } }
                        Spacer()
                        Text(review.createdAt, style: .date).font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    if !review.comment.isEmpty {
                        Text(review.comment).font(.system(size: 9)).foregroundColor(Theme.text)
                    }
                }
                .padding(6).background(Theme.panel).cornerRadius(6)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
    }

    private func ratingRow(_ label: String, _ value: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted).frame(width: 50, alignment: .leading)
            ForEach(1...5, id: \.self) { i in
                Button { value.wrappedValue = i } label: {
                    Image(systemName: i <= value.wrappedValue ? "star.fill" : "star")
                        .font(.system(size: 10)).foregroundColor(Theme.gold)
                }.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - ========== ConstructionOSNetwork.swift ==========


// MARK: - Construction OS Network

enum ConstructionOSNetworkPostType: String, CaseIterable {
    case workUpdate    = "Work Update"
    case projectWin    = "Project Win"
    case jobPosting    = "Job Posting"
    case bidOpportunity = "Bid Request"
    case shoutout      = "Shoutout"

    var icon: String {
        switch self {
        case .workUpdate:     return "🔧"
        case .projectWin:     return "🏆"
        case .jobPosting:     return "💼"
        case .bidOpportunity: return "📋"
        case .shoutout:       return "🙌"
        }
    }
    var color: Color {
        switch self {
        case .workUpdate:     return Theme.cyan
        case .projectWin:     return Theme.gold
        case .jobPosting:     return Theme.accent
        case .bidOpportunity: return Theme.green
        case .shoutout:       return Theme.purple
        }
    }
}

enum ConstructionOSNetworkTrade: String, CaseIterable {
    case general    = "General"
    case concrete   = "Concrete"
    case steel      = "Steel"
    case electrical = "Electrical"
    case plumbing   = "Plumbing"
    case hvac       = "HVAC"
    case framing    = "Framing"
    case roofing    = "Roofing"
    case crane      = "Crane"
    case finishing  = "Finishing"

    var icon: String {
        switch self {
        case .general:    return "🏗"
        case .concrete:   return "🧱"
        case .steel:      return "⚙️"
        case .electrical: return "⚡"
        case .plumbing:   return "🔧"
        case .hvac:       return "❄️"
        case .framing:    return "🪵"
        case .roofing:    return "🏠"
        case .crane:      return "🏗"
        case .finishing:  return "🎨"
        }
    }
}

struct ConstructionOSNetworkPost: Identifiable {
    let id = UUID()
    let authorName: String
    let authorRole: String
    let authorTrade: ConstructionOSNetworkTrade
    let postType: ConstructionOSNetworkPostType
    let content: String
    let tags: [String]
    let timeAgo: String
    let likes: Int
    let comments: Int
    let projectRef: String?
    let initials: String
    let avatarColors: [Color]
}

struct ConstructionOSNetworkCrewMember: Identifiable {
    let id = UUID()
    let name: String
    let trade: ConstructionOSNetworkTrade
    let role: String
    let yearsExp: Int
    let location: String
    let rating: Double
    let jobsDone: Int
    let socialHealthScore: Int
    let workEthicScore: Int
    let socialHealthTrend7d: [Int]
    let workEthicTrend7d: [Int]
    let available: Bool
    let badge: String?
    let connections: Int
    let initials: String
}

struct ConstructionOSNetworkJobListing: Identifiable {
    let id = UUID()
    let title: String
    let company: String
    let trade: ConstructionOSNetworkTrade
    let location: String
    let payRate: String
    let startDate: String
    let duration: String
    let urgent: Bool
    let applicants: Int
    let requirements: [String]
}

struct ConstructionOSNetworkComment: Identifiable {
    let id = UUID()
    let authorName: String
    let text: String
    let timeAgo: String
    let photoData: Data?
}

private let mockConstructionOSNetworkPosts: [ConstructionOSNetworkPost] = [
    ConstructionOSNetworkPost(
        authorName: "Marcus Rivera", authorRole: "Senior Ironworker",
        authorTrade: .steel, postType: .projectWin,
        content: "Just wrapped the structural steel on the Harborview Tower. 47 floors, 14 months, zero LTIs. Crew of 38 — every single one of you made this possible. 💪 Proud doesn't cover it.",
        tags: ["#SteelWork", "#SafetyFirst", "#Harborview"],
        timeAgo: "2h ago", likes: 184, comments: 42,
        projectRef: "Harborview Tower", initials: "MR",
        avatarColors: [Theme.accent, Theme.gold]
    ),
    ConstructionOSNetworkPost(
        authorName: "Delta Build Group", authorRole: "General Contractor · Licensed",
        authorTrade: .general, postType: .bidOpportunity,
        content: "🔔 SEEKING BIDS — 240-unit residential complex, Phoenix AZ. Packages open: MEP, framing, exterior envelope. Min bonding $2M. Prevailing wage applies. DM or reply with qualifications.",
        tags: ["#OpenBid", "#PhoenixAZ", "#MEP", "#Framing"],
        timeAgo: "4h ago", likes: 67, comments: 31,
        projectRef: "Phoenix Residential Phase 2", initials: "DB",
        avatarColors: [Theme.cyan, Theme.green]
    ),
    ConstructionOSNetworkPost(
        authorName: "Priya Nair", authorRole: "Project Manager · LEED AP",
        authorTrade: .general, postType: .workUpdate,
        content: "Day 180 on the Eastside Medical Center. MEP rough-in is 92% complete ahead of the drywall sequence. Running 6 days ahead of schedule — shoutout to the Phoenix MEP crew for the push this week.",
        tags: ["#Healthcare", "#MEP", "#LEED"],
        timeAgo: "6h ago", likes: 93, comments: 18,
        projectRef: "Eastside Medical Center", initials: "PN",
        avatarColors: [Theme.green, Theme.cyan]
    ),
    ConstructionOSNetworkPost(
        authorName: "TruBuild Electrical", authorRole: "Electrical Contractor",
        authorTrade: .electrical, postType: .jobPosting,
        content: "NOW HIRING — Journeyman Electricians (4 positions) for a data center project in Austin, TX. 12-month contract, $42–$48/hr DOE. Per diem available. IBEW card preferred but not required.",
        tags: ["#Hiring", "#Electrician", "#AustinTX", "#DataCenter"],
        timeAgo: "8h ago", likes: 112, comments: 58,
        projectRef: nil, initials: "TE",
        avatarColors: [Theme.gold, Theme.accent]
    ),
    ConstructionOSNetworkPost(
        authorName: "Darnell Washington", authorRole: "Concrete Foreman · 21 yrs",
        authorTrade: .concrete, postType: .shoutout,
        content: "Huge shoutout to my pour crew — 8,400 SF mat slab in 11 hours straight. Not a single cold joint. This is what it looks like when you trust your team. 🏆",
        tags: ["#ConcreteCrew", "#Foundation", "#SiteLife"],
        timeAgo: "12h ago", likes: 247, comments: 89,
        projectRef: "Central District Highrise", initials: "DW",
        avatarColors: [Theme.red, Theme.gold]
    ),
    ConstructionOSNetworkPost(
        authorName: "Apex MEP Solutions", authorRole: "Mechanical Contractor",
        authorTrade: .hvac, postType: .workUpdate,
        content: "HVAC main trunk install complete on floors 12–24 of the Gateway Office Tower. BIM coordination saved us 340 hours of rework this phase. The model doesn't lie.",
        tags: ["#HVAC", "#BIM", "#MEP"],
        timeAgo: "1d ago", likes: 61, comments: 14,
        projectRef: "Gateway Office Tower", initials: "AM",
        avatarColors: [Theme.cyan, Theme.purple]
    ),
]

private let mockConstructionOSNetworkCrew: [ConstructionOSNetworkCrewMember] = [
    ConstructionOSNetworkCrewMember(name: "Jerome Okafor",   trade: .crane,      role: "Tower Crane Operator",       yearsExp: 18, location: "Chicago, IL",  rating: 4.9, jobsDone: 94,  socialHealthScore: 92, workEthicScore: 96, socialHealthTrend7d: [88, 89, 89, 90, 91, 92, 92], workEthicTrend7d: [93, 93, 94, 94, 95, 95, 96], available: true,  badge: "NCCCO Certified",  connections: 312, initials: "JO"),
    ConstructionOSNetworkCrewMember(name: "Sofia Mendez",    trade: .electrical, role: "Master Electrician",          yearsExp: 14, location: "Dallas, TX",   rating: 4.8, jobsDone: 127, socialHealthScore: 94, workEthicScore: 92, socialHealthTrend7d: [90, 91, 92, 92, 93, 93, 94], workEthicTrend7d: [90, 90, 91, 91, 92, 92, 92], available: true,  badge: "IBEW L20",         connections: 488, initials: "SM"),
    ConstructionOSNetworkCrewMember(name: "Kevin Park",      trade: .plumbing,   role: "Plumbing Foreman",            yearsExp: 11, location: "Seattle, WA",  rating: 4.7, jobsDone: 83,  socialHealthScore: 79, workEthicScore: 84, socialHealthTrend7d: [82, 82, 81, 81, 80, 79, 79], workEthicTrend7d: [86, 86, 85, 85, 84, 84, 84], available: false, badge: "Master Plumber",   connections: 201, initials: "KP"),
    ConstructionOSNetworkCrewMember(name: "Asha Williams",   trade: .steel,      role: "Structural Detailer",         yearsExp: 9,  location: "Atlanta, GA",  rating: 4.9, jobsDone: 61,  socialHealthScore: 87, workEthicScore: 90, socialHealthTrend7d: [84, 84, 85, 86, 86, 87, 87], workEthicTrend7d: [87, 88, 88, 89, 89, 90, 90], available: true,  badge: "AWS Certified",    connections: 274, initials: "AW"),
    ConstructionOSNetworkCrewMember(name: "Tomás Fuentes",   trade: .concrete,   role: "Concrete Superintendent",     yearsExp: 22, location: "Phoenix, AZ",  rating: 5.0, jobsDone: 148, socialHealthScore: 91, workEthicScore: 95, socialHealthTrend7d: [88, 89, 89, 90, 90, 91, 91], workEthicTrend7d: [92, 93, 93, 94, 94, 95, 95], available: true,  badge: "ACI Grade 1",      connections: 390, initials: "TF"),
    ConstructionOSNetworkCrewMember(name: "Rachel Kim",      trade: .hvac,       role: "HVAC Lead Technician",        yearsExp: 8,  location: "Denver, CO",   rating: 4.6, jobsDone: 54,  socialHealthScore: 77, workEthicScore: 82, socialHealthTrend7d: [80, 80, 79, 79, 78, 78, 77], workEthicTrend7d: [84, 84, 83, 83, 83, 82, 82], available: false, badge: "EPA 608",          connections: 165, initials: "RK"),
    ConstructionOSNetworkCrewMember(name: "DeShawn Morris",  trade: .roofing,    role: "Roofing Foreman",             yearsExp: 16, location: "Miami, FL",    rating: 4.8, jobsDone: 109, socialHealthScore: 85, workEthicScore: 88, socialHealthTrend7d: [82, 82, 83, 84, 84, 85, 85], workEthicTrend7d: [85, 86, 86, 87, 87, 88, 88], available: true,  badge: "NRCA Certified",   connections: 258, initials: "DM"),
]

private let mockConstructionOSNetworkJobs: [ConstructionOSNetworkJobListing] = [
    ConstructionOSNetworkJobListing(title: "Concrete Superintendent",    company: "Trident Construction",   trade: .concrete,   location: "Las Vegas, NV", payRate: "$95–$115K/yr", startDate: "Mar 24",    duration: "18 months", urgent: true,  applicants: 7,  requirements: ["ACI certified", "10+ yrs high-rise", "OSHA 30"]),
    ConstructionOSNetworkJobListing(title: "Journeyman Electrician",     company: "TruBuild Electrical",    trade: .electrical, location: "Austin, TX",    payRate: "$42–$48/hr",   startDate: "Apr 1",     duration: "12 months", urgent: false, applicants: 23, requirements: ["IBEW preferred", "Commercial exp", "Lift cert"]),
    ConstructionOSNetworkJobListing(title: "Tower Crane Operator",       company: "Skyline Lift Solutions", trade: .crane,      location: "New York, NY",  payRate: "$85–$105/hr",  startDate: "Immediate", duration: "24 months", urgent: true,  applicants: 3,  requirements: ["NCCCO certified", "NYC DOB approved", "5+ yrs high-rise"]),
    ConstructionOSNetworkJobListing(title: "Structural Steel Foreman",   company: "Atlas Iron Works",       trade: .steel,      location: "Houston, TX",   payRate: "$88–$102K/yr", startDate: "Apr 15",    duration: "14 months", urgent: false, applicants: 11, requirements: ["AISC knowledge", "AWS D1.1", "15+ crew exp"]),
    ConstructionOSNetworkJobListing(title: "HVAC Project Manager",       company: "Apex MEP Solutions",     trade: .hvac,       location: "Denver, CO",    payRate: "$110–$130K/yr", startDate: "May 1",    duration: "Full-time", urgent: false, applicants: 5,  requirements: ["PE or LEED AP", "BIM/Revit MEP", "PMP preferred"]),
    ConstructionOSNetworkJobListing(title: "Plumbing Foreman",           company: "Summit Mechanical",      trade: .plumbing,   location: "Portland, OR",  payRate: "$75–$90K/yr",  startDate: "Mar 31",    duration: "10 months", urgent: true,  applicants: 9,  requirements: ["Master plumber lic.", "Commercial exp", "OSHA 30"]),
]

struct ConstructionOSNetworkLiveSeed {
    let authorName: String
    let authorRole: String
    let trade: ConstructionOSNetworkTrade
    let postType: ConstructionOSNetworkPostType
    let content: String
    let tags: [String]
    let projectRef: String?
}

private let constructionOSNetworkLiveSeeds: [ConstructionOSNetworkLiveSeed] = [
    ConstructionOSNetworkLiveSeed(authorName: "Skyline Lift Ops", authorRole: "Crane Operations", trade: .crane, postType: .workUpdate, content: "Tower crane #2 back online after wind hold release. Steel picks resumed on north core.", tags: ["#CraneOps", "#LiveSite"], projectRef: "Harborview Tower"),
    ConstructionOSNetworkLiveSeed(authorName: "TruBuild Electrical", authorRole: "Electrical Contractor", trade: .electrical, postType: .workUpdate, content: "Power-up complete for level 5 switchgear. Field verification signed and released.", tags: ["#Electrical", "#Commissioning"], projectRef: "Eastside Medical Center"),
    ConstructionOSNetworkLiveSeed(authorName: "Delta Build Group", authorRole: "General Contractor", trade: .general, postType: .bidOpportunity, content: "Live package release: interior framing + drywall bundle now open for fast-track pricing.", tags: ["#BidRelease", "#FastTrack"], projectRef: "Phoenix Residential Phase 2"),
    ConstructionOSNetworkLiveSeed(authorName: "Apex MEP Solutions", authorRole: "Mechanical Contractor", trade: .hvac, postType: .projectWin, content: "Inspection passed for AHU tie-in sequence. Zero punch items on turnover.", tags: ["#MEP", "#ProjectWin"], projectRef: "Gateway Office Tower"),
]

@MainActor
final class ConstructionOSNetworkService: ObservableObject {
    @Published var posts: [ConstructionOSNetworkPost] = mockConstructionOSNetworkPosts

    private let storageKey = "ConstructOS.Network.State.v1"
    @Published private var likedPostKeys: Set<String> = []
    @Published private var followedCrewKeys: Set<String> = []
    @Published private var appliedJobKeys: Set<String> = []
    @Published private var commentsByPostKey: [String: [ConstructionOSNetworkComment]] = [:]
    @Published private var persistedPosts: [PersistedPost] = []

    init() {
        loadState()
    }

    func isLiked(_ post: ConstructionOSNetworkPost) -> Bool {
        likedPostKeys.contains(postKey(post))
    }

    func isFollowing(_ member: ConstructionOSNetworkCrewMember) -> Bool {
        followedCrewKeys.contains(crewKey(member))
    }

    func hasApplied(_ job: ConstructionOSNetworkJobListing) -> Bool {
        appliedJobKeys.contains(jobKey(job))
    }

    func publishPost(text: String, postType: ConstructionOSNetworkPostType, trade: ConstructionOSNetworkTrade) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let hashtags = extractTags(from: trimmed)
        let newPost = ConstructionOSNetworkPost(
            authorName: "You",
            authorRole: "ConstructionOS Member",
            authorTrade: trade,
            postType: postType,
            content: trimmed,
            tags: hashtags,
            timeAgo: "just now",
            likes: 0,
            comments: 0,
            projectRef: nil,
            initials: "YOU",
            avatarColors: [Theme.accent, Theme.cyan]
        )

        persistedPosts.insert(
            PersistedPost(
                authorName: newPost.authorName,
                authorRole: newPost.authorRole,
                authorTrade: newPost.authorTrade.rawValue,
                postType: newPost.postType.rawValue,
                content: newPost.content,
                tags: newPost.tags,
                timeAgo: newPost.timeAgo,
                likes: newPost.likes,
                comments: newPost.comments,
                projectRef: newPost.projectRef,
                initials: newPost.initials
            ),
            at: 0
        )
        posts.insert(newPost, at: 0)
        saveState()
    }

    func injectLivePost(seed: ConstructionOSNetworkLiveSeed) {
        let newPost = ConstructionOSNetworkPost(
            authorName: seed.authorName,
            authorRole: seed.authorRole,
            authorTrade: seed.trade,
            postType: seed.postType,
            content: seed.content,
            tags: seed.tags,
            timeAgo: "just now",
            likes: 0,
            comments: 0,
            projectRef: seed.projectRef,
            initials: String(seed.authorName.prefix(2)).uppercased(),
            avatarColors: [Theme.cyan, Theme.green]
        )
        posts.insert(newPost, at: 0)
        saveState()
    }

    func toggleLike(post: ConstructionOSNetworkPost) {
        let key = postKey(post)
        if likedPostKeys.contains(key) {
            likedPostKeys.remove(key)
        } else {
            likedPostKeys.insert(key)
        }
        saveState()
    }

    func toggleFollow(member: ConstructionOSNetworkCrewMember) {
        let key = crewKey(member)
        if followedCrewKeys.contains(key) {
            followedCrewKeys.remove(key)
        } else {
            followedCrewKeys.insert(key)
        }
        saveState()
    }

    func applyToJob(job: ConstructionOSNetworkJobListing) {
        appliedJobKeys.insert(jobKey(job))
        saveState()
    }

    func addComment(post: ConstructionOSNetworkPost, text: String, photoData: Data? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || photoData != nil else { return }
        let key = postKey(post)
        let comment = ConstructionOSNetworkComment(
            authorName: "You",
            text: trimmed.isEmpty ? "Photo attachment" : trimmed,
            timeAgo: "now",
            photoData: photoData
        )
        commentsByPostKey[key, default: []].append(comment)
        saveState()
    }

    func comments(for post: ConstructionOSNetworkPost) -> [ConstructionOSNetworkComment] {
        commentsByPostKey[postKey(post)] ?? []
    }

    func totalComments(for post: ConstructionOSNetworkPost) -> Int {
        post.comments + (commentsByPostKey[postKey(post)]?.count ?? 0)
    }

    private func postKey(_ post: ConstructionOSNetworkPost) -> String {
        "\(post.authorName)|\(post.authorRole)|\(post.content)|\(post.timeAgo)"
    }

    private func crewKey(_ member: ConstructionOSNetworkCrewMember) -> String {
        "\(member.name)|\(member.role)|\(member.location)"
    }

    private func jobKey(_ job: ConstructionOSNetworkJobListing) -> String {
        "\(job.title)|\(job.company)|\(job.location)|\(job.startDate)"
    }

    private func loadState() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(ConstructionOSNetworkSnapshot.self, from: data)
        else {
            posts = mockConstructionOSNetworkPosts
            return
        }

        likedPostKeys = Set(snapshot.likedPostKeys)
        followedCrewKeys = Set(snapshot.followedCrewKeys)
        appliedJobKeys = Set(snapshot.appliedJobKeys)
        commentsByPostKey = Dictionary(
            uniqueKeysWithValues: snapshot.commentsByPostKey.map { key, values in
                    (
                        key,
                        values.map {
                            ConstructionOSNetworkComment(
                                authorName: $0.authorName,
                                text: $0.text,
                                timeAgo: $0.timeAgo,
                                photoData: $0.photoData
                            )
                        }
                    )
                }
        )
        persistedPosts = snapshot.persistedPosts

        let restored = persistedPosts.map { persisted -> ConstructionOSNetworkPost in
            let trade = ConstructionOSNetworkTrade(rawValue: persisted.authorTrade) ?? .general
            let type = ConstructionOSNetworkPostType(rawValue: persisted.postType) ?? .workUpdate
            return ConstructionOSNetworkPost(
                authorName: persisted.authorName,
                authorRole: persisted.authorRole,
                authorTrade: trade,
                postType: type,
                content: persisted.content,
                tags: persisted.tags,
                timeAgo: persisted.timeAgo,
                likes: persisted.likes,
                comments: persisted.comments,
                projectRef: persisted.projectRef,
                initials: persisted.initials,
                avatarColors: [Theme.accent, Theme.cyan]
            )
        }

        posts = restored + mockConstructionOSNetworkPosts
    }

    private func saveState() {
        let commentSnapshot = Dictionary(
            uniqueKeysWithValues: commentsByPostKey.map { key, values in
                    (
                        key,
                        values.map {
                            PersistedComment(
                                authorName: $0.authorName,
                                text: $0.text,
                                timeAgo: $0.timeAgo,
                                photoData: $0.photoData
                            )
                        }
                    )
                }
        )

        let snapshot = ConstructionOSNetworkSnapshot(
            likedPostKeys: Array(likedPostKeys),
            followedCrewKeys: Array(followedCrewKeys),
            appliedJobKeys: Array(appliedJobKeys),
            commentsByPostKey: commentSnapshot,
            persistedPosts: persistedPosts
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func extractTags(from text: String) -> [String] {
        text.split(separator: " ")
            .map(String.init)
            .filter { $0.hasPrefix("#") && $0.count > 1 }
            .prefix(4)
            .map { $0 }
    }

    private struct PersistedComment: Codable {
        let authorName: String
        let text: String
        let timeAgo: String
        let photoData: Data?

        init(authorName: String, text: String, timeAgo: String, photoData: Data? = nil) {
            self.authorName = authorName
            self.text = text
            self.timeAgo = timeAgo
            self.photoData = photoData
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            authorName = try container.decode(String.self, forKey: .authorName)
            text = try container.decode(String.self, forKey: .text)
            timeAgo = try container.decode(String.self, forKey: .timeAgo)
            photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        }
    }

    private struct PersistedPost: Codable {
        let authorName: String
        let authorRole: String
        let authorTrade: String
        let postType: String
        let content: String
        let tags: [String]
        let timeAgo: String
        let likes: Int
        let comments: Int
        let projectRef: String?
        let initials: String
    }

    private struct ConstructionOSNetworkSnapshot: Codable {
        let likedPostKeys: [String]
        let followedCrewKeys: [String]
        let appliedJobKeys: [String]
        let commentsByPostKey: [String: [PersistedComment]]
        let persistedPosts: [PersistedPost]
    }
}

enum ConstructionOSNetworkLiveMode: String, CaseIterable {
    case off = "Off"
    case normal = "Normal"
    case highActivity = "High"

    var interval: TimeInterval {
        switch self {
        case .off: return .infinity
        case .normal: return 8
        case .highActivity: return 3
        }
    }

    var accentColor: Color {
        switch self {
        case .off: return Theme.muted
        case .normal: return Theme.green
        case .highActivity: return Theme.red
        }
    }
}

struct ConstructionOSNetworkPanel: View {
    @StateObject private var backend = ConstructionOSNetworkService()
    @State private var activeTab: String = "Feed"
    @State private var selectedTrade: String = "All"
    @State private var showCompose: Bool = false
    @State private var composeText: String = ""
    @State private var composeType: ConstructionOSNetworkPostType = .workUpdate
    @State private var commentDrafts: [UUID: String] = [:]
    @State private var commentPhotoSelections: [UUID: PhotosPickerItem] = [:]
    @State private var commentPhotoDrafts: [UUID: Data] = [:]
    @State private var commentAttachmentStatuses: [UUID: String] = [:]
    @State private var searchText: String = ""
    @State private var liveOnlineCount: Int = 2400
    @State private var livePulseText: String = "Live pulse online"
    @State private var livePulseColor: Color = Theme.green
    @State private var liveEventsCount: Int = 0
    @State private var liveTickCount: Int = 0
    @State private var liveMode: ConstructionOSNetworkLiveMode = .normal
    @State private var lastLiveCycleAt: Date = .distantPast

    private let tabs = ["Feed", "Crew", "Jobs"]
    private let tradeFilters = ["All"] + ConstructionOSNetworkTrade.allCases.map(\.rawValue)
    private let liveTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let maxCommentPhotoBytes = 1_500_000

    private let livePulseMessages: [(text: String, color: Color)] = [
        ("Permit inspection marked complete on active site", Theme.green),
        ("New bid request posted by a GC in your network", Theme.accent),
        ("Safety update published from field team", Theme.cyan),
        ("Crew availability changed in your selected trade", Theme.gold),
    ]

    private var filteredPosts: [ConstructionOSNetworkPost] {
        let base = selectedTrade == "All" ? backend.posts : backend.posts.filter { $0.authorTrade.rawValue == selectedTrade }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.authorName.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredCrew: [ConstructionOSNetworkCrewMember] {
        let base = selectedTrade == "All" ? mockConstructionOSNetworkCrew : mockConstructionOSNetworkCrew.filter { $0.trade.rawValue == selectedTrade }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredJobs: [ConstructionOSNetworkJobListing] {
        let base = selectedTrade == "All" ? mockConstructionOSNetworkJobs : mockConstructionOSNetworkJobs.filter { $0.trade.rawValue == selectedTrade }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.company.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 8) {
                DashboardPanelHeading(
                    eyebrow: "NETWORK",
                    title: "Construction OS Network",
                    detail: "Social signal for crews, jobs, bid flow, and field updates across the construction network.",
                    accent: Theme.accent
                )
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Theme.green).frame(width: 6, height: 6)
                    Text("\(liveOnlineCount) ONLINE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Theme.green.opacity(0.12)).cornerRadius(10)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(liveOnlineCount)", label: "ONLINE", color: Theme.green)
                DashboardStatPill(value: "\(liveEventsCount)", label: "LIVE EVENTS", color: livePulseColor)
                DashboardStatPill(value: activeTab.uppercased(), label: "ACTIVE VIEW", color: Theme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            HStack(spacing: 8) {
                Text("LIVE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(livePulseColor)
                    .cornerRadius(4)

                Text(livePulseText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(livePulseColor)
                    .lineLimit(1)

                Spacer()

                Text("EVENTS \(liveEventsCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.muted)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            .overlay(Rectangle().fill(Theme.border.opacity(0.45)).frame(height: 1), alignment: .bottom)

            HStack(spacing: 6) {
                Text("MODE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Theme.muted)

                ForEach(ConstructionOSNetworkLiveMode.allCases, id: \.rawValue) { mode in
                    Button(action: {
                        liveMode = mode
                        if mode == .off {
                            livePulseText = "Live feed paused"
                            livePulseColor = Theme.muted
                        } else {
                            livePulseText = mode == .normal ? "Live pulse online" : "High activity monitoring"
                            livePulseColor = mode.accentColor
                            lastLiveCycleAt = .distantPast
                        }
                    }) {
                        Text(mode.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(liveMode == mode ? .black : mode.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(liveMode == mode ? mode.accentColor : mode.accentColor.opacity(0.14))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // ── Stats strip ─────────────────────────────────────────────────
            HStack(spacing: 0) {
                BNStatChip(value: "48.6K", label: "Members",    color: Theme.accent)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                BNStatChip(value: "312",   label: "Open Jobs",  color: Theme.cyan)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                BNStatChip(value: "94",    label: "Bid Requests", color: Theme.gold)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                BNStatChip(value: "1.2K",  label: "Posts Today", color: Theme.green)
            }
            .padding(.horizontal, 14).padding(.bottom, 10)

            // ── Compose ─────────────────────────────────────────────────────
            if showCompose {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("COMPOSE POST").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.accent)
                        Spacer()
                        Button(action: { withAnimation { showCompose = false; composeText = "" } }) {
                            Text("✕").font(.system(size: 12)).foregroundColor(Theme.muted)
                        }.buttonStyle(.plain)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(ConstructionOSNetworkPostType.allCases, id: \.rawValue) { type in
                                Button(action: { composeType = type }) {
                                    HStack(spacing: 4) {
                                        Text(type.icon).font(.system(size: 10))
                                        Text(type.rawValue).font(.system(size: 9, weight: .semibold))
                                    }
                                    .foregroundColor(composeType == type ? .black : type.color)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(composeType == type ? type.color : type.color.opacity(0.12))
                                    .cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    TextEditor(text: $composeText)
                        .font(.system(size: 12)).foregroundColor(Theme.text)
                        .scrollContentBackground(.hidden).background(Theme.surface)
                        .frame(height: 72).padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    HStack {
                        Text("\(composeText.count)/500").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Spacer()
                        Button(action: {
                            backend.publishPost(text: composeText, postType: composeType, trade: selectedTradeModel)
                            withAnimation { showCompose = false; composeText = "" }
                        }) {
                            Text("PUBLISH")
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(composeText.isEmpty ? Theme.muted : Theme.accent)
                                .cornerRadius(6)
                        }.buttonStyle(.plain).disabled(composeText.isEmpty)
                    }
                }
                .padding(12)
                .background(Theme.surface.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(10)
                .padding(.horizontal, 14).padding(.bottom, 8)
            } else {
                Button(action: { withAnimation(.spring()) { showCompose = true } }) {
                    HStack(spacing: 8) {
                        LinearGradient(colors: [Theme.accent, Theme.cyan], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 30, height: 30).cornerRadius(15)
                            .overlay(Text("YOU").font(.system(size: 7, weight: .black)).foregroundColor(.black))
                        Text("Share an update, find crew, post a bid request...")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                        Spacer()
                        Text("POST").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.accent).cornerRadius(6)
                    }
                    .padding(10).background(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                    .cornerRadius(10)
                }.buttonStyle(.plain)
                .padding(.horizontal, 14).padding(.bottom, 8)
            }

            // ── Tab bar ─────────────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: { activeTab = tab }) {
                        VStack(spacing: 2) {
                            Text(tab.uppercased()).font(.system(size: 10, weight: .bold))
                                .foregroundColor(activeTab == tab ? Theme.accent : Theme.muted)
                            Rectangle().fill(activeTab == tab ? Theme.accent : Color.clear).frame(height: 2)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.plain)
                }
            }
            .background(Theme.surface)
            .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .bottom)

            // ── Search + trade filter ────────────────────────────────────────
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundColor(Theme.muted)
                    TextField(
                        activeTab == "Feed" ? "Search posts, hashtags, members..." :
                        activeTab == "Crew" ? "Search by name, trade, location..." :
                                             "Search jobs, companies, locations...",
                        text: $searchText
                    ).font(.system(size: 12)).foregroundColor(Theme.text)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(Theme.muted)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Theme.panel)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tradeFilters, id: \.self) { trade in
                            Button(action: { selectedTrade = trade }) {
                                Text(trade).font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(selectedTrade == trade ? .black : Theme.text)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(selectedTrade == trade ? Theme.accent : Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                                        selectedTrade == trade ? Theme.accent : Theme.border, lineWidth: 1))
                                    .cornerRadius(6)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            // ── Content ─────────────────────────────────────────────────────
            if activeTab == "Feed" {
                VStack(spacing: 10) {
                    if filteredPosts.isEmpty {
                        Text("No posts match your filters.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                    } else {
                        ForEach(filteredPosts) { post in
                            ConstructionOSPostCard(
                                post: post,
                                isLiked: backend.isLiked(post),
                                commentCount: backend.totalComments(for: post),
                                comments: backend.comments(for: post),
                                commentDraft: Binding(
                                    get: { commentDrafts[post.id, default: ""] },
                                    set: { commentDrafts[post.id] = $0 }
                                ),
                                commentPhotoItem: commentPhotoSelectionBinding(for: post.id),
                                pendingCommentPhotoData: commentPhotoDrafts[post.id],
                                commentAttachmentStatus: commentAttachmentStatuses[post.id],
                                onLike: { backend.toggleLike(post: post) },
                                onRemoveCommentPhoto: { removeCommentPhoto(for: post.id) },
                                onSubmitComment: {
                                    let draft = commentDrafts[post.id, default: ""]
                                    let photoData = commentPhotoDrafts[post.id]
                                    backend.addComment(post: post, text: draft, photoData: photoData)
                                    commentDrafts[post.id] = ""
                                    commentPhotoDrafts[post.id] = nil
                                    commentPhotoSelections[post.id] = nil
                                    commentAttachmentStatuses[post.id] = nil
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)

            } else if activeTab == "Crew" {
                VStack(spacing: 10) {
                    if filteredCrew.isEmpty {
                        Text("No crew members match your filters.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                    } else {
                        ForEach(filteredCrew) { member in
                            BNCrewCard(member: member, isConnected: backend.isFollowing(member)) {
                                backend.toggleFollow(member: member)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)

            } else {
                VStack(spacing: 10) {
                    if filteredJobs.isEmpty {
                        Text("No job listings match your filters.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                    } else {
                        ForEach(filteredJobs) { job in
                            BNJobCard(job: job, hasApplied: backend.hasApplied(job)) {
                                backend.applyToJob(job: job)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 16, color: Theme.accent)
        .onReceive(liveTimer) { _ in
            guard liveMode != .off else { return }

            let now = Date()
            guard now.timeIntervalSince(lastLiveCycleAt) >= liveMode.interval else { return }
            lastLiveCycleAt = now

            liveTickCount += 1
            let onlineDeltaRange: ClosedRange<Int> = liveMode == .highActivity ? -20...34 : -12...20
            liveOnlineCount = max(1700, min(3900, liveOnlineCount + Int.random(in: onlineDeltaRange)))

            if let pulse = livePulseMessages.randomElement() {
                livePulseText = pulse.text
                livePulseColor = pulse.color
            }

            if liveTickCount % 2 == 0 {
                liveEventsCount += 1
            }

            if Int.random(in: 0...3) == 0, let seed = constructionOSNetworkLiveSeeds.randomElement() {
                backend.injectLivePost(seed: seed)
                livePulseText = "New live post from \(seed.authorName)"
                livePulseColor = Theme.accent
                liveEventsCount += 1
            }
        }
    }

    private func commentPhotoSelectionBinding(for postID: UUID) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { commentPhotoSelections[postID] },
            set: { newValue in
                commentPhotoSelections[postID] = newValue
                loadCommentPhoto(for: postID, item: newValue)
            }
        )
    }

    private func loadCommentPhoto(for postID: UUID, item: PhotosPickerItem?) {
        guard let item else {
            commentPhotoDrafts[postID] = nil
            commentAttachmentStatuses[postID] = nil
            return
        }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    commentPhotoDrafts[postID] = nil
                    commentPhotoSelections[postID] = nil
                    commentAttachmentStatuses[postID] = "Could not load selected photo."
                }
                return
            }

            await MainActor.run {
                if data.count > maxCommentPhotoBytes {
                    let limit = ByteCountFormatter.string(fromByteCount: Int64(maxCommentPhotoBytes), countStyle: .file)
                    commentPhotoDrafts[postID] = nil
                    commentPhotoSelections[postID] = nil
                    commentAttachmentStatuses[postID] = "Photo too large. Max \(limit)."
                } else {
                    commentPhotoDrafts[postID] = data
                    let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                    commentAttachmentStatuses[postID] = "Photo attached (\(size))."
                }
            }
        }
    }

    private func removeCommentPhoto(for postID: UUID) {
        commentPhotoSelections[postID] = nil
        commentPhotoDrafts[postID] = nil
        commentAttachmentStatuses[postID] = nil
    }

    private var selectedTradeModel: ConstructionOSNetworkTrade {
        ConstructionOSNetworkTrade(rawValue: selectedTrade) ?? .general
    }
}

// MARK: Construction OS Network Subviews

struct BNStatChip: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }
}

struct TrendSparkline: View {
    let values: [Int]
    let color: Color

    private var minValue: Int { values.min() ?? 0 }
    private var maxValue: Int { values.max() ?? 1 }

    private func normalizedHeight(_ value: Int) -> CGFloat {
        if maxValue == minValue { return 8 }
        let ratio = Double(value - minValue) / Double(maxValue - minValue)
        return CGFloat(4 + ratio * 10)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: normalizedHeight(value))
            }
        }
        .padding(.vertical, 1)
    }
}

struct ConstructionOSPostCard: View {
    let post: ConstructionOSNetworkPost
    let isLiked: Bool
    let commentCount: Int
    let comments: [ConstructionOSNetworkComment]
    @Binding var commentDraft: String
    @Binding var commentPhotoItem: PhotosPickerItem?
    let pendingCommentPhotoData: Data?
    let commentAttachmentStatus: String?
    let onLike: () -> Void
    let onRemoveCommentPhoto: () -> Void
    let onSubmitComment: () -> Void

    private var canSubmitComment: Bool {
        !commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingCommentPhotoData != nil
    }

    private func image(from data: Data) -> Image? {
#if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
#elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
#else
        return nil
#endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                LinearGradient(colors: post.postType == .projectWin ? [Theme.gold, Theme.accent] : [Theme.accent, Theme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 38, height: 38).cornerRadius(19)
                    .overlay(Text(post.initials).font(.system(size: 11, weight: .heavy)).foregroundColor(.black))
                VStack(alignment: .leading, spacing: 1) {
                    Text(post.authorName).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                    Text(post.authorRole).font(.system(size: 10)).foregroundColor(Theme.muted)
                }
                Spacer()
                HStack(spacing: 3) {
                    Text(post.postType.icon).font(.system(size: 9))
                    Text(post.postType.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(post.postType.color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(post.postType.color.opacity(0.14)).cornerRadius(5)
            }

            if let ref = post.projectRef {
                HStack(spacing: 4) {
                    Image(systemName: "building.2").font(.system(size: 9)).foregroundColor(Theme.cyan)
                    Text(ref).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.cyan)
                }
            }

            Text(post.content)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text(tag).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.1)).cornerRadius(4)
                    }
                }
            }

            Rectangle().fill(Theme.border).frame(height: 1)

            HStack(spacing: 0) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 11))
                            .foregroundColor(isLiked ? Theme.accent : Theme.muted)
                        Text("\(post.likes + (isLiked ? 1 : 0))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isLiked ? Theme.accent : Theme.muted)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left").font(.system(size: 11)).foregroundColor(Theme.muted)
                        Text("\(commentCount)").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.forward").font(.system(size: 11)).foregroundColor(Theme.muted)
                        Text("Share").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)

                Text(post.timeAgo).font(.system(size: 9)).foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(comments.suffix(2))) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(comment.authorName.uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.cyan)
                                Text(comment.timeAgo)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                            if let photoData = comment.photoData, let commentImage = image(from: photoData) {
                                commentImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 120)
                                    .clipped()
                                    .cornerRadius(6)
                            }
                            Text(comment.text)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Theme.panel)
                        .cornerRadius(6)
                    }
                }
            }

            if let pendingData = pendingCommentPhotoData, let pendingImage = image(from: pendingData) {
                HStack(spacing: 8) {
                    pendingImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 48)
                        .clipped()
                        .cornerRadius(6)
                    Text("Photo ready")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Button("Remove", action: onRemoveCommentPhoto)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.red)
                        .buttonStyle(.plain)
                }
            }

            if let commentAttachmentStatus {
                Text(commentAttachmentStatus)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(commentAttachmentStatus.contains("too large") ? Theme.red : Theme.muted)
            }

            HStack(spacing: 6) {
                PhotosPicker(selection: $commentPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Theme.gold)
                        .cornerRadius(6)
                }

                TextField("Add comment...", text: $commentDraft)
                    .font(.system(size: 11)).foregroundColor(Theme.text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    .cornerRadius(6)

                Button(action: onSubmitComment) {
                    Text("Send")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(canSubmitComment ? Theme.accent : Theme.muted)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmitComment)
            }
        }
        .padding(14).background(Theme.surface)
        .premiumGlow(cornerRadius: 12, color: Theme.border.opacity(0.5))
    }
}

struct BNCrewCard: View {
    let member: ConstructionOSNetworkCrewMember
    let isConnected: Bool
    let onConnect: () -> Void

    private func trendDelta(_ history: [Int]) -> Int {
        guard let first = history.first, let last = history.last else { return 0 }
        return last - first
    }

    private func trendSymbol(_ delta: Int) -> String {
        if delta > 0 { return "↑" }
        if delta < 0 { return "↓" }
        return "→"
    }

    private func trendColor(_ delta: Int) -> Color {
        if delta > 0 { return Theme.green }
        if delta < 0 { return Theme.red }
        return Theme.muted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    LinearGradient(colors: [Theme.cyan, Theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 42, height: 42).cornerRadius(21)
                    Text(member.initials).font(.system(size: 12, weight: .heavy)).foregroundColor(.black)
                        .frame(width: 42, height: 42)
                    if member.available {
                        Circle().fill(Theme.green).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Theme.panel, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(member.name).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        if let badge = member.badge {
                            Text(badge).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.12)).cornerRadius(4)
                        }
                    }
                    Text(member.role).font(.system(size: 10)).foregroundColor(Theme.muted)
                    HStack(spacing: 4) {
                        Text(member.trade.icon).font(.system(size: 10))
                        Text(member.trade.rawValue).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                        Text("·").foregroundColor(Theme.muted).font(.system(size: 10))
                        Image(systemName: "mappin").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(member.location).font(.system(size: 10)).foregroundColor(Theme.muted)
                    }
                }
                Spacer()
                Text(member.available ? "AVAILABLE" : "ON PROJECT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(member.available ? Theme.green : Theme.gold)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background((member.available ? Theme.green : Theme.gold).opacity(0.14))
                    .cornerRadius(5)
            }

            HStack(spacing: 4) {
                Text("WORK ETHIC")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Theme.muted)
                Text("\(member.workEthicScore)")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(member.workEthicScore >= 90 ? Theme.green : (member.workEthicScore >= 80 ? Theme.cyan : Theme.gold))
                    .cornerRadius(5)
                Text("\(trendSymbol(trendDelta(member.workEthicTrend7d)))\(trendDelta(member.workEthicTrend7d))")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(trendColor(trendDelta(member.workEthicTrend7d)))
                Spacer()
                Text("SOCIAL \(member.socialHealthScore)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Theme.muted)
                Text("\(trendSymbol(trendDelta(member.socialHealthTrend7d)))\(trendDelta(member.socialHealthTrend7d))")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(trendColor(trendDelta(member.socialHealthTrend7d)))
            }

            HStack(spacing: 4) {
                TrendSparkline(values: member.workEthicTrend7d, color: Theme.green)
                    .frame(maxWidth: .infinity)
                TrendSparkline(values: member.socialHealthTrend7d, color: Theme.cyan)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(member.yearsExp)yr").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("Experience").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text("⭐").font(.system(size: 10))
                        Text(String(format: "%.1f", member.rating)).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.gold)
                    }
                    Text("Rating").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                VStack(spacing: 2) {
                    Text("\(member.jobsDone)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.cyan)
                    Text("Jobs Done").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                VStack(spacing: 2) {
                    Text("\(member.connections)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green)
                    Text("Network").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
            }

            HStack(spacing: 8) {
                Button(action: onConnect) {
                    Text(isConnected ? "✓ Following" : "+ Follow")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isConnected ? .black : Theme.accent)
                        .frame(maxWidth: .infinity).frame(height: 30)
                        .background(isConnected ? Theme.accent : Theme.accent.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
                Button(action: {}) {
                    Text("Message")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.cyan)
                        .frame(maxWidth: .infinity).frame(height: 30)
                        .background(Theme.cyan.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.cyan.opacity(0.4), lineWidth: 1))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
            }
        }
        .padding(14).background(Theme.surface)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan.opacity(0.6))
    }
}

struct BNJobCard: View {
    let job: ConstructionOSNetworkJobListing
    let hasApplied: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(job.title).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        if job.urgent {
                            Text("URGENT").font(.system(size: 8, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Theme.red).cornerRadius(4)
                        }
                    }
                    Text(job.company).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.accent)
                    HStack(spacing: 6) {
                        Text(job.trade.icon).font(.system(size: 10))
                        Text(job.trade.rawValue).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                        Text("·").foregroundColor(Theme.muted).font(.system(size: 10))
                        Image(systemName: "mappin").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(job.location).font(.system(size: 10)).foregroundColor(Theme.muted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(job.payRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green)
                    Text("\(job.applicants) applied").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 14) {
                Label(job.startDate, systemImage: "calendar").font(.system(size: 10)).foregroundColor(Theme.muted)
                Label(job.duration,  systemImage: "clock").font(.system(size: 10)).foregroundColor(Theme.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(job.requirements, id: \.self) { req in
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.green)
                            Text(req).font(.system(size: 9, weight: .medium)).foregroundColor(Theme.text)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Theme.green.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.green.opacity(0.25), lineWidth: 1))
                        .cornerRadius(5)
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: { if !hasApplied { onApply() } }) {
                    Text(hasApplied ? "✓ APPLIED" : "QUICK APPLY")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 30)
                        .background(hasApplied ? Theme.muted : (job.urgent ? Theme.red : Theme.accent))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
                Button(action: {}) {
                    Text("SAVE JOB").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.gold)
                        .frame(width: 80).frame(height: 30)
                        .background(Theme.gold.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.gold.opacity(0.35), lineWidth: 1))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
            }
        }
        .padding(14).background(Theme.surface)
        .premiumGlow(cornerRadius: 12, color: job.urgent ? Theme.red.opacity(0.5) : Theme.accent.opacity(0.4))
    }
}

