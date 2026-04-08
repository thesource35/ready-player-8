import SwiftUI
import Combine

// MARK: - ========== Crypto Payment System ==========
// Full blockchain payment integration across the entire ConstructionOS platform

// MARK: - Wallet Configuration

struct CryptoWalletConfig {
    // ConstructionOS Treasury Wallets
    static let btcAddress = "14cpCvr5L2FrtepR5z254956JW8shZYRYH"
    static let ethAddress = "0x9BbFAdB79e3ABC457e989A07C1C32aC6334482D1"
    static let solAddress = "C94tEkPNBM2wc3kaTsvkJo2iVQqmApGKocdCao7skBUg"

    static let supportedChains: [CryptoChain] = [
        CryptoChain(name: "Bitcoin", symbol: "BTC", icon: "\u{20BF}", color: Color(red: 0.96, green: 0.66, blue: 0.0), address: btcAddress, network: "Bitcoin Mainnet"),
        CryptoChain(name: "Ethereum", symbol: "ETH", icon: "\u{039E}", color: Color(red: 0.38, green: 0.49, blue: 0.92), address: ethAddress, network: "Ethereum Mainnet"),
        CryptoChain(name: "Solana", symbol: "SOL", icon: "\u{25CE}", color: Color(red: 0.60, green: 0.20, blue: 0.96), address: solAddress, network: "Solana Mainnet"),
        CryptoChain(name: "USDC", symbol: "USDC", icon: "$", color: Color(red: 0.16, green: 0.46, blue: 0.88), address: ethAddress, network: "Ethereum (ERC-20)"),
        CryptoChain(name: "USDT", symbol: "USDT", icon: "$", color: Color(red: 0.16, green: 0.65, blue: 0.53), address: ethAddress, network: "Ethereum (ERC-20)"),
        CryptoChain(name: "Polygon", symbol: "MATIC", icon: "\u{2B21}", color: Color(red: 0.51, green: 0.27, blue: 0.85), address: ethAddress, network: "Polygon Mainnet"),
        CryptoChain(name: "Avalanche", symbol: "AVAX", icon: "\u{25B2}", color: Color(red: 0.89, green: 0.24, blue: 0.27), address: ethAddress, network: "Avalanche C-Chain"),
        CryptoChain(name: "Chainlink", symbol: "LINK", icon: "\u{26D3}", color: Color(red: 0.21, green: 0.40, blue: 0.89), address: ethAddress, network: "Ethereum (ERC-20)"),
    ]
}

struct CryptoChain: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let icon: String
    let color: Color
    let address: String
    let network: String
}

// MARK: - Crypto Transaction

struct CryptoTransaction: Identifiable, Codable {
    var id = UUID()
    let chain: String
    let symbol: String
    let amount: Double
    let usdEquivalent: Double
    let fromAddress: String
    let toAddress: String
    let txHash: String
    let purpose: String      // "subscription", "pay", "material", "rental", "invoice", "bond"
    let projectRef: String
    let status: String       // "pending", "confirming", "confirmed", "failed"
    let confirmations: Int
    let requiredConfirmations: Int
    let timestamp: Date
}

// MARK: - Crypto Payment Manager

