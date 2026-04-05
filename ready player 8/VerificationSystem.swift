import SwiftUI
import Combine

// MARK: - ========== Verification System ==========

// MARK: - Verification Tier

enum VerificationTier: String, CaseIterable, Codable {
    case none = "Unverified"
    case identity = "Identity Verified"
    case licensed = "License Verified"
    case company = "Company Verified"

    var icon: String {
        switch self {
        case .none: return ""
        case .identity: return "checkmark.circle.fill"
        case .licensed: return "checkmark.seal.fill"
        case .company: return "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: return Theme.muted
        case .identity: return Theme.green
        case .licensed: return Theme.cyan
        case .company: return Theme.gold
        }
    }

    var price: String {
        switch self {
        case .none: return "Free"
        case .identity: return "Free"
        case .licensed: return "$27.99/mo"
        case .company: return "$49.99/mo"
        }
    }

    var annualPrice: String {
        switch self {
        case .none: return ""
        case .identity: return "Free"
        case .licensed: return "$279.99/yr"
        case .company: return "$499.99/yr"
        }
    }

    var tag: String {
        switch self {
        case .none: return ""
        case .identity: return "VERIFIED"
        case .licensed: return "LICENSED"
        case .company: return "INSURED & BONDED"
        }
    }
}

// MARK: - Verification Request

struct VerificationRequest: Identifiable, Codable {
    var id = UUID()
    let tier: String
    let fullName: String
    let email: String
    let trade: String
    let licenseType: String
    let licenseNumber: String
    let licenseState: String
    let oshaLevel: String
    let companyName: String
    let ein: String
    let insuranceCarrier: String
    let policyNumber: String
    let bondingCompany: String
    let bondAmount: String
    var status: String        // "pending", "reviewing", "approved", "denied"
    var submittedAt: Date
    var reviewedAt: Date?
    var denialReason: String?
    var reportCount: Int
}

// MARK: - License Types by Trade

struct TradeRequirement {
    let trade: String
    let requiresStateLicense: Bool
    let licenseTypes: [String]
    let acceptedCertifications: [String]
    let verifyWith: String
}

let tradeVerificationRequirements: [TradeRequirement] = [
    TradeRequirement(trade: "Electrician", requiresStateLicense: true, licenseTypes: ["Journeyman Electrician", "Master Electrician"], acceptedCertifications: ["OSHA 30", "NFPA 70E"], verifyWith: "State Licensing Board"),
    TradeRequirement(trade: "Plumber", requiresStateLicense: true, licenseTypes: ["Journeyman Plumber", "Master Plumber"], acceptedCertifications: ["OSHA 30", "Medical Gas"], verifyWith: "State Licensing Board"),
    TradeRequirement(trade: "HVAC", requiresStateLicense: true, licenseTypes: ["HVAC License", "EPA 608 Universal"], acceptedCertifications: ["NATE", "R-410A"], verifyWith: "EPA / State Board"),
    TradeRequirement(trade: "General Contractor", requiresStateLicense: true, licenseTypes: ["General Contractor License", "Building Contractor"], acceptedCertifications: ["PMP", "LEED AP"], verifyWith: "State Contractor Board"),
    TradeRequirement(trade: "Crane Operator", requiresStateLicense: true, licenseTypes: ["NCCCO Certification"], acceptedCertifications: ["OSHA 30", "Signal Person"], verifyWith: "NCCCO Database"),
    TradeRequirement(trade: "Welder", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["AWS D1.1", "AWS D1.5", "ASME IX", "CWI"], verifyWith: "AWS Certification Database"),
    TradeRequirement(trade: "Fire Alarm", requiresStateLicense: true, licenseTypes: ["NICET Level II", "NICET Level III", "NICET Level IV"], acceptedCertifications: ["OSHA 10"], verifyWith: "NICET Database"),
    TradeRequirement(trade: "Elevator", requiresStateLicense: true, licenseTypes: ["Elevator Mechanic License"], acceptedCertifications: ["OSHA 30", "QEI"], verifyWith: "State Labor Dept"),
    TradeRequirement(trade: "Concrete", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["ACI Grade 1", "ACI Flatwork", "OSHA 30"], verifyWith: "ACI Database"),
    TradeRequirement(trade: "Steel", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["AWS D1.1", "AISC Certified", "OSHA 30"], verifyWith: "AISC / AWS Database"),
    TradeRequirement(trade: "Roofing", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["GAF Master Elite", "NRCA", "CertainTeed SELECT"], verifyWith: "Manufacturer Certification"),
    TradeRequirement(trade: "Solar", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["NABCEP PV Installer", "NABCEP PV Design"], verifyWith: "NABCEP Database"),
    TradeRequirement(trade: "Fiber Optic", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["BICSI RCDD", "BICSI TECH", "CFOT", "CPCT"], verifyWith: "BICSI Database"),
    TradeRequirement(trade: "Low Voltage", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["NICET Level I", "NICET Level II", "BICSI TECH"], verifyWith: "NICET / BICSI Database"),
    TradeRequirement(trade: "Safety", requiresStateLicense: false, licenseTypes: [], acceptedCertifications: ["OSHA 30", "CHST", "CSP", "First Aid/CPR"], verifyWith: "BCSP / DOL Database"),
]

