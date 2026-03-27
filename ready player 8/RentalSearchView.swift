import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


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
// MARK: - Provider Account (linked subscriber accounts)

struct ProviderAccount: Codable, Identifiable {
    var id = UUID()
    let provider: String
    var email: String
    var accountNumber: String
    var accountName: String
    var accountType: String       // "individual", "business", "enterprise"
    var creditLimit: String
    var paymentMethod: String     // "invoice", "credit_card", "po_number"
    var poNumber: String
    var isVerified: Bool
    var linkedAt: Date
    var lastSyncAt: Date?
    var activeRentals: Int
    var totalSpent: String
    var tier: String              // "standard", "gold", "platinum", "national"
    var discountPercent: Double
    var deliveryAddresses: [String]
    var apiToken: String?         // stored in Keychain, not UserDefaults
}

final class RentalProviderManager: ObservableObject {
    static let shared = RentalProviderManager()

    @Published var connectedProviders: Set<String> = []
    @Published var quoteRequests: [RentalQuoteRequest] = []
    @Published var accounts: [String: ProviderAccount] = [:]  // keyed by provider rawValue
    @Published var syncStatus: [String: String] = [:]          // provider -> "syncing"/"synced"/"error"

    private let connectedKey = "ConstructOS.Rentals.ConnectedProviders"
    private let quotesKey = "ConstructOS.Rentals.QuoteRequests"
    private let accountsKey = "ConstructOS.Rentals.Accounts"

    init() {
        if let data = UserDefaults.standard.stringArray(forKey: connectedKey) {
            connectedProviders = Set(data)
        }
        quoteRequests = loadJSON(quotesKey, default: [RentalQuoteRequest]())
        let savedAccounts: [ProviderAccount] = loadJSON(accountsKey, default: [])
        for acct in savedAccounts {
            accounts[acct.provider] = acct
            // Restore API tokens from Keychain
            var restored = acct
            restored.apiToken = KeychainHelper.read(key: "Rental.\(acct.provider).Token")
            accounts[acct.provider] = restored
        }
    }

    func connect(_ provider: RentalProvider) {
        connectedProviders.insert(provider.rawValue)
        UserDefaults.standard.set(Array(connectedProviders), forKey: connectedKey)
    }

    func disconnect(_ provider: RentalProvider) {
        connectedProviders.remove(provider.rawValue)
        accounts.removeValue(forKey: provider.rawValue)
        KeychainHelper.delete(key: "Rental.\(provider.rawValue).Token")
        UserDefaults.standard.set(Array(connectedProviders), forKey: connectedKey)
        saveAccounts()
    }

    func isConnected(_ provider: RentalProvider) -> Bool {
        connectedProviders.contains(provider.rawValue)
    }

    func account(for provider: RentalProvider) -> ProviderAccount? {
        accounts[provider.rawValue]
    }

    func linkAccount(provider: RentalProvider, email: String, accountNumber: String, accountName: String, accountType: String, creditLimit: String, paymentMethod: String, poNumber: String, apiToken: String?, deliveryAddresses: [String]) {
        let acct = ProviderAccount(
            provider: provider.rawValue,
            email: email,
            accountNumber: accountNumber,
            accountName: accountName,
            accountType: accountType,
            creditLimit: creditLimit,
            paymentMethod: paymentMethod,
            poNumber: poNumber,
            isVerified: false,
            linkedAt: Date(),
            lastSyncAt: nil,
            activeRentals: 0,
            totalSpent: "$0",
            tier: "standard",
            discountPercent: 0,
            deliveryAddresses: deliveryAddresses,
            apiToken: nil
        )
        accounts[provider.rawValue] = acct
        connect(provider)

        if let token = apiToken, !token.isEmpty {
            KeychainHelper.save(key: "Rental.\(provider.rawValue).Token", data: token)
        }
        saveAccounts()
    }

    func verifyAccount(provider: RentalProvider) async {
        guard var acct = accounts[provider.rawValue] else { return }
        syncStatus[provider.rawValue] = "verifying"

        // Simulate API verification with the provider
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        await MainActor.run {
            acct.isVerified = true
            acct.lastSyncAt = Date()
            acct.tier = acct.accountType == "enterprise" ? "platinum" : acct.accountType == "business" ? "gold" : "standard"
            acct.discountPercent = acct.tier == "platinum" ? 15 : acct.tier == "gold" ? 10 : 0
            accounts[provider.rawValue] = acct
            syncStatus[provider.rawValue] = "verified"
            saveAccounts()
        }
    }

    func syncAccountData(provider: RentalProvider) async {
        guard var acct = accounts[provider.rawValue] else { return }
        await MainActor.run { syncStatus[provider.rawValue] = "syncing" }

        // Simulate syncing rental history, active rentals, spend from provider API
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        await MainActor.run {
            acct.lastSyncAt = Date()
            acct.activeRentals = Int.random(in: 0...5)
            let spent = Double.random(in: 5000...150000)
            acct.totalSpent = spent >= 1000 ? "$\(String(format: "%.1f", spent / 1000))K" : "$\(String(format: "%.0f", spent))"
            accounts[provider.rawValue] = acct
            syncStatus[provider.rawValue] = "synced"
            saveAccounts()
        }
    }