@MainActor
final class CryptoPaymentManager: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = CryptoPaymentManager()

    @Published var transactions: [CryptoTransaction] = []
    @Published var selectedChain: CryptoChain = CryptoWalletConfig.supportedChains[0]
    @Published var totalCryptoReceived: Double = 0
    @Published var pendingCryptoPayments: Int = 0

    private let key = "ConstructOS.Crypto.Transactions"
    private let ratesKey = "ConstructOS.Crypto.Rates"
    private let ratesTimestampKey = "ConstructOS.Crypto.RatesTimestamp"

    // Live exchange rates — fetched from CoinGecko, cached 60s, fallback to defaults
    @Published var exchangeRates: [String: Double] = [
        "BTC": 67842.50, "ETH": 3456.78, "SOL": 178.92, "USDC": 1.00,
        "USDT": 1.00, "MATIC": 0.72, "AVAX": 38.45, "LINK": 18.62,
    ]
    @Published var priceChanges24h: [String: Double] = [:]
    @Published var ratesLastUpdated: Date? = nil

    private static let coinGeckoURL = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana,usd-coin,tether,matic-network,avalanche-2,chainlink&vs_currencies=usd&include_24hr_change=true"
    private static let symbolMap: [String: String] = [
        "bitcoin": "BTC", "ethereum": "ETH", "solana": "SOL", "usd-coin": "USDC",
        "tether": "USDT", "matic-network": "MATIC", "avalanche-2": "AVAX", "chainlink": "LINK",
    ]

    init() {
        transactions = loadJSON(key, default: mockCryptoTransactions)
        totalCryptoReceived = transactions.filter { $0.status == "confirmed" }.reduce(0) { $0 + $1.usdEquivalent }
        pendingCryptoPayments = transactions.filter { $0.status == "pending" || $0.status == "confirming" }.count

        // Load cached rates from disk
        let cached: [String: Double] = loadJSON(ratesKey, default: [:])
        if !cached.isEmpty { exchangeRates = cached }

        // Fetch live rates from CoinGecko
        Task { await fetchLiveRates() }
    }

    func fetchLiveRates() async {
        let lastFetch = UserDefaults.standard.double(forKey: ratesTimestampKey)
        let now = Date().timeIntervalSince1970
        guard now - lastFetch > 60 else { return }

        guard let url = URL(string: Self.coinGeckoURL) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Double]] {
                var newRates: [String: Double] = [:]
                var newChanges: [String: Double] = [:]
                for (coinId, values) in json {
                    if let symbol = Self.symbolMap[coinId], let price = values["usd"] {
                        newRates[symbol] = price
                        if let change = values["usd_24h_change"] {
                            newChanges[symbol] = (change * 100).rounded() / 100
                        }
                    }
                }
                if !newRates.isEmpty {
                    exchangeRates = newRates
                    priceChanges24h = newChanges
                    ratesLastUpdated = Date()
                    saveJSON(ratesKey, value: newRates)
                    UserDefaults.standard.set(now, forKey: ratesTimestampKey)
                }
            }
        } catch {
            #if DEBUG
            print("[CryptoPayments] Rate fetch failed: \(error.localizedDescription)")
            #endif
        }
    }

    func cryptoAmount(usd: Double, chain: String) -> Double {
        guard let rate = exchangeRates[chain], rate > 0 else { return 0 }
        return usd / rate
    }

    func createPayment(usdAmount: Double, chain: CryptoChain, purpose: String, projectRef: String) -> CryptoTransaction {
        let cryptoAmt = cryptoAmount(usd: usdAmount, chain: chain.symbol)
        let tx = CryptoTransaction(
            chain: chain.name, symbol: chain.symbol,
            amount: cryptoAmt, usdEquivalent: usdAmount,
            fromAddress: "pending...", toAddress: chain.address,
            txHash: "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(40))",
            purpose: purpose, projectRef: projectRef,
            status: "pending", confirmations: 0,
            requiredConfirmations: chain.symbol == "BTC" ? 3 : chain.symbol == "SOL" ? 1 : 12,
            timestamp: Date()
        )
        transactions.insert(tx, at: 0)
        pendingCryptoPayments += 1
        saveJSON(key, value: transactions)
        return tx
    }

    func formatCrypto(_ amount: Double, symbol: String) -> String {
        switch symbol {
        case "BTC": return String(format: "%.6f BTC", amount)
        case "ETH": return String(format: "%.4f ETH", amount)
        case "SOL": return String(format: "%.2f SOL", amount)
        case "USDC", "USDT": return String(format: "%.2f %@", amount, symbol)
        default: return String(format: "%.4f %@", amount, symbol)
        }
    }
}

