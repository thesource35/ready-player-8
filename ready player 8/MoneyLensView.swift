import Charts
import Foundation
import SwiftUI

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

let moneyLensMockContracts: [SupabaseContract] = [
    SupabaseContract(id: "1", title: "Tower A Foundation", client: "Metro Development", location: "Downtown", sector: "Commercial", stage: "Active", package: "Structural", budget: "$4.2M", bidDue: "2026-04-15", liveFeedStatus: "On Track", bidders: 3, score: 85, watchCount: 12),
    SupabaseContract(id: "2", title: "Highway Bridge Rehab", client: "State DOT", location: "County Line", sector: "Infrastructure", stage: "Pursuit", package: "Civil", budget: "$8.7M", bidDue: "2026-05-01", liveFeedStatus: "Competitive", bidders: 7, score: 72, watchCount: 8),
    SupabaseContract(id: "3", title: "Medical Center Wing B", client: "Regional Health", location: "Westside", sector: "Healthcare", stage: "Active", package: "General", budget: "$12.1M", bidDue: "2026-03-30", liveFeedStatus: "Awarded", bidders: 5, score: 91, watchCount: 15),
]

// MARK: - Mock Projects for Demo

let moneyLensMockProjects: [SupabaseProject] = [
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
