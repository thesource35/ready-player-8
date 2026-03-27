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
