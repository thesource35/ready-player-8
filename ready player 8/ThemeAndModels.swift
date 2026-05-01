import Combine
import Foundation
import MapKit
import Security
import SwiftUI

// MARK: - ========== ThemeAndModels.swift ==========

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTRUCTIONOS — Theme, Models & Mock Data
// ═══════════════════════════════════════════════════════════════════════════════

// MARK: - ConstructOS namespace
// Container for feature-scoped static constants (AppStorage keys, feature flags, etc.).
// Pattern: ConstructOS.{Feature}.{Property} — see also ConstructOS.Video (Phase 22),
// ConstructOS.Wealth.*, ConstructOS.AngelicAI.*, ConstructOS.Integrations.Backend.*.
enum ConstructOS {}

// MARK: - Theme System (Dark + Light mode)
struct Theme {
    // Dark mode colors (default)
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

    // Adaptive colors — use these in views for automatic light/dark support
    static let adaptiveBg = Color("AdaptiveBg", bundle: nil)._resolvedOrFallback(dark: bg, light: Color(red: 0.96, green: 0.97, blue: 0.98))
    static let adaptiveSurface = Color._adaptive(dark: surface, light: Color.white)
    static let adaptivePanel = Color._adaptive(dark: panel, light: Color(red: 0.94, green: 0.95, blue: 0.96))
    static let adaptiveText = Color._adaptive(dark: text, light: Color(red: 0.10, green: 0.12, blue: 0.14))
    static let adaptiveMuted = Color._adaptive(dark: muted, light: Color(red: 0.45, green: 0.50, blue: 0.55))
    static let adaptiveBorder = Color._adaptive(dark: border, light: Color(red: 0.85, green: 0.87, blue: 0.90))
}

// MARK: - Adaptive Color Helper

extension Color {
    static func _adaptive(dark: Color, light: Color) -> Color {
        // Returns the appropriate color based on color scheme
        // Views should wrap in: @Environment(\.colorScheme) var colorScheme
        // For now, returns dark (app is dark-first). Views can use:
        //   colorScheme == .dark ? Theme.bg : Theme.adaptiveBg
        return dark
    }

    func _resolvedOrFallback(dark: Color, light: Color) -> Color {
        return dark
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Apply scaled font that respects Dynamic Type settings
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.font(.system(size: size, weight: weight, design: design))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// Constrain Dynamic Type to readable sizes (prevents extreme scaling)
    func constrainedDynamicType() -> some View {
        self.dynamicTypeSize(.small...DynamicTypeSize.xxxLarge)
    }
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

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    enum Role: String, Codable { case user, ai }
    enum DeliveryState: String, Codable {
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
//
// 999.5 (d) Tier 3: bundle-gate user-data simulation arrays so App Store
// release builds never ship realistic-looking fake company names.
// In Release: empty arrays — unconfigured users see the existing DEMO MODE
// banner over an empty list (explicit "configure your backend" affordance
// already lives on AuthGateView via 999.5 c). In Debug: rich demo data
// preserved for development.
#if DEBUG
let mockProjects = [
    Project(name: "Nexus Tower Complex", client: "Summit Dev Group", type: "Commercial High-Rise", status: "On Track", progress: 67, budget: "$42.8M", score: "9.4", team: "48 crew", likes: 1247, comments: 89, shares: 234),
    Project(name: "Riverside Lofts", client: "Urban Renewal LLC", type: "Mixed-Use Residential", status: "Delayed", progress: 34, budget: "$8.1M", score: "7.8", team: "22 crew", likes: 534, comments: 41, shares: 89),
    Project(name: "Harbor Industrial Park", client: "Port Authority", type: "Industrial", status: "On Track", progress: 89, budget: "$19.4M", score: "9.7", team: "61 crew", likes: 2103, comments: 156, shares: 445),
    Project(name: "Tech Campus Phase II", client: "InnovateCorp", type: "Commercial Office", status: "Ahead", progress: 52, budget: "$67.2M", score: "9.1", team: "104 crew", likes: 3841, comments: 267, shares: 891),
]
#else
let mockProjects: [Project] = []
#endif

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

#if DEBUG
let mockMarketData = [
    MarketData(city: "New York", vacancy: 12.4, newBiz: 847, closed: 203, trend: "up"),
    MarketData(city: "Los Angeles", vacancy: 9.8, newBiz: 612, closed: 178, trend: "up"),
    MarketData(city: "Chicago", vacancy: 15.2, newBiz: 441, closed: 267, trend: "down"),
    MarketData(city: "Houston", vacancy: 8.1, newBiz: 723, closed: 145, trend: "up"),
    MarketData(city: "London", vacancy: 11.3, newBiz: 934, closed: 312, trend: "neutral"),
    MarketData(city: "Dubai", vacancy: 6.7, newBiz: 1204, closed: 89, trend: "up"),
]
#else
let mockMarketData: [MarketData] = []
#endif

#if DEBUG
let mockContracts = [
    ContractOpportunity(title: "West Loop Medical Tower", client: "Meridian Health Partners", location: "Chicago, IL", sector: "Healthcare", stage: "Open For Bid", package: "Core & Shell", budget: "$28.4M", bidDue: "Apr 18", liveFeedStatus: "3D map + drone online", bidders: 16, score: 96, watchCount: 482),
    ContractOpportunity(title: "Portside Logistics Hub", client: "Atlas Freight Group", location: "Houston, TX", sector: "Industrial", stage: "Prequalifying Teams", package: "Site + Structural", budget: "$61.9M", bidDue: "Apr 26", liveFeedStatus: "Satellite refresh every 4h", bidders: 23, score: 92, watchCount: 615),
    ContractOpportunity(title: "Crown District Residences", client: "Urban Frontier Dev Co", location: "Dubai, UAE", sector: "Mixed-Use", stage: "Negotiation", package: "MEP + Interiors", budget: "$44.7M", bidDue: "May 02", liveFeedStatus: "Live tower cam active", bidders: 11, score: 94, watchCount: 338),
]
#else
let mockContracts: [ContractOpportunity] = []
#endif

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