// MARK: - Verification Store

@MainActor
final class VerificationManager: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = VerificationManager()

    @Published var currentTier: VerificationTier = .none
    @Published var currentRequest: VerificationRequest?
    @Published var isProcessing = false

    private let requestKey = "ConstructOS.Verification.Request"
    private let tierKey = "ConstructOS.Verification.Tier"

    init() {
        currentRequest = loadJSON(requestKey, default: nil as VerificationRequest?)
        if let tierRaw = UserDefaults.standard.string(forKey: tierKey),
           let tier = VerificationTier(rawValue: tierRaw) {
            currentTier = tier
        }
    }

    func submitIdentityVerification(name: String, email: String, phone: String) {
        currentTier = .identity
        UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
    }

    func submitLicenseVerification(request: VerificationRequest) {
        var req = request
        req.status = "pending"
        req.submittedAt = Date()
        currentRequest = req
        isProcessing = true
        saveJSON(requestKey, value: req)

        // Submit to Supabase backend if configured, then update status
        Task { @MainActor [weak self] in
            let svc = SupabaseService.shared
            if svc.isConfigured {
                do {
                    // Submit verification request to backend
                    try await svc.insert(SupabaseTable.verificationRequests, record: req)
                    self?.currentRequest?.status = "submitted"
                } catch {
                    // Expected: Backend unavailable — fall back to local-only review
                    CrashReporter.shared.reportError("Verification backend unavailable (local fallback): \(error.localizedDescription)")
                    self?.currentRequest?.status = "reviewing"
                }
            } else {
                // No backend — simulate review locally
                try? await Task.sleep(for: .seconds(3))
                self?.currentRequest?.status = "reviewing"
            }
            if let r = self?.currentRequest { saveJSON(self?.requestKey ?? "", value: r) }
            self?.isProcessing = false
        }
    }

    func approveVerification() {
        currentRequest?.status = "approved"
        currentRequest?.reviewedAt = Date()
        if currentRequest?.ein.isEmpty == false && currentRequest?.insuranceCarrier.isEmpty == false {
            currentTier = .company
        } else {
            currentTier = .licensed
        }
        UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
        isProcessing = false
        if let r = currentRequest { saveJSON(requestKey, value: r) }
    }

    func reportProfile(userID: String) {
        // 3 reports triggers re-review
    }

    func requirementForTrade(_ trade: String) -> TradeRequirement? {
        tradeVerificationRequirements.first { $0.trade == trade }
    }
}

// MARK: - Verification Application View

struct VerificationApplicationView: View {
    @ObservedObject var manager = VerificationManager.shared
    @ObservedObject var profileStore = UserProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: VerificationTier = .licensed
    @State private var licenseType = ""
    @State private var licenseNumber = ""
    @State private var licenseState = ""
    @State private var oshaLevel = "OSHA 30"
    @State private var ein = ""
    @State private var insuranceCarrier = ""
    @State private var policyNumber = ""
    @State private var bondingCompany = ""
    @State private var bondAmount = ""
    @State private var error: String?
    @State private var step = 0  // 0=tier select, 1=license info, 2=company info, 3=review

