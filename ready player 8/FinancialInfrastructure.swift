import SwiftUI
import Combine

// MARK: - ========== ConstructionOS Financial Infrastructure ==========
// The payment rails, lending, insurance, and supply chain for global construction

// MARK: - ConstructionOS Pay

struct PaymentTransaction: Identifiable, Codable {
    var id = UUID()
    let fromName: String
    let toName: String
    let amount: Double
    let type: String        // "invoice", "payroll", "material", "rental", "bond"
    let projectRef: String
    let status: String      // "pending", "processing", "completed", "failed"
    let fee: Double
    let date: Date
}

// MARK: - Payment Gateway Configuration

struct PaymentGatewayConfig {
    // Paddle (Merchant of Record) — standard card/bank payments
    static let paddleEnabled: Bool = {
        let key = KeychainHelper.read(key: "Paddle.APIKey") ?? ""
        return !key.isEmpty
    }()
    static var paddleAPIKey: String { KeychainHelper.read(key: "Paddle.APIKey") ?? "" }
    static var paddleWebhookSecret: String { KeychainHelper.read(key: "Paddle.WebhookSecret") ?? "" }

    // Coinbase Commerce — crypto payments
    static let coinbaseEnabled: Bool = {
        let key = KeychainHelper.read(key: "Coinbase.APIKey") ?? ""
        return !key.isEmpty
    }()
    static var coinbaseAPIKey: String { KeychainHelper.read(key: "Coinbase.APIKey") ?? "" }

    // Supported standard payment methods
    static let standardMethods = ["Visa", "Mastercard", "Amex", "Apple Pay", "Google Pay", "Bank Transfer", "PayPal", "ACH Direct"]

    // Configure keys (called from Integration Hub)
    static func configurePaddle(apiKey: String, webhookSecret: String) {
        KeychainHelper.save(key: "Paddle.APIKey", data: apiKey)
        KeychainHelper.save(key: "Paddle.WebhookSecret", data: webhookSecret)
    }

    static func configureCoinbase(apiKey: String) {
        KeychainHelper.save(key: "Coinbase.APIKey", data: apiKey)
    }
}

@MainActor
final class ConstructionOSPay: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = ConstructionOSPay()
    @Published var balance: Double = 0
    @Published var pendingIn: Double = 0
    @Published var pendingOut: Double = 0
    @Published var transactions: [PaymentTransaction] = []
    @Published var processingFeeRate: Double = 0.015  // 1.5%
    @Published var paymentGateway: String = PaymentGatewayConfig.paddleEnabled ? "Paddle" : "Demo"

    private let key = "ConstructOS.Pay.Transactions"
    init() {
        transactions = loadJSON(key, default: mockTransactions)
        balance = transactions.filter { $0.status == "completed" && $0.toName == "You" }.reduce(0) { $0 + $1.amount }
        pendingIn = transactions.filter { $0.status == "pending" && $0.toName == "You" }.reduce(0) { $0 + $1.amount }
        pendingOut = transactions.filter { $0.status == "pending" && $0.fromName == "You" }.reduce(0) { $0 + $1.amount }
    }

    func sendPayment(to: String, amount: Double, type: String, project: String) {
        let fee = amount * processingFeeRate
        let tx = PaymentTransaction(fromName: "You", toName: to, amount: amount, type: type, projectRef: project, status: PaymentGatewayConfig.paddleEnabled ? "processing" : "demo", fee: fee, date: Date())
        transactions.insert(tx, at: 0)
        pendingOut += amount
        saveJSON(key, value: transactions)

        // If Paddle is configured, create a real transaction
        if PaymentGatewayConfig.paddleEnabled {
            Task { await createPaddleTransaction(amount: amount, to: to, type: type) }
        }
    }

    func requestPayment(from: String, amount: Double, type: String, project: String) {
        let tx = PaymentTransaction(fromName: from, toName: "You", amount: amount, type: type, projectRef: project, status: "pending", fee: 0, date: Date())
        transactions.insert(tx, at: 0)
        pendingIn += amount
        saveJSON(key, value: transactions)
    }

    private func createPaddleTransaction(amount: Double, to: String, type: String) async {
        // Paddle API integration — creates a transaction via their REST API
        guard !PaymentGatewayConfig.paddleAPIKey.isEmpty,
              let url = URL(string: "https://api.paddle.com/transactions") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(PaymentGatewayConfig.paddleAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "items": [["quantity": 1]],
            "custom_data": ["to": to, "type": type, "platform": "ios"]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Paddle transaction: HTTP \(httpResponse.statusCode)")
            }
        } catch {
            print("Paddle transaction error: \(error.localizedDescription)")
        }
    }
}