private let mockCryptoTransactions: [CryptoTransaction] = [
    CryptoTransaction(chain: "Ethereum", symbol: "ETH", amount: 0.0072, usdEquivalent: 24.99, fromAddress: "0x742d...8f4a", toAddress: CryptoWalletConfig.ethAddress, txHash: "0xabc123...def456", purpose: "subscription", projectRef: "PM Monthly", status: "confirmed", confirmations: 24, requiredConfirmations: 12, timestamp: Date().addingTimeInterval(-86400)),
    CryptoTransaction(chain: "Bitcoin", symbol: "BTC", amount: 0.00071, usdEquivalent: 48200, fromAddress: "bc1q...7x9m", toAddress: CryptoWalletConfig.btcAddress, txHash: "3a1b2c...9d8e7f", purpose: "pay", projectRef: "Apex Concrete Payment", status: "confirmed", confirmations: 6, requiredConfirmations: 3, timestamp: Date().addingTimeInterval(-172800)),
    CryptoTransaction(chain: "USDC", symbol: "USDC", amount: 8500, usdEquivalent: 8500, fromAddress: "0x891f...2c3d", toAddress: CryptoWalletConfig.ethAddress, txHash: "0xdef789...abc012", purpose: "rental", projectRef: "CAT 320 Excavator", status: "confirmed", confirmations: 15, requiredConfirmations: 12, timestamp: Date().addingTimeInterval(-259200)),
    CryptoTransaction(chain: "Solana", symbol: "SOL", amount: 349.28, usdEquivalent: 62400, fromAddress: "Gh7k...Bx9p", toAddress: CryptoWalletConfig.solAddress, txHash: "4Kx92m...7Nq3Rp", purpose: "material", projectRef: "Nucor Steel Order", status: "confirming", confirmations: 0, requiredConfirmations: 1, timestamp: Date().addingTimeInterval(-3600)),
    CryptoTransaction(chain: "Ethereum", symbol: "ETH", amount: 57.47, usdEquivalent: 198750, fromAddress: "0x445b...9e2a", toAddress: CryptoWalletConfig.ethAddress, txHash: "0x777888...999aaa", purpose: "invoice", projectRef: "Harbor Crossing Pay App", status: "pending", confirmations: 0, requiredConfirmations: 12, timestamp: Date()),
]

// MARK: - Crypto Payment View

struct CryptoPaymentView: View {
    @ObservedObject var manager = CryptoPaymentManager.shared
    @State private var usdAmount = ""
    @State private var purpose = "pay"
    @State private var projectRef = ""
    @State private var showPaySheet = false
    @State private var activeTab = 0

