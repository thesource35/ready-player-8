import Combine
import Foundation
import LocalAuthentication
import StoreKit
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


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

    @Published var subscriptionStatus: SubscriptionTier = .fieldWorker
    @Published var availableProducts: [Product] = []
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    enum SubscriptionTier: String {
        case fieldWorker = "Field Worker"
        case projectManager = "Project Manager"
        case companyOwner = "Company Owner"

        var price: String {
            switch self {
            case .fieldWorker: return "$9.99/mo"
            case .projectManager: return "$24.99/mo"
            case .companyOwner: return "$49.99/mo"
            }
        }

        var annualPrice: String {
            switch self {
            case .fieldWorker: return "$99/yr"
            case .projectManager: return "$249/yr"
            case .companyOwner: return "$499/yr"
            }
        }

        var description: String {
            switch self {
            case .fieldWorker: return "For electricians, plumbers, framers, concrete workers, and every trade on the jobsite"
            case .projectManager: return "For superintendents, PMs, estimators, and field engineers running projects"
            case .companyOwner: return "For GCs, subcontractor owners, and executives managing a business"
            }
        }

        var features: [String] {
            // ALL features included on every tier — no lockouts
            return [
                "All 30 tabs — full access",
                "56 AI-powered MCP tools",
                "Unlimited projects & contracts",
                "Equipment rental marketplace (97 items)",
                "Digital twin & 3D scanning",
                "Smart concrete testing AI",
                "Punch list pro with photos",
                "Financial tools (invoicing, lien waivers)",
                "Tax center with deduction finder",
                "Crew timecards & GPS tracking",
                "Construction network & connections",
                "Satellite roof estimator",
                "Gantt scheduling & cost codes",
                "Compliance & safety tools",
                "Unlimited cloud sync",
                "PDF export & document storage",
                "Push notifications & calendar sync",
            ]
        }

        var bonusFeatures: [String] {
            switch self {
            case .fieldWorker: return ["Personal profile & network", "Job lead alerts", "Certification tracker"]
            case .projectManager: return ["Everything in Field Worker +", "Team management (up to 25)", "Client portal sharing", "Bid analytics"]
            case .companyOwner: return ["Everything in Project Manager +", "Unlimited team members", "AI pricing engine", "White-label client portal", "Priority support", "Custom integrations"]
            }
        }

        var color: Color {
            switch self {
            case .fieldWorker: return Theme.cyan
            case .projectManager: return Theme.gold
            case .companyOwner: return Theme.accent
            }
        }
    }

    private let productIDs = [
        "com.constructionos.fieldworker.monthly",
        "com.constructionos.fieldworker.annual",
        "com.constructionos.pm.monthly",
        "com.constructionos.pm.annual",
        "com.constructionos.owner.monthly",
        "com.constructionos.owner.annual"
    ]

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Set(productIDs))
            await MainActor.run {
                availableProducts = products.sorted { $0.price < $1.price }
                if products.isEmpty {
                    purchaseError = nil // Don't show error if products aren't configured yet
                }
            }
        } catch {
            await MainActor.run {
                purchaseError = nil // Silently handle — products may not be set up yet
            }
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
                    await MainActor.run { subscriptionStatus = .companyOwner }
                    return
                } else if transaction.productID.contains("pro") {
                    await MainActor.run { subscriptionStatus = .projectManager }
                    return
                }
            }
        }
        await MainActor.run { subscriptionStatus = .fieldWorker }
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
                    ForEach([SubscriptionManager.SubscriptionTier.fieldWorker, .projectManager, .companyOwner], id: \.rawValue) { tier in
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
                        Text("Subscription products will be available soon. Contact us for early access pricing.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center).padding(.vertical, 10)
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

// MARK: - ========== AI-Driven Pricing Engine ==========

/// Revenue-based dynamic pricing like Procore — AI determines the price
/// based on annual construction volume, modules, and usage patterns.

enum PricingModule: String, CaseIterable, Identifiable {
    case projectManagement = "Project Management"
    case fieldProductivity = "Field Productivity"
    case financials = "Financials & ERP"
    case qualitySafety = "Quality & Safety"
    case bidManagement = "Bid Management"
    case wealthIntelligence = "Wealth Intelligence"
    case rentalMarketplace = "Rental Marketplace"
    case aiAssistant = "AI Assistant (Angelic)"
    case complianceSuite = "Compliance Suite"
    case clientPortal = "Client Portal"
    case analyticsBI = "Analytics & BI"
    case electricalFiber = "Electrical & Fiber"
    case taxCenter = "Tax Center"

    var id: String { rawValue }

    var baseMonthly: Double {
        switch self {
        case .projectManagement: return 375
        case .fieldProductivity: return 275
        case .financials: return 500
        case .qualitySafety: return 200
        case .bidManagement: return 225
        case .wealthIntelligence: return 150
        case .rentalMarketplace: return 175
        case .aiAssistant: return 300
        case .complianceSuite: return 250
        case .clientPortal: return 125
        case .analyticsBI: return 350
        case .electricalFiber: return 200
        case .taxCenter: return 175
        }
    }

    var icon: String {
        switch self {
        case .projectManagement: return "\u{1F3D7}"
        case .fieldProductivity: return "\u{1F4F1}"
        case .financials: return "\u{1F4B5}"
        case .qualitySafety: return "\u{1F6E1}"
        case .bidManagement: return "\u{1F4CB}"
        case .wealthIntelligence: return "\u{1F48E}"
        case .rentalMarketplace: return "\u{1F6E0}"
        case .aiAssistant: return "\u{1F47C}"
        case .complianceSuite: return "\u{2696}\u{FE0F}"
        case .clientPortal: return "\u{1F465}"
        case .analyticsBI: return "\u{1F4C8}"
        case .electricalFiber: return "\u{26A1}"
        case .taxCenter: return "\u{1F4B0}"
        }
    }

    var description: String {
        switch self {
        case .projectManagement: return "Projects, contracts, scheduling, documents, daily logs"
        case .fieldProductivity: return "Timecards, equipment tracking, geofencing, QR scanning"
        case .financials: return "AIA invoicing, lien waivers, cash flow, cost codes"
        case .qualitySafety: return "Safety incidents, toolbox talks, inspections, punch lists"
        case .bidManagement: return "Bid pipeline, estimating, subcontractor prequalification"
        case .wealthIntelligence: return "Money Lens, Psychology, Power Thinking, Leverage, Opportunity"
        case .rentalMarketplace: return "97 items, 6 providers, calculator, AI recommender"
        case .aiAssistant: return "Claude-powered AI with 18 MCP tools for live data"
        case .complianceSuite: return "Certified payroll, environmental, training certs"
        case .clientPortal: return "Owner dashboard, selections, warranty, meetings"
        case .analyticsBI: return "Bid analytics, labor productivity, risk AI scoring"
        case .electricalFiber: return "Contractor directory, leads, fiber projects, emergency"
        case .taxCenter: return "Expense tracking, deductions, quarterly estimates, 1099s"
        }
    }
}

enum RevenueVolumeTier: String, CaseIterable {
    case starter = "Starter"         // <$5M
    case growing = "Growing"         // $5M-$25M
    case established = "Established" // $25M-$50M
    case midMarket = "Mid-Market"    // $50M-$150M
    case enterprise = "Enterprise"   // $150M-$500M
    case mega = "Mega"               // $500M+

    var revenueRange: String {
        switch self {
        case .starter: return "Under $5M"
        case .growing: return "$5M - $25M"
        case .established: return "$25M - $50M"
        case .midMarket: return "$50M - $150M"
        case .enterprise: return "$150M - $500M"
        case .mega: return "$500M+"
        }
    }

    var multiplier: Double {
        switch self {
        case .starter: return 0.5
        case .growing: return 0.75
        case .established: return 1.0
        case .midMarket: return 1.5
        case .enterprise: return 2.5
        case .mega: return 4.0
        }
    }

    var discount: Double {
        switch self {
        case .starter: return 0
        case .growing: return 5
        case .established: return 10
        case .midMarket: return 15
        case .enterprise: return 20
        case .mega: return 25
        }
    }

    var color: Color {
        switch self {
        case .starter: return Theme.muted
        case .growing: return Theme.cyan
        case .established: return Theme.green
        case .midMarket: return Theme.gold
        case .enterprise: return Theme.accent
        case .mega: return Theme.purple
        }
    }
}

@MainActor
final class PricingEngine: ObservableObject {
    static let shared = PricingEngine()

    @Published var selectedTier: RevenueVolumeTier = .established
    @Published var selectedModules: Set<PricingModule> = [.projectManagement, .fieldProductivity, .qualitySafety]
    @Published var annualRevenue: String = "$50M"
    @Published var projectCount: Int = 12
    @Published var userCount: Int = 25
    @AppStorage("ConstructOS.Pricing.CustomQuote") var customQuoteRequested: Bool = false

    // AI calculates price based on all factors
    var monthlyPrice: Double {
        let baseModuleCost = selectedModules.reduce(0.0) { $0 + $1.baseMonthly }
        let volumeAdjusted = baseModuleCost * selectedTier.multiplier
        let projectFactor = 1.0 + Double(max(0, projectCount - 5)) * 0.02
        let discounted = volumeAdjusted * projectFactor * (1.0 - selectedTier.discount / 100)
        return max(375, discounted) // minimum $375/mo
    }

    var annualPrice: Double { monthlyPrice * 12 * 0.85 } // 15% annual discount
    var perProjectCost: Double { projectCount > 0 ? monthlyPrice / Double(projectCount) : monthlyPrice }

    var recommendedTier: RevenueVolumeTier {
        if selectedModules.count >= 10 { return .enterprise }
        if selectedModules.count >= 7 { return .midMarket }
        if selectedModules.count >= 4 { return .established }
        return .growing
    }

    var aiPricingRationale: String {
        let modCount = selectedModules.count
        let hasFinancials = selectedModules.contains(.financials)
        let hasAI = selectedModules.contains(.aiAssistant)
        var reasons: [String] = []
        reasons.append("Based on \(selectedTier.revenueRange) annual construction volume")
        reasons.append("\(modCount) modules selected (\(modCount >= 8 ? "comprehensive" : modCount >= 5 ? "standard" : "essential") coverage)")
        if projectCount > 20 { reasons.append("High project volume (\(projectCount)) adds 2% per project over 5") }
        if hasFinancials { reasons.append("Financials module includes AIA pay apps + cost code tracking") }
        if hasAI { reasons.append("AI assistant with 18 live data tools included") }
        reasons.append("Unlimited users and storage included at all tiers")
        reasons.append("\(String(format: "%.0f", selectedTier.discount))% volume discount applied")
        return reasons.joined(separator: "\n")
    }
}

// MARK: - MCP Payment Tools

extension MCPToolServer {
    var paymentToolDefinitions: [[String: Any]] {
        [
            toolDef("get_pricing_quote", "Generate a dynamic pricing quote based on revenue volume, modules, and project count", [
                "annual_revenue": ["type": "string", "description": "Annual construction volume (e.g. '$50M')"],
                "modules": ["type": "string", "description": "Comma-separated module names"],
                "project_count": ["type": "string", "description": "Number of active projects"],
            ]),
            toolDef("get_module_list", "List all available ConstructionOS modules with base pricing", [:]),
            toolDef("compare_to_procore", "Compare ConstructionOS pricing to Procore for a given company size", [
                "company_size": ["type": "string", "description": "small, mid, or large"],
            ]),
            toolDef("get_invoice_status", "Get current subscription invoice status and payment history", [:]),
        ]
    }

    func executePaymentTool(name: String, input: [String: Any]) -> String {
        let engine = PricingEngine.shared
        switch name {
        case "get_pricing_quote":
            let modules = engine.selectedModules.map(\.rawValue).joined(separator: ", ")
            return """
            CONSTRUCTIONOS PRICING QUOTE
            Revenue Tier: \(engine.selectedTier.rawValue) (\(engine.selectedTier.revenueRange))
            Modules: \(modules)
            Projects: \(engine.projectCount)
            Users: Unlimited (included)
            Storage: Unlimited (included)
            ---
            Monthly: $\(String(format: "%.0f", engine.monthlyPrice))/mo
            Annual: $\(String(format: "%.0f", engine.annualPrice))/yr (15% discount)
            Per Project: $\(String(format: "%.0f", engine.perProjectCost))/mo/project
            Volume Discount: \(String(format: "%.0f", engine.selectedTier.discount))%
            ---
            AI RATIONALE:
            \(engine.aiPricingRationale)
            """

        case "get_module_list":
            return PricingModule.allCases.map {
                "\($0.icon) \($0.rawValue): $\(String(format: "%.0f", $0.baseMonthly))/mo - \($0.description)"
            }.joined(separator: "\n")

        case "compare_to_procore":
            let size = (input["company_size"] as? String ?? "mid").lowercased()
            let (procore, cos) = {
                switch size {
                case "small": return ("$20,000-$80,000/yr", "$\(String(format: "%.0f", engine.monthlyPrice * 12))/yr")
                case "large": return ("$100,000-$600,000+/yr", "$\(String(format: "%.0f", engine.annualPrice))/yr")
                default: return ("$50,000-$150,000/yr", "$\(String(format: "%.0f", engine.annualPrice))/yr")
                }
            }()
            return """
            PROCORE vs CONSTRUCTIONOS COMPARISON
            Company Size: \(size)
            Procore: \(procore)
            ConstructionOS: \(cos)
            ---
            ConstructionOS Advantages:
            - AI assistant with 18 live MCP tools (Procore has none)
            - Rental marketplace with 97 items from 6 providers
            - Wealth Intelligence Suite (5 tools)
            - Tax center with deduction finder
            - Electrical & fiber contractor network
            - Dynamic AI-based pricing (not fixed annual contract)
            - Same unlimited users and storage
            """

        case "get_invoice_status":
            return """
            SUBSCRIPTION STATUS
            Plan: \(engine.selectedTier.rawValue)
            Monthly Rate: $\(String(format: "%.0f", engine.monthlyPrice))
            Billing Cycle: Monthly
            Next Invoice: \(DateFormatter.localizedString(from: Date().addingTimeInterval(30*86400), dateStyle: .medium, timeStyle: .none))
            Payment Method: On file
            Status: ACTIVE
            """

        default: return "Unknown payment tool"
        }
    }

    private func toolDef(_ name: String, _ desc: String, _ props: [String: [String: String]]) -> [String: Any] {
        var schema: [String: Any] = ["type": "object", "properties": props]
        if !props.isEmpty { schema["required"] = Array(props.keys) }
        return ["name": name, "description": desc, "input_schema": schema]
    }
}

// MARK: - AI Pricing Dashboard View

struct AIPricingDashboardView: View {
    @ObservedObject var engine = PricingEngine.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{1F916}").font(.system(size: 18))
                            Text("AI PRICING").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent)
                        }
                        Text("Dynamic Construction Pricing")
                            .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("AI determines your price based on revenue, modules, and usage")
                            .font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.0f", engine.monthlyPrice))")
                            .font(.system(size: 32, weight: .heavy)).foregroundColor(Theme.accent)
                        Text("/month").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }
                .padding(16).background(Theme.surface).cornerRadius(16)
                .premiumGlow(cornerRadius: 16, color: Theme.accent)

                // Price summary
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text("$\(String(format: "%.0f", engine.monthlyPrice))").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent)
                        Text("MONTHLY").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) {
                        Text("$\(String(format: "%.0f", engine.annualPrice / 1000))K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green)
                        Text("ANNUAL (15% OFF)").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) {
                        Text("$\(String(format: "%.0f", engine.perProjectCost))").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan)
                        Text("PER PROJECT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                    VStack(spacing: 2) {
                        Text("UNLIMITED").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.gold)
                        Text("USERS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                }

                // Revenue tier selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("ANNUAL CONSTRUCTION VOLUME").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(RevenueVolumeTier.allCases, id: \.rawValue) { tier in
                                Button { engine.selectedTier = tier } label: {
                                    VStack(spacing: 3) {
                                        Text(tier.rawValue).font(.system(size: 9, weight: .bold))
                                        Text(tier.revenueRange).font(.system(size: 7))
                                        if tier.discount > 0 {
                                            Text("-\(String(format: "%.0f", tier.discount))%").font(.system(size: 7, weight: .black)).foregroundColor(Theme.green)
                                        }
                                    }
                                    .foregroundColor(engine.selectedTier == tier ? .black : Theme.text)
                                    .padding(.horizontal, 10).padding(.vertical, 8)
                                    .background(engine.selectedTier == tier ? tier.color : Theme.surface)
                                    .cornerRadius(8)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // Project count
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("ACTIVE PROJECTS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
                        Spacer()
                        Text("\(engine.projectCount)").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent)
                    }
                    Stepper("", value: $engine.projectCount, in: 1...100)
                        .labelsHidden()
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // Module selector
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SELECT MODULES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
                        Spacer()
                        Text("\(engine.selectedModules.count) of \(PricingModule.allCases.count)")
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                        Button {
                            if engine.selectedModules.count == PricingModule.allCases.count {
                                engine.selectedModules = [.projectManagement]
                            } else {
                                engine.selectedModules = Set(PricingModule.allCases)
                            }
                        } label: {
                            Text(engine.selectedModules.count == PricingModule.allCases.count ? "MINIMAL" : "SELECT ALL")
                                .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.accent)
                        }.buttonStyle(.plain)
                    }

                    ForEach(PricingModule.allCases) { module in
                        let isSelected = engine.selectedModules.contains(module)
                        Button {
                            if isSelected && engine.selectedModules.count > 1 {
                                engine.selectedModules.remove(module)
                            } else {
                                engine.selectedModules.insert(module)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14)).foregroundColor(isSelected ? Theme.accent : Theme.muted)
                                Text(module.icon).font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.rawValue).font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isSelected ? Theme.text : Theme.muted)
                                    Text(module.description).font(.system(size: 8))
                                        .foregroundColor(Theme.muted).lineLimit(1)
                                }
                                Spacer()
                                Text("$\(String(format: "%.0f", module.baseMonthly))")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(isSelected ? Theme.accent : Theme.muted)
                            }
                            .padding(10)
                            .background(isSelected ? Theme.accent.opacity(0.04) : Color.clear)
                            .cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // AI Rationale
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("\u{1F916}").font(.system(size: 14))
                        Text("AI PRICING RATIONALE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
                    }
                    Text(engine.aiPricingRationale)
                        .font(.system(size: 10)).foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14).background(Theme.surface).cornerRadius(12)
                .premiumGlow(cornerRadius: 12, color: Theme.purple)

                // Procore comparison
                VStack(alignment: .leading, spacing: 10) {
                    Text("vs PROCORE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.red)

                    let procoreRange: String = {
                        switch engine.selectedTier {
                        case .starter, .growing: return "$20K - $80K"
                        case .established: return "$50K - $100K"
                        case .midMarket: return "$50K - $150K"
                        case .enterprise: return "$100K - $350K"
                        case .mega: return "$200K - $600K+"
                        }
                    }()

                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text("PROCORE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.red)
                            Text(procoreRange).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.red)
                            Text("/year").font(.system(size: 8)).foregroundColor(Theme.muted)
                        }.frame(maxWidth: .infinity).padding(12).background(Theme.red.opacity(0.06)).cornerRadius(10)

                        VStack(spacing: 4) {
                            Text("CONSTRUCTIONOS").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
                            Text("$\(String(format: "%.0f", engine.annualPrice / 1000))K").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green)
                            Text("/year").font(.system(size: 8)).foregroundColor(Theme.muted)
                        }.frame(maxWidth: .infinity).padding(12).background(Theme.green.opacity(0.06)).cornerRadius(10)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ConstructionOS includes that Procore doesn't:").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text)
                        ForEach(["AI assistant with 18 live data MCP tools", "Rental marketplace (97 items, 6 providers)", "Wealth Intelligence Suite", "Tax center with deduction finder", "Electrical & fiber contractor network", "Dynamic AI pricing (no locked annual contracts)"], id: \.self) { adv in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 8)).foregroundColor(Theme.green)
                                Text(adv).font(.system(size: 9)).foregroundColor(Theme.muted)
                            }
                        }
                    }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // CTA
                Button {
                    engine.customQuoteRequested = true
                } label: {
                    VStack(spacing: 4) {
                        Text("START WITH CONSTRUCTIONOS")
                            .font(.system(size: 14, weight: .bold)).tracking(1)
                        Text("$\(String(format: "%.0f", engine.monthlyPrice))/mo \u{2022} Unlimited users \u{2022} Cancel anytime")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Theme.bg)
    }
}