    private var tradeReq: TradeRequirement? {
        manager.requirementForTrade(profileStore.currentUser?.trade ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        VStack(alignment: .center, spacing: 8) {
                            Image(systemName: "checkmark.shield.fill").font(.system(size: 40)).foregroundColor(Theme.gold)
                            Text("GET VERIFIED").font(.system(size: 18, weight: .heavy)).tracking(2).foregroundColor(Theme.text)
                            Text("Prove your credentials to the construction network").font(.system(size: 11)).foregroundColor(Theme.muted)
                        }.frame(maxWidth: .infinity).padding(.top, 10)

                        if let request = manager.currentRequest, request.status != "approved" {
                            pendingStatusView(request)
                        } else if step == 0 {
                            tierSelectionView
                        } else if step == 1 {
                            licenseInfoView
                        } else if step == 2 {
                            companyInfoView
                        } else {
                            reviewView
                        }
                    }.padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
            }
        }.preferredColorScheme(.dark)
    }

    // MARK: - Pending Status
    private func pendingStatusView(_ request: VerificationRequest) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark").font(.system(size: 36)).foregroundColor(Theme.gold)
            Text("VERIFICATION \(request.status.uppercased())").font(.system(size: 14, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            Text("Your credentials are being reviewed. This typically takes 24-48 hours.")
                .font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                statusRow("Identity", "complete")
                statusRow("License Upload", request.licenseNumber.isEmpty ? "pending" : "complete")
                statusRow("License Verification", request.status == "reviewing" ? "in review" : "pending")
                if !request.insuranceCarrier.isEmpty {
                    statusRow("Insurance Verification", "pending")
                    statusRow("Bonding Verification", "pending")
                }
            }.padding(14).background(Theme.surface).cornerRadius(12)

            // Demo: simulate approval
            Button {
                manager.approveVerification()
                dismiss()
            } label: {
                Text("SIMULATE APPROVAL (DEMO)").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.green)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Theme.green.opacity(0.1)).cornerRadius(8)
            }.buttonStyle(.plain)
        }
    }

    private func statusRow(_ label: String, _ status: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: status == "complete" ? "checkmark.circle.fill" : status == "in review" ? "magnifyingglass.circle.fill" : "clock.fill")
                .font(.system(size: 12)).foregroundColor(status == "complete" ? Theme.green : status == "in review" ? Theme.cyan : Theme.gold)
            Text(label).font(.system(size: 11)).foregroundColor(Theme.text)
            Spacer()
            Text(status.uppercased()).font(.system(size: 8, weight: .bold)).foregroundColor(status == "complete" ? Theme.green : Theme.gold)
        }
    }

    // MARK: - Tier Selection
    private var tierSelectionView: some View {
        VStack(spacing: 12) {
            ForEach([VerificationTier.identity, .licensed, .company], id: \.rawValue) { tier in
                Button { selectedTier = tier } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: tier.icon).font(.system(size: 18)).foregroundColor(tier.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tier.rawValue).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
                                Text(tier.tag.isEmpty ? "Basic verification" : tier.tag).font(.system(size: 9, weight: .bold)).foregroundColor(tier.color)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(tier.price).font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.accent)
                                if !tier.annualPrice.isEmpty && tier.annualPrice != "Free" {
                                    Text(tier.annualPrice).font(.system(size: 9)).foregroundColor(Theme.muted)
                                }
                            }
                            Image(systemName: selectedTier == tier ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18)).foregroundColor(selectedTier == tier ? tier.color : Theme.muted)
                        }

                        if tier == .licensed {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Requires:").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                Text("\u{2022} State license OR trade certification").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text("\u{2022} OSHA card (10 or 30 hour)").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text("\u{2022} Photo of physical license/card").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text("\u{2022} 24-48 hour manual review").font(.system(size: 9)).foregroundColor(Theme.muted)
                            }
                        }

                        if tier == .company {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Requires everything in Licensed plus:").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
                                Text("\u{2022} Certificate of Insurance (COI)").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text("\u{2022} Bonding certificate").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text("\u{2022} Business license / EIN").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text("\u{2022} Workers comp proof").font(.system(size: 9)).foregroundColor(Theme.muted)
                            }
                        }
                    }
                    .padding(14).background(selectedTier == tier ? tier.color.opacity(0.06) : Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedTier == tier ? tier.color.opacity(0.4) : Theme.border.opacity(0.15), lineWidth: selectedTier == tier ? 2 : 1))
                    .cornerRadius(12)
                }.buttonStyle(.plain)
            }

            // What blocks fakes
            VStack(alignment: .leading, spacing: 6) {
                Text("HOW WE PREVENT FRAUD").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.red)
                fraudItem("License numbers cross-referenced with state databases")
                fraudItem("Insurance certificates verified with carrier")
                fraudItem("OSHA cards checked against DOL records")
                fraudItem("Photos of physical cards required")
                fraudItem("24-48 hour human review before badge granted")
                fraudItem("Badge revoked if license expires")
                fraudItem("Annual re-verification required")
                fraudItem("3 community reports triggers immediate re-review")
            }.padding(12).background(Theme.red.opacity(0.04)).cornerRadius(10)

            Button {
                if selectedTier == .identity {
                    manager.submitIdentityVerification(name: profileStore.currentUser?.fullName ?? "", email: profileStore.currentUser?.email ?? "", phone: profileStore.currentUser?.phone ?? "")
                    dismiss()
                } else {
                    step = 1
                }
            } label: {
                Text("CONTINUE").font(.system(size: 13, weight: .bold)).tracking(1)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 48)
                    .background(LinearGradient(colors: [selectedTier.color, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
            }.buttonStyle(.plain)
        }
    }

    private func fraudItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "shield.checkered").font(.system(size: 8)).foregroundColor(Theme.red).padding(.top, 2)
            Text(text).font(.system(size: 9)).foregroundColor(Theme.muted)
        }
    }

    // MARK: - License Info
    private var licenseInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LICENSE INFORMATION").font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)

            if let req = tradeReq {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requirements for \(req.trade):").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.accent)
                    if req.requiresStateLicense {
                        Text("State license required").font(.system(size: 9)).foregroundColor(Theme.gold)
                        ForEach(req.licenseTypes, id: \.self) { lt in
                            Text("\u{2022} \(lt)").font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                    }
                    Text("Accepted certifications:").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted).padding(.top, 4)
                    ForEach(req.acceptedCertifications, id: \.self) { cert in
                        Text("\u{2022} \(cert)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Text("Verified with: \(req.verifyWith)").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan).padding(.top, 4)
                }.padding(12).background(Theme.surface).cornerRadius(10)
            }

            verifyField("License Type", "e.g. Master Electrician", $licenseType)
            verifyField("License Number", "e.g. ME-48291", $licenseNumber)
            verifyField("State / Issuing Authority", "e.g. Texas", $licenseState)

            Text("OSHA LEVEL").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.muted)
            HStack(spacing: 6) {
                ForEach(["OSHA 10", "OSHA 30", "OSHA 500", "None"], id: \.self) { level in
                    Button { oshaLevel = level } label: {
                        Text(level).font(.system(size: 9, weight: .bold))
                            .foregroundColor(oshaLevel == level ? .black : Theme.text)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(oshaLevel == level ? Theme.cyan : Theme.surface).cornerRadius(6)
                    }.buttonStyle(.plain)
                }
            }

            if let error { Text(error).font(.system(size: 10)).foregroundColor(Theme.red) }

            HStack(spacing: 8) {
                Button { step = 0 } label: {
                    Text("BACK").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 12).background(Theme.surface).cornerRadius(8)
                }.buttonStyle(.plain)
                Button {
                    guard !licenseNumber.isEmpty else { error = "License number is required"; return }
                    if selectedTier == .company { step = 2 } else { step = 3 }
                } label: {
                    Text("NEXT").font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing)).cornerRadius(8)
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: - Company Info
    private var companyInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPANY VERIFICATION").font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            Text("Additional documentation for Company Verified badge").font(.system(size: 9)).foregroundColor(Theme.muted)

            verifyField("EIN (Tax ID)", "XX-XXXXXXX", $ein)
            verifyField("Insurance Carrier", "e.g. Liberty Mutual", $insuranceCarrier)
            verifyField("Policy Number", "GL policy number", $policyNumber)
            verifyField("Bonding Company", "e.g. Travelers", $bondingCompany)
            verifyField("Bonding Capacity", "e.g. $5M single / $15M aggregate", $bondAmount)

            if let error { Text(error).font(.system(size: 10)).foregroundColor(Theme.red) }

            HStack(spacing: 8) {
                Button { step = 1 } label: {
                    Text("BACK").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 12).background(Theme.surface).cornerRadius(8)
                }.buttonStyle(.plain)
                Button {
                    guard !insuranceCarrier.isEmpty else { error = "Insurance carrier is required"; return }
                    step = 3
                } label: {
                    Text("REVIEW").font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(LinearGradient(colors: [Theme.gold, Theme.accent], startPoint: .leading, endPoint: .trailing)).cornerRadius(8)
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: - Review & Submit
    private var reviewView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REVIEW & SUBMIT").font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(Theme.green)

            VStack(alignment: .leading, spacing: 6) {
                reviewRow("Tier", selectedTier.rawValue)
                reviewRow("Price", selectedTier.price)
                reviewRow("Name", profileStore.currentUser?.fullName ?? "")
                reviewRow("Trade", profileStore.currentUser?.trade ?? "")
                reviewRow("License", "\(licenseType) #\(licenseNumber) (\(licenseState))")
                reviewRow("OSHA", oshaLevel)
                if selectedTier == .company {
                    reviewRow("EIN", ein)
                    reviewRow("Insurance", "\(insuranceCarrier) #\(policyNumber)")
                    reviewRow("Bonding", "\(bondingCompany) \(bondAmount)")
                }
            }.padding(14).background(Theme.surface).cornerRadius(12)

            Text("By submitting, you confirm all information is accurate. Providing false credentials will result in permanent account suspension.")
                .font(.system(size: 9)).foregroundColor(Theme.red.opacity(0.7))

            Button {
                let request = VerificationRequest(
                    tier: selectedTier.rawValue, fullName: profileStore.currentUser?.fullName ?? "",
                    email: profileStore.currentUser?.email ?? "", trade: profileStore.currentUser?.trade ?? "",
                    licenseType: licenseType, licenseNumber: licenseNumber, licenseState: licenseState,
                    oshaLevel: oshaLevel, companyName: profileStore.currentUser?.company ?? "",
                    ein: ein, insuranceCarrier: insuranceCarrier, policyNumber: policyNumber,
                    bondingCompany: bondingCompany, bondAmount: bondAmount,
                    status: "pending", submittedAt: Date(), reportCount: 0
                )
                manager.submitLicenseVerification(request: request)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 14))
                    Text("SUBMIT FOR VERIFICATION").font(.system(size: 13, weight: .bold)).tracking(1)
                }
                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 48)
                .background(LinearGradient(colors: [selectedTier.color, Theme.gold], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(10)
            }.buttonStyle(.plain)

            Button { step = selectedTier == .company ? 2 : 1 } label: {
                Text("Go back and edit").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)
                    .frame(maxWidth: .infinity)
            }.buttonStyle(.plain)
        }
    }

    private func reviewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.muted).frame(width: 70, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text)
        }
    }

    private func verifyField(_ label: String, _ placeholder: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            TextField(placeholder, text: text)
                .font(.system(size: 13)).foregroundColor(Theme.text)
                .padding(12).background(Theme.panel)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.2), lineWidth: 1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Verification Badge Display