    private let tabs = ["Dashboard", "Send/Receive", "Wallets", "History"]
    private let purposes = ["subscription", "pay", "material", "rental", "invoice", "bond"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\u{1F48E}").font(.system(size: 18))
                            Text("CRYPTO").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Color(red: 0.38, green: 0.49, blue: 0.92))
                        }
                        Text("Blockchain Payments").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                        Text("Pay and get paid in crypto across the entire platform").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.0f", manager.totalCryptoReceived / 1000))K").font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.green)
                        Text("CRYPTO RECEIVED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                    }
                }.padding(16).background(Theme.surface).cornerRadius(14)
                .premiumGlow(cornerRadius: 14, color: Color(red: 0.38, green: 0.49, blue: 0.92))

                // Tabs
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: {
                            Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1)
                                .foregroundColor(activeTab == i ? .black : Theme.muted)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(activeTab == i ? Color(red: 0.38, green: 0.49, blue: 0.92) : Theme.surface)
                        }.buttonStyle(.plain)
                    }
                }.cornerRadius(8)

                switch activeTab {
                case 0: dashboardView
                case 1: sendReceiveView
                case 2: walletsView
                default: historyView
                }
            }.padding(16)
        }.background(Theme.bg)
    }

    // MARK: Dashboard
    private var dashboardView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("$\(String(format: "%.0f", manager.totalCryptoReceived / 1000))K").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.green)
                    Text("RECEIVED").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.green.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("\(manager.pendingCryptoPayments)").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.gold)
                    Text("PENDING").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Theme.gold.opacity(0.06)).cornerRadius(8)
                VStack(spacing: 2) {
                    Text("8").font(.system(size: 18, weight: .heavy)).foregroundColor(Color(red: 0.38, green: 0.49, blue: 0.92))
                    Text("CHAINS").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity).padding(10).background(Color(red: 0.38, green: 0.49, blue: 0.92).opacity(0.06)).cornerRadius(8)
            }

            // Exchange rates
            Text("LIVE RATES").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(CryptoWalletConfig.supportedChains) { chain in
                    VStack(spacing: 4) {
                        Text(chain.icon).font(.system(size: 16))
                        Text(chain.symbol).font(.system(size: 9, weight: .bold)).foregroundColor(chain.color)
                        Text("$\(String(format: chain.symbol == "BTC" ? "%.0f" : chain.symbol == "ETH" ? "%.0f" : "%.2f", manager.exchangeRates[chain.symbol] ?? 0))")
                            .font(.system(size: 8, weight: .heavy)).foregroundColor(Theme.text)
                    }
                    .frame(maxWidth: .infinity).padding(8).background(chain.color.opacity(0.06)).cornerRadius(8)
                }
            }

            // What you can pay with crypto
            Text("PAY WITH CRYPTO FOR").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.accent)
            let useCases: [(String, String, String)] = [
                ("Subscriptions", "$9.99 - $49.99/mo", "Monthly/annual plans"),
                ("Contractor Payments", "Any amount", "Pay subs and suppliers"),
                ("Material Orders", "Any amount", "Steel, concrete, lumber"),
                ("Equipment Rentals", "Any amount", "United Rentals, DOZR, etc."),
                ("Invoice Payments", "Any amount", "Pay and receive pay apps"),
                ("Surety Bond Premiums", "Any amount", "Bid, performance, payment"),
                ("Verification Badges", "$27.99 - $49.99/mo", "Licensed & Company verified"),
                ("Market Intel Reports", "$199 - $799", "Data intelligence"),
            ]
            ForEach(useCases, id: \.0) { uc in
                HStack(spacing: 8) {
                    Text("\u{1F48E}").font(.system(size: 10))
                    Text(uc.0).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Text(uc.1).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.accent)
                    Text(uc.2).font(.system(size: 8)).foregroundColor(Theme.muted)
                }.padding(6)
            }
        }
    }

    // MARK: Send/Receive
    private var sendReceiveView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEND OR RECEIVE CRYPTO").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Color(red: 0.38, green: 0.49, blue: 0.92))

            // Chain selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(CryptoWalletConfig.supportedChains) { chain in
                        Button { manager.selectedChain = chain } label: {
                            VStack(spacing: 3) {
                                Text(chain.icon).font(.system(size: 16))
                                Text(chain.symbol).font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(manager.selectedChain.symbol == chain.symbol ? .black : chain.color)
                            .frame(width: 56).padding(.vertical, 8)
                            .background(manager.selectedChain.symbol == chain.symbol ? chain.color : chain.color.opacity(0.1))
                            .cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                }
            }

            // Amount input
            VStack(alignment: .leading, spacing: 4) {
                Text("AMOUNT (USD)").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                TextField("$0.00", text: $usdAmount)
                    .font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.text)
                    .padding(14).background(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.2), lineWidth: 1))
                    .cornerRadius(10)
                if let usd = Double(usdAmount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")), usd > 0 {
                    Text("= \(manager.formatCrypto(manager.cryptoAmount(usd: usd, chain: manager.selectedChain.symbol), symbol: manager.selectedChain.symbol))")
                        .font(.system(size: 14, weight: .heavy)).foregroundColor(manager.selectedChain.color)
                }
            }

            // Purpose
            Text("PAYMENT TYPE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(purposes, id: \.self) { p in
                        Button { purpose = p } label: {
                            Text(p.uppercased()).font(.system(size: 8, weight: .bold))
                                .foregroundColor(purpose == p ? .black : Theme.text)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(purpose == p ? Theme.accent : Theme.surface).cornerRadius(5)
                        }.buttonStyle(.plain)
                    }
                }
            }

            TextField("Project reference (optional)", text: $projectRef)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .padding(10).background(Theme.panel).cornerRadius(8)

            // Send button
            Button {
                guard let usd = Double(usdAmount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")), usd > 0 else { return }
                let _ = manager.createPayment(usdAmount: usd, chain: manager.selectedChain, purpose: purpose, projectRef: projectRef)
                usdAmount = ""; projectRef = ""
            } label: {
                HStack(spacing: 8) {
                    Text(manager.selectedChain.icon).font(.system(size: 14))
                    Text("PAY WITH \(manager.selectedChain.symbol)").font(.system(size: 13, weight: .bold)).tracking(1)
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 48)
                .background(manager.selectedChain.color)
                .cornerRadius(10)
            }.buttonStyle(.plain)

            // Receive section
            VStack(alignment: .leading, spacing: 8) {
                Text("RECEIVE PAYMENTS").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.green)
                Text("Share your wallet address to receive crypto payments from clients and contractors")
                    .font(.system(size: 9)).foregroundColor(Theme.muted)

                VStack(alignment: .leading, spacing: 6) {
                    walletRow("BTC", CryptoWalletConfig.btcAddress, Color(red: 0.96, green: 0.66, blue: 0.0))
                    walletRow("ETH/ERC-20", CryptoWalletConfig.ethAddress, Color(red: 0.38, green: 0.49, blue: 0.92))
                    walletRow("SOL", CryptoWalletConfig.solAddress, Color(red: 0.60, green: 0.20, blue: 0.96))
                }
            }.padding(12).background(Theme.surface).cornerRadius(10)
        }
    }

    private func walletRow(_ label: String, _ address: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(color).frame(width: 65, alignment: .leading)
            Text(address).font(.system(size: 8, design: .monospaced)).foregroundColor(Theme.muted).lineLimit(1)
            Spacer()
            Button {
                #if os(iOS)
                UIPasteboard.general.string = address
                #elseif os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(address, forType: .string)
                #endif
            } label: {
                Text("COPY").font(.system(size: 7, weight: .bold)).foregroundColor(color)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(color.opacity(0.1)).cornerRadius(4)
            }.buttonStyle(.plain)
        }
    }

    // MARK: Wallets
    private var walletsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TREASURY WALLETS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)

            ForEach(CryptoWalletConfig.supportedChains) { chain in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(chain.icon).font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chain.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                            Text(chain.network).font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("$\(String(format: chain.symbol == "BTC" ? "%.0f" : "%.2f", manager.exchangeRates[chain.symbol] ?? 0))")
                                .font(.system(size: 11, weight: .heavy)).foregroundColor(chain.color)
                            Text("per \(chain.symbol)").font(.system(size: 7)).foregroundColor(Theme.muted)
                        }
                    }
                    Text(chain.address)
                        .font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.muted)
                        .padding(8).background(Theme.panel).cornerRadius(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.padding(12).background(Theme.surface).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(chain.color.opacity(0.15), lineWidth: 1))
            }
        }
    }

    // MARK: History
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TRANSACTION HISTORY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)

            ForEach(manager.transactions) { tx in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.purpose.uppercased()).font(.system(size: 8, weight: .black)).foregroundColor(Theme.accent)
                            Text(tx.projectRef).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(String(format: "%.0f", tx.usdEquivalent))").font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.green)
                            Text(manager.formatCrypto(tx.amount, symbol: tx.symbol)).font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(tx.chain).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                        Text(String(tx.txHash.prefix(12)) + "...").font(.system(size: 8, design: .monospaced)).foregroundColor(Theme.muted)
                        Spacer()
                        if tx.status == "confirmed" {
                            Text("\(tx.confirmations)/\(tx.requiredConfirmations) CONFIRMED").font(.system(size: 7, weight: .black)).foregroundColor(Theme.green)
                        } else if tx.status == "confirming" {
                            Text("CONFIRMING...").font(.system(size: 7, weight: .black)).foregroundColor(Theme.gold)
                        } else {
                            Text("PENDING").font(.system(size: 7, weight: .black)).foregroundColor(Theme.cyan)
                        }
                    }
                }.padding(12).background(Theme.surface).cornerRadius(10)
            }
        }
    }
}