private let mockTransactions: [PaymentTransaction] = [
    PaymentTransaction(fromName: "Metro Development", toName: "You", amount: 284500, type: "invoice", projectRef: "Riverside Lofts", status: "completed", fee: 4267.50, date: Date().addingTimeInterval(-86400*3)),
    PaymentTransaction(fromName: "You", toName: "Apex Concrete LLC", amount: 48200, type: "payroll", projectRef: "Riverside Lofts", status: "completed", fee: 723, date: Date().addingTimeInterval(-86400*5)),
    PaymentTransaction(fromName: "You", toName: "Nucor Steel", amount: 62400, type: "material", projectRef: "Harbor Crossing", status: "processing", fee: 936, date: Date().addingTimeInterval(-86400)),
    PaymentTransaction(fromName: "Harbor Industries", toName: "You", amount: 198750, type: "invoice", projectRef: "Harbor Crossing", status: "pending", fee: 0, date: Date()),
    PaymentTransaction(fromName: "You", toName: "United Rentals", amount: 8500, type: "rental", projectRef: "Pine Ridge", status: "completed", fee: 127.50, date: Date().addingTimeInterval(-86400*7)),
    PaymentTransaction(fromName: "Urban Living", toName: "You", amount: 156200, type: "invoice", projectRef: "Riverside Residential", status: "pending", fee: 0, date: Date().addingTimeInterval(-86400*2)),
]

// MARK: - ConstructionOS Capital (Invoice Factoring)

struct FactoringOffer: Identifiable {
    let id = UUID()
    let invoiceRef: String
    let client: String
    let invoiceAmount: Double
    let advanceRate: Double     // 90%
    let fee: Double             // 2.5%
    let advanceAmount: Double
    let holdback: Double
    let daysToFund: Int
    let status: String
}

@MainActor
final class ConstructionOSCapital: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = ConstructionOSCapital()
    @Published var creditLine: Double = 500000
    @Published var available: Double = 347000
    @Published var outstanding: Double = 153000
    @Published var offers: [FactoringOffer] = []

    init() {
        offers = [
            FactoringOffer(invoiceRef: "PAY-APP-07", client: "Metro Development", invoiceAmount: 284500, advanceRate: 0.90, fee: 0.025, advanceAmount: 256050, holdback: 28450, daysToFund: 1, status: "available"),
            FactoringOffer(invoiceRef: "PAY-APP-04", client: "Harbor Industries", invoiceAmount: 198750, advanceRate: 0.90, fee: 0.025, advanceAmount: 178875, holdback: 19875, daysToFund: 1, status: "available"),
            FactoringOffer(invoiceRef: "PAY-APP-12", client: "Urban Living", invoiceAmount: 156200, advanceRate: 0.90, fee: 0.025, advanceAmount: 140580, holdback: 15620, daysToFund: 1, status: "funded"),
        ]
    }
}

// MARK: - ConstructionOS Insurance

struct InsuranceQuote: Identifiable {
    let id = UUID()
    let carrier: String
    let type: String            // "GL", "WC", "Umbrella", "Builder's Risk", "Professional"
    let coverage: String
    let annualPremium: Double
    let deductible: String
    let rating: String          // "A+", "A", "A-"
    let recommended: Bool
}