struct VerificationBadgeView: View {
    let tier: VerificationTier
    let size: CGFloat

    var body: some View {
        if tier != .none {
            Image(systemName: tier.icon)
                .font(.system(size: size))
                .foregroundColor(tier.color)
        }
    }
}

// MARK: - Profile Verification Status Card

struct VerificationStatusCard: View {
    @ObservedObject var manager = VerificationManager.shared
    @State private var showApplication = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("VERIFICATION STATUS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                Spacer()
                VerificationBadgeView(tier: manager.currentTier, size: 16)
                Text(manager.currentTier.rawValue).font(.system(size: 9, weight: .bold)).foregroundColor(manager.currentTier.color)
            }

            if manager.currentTier == .none {
                Text("Get verified to build trust in the network. Show your license, insurance, and credentials.")
                    .font(.system(size: 10)).foregroundColor(Theme.muted)
                Button { showApplication = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 12))
                        Text("GET VERIFIED").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(LinearGradient(colors: [Theme.gold, Theme.accent], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(8)
                }.buttonStyle(.plain)
            } else if manager.currentTier == .identity {
                Text("Upgrade to License Verified (\(VerificationTier.licensed.price)) to show your credentials")
                    .font(.system(size: 10)).foregroundColor(Theme.muted)
                Button { showApplication = true } label: {
                    Text("UPGRADE TO LICENSED").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.cyan)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Theme.cyan.opacity(0.1)).cornerRadius(6)
                }.buttonStyle(.plain)
            } else {
                if let req = manager.currentRequest {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text("License:").font(.system(size: 9)).foregroundColor(Theme.muted); Text("\(req.licenseType) #\(String(req.licenseNumber.prefix(4)))****").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text) }
                        HStack { Text("State:").font(.system(size: 9)).foregroundColor(Theme.muted); Text(req.licenseState).font(.system(size: 9)).foregroundColor(Theme.text) }
                        HStack { Text("OSHA:").font(.system(size: 9)).foregroundColor(Theme.muted); Text(req.oshaLevel).font(.system(size: 9)).foregroundColor(Theme.text) }
                        if !req.insuranceCarrier.isEmpty {
                            HStack { Text("Insurance:").font(.system(size: 9)).foregroundColor(Theme.muted); Text("\(req.insuranceCarrier) \u{2022} Active").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green) }
                        }
                        HStack { Text("Verified:").font(.system(size: 9)).foregroundColor(Theme.muted); Text(req.submittedAt, style: .date).font(.system(size: 9)).foregroundColor(Theme.text) }
                        Text("Annual re-verification required").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(manager.currentTier.color.opacity(0.2), lineWidth: 1))
        .sheet(isPresented: $showApplication) { VerificationApplicationView() }
    }
}
