import Foundation
import SwiftUI

// MARK: - ========== MarketView.swift ==========

struct MarketView: View {
    @State private var marketData: [SupabaseMarketData] = loadJSON("ConstructOS.Market.DataRaw", default: [SupabaseMarketData]())
    @State private var contracts: [SupabaseContract] = loadJSON("ConstructOS.Market.ContractsRaw", default: [SupabaseContract]())
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var regionFilter = "All"
    @State private var watchedIDs: Set<String> = Set(loadJSON("ConstructOS.Market.WatchedIDs", default: [String]()))

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
            LazyVStack(alignment: .leading, spacing: 14) {
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
        .onChange(of: marketData) { _, newValue in
            saveJSON("ConstructOS.Market.DataRaw", value: newValue)
        }
        .onChange(of: contracts) { _, newValue in
            saveJSON("ConstructOS.Market.ContractsRaw", value: newValue)
        }
        .onChange(of: watchedIDs) { _, newValue in
            saveJSON("ConstructOS.Market.WatchedIDs", value: Array(newValue))
        }
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
            let mData: [SupabaseMarketData] = try await supabase.fetch(SupabaseTable.marketData)
            let cData: [SupabaseContract] = try await supabase.fetch(SupabaseTable.contracts)
            marketData = mData
            contracts = cData
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

let mockSupabaseContracts: [SupabaseContract] = mockContracts.map {
    SupabaseContract(id: $0.id.uuidString, title: $0.title, client: $0.client, location: $0.location,
                     sector: $0.sector, stage: $0.stage, package: $0.package, budget: $0.budget,
                     bidDue: $0.bidDue, liveFeedStatus: $0.liveFeedStatus,
                     bidders: $0.bidders, score: $0.score, watchCount: $0.watchCount)
}