@MainActor
final class ConstructionOSInsurance: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = ConstructionOSInsurance()
    @Published var riskScore: Int = 82
    @Published var quotes: [InsuranceQuote] = []
    @Published var activePolicies: [(type: String, carrier: String, premium: String, expires: String)] = []

    init() {
        quotes = [
            InsuranceQuote(carrier: "Liberty Mutual", type: "General Liability", coverage: "$2M/$4M", annualPremium: 8400, deductible: "$2,500", rating: "A", recommended: true),
            InsuranceQuote(carrier: "Zurich", type: "General Liability", coverage: "$2M/$4M", annualPremium: 9200, deductible: "$5,000", rating: "A+", recommended: false),
            InsuranceQuote(carrier: "Travelers", type: "Workers Comp", coverage: "Statutory", annualPremium: 42000, deductible: "$1,000", rating: "A+", recommended: true),
            InsuranceQuote(carrier: "Hartford", type: "Workers Comp", coverage: "Statutory", annualPremium: 38500, deductible: "$2,500", rating: "A", recommended: false),
            InsuranceQuote(carrier: "CNA", type: "Umbrella", coverage: "$5M", annualPremium: 6800, deductible: "$10,000", rating: "A", recommended: true),
            InsuranceQuote(carrier: "Berkshire Hathaway", type: "Builder's Risk", coverage: "$10M", annualPremium: 12400, deductible: "$25,000", rating: "A++", recommended: true),
            InsuranceQuote(carrier: "Chubb", type: "Professional Liability", coverage: "$1M/$3M", annualPremium: 4200, deductible: "$5,000", rating: "A++", recommended: false),
        ]
        activePolicies = [
            ("General Liability", "Liberty Mutual", "$8,400/yr", "Dec 2026"),
            ("Workers Comp", "Travelers", "$42,000/yr", "Jun 2026"),
            ("Umbrella", "CNA", "$6,800/yr", "Dec 2026"),
        ]
    }
}

// MARK: - ConstructionOS Workforce (Staffing)

struct WorkforceCandidate: Identifiable {
    let id = UUID()
    let name: String
    let trade: String
    let experience: Int
    let rate: String
    let location: String
    let available: String
    let certs: [String]
    let rating: Double
    let matchScore: Int
    let initials: String
}

struct StaffingRequest: Identifiable, Codable {
    var id = UUID()
    let trade: String
    let headcount: Int
    let startDate: String
    let duration: String
    let payRate: String
    let site: String
    let status: String
}

// MARK: - ConstructionOS Supply Chain

struct MaterialOrder: Identifiable {
    let id = UUID()
    let material: String
    let supplier: String
    let quantity: String
    let unitPrice: String
    let totalPrice: Double
    let groupDiscount: Double
    let savings: Double
    let deliveryDate: String
    let status: String
}

// MARK: - ConstructionOS Bonds (Surety)

struct SuretyBond: Identifiable {
    let id = UUID()
    let type: String            // "Bid Bond", "Performance Bond", "Payment Bond"
    let project: String
    let amount: Double
    let premium: Double
    let surety: String
    let status: String
    let expires: String
}

// MARK: - ConstructionOS Intelligence (Data)

struct MarketIntelReport: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let price: String
    let dataPoints: Int
    let lastUpdated: String
    let description: String
}

// MARK: - ========== Empire Dashboard View ==========