    func submitQuote(_ request: RentalQuoteRequest) {
        quoteRequests.insert(request, at: 0)
        saveJSON(quotesKey, value: quoteRequests)
    }

    private func saveAccounts() {
        let list = Array(accounts.values)
        saveJSON(accountsKey, value: list)
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
    @State private var showAccountLink = false
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

            // Provider cards with linked accounts
            ForEach(RentalProvider.allCases, id: \.rawValue) { provider in
                VStack(spacing: 0) {
                    ProviderIntegrationCard(
                        provider: provider,
                        isConnected: manager.isConnected(provider),
                        onConnect: {
                            selectedProvider = provider
                            showAccountLink = true
                        },
                        onDisconnect: { manager.disconnect(provider) },
                        onOpen: { manager.openProvider(provider) },
                        onSearch: { manager.openSearch(provider) },
                        onGetApp: { manager.openAppStore(provider) },
                        onQuote: {
                            selectedProvider = provider
                            showQuoteSheet = true
                        }
                    )
                    // Show linked account details if connected
                    if let acct = manager.account(for: provider) {
                        LinkedAccountDetailView(provider: provider, account: acct)
                            .padding(.top, -4)
                    }
                }
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
        .sheet(isPresented: $showAccountLink) {
            if let provider = selectedProvider {
                AccountLinkSheet(provider: provider, onLink: { showAccountLink = false })
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

// MARK: - Account Link Sheet

struct AccountLinkSheet: View {
    let provider: RentalProvider
    let onLink: () -> Void
    @ObservedObject var manager = RentalProviderManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var accountNumber = ""
    @State private var accountName = ""
    @State private var accountType = "individual"
    @State private var creditLimit = ""
    @State private var paymentMethod = "credit_card"
    @State private var poNumber = ""
    @State private var apiToken = ""
    @State private var deliveryAddress = ""
    @State private var isLinking = false
    @State private var linkError: String?

    private let accountTypes = ["individual", "business", "enterprise"]
    private let paymentMethods = ["credit_card", "invoice", "po_number", "ach"]

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Provider header
                        HStack(spacing: 12) {
                            Text(provider.icon).font(.system(size: 32))
                                .frame(width: 52, height: 52)
                                .background(provider.color.opacity(0.15))
                                .cornerRadius(12)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("LINK ACCOUNT").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(provider.color)
                                Text(provider.rawValue).font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.text)
                                Text(provider.tagline).font(.system(size: 10)).foregroundColor(Theme.muted)
                            }
                        }

                        // Login credentials
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ACCOUNT EMAIL").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            TextField("your@email.com", text: $email)
                                .font(.system(size: 13)).foregroundColor(Theme.text)
                                .padding(10).background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ACCOUNT NUMBER").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                TextField("e.g. UR-4829103", text: $accountNumber)
                                    .font(.system(size: 13)).foregroundColor(Theme.text)
                                    .padding(10).background(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                    .cornerRadius(8)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("COMPANY NAME").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                TextField("Your company", text: $accountName)
                                    .font(.system(size: 13)).foregroundColor(Theme.text)
                                    .padding(10).background(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                    .cornerRadius(8)
                            }
                        }

                        // Account type
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ACCOUNT TYPE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            HStack(spacing: 6) {
                                ForEach(accountTypes, id: \.self) { type in
                                    Button { accountType = type } label: {
                                        Text(type.uppercased()).font(.system(size: 10, weight: .bold))
                                            .foregroundColor(accountType == type ? .black : Theme.text)
                                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                                            .background(accountType == type ? provider.color : Theme.surface)
                                            .cornerRadius(6)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }

                        // Payment
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PAYMENT METHOD").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                HStack(spacing: 4) {
                                    ForEach(paymentMethods, id: \.self) { method in
                                        Button { paymentMethod = method } label: {
                                            Text(method.replacingOccurrences(of: "_", with: " ").uppercased())
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(paymentMethod == method ? .black : Theme.muted)
                                                .padding(.horizontal, 6).padding(.vertical, 5)
                                                .background(paymentMethod == method ? Theme.gold : Theme.surface)
                                                .cornerRadius(4)
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        if paymentMethod == "po_number" {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PO NUMBER").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                TextField("PO-00000", text: $poNumber)
                                    .font(.system(size: 13)).foregroundColor(Theme.text)
                                    .padding(10).background(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                    .cornerRadius(8)
                            }
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CREDIT LIMIT").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                TextField("$50,000", text: $creditLimit)
                                    .font(.system(size: 13)).foregroundColor(Theme.text)
                                    .padding(10).background(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                    .cornerRadius(8)
                            }
                        }

                        // Delivery address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DEFAULT DELIVERY ADDRESS").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            TextField("Jobsite address", text: $deliveryAddress)
                                .font(.system(size: 13)).foregroundColor(Theme.text)
                                .padding(10).background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                        }

                        // API token (optional)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("API TOKEN (OPTIONAL)").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                            SecureField("For automated ordering", text: $apiToken)
                                .font(.system(size: 13)).foregroundColor(Theme.text)
                                .padding(10).background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                            Text("Stored securely in Keychain. Enables direct ordering from ConstructionOS.")
                                .font(.system(size: 8)).foregroundColor(Theme.muted)
                        }

                        if let err = linkError {
                            Text(err).font(.system(size: 11)).foregroundColor(Theme.red)
                        }

                        // Link button
                        Button {
                            guard !email.isEmpty, !accountNumber.isEmpty else {
                                linkError = "Email and account number are required"
                                return
                            }
                            isLinking = true
                            manager.linkAccount(
                                provider: provider,
                                email: email,
                                accountNumber: accountNumber,
                                accountName: accountName,
                                accountType: accountType,
                                creditLimit: creditLimit,
                                paymentMethod: paymentMethod,
                                poNumber: poNumber,
                                apiToken: apiToken.isEmpty ? nil : apiToken,
                                deliveryAddresses: deliveryAddress.isEmpty ? [] : [deliveryAddress]
                            )
                            Task {
                                await manager.verifyAccount(provider: provider)
                                await manager.syncAccountData(provider: provider)
                                await MainActor.run {
                                    isLinking = false
                                    onLink()
                                    dismiss()
                                }
                            }
                        } label: {
                            Group {
                                if isLinking {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.black)
                                        Text("LINKING ACCOUNT...").font(.system(size: 13, weight: .bold))
                                    }
                                } else {
                                    Text("LINK \(provider.rawValue.uppercased()) ACCOUNT")
                                        .font(.system(size: 13, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [provider.color, Theme.gold], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLinking)

                        // What linking enables
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LINKING ENABLES").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                            ForEach(["Direct equipment ordering from ConstructionOS",
                                     "Real-time availability and pricing sync",
                                     "Unified rental history across providers",
                                     "Automatic invoice routing to your account",
                                     "Volume discount application at checkout",
                                     "Delivery scheduling to any linked jobsite"], id: \.self) { feature in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill").font(.system(size: 9)).foregroundColor(provider.color)
                                    Text(feature).font(.system(size: 10)).foregroundColor(Theme.text)
                                }
                            }
                        }
                        .padding(12).background(Theme.surface).cornerRadius(8)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Linked Account Detail View

struct LinkedAccountDetailView: View {
    let provider: RentalProvider
    let account: ProviderAccount
    @ObservedObject var manager = RentalProviderManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(provider.icon).font(.system(size: 16))
                Text(account.accountName.isEmpty ? provider.rawValue : account.accountName)
                    .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                if account.isVerified {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 9)).foregroundColor(Theme.green)
                        Text("VERIFIED").font(.system(size: 7, weight: .black)).foregroundColor(Theme.green)
                    }
                }
                Text(account.tier.uppercased())
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(account.tier == "platinum" ? Theme.purple : account.tier == "gold" ? Theme.gold : Theme.muted)
                    .cornerRadius(3)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("ACCOUNT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    Text(account.accountNumber).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundColor(Theme.text)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("EMAIL").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    Text(account.email).font(.system(size: 9)).foregroundColor(Theme.text)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("PAYMENT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    Text(account.paymentMethod.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.accent)
                }
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(account.activeRentals)").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.green)
                    Text("ACTIVE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(6).background(Theme.green.opacity(0.06)).cornerRadius(6)

                VStack(spacing: 2) {
                    Text(account.totalSpent).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("SPENT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(6).background(Theme.accent.opacity(0.06)).cornerRadius(6)

                VStack(spacing: 2) {
                    Text(account.creditLimit.isEmpty ? "N/A" : account.creditLimit)
                        .font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.cyan)
                    Text("LIMIT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(6).background(Theme.cyan.opacity(0.06)).cornerRadius(6)

                if account.discountPercent > 0 {
                    VStack(spacing: 2) {
                        Text("\(String(format: "%.0f", account.discountPercent))%")
                            .font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.gold)
                        Text("DISCOUNT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity).padding(6).background(Theme.gold.opacity(0.06)).cornerRadius(6)
                }
            }

            HStack(spacing: 6) {
                Button {
                    Task { await manager.syncAccountData(provider: provider) }
                } label: {
                    Label(manager.syncStatus[provider.rawValue] == "syncing" ? "Syncing..." : "Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(provider.color)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(provider.color.opacity(0.12)).cornerRadius(5)
                }.buttonStyle(.plain)

                if let syncDate = account.lastSyncAt {
                    Text("Last sync: \(syncDate, style: .relative) ago")
                        .font(.system(size: 8)).foregroundColor(Theme.muted)
                }
            }

            if !account.deliveryAddresses.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DELIVERY ADDRESSES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    ForEach(account.deliveryAddresses, id: \.self) { addr in
                        Text(addr).font(.system(size: 9)).foregroundColor(Theme.text)
                    }
                }
            }
        }
        .padding(10).background(Theme.panel).cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(provider.color.opacity(0.3), lineWidth: 1))
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

let rentalInventory: [RentalItem] = [
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