struct EmpireDashboardView: View {
    @State private var activeTab = 0
    private let tabs = ["Pay", "Capital", "Insurance", "Workforce", "Supply", "Bonds", "Intel"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{1F3E6}").font(.system(size: 18))
                            Text("EMPIRE").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.gold)
                        }
                        Text("Financial Infrastructure").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Payments, lending, insurance, staffing, supply chain").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                }.padding(16).background(Theme.surface).cornerRadius(14).premiumGlow(cornerRadius: 14, color: Theme.gold)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button { withAnimation { activeTab = i } } label: {
                                Text(tabs[i].uppercased()).font(.system(size: 8, weight: .bold)).tracking(1)
                                    .foregroundColor(activeTab == i ? .black : Theme.muted)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(activeTab == i ? Theme.gold : Theme.surface)
                            }.buttonStyle(.plain)
                        }
                    }.cornerRadius(8)
                }

                switch activeTab {
                case 0:
                    if FeatureGates.payments.isAvailable { payView } else {
                        ComingSoonOverlay(feature: "ConstructionOS Pay", description: "Payment processing for invoices, payroll, materials, and rentals. 1.5% processing fee with instant transfers.", expectedDate: "Q3 2026")
                    }
                    LegalDisclaimerView(text: LegalDisclaimers.paymentDisclaimer)
                case 1:
                    if FeatureGates.capital.isAvailable { capitalView } else {
                        ComingSoonOverlay(feature: "ConstructionOS Capital", description: "Invoice factoring — get 90% of approved pay apps advanced in 24 hours. 2.5% factoring fee.", expectedDate: "Q4 2026")
                    }
                    LegalDisclaimerView(text: LegalDisclaimers.capitalDisclaimer)
                case 2:
                    if FeatureGates.insurance.isAvailable { insuranceView } else {
                        ComingSoonOverlay(feature: "ConstructionOS Insurance", description: "Compare quotes from top carriers. GL, Workers Comp, Umbrella, Builder's Risk.", expectedDate: "Q3 2026")
                    }
                    LegalDisclaimerView(text: LegalDisclaimers.insuranceDisclaimer)
                case 3: workforceView; LegalDisclaimerView(text: LegalDisclaimers.workforceDisclaimer)
                case 4: supplyChainView
                case 5:
                    if FeatureGates.bonds.isAvailable { bondsView } else {
                        ComingSoonOverlay(feature: "ConstructionOS Bonds", description: "Surety bonding powered by your project performance data. Bid, performance, and payment bonds.", expectedDate: "Q4 2026")
                    }
                    LegalDisclaimerView(text: LegalDisclaimers.bondDisclaimer)
                default: intelView
                }
            }.padding(16)
        }.background(Theme.bg)
    }

    // MARK: - Pay
    private var payView: some View {
        let pay = ConstructionOSPay.shared
        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS PAY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.0f", pay.balance / 1000))K").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.green)
                    Text("BALANCE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.0f", pay.pendingIn / 1000))K").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.cyan)
                    Text("INCOMING").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.0f", pay.pendingOut / 1000))K").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.gold)
                    Text("OUTGOING").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("1.5%").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("FEE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
            }

            HStack(spacing: 8) {
                Button { ToastManager.shared.show("Coming soon") } label: { Label("SEND", systemImage: "arrow.up.circle.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 10).background(Theme.accent).cornerRadius(8) }.buttonStyle(.plain)
                Button { ToastManager.shared.show("Coming soon") } label: { Label("REQUEST", systemImage: "arrow.down.circle.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 10).background(Theme.green).cornerRadius(8) }.buttonStyle(.plain)
            }

            ForEach(pay.transactions) { tx in
                HStack(spacing: 10) {
                    Circle().fill(tx.toName == "You" ? Theme.green.opacity(0.15) : Theme.red.opacity(0.15)).frame(width: 36, height: 36)
                        .overlay(Image(systemName: tx.toName == "You" ? "arrow.down" : "arrow.up").font(.system(size: 14)).foregroundColor(tx.toName == "You" ? Theme.green : Theme.red))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.toName == "You" ? tx.fromName : tx.toName).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(tx.type.capitalized) \u{2022} \(tx.projectRef)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(tx.toName == "You" ? "+" : "-")$\(String(format: "%.0f", tx.amount))").font(.system(size: 12, weight: .heavy)).foregroundColor(tx.toName == "You" ? Theme.green : Theme.text)
                        Text(tx.status.uppercased()).font(.system(size: 7, weight: .black)).foregroundColor(tx.status == "completed" ? Theme.green : tx.status == "processing" ? Theme.gold : Theme.cyan)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    // MARK: - Capital
    private var capitalView: some View {
        let cap = ConstructionOSCapital.shared
        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS CAPITAL").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
            Text("Get paid today. Don't wait 60-90 days for pay apps.").font(.system(size: 9)).foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", cap.creditLine / 1000))K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("CREDIT LINE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", cap.available / 1000))K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("AVAILABLE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("2.5%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("FACTORING FEE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }

            Text("AVAILABLE ADVANCES").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.cyan)
            ForEach(cap.offers) { offer in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(offer.invoiceRef).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Text(offer.client).font(.system(size: 9)).foregroundColor(Theme.muted); Spacer(); Text(offer.status.uppercased()).font(.system(size: 7, weight: .black)).foregroundColor(offer.status == "funded" ? Theme.green : Theme.accent) }
                    HStack(spacing: 16) {
                        VStack(spacing: 1) { Text("$\(String(format: "%.0f", offer.invoiceAmount / 1000))K").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text); Text("INVOICE").font(.system(size: 7)).foregroundColor(Theme.muted) }
                        Image(systemName: "arrow.right").foregroundColor(Theme.accent)
                        VStack(spacing: 1) { Text("$\(String(format: "%.0f", offer.advanceAmount / 1000))K").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green); Text("ADVANCE (90%)").font(.system(size: 7)).foregroundColor(Theme.muted) }
                        VStack(spacing: 1) { Text("$\(String(format: "%.0f", offer.invoiceAmount * offer.fee / 1000))K").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.gold); Text("FEE (2.5%)").font(.system(size: 7)).foregroundColor(Theme.muted) }
                    }
                    if offer.status == "available" {
                        Button { ToastManager.shared.show("Coming soon") } label: { Text("GET FUNDED IN \(offer.daysToFund) DAY").font(.system(size: 10, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 8).background(Theme.green).cornerRadius(6) }.buttonStyle(.plain)
                    }
                }.padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
    }

    // MARK: - Insurance
    private var insuranceView: some View {
        let ins = ConstructionOSInsurance.shared
        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS INSURANCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("\(ins.riskScore)").font(.system(size: 20, weight: .heavy)).foregroundColor(ins.riskScore >= 80 ? Theme.green : Theme.gold); Text("RISK SCORE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(ins.activePolicies.count)").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.cyan); Text("ACTIVE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("\(ins.quotes.count)").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.accent); Text("QUOTES").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
            }

            Text("ACTIVE POLICIES").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.green)
            ForEach(ins.activePolicies, id: \.type) { p in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 14)).foregroundColor(Theme.green)
                    VStack(alignment: .leading, spacing: 1) { Text(p.type).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Text(p.carrier).font(.system(size: 8)).foregroundColor(Theme.muted) }
                    Spacer()
                    Text(p.premium).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("exp \(p.expires)").font(.system(size: 8)).foregroundColor(Theme.muted)
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }

            Text("COMPETITIVE QUOTES").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.accent)
            ForEach(ins.quotes) { q in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) { Text(q.type).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); if q.recommended { Text("BEST").font(.system(size: 7, weight: .black)).foregroundColor(.black).padding(.horizontal, 4).padding(.vertical, 1).background(Theme.green).cornerRadius(3) } }
                        Text("\(q.carrier) \u{2022} \(q.rating) rated \u{2022} \(q.coverage)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) { Text("$\(String(format: "%.0f", q.annualPremium))").font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent); Text("/year").font(.system(size: 7)).foregroundColor(Theme.muted) }
                }.padding(8).background(q.recommended ? Theme.green.opacity(0.04) : Theme.surface).cornerRadius(6)
            }
        }
    }

    // MARK: - Workforce
    private var workforceView: some View {
        let candidates: [WorkforceCandidate] = [
            WorkforceCandidate(name: "Tony Ramirez", trade: "Concrete", experience: 12, rate: "$38/hr", location: "Houston, TX", available: "Immediate", certs: ["ACI", "OSHA 30"], rating: 4.8, matchScore: 95, initials: "TR"),
            WorkforceCandidate(name: "Mike Sullivan", trade: "Electrical", experience: 8, rate: "$45/hr", location: "Houston, TX", available: "1 week", certs: ["Journeyman", "OSHA 10"], rating: 4.6, matchScore: 88, initials: "MS"),
            WorkforceCandidate(name: "Lisa Park", trade: "Steel", experience: 15, rate: "$42/hr", location: "Dallas, TX", available: "2 weeks", certs: ["AWS D1.1", "OSHA 30"], rating: 4.9, matchScore: 82, initials: "LP"),
            WorkforceCandidate(name: "James Carter", trade: "Framing", experience: 6, rate: "$32/hr", location: "Houston, TX", available: "Immediate", certs: ["OSHA 10"], rating: 4.5, matchScore: 78, initials: "JC"),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS WORKFORCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            Text("AI-matched workers placed automatically. You pay, we handle payroll & compliance.").font(.system(size: 9)).foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("15%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("PLATFORM FEE").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("24hr").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("AVG PLACEMENT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("8M+").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.cyan); Text("WORKERS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.cyan.opacity(0.06)).cornerRadius(8)
            }

            Text("AI-MATCHED CANDIDATES").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.green)
            ForEach(candidates) { c in
                HStack(spacing: 10) {
                    ZStack(alignment: .topTrailing) {
                        Circle().fill(LinearGradient(colors: [Theme.cyan, Theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 40, height: 40)
                            .overlay(Text(c.initials).font(.system(size: 13, weight: .heavy)).foregroundColor(.white))
                        Text("\(c.matchScore)%").font(.system(size: 7, weight: .black)).foregroundColor(.black).padding(.horizontal, 3).padding(.vertical, 1).background(Theme.green).cornerRadius(3).offset(x: 4, y: -4)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.name).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(c.trade) \u{2022} \(c.experience) yrs \u{2022} \(c.location)").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(c.certs.joined(separator: " \u{2022} ")).font(.system(size: 8)).foregroundColor(Theme.cyan)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(c.rate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent)
                        Text(c.available).font(.system(size: 8, weight: .bold)).foregroundColor(c.available == "Immediate" ? Theme.green : Theme.gold)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    // MARK: - Supply Chain
    private var supplyChainView: some View {
        let orders: [MaterialOrder] = [
            MaterialOrder(material: "Structural Steel W8x31", supplier: "Nucor Steel", quantity: "48 tons", unitPrice: "$1,820/ton", totalPrice: 87360, groupDiscount: 12, savings: 11904, deliveryDate: "Apr 5", status: "CONFIRMED"),
            MaterialOrder(material: "Ready Mix 4000 PSI", supplier: "LaFarge", quantity: "240 CY", unitPrice: "$142/CY", totalPrice: 34080, groupDiscount: 8, savings: 2966, deliveryDate: "Apr 1", status: "ORDERED"),
            MaterialOrder(material: "5/8\" Type X Drywall", supplier: "USG Corp", quantity: "12,000 SF", unitPrice: "$0.68/SF", totalPrice: 8160, groupDiscount: 15, savings: 1440, deliveryDate: "Apr 12", status: "PENDING"),
            MaterialOrder(material: "3/4\" EMT Conduit", supplier: "Graybar Electric", quantity: "2,400 ft", unitPrice: "$1.45/ft", totalPrice: 3480, groupDiscount: 10, savings: 387, deliveryDate: "Apr 3", status: "CONFIRMED"),
        ]
        let totalSavings = orders.reduce(0.0) { $0 + $1.savings }

        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS SUPPLY CHAIN").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            Text("Group purchasing power. Volume pricing no individual contractor can get.").font(.system(size: 9)).foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("$\(String(format: "%.0f", totalSavings / 1000))K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green); Text("SAVED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("142K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent); Text("BUYERS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("8-15%").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold); Text("AVG DISCOUNT").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }

            ForEach(orders) { order in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(order.material).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text(order.status).font(.system(size: 7, weight: .black)).foregroundColor(order.status == "CONFIRMED" ? Theme.green : Theme.gold) }
                    HStack(spacing: 12) {
                        Text("\(order.supplier) \u{2022} \(order.quantity)").font(.system(size: 8)).foregroundColor(Theme.muted)
                        Spacer()
                        Text("$\(String(format: "%.0f", order.totalPrice))").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.accent)
                        Text("-\(String(format: "%.0f", order.groupDiscount))%").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
                        Text("saved $\(String(format: "%.0f", order.savings))").font(.system(size: 8)).foregroundColor(Theme.green)
                    }
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
    }

    // MARK: - Bonds
    private var bondsView: some View {
        let bonds: [SuretyBond] = [
            SuretyBond(type: "Bid Bond", project: "City Hall Renovation", amount: 500000, premium: 2500, surety: "Travelers", status: "ACTIVE", expires: "Apr 15, 2026"),
            SuretyBond(type: "Performance Bond", project: "Riverside Lofts", amount: 4200000, premium: 63000, surety: "Liberty Mutual", status: "ACTIVE", expires: "Dec 2026"),
            SuretyBond(type: "Payment Bond", project: "Riverside Lofts", amount: 4200000, premium: 42000, surety: "Liberty Mutual", status: "ACTIVE", expires: "Dec 2026"),
            SuretyBond(type: "Bid Bond", project: "Airport Terminal B", amount: 2000000, premium: 10000, surety: "Zurich", status: "PENDING", expires: "May 1, 2026"),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS BONDS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
            Text("Surety bonding powered by your ConstructionOS performance data").font(.system(size: 9)).foregroundColor(Theme.muted)

            HStack(spacing: 8) {
                VStack(spacing: 2) { Text("$10.9M").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent); Text("BONDED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.accent.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$50M").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.green); Text("CAPACITY").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) { Text("$117K").font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.gold); Text("PREMIUMS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted) }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
            }

            ForEach(bonds) { bond in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bond.type).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(bond.project) \u{2022} \(bond.surety)").font(.system(size: 8)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.0f", bond.amount / 1000))K").font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.accent)
                        Text(bond.status).font(.system(size: 7, weight: .black)).foregroundColor(bond.status == "ACTIVE" ? Theme.green : Theme.gold)
                    }
                }.padding(8).background(Theme.surface).cornerRadius(6)
            }
        }
    }

    // MARK: - Intelligence
    private var intelView: some View {
        let reports: [MarketIntelReport] = [
            MarketIntelReport(title: "Houston Commercial Construction Q1 2026", category: "Market Report", price: "$499", dataPoints: 14200, lastUpdated: "Mar 2026", description: "Cost per SF, labor rates, material trends, bid activity"),
            MarketIntelReport(title: "National Concrete Pricing Trends", category: "Material Intelligence", price: "$299", dataPoints: 8400, lastUpdated: "Mar 2026", description: "Regional pricing, supply chain status, demand forecast"),
            MarketIntelReport(title: "Data Center Construction Pipeline", category: "Sector Report", price: "$799", dataPoints: 22000, lastUpdated: "Mar 2026", description: "Planned projects, contractor demand, technology trends"),
            MarketIntelReport(title: "Construction Labor Market Analysis", category: "Workforce Report", price: "$399", dataPoints: 31000, lastUpdated: "Mar 2026", description: "Wage trends, availability by trade, migration patterns"),
            MarketIntelReport(title: "Equipment Rental Rate Index", category: "Equipment Report", price: "$199", dataPoints: 9700, lastUpdated: "Mar 2026", description: "Average rates by category, utilization trends, seasonal patterns"),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("CONSTRUCTIONOS INTELLIGENCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
            Text("Real-time market data from 142,891 professionals. Updated continuously.").font(.system(size: 9)).foregroundColor(Theme.muted)

            ForEach(reports) { report in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(report.title).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text); Spacer(); Text(report.price).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.accent) }
                    Text(report.description).font(.system(size: 9)).foregroundColor(Theme.muted)
                    HStack(spacing: 8) {
                        Text(report.category).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                        Text("\(report.dataPoints) data points").font(.system(size: 8)).foregroundColor(Theme.muted)
                        Text("Updated \(report.lastUpdated)").font(.system(size: 8)).foregroundColor(Theme.muted)
                        Spacer()
                        Button { ToastManager.shared.show("Coming soon") } label: { Text("BUY").font(.system(size: 8, weight: .bold)).foregroundColor(.black).padding(.horizontal, 10).padding(.vertical, 4).background(Theme.accent).cornerRadius(4) }.buttonStyle(.plain)
                    }
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }
}
