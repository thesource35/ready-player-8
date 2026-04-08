import Foundation
import SwiftUI

// MARK: - ========== OpportunityFilterView.swift ==========

// Run every opportunity through the wealth signal matrix before committing time or capital


struct OpportunityFilterView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.OpportunitiesRaw") private var opportunitiesRaw: String = ""
    @AppStorage("ConstructOS.Wealth.ArchivedOpportunitiesRaw") private var archivedRaw: String = ""

    @State private var opportunities: [WealthOpportunity] = loadJSON(StorageKey.opportunitiesRaw, default: [WealthOpportunity]())
    @State private var archivedOpportunities: [WealthOpportunity] = loadJSON(StorageKey.archivedOpportunitiesRaw, default: [WealthOpportunity]())
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
                            .accessibilityLabel(selectedForCompare.contains(opp.id) ? "Deselect for comparison" : "Select for comparison")

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
                        .accessibilityLabel("Restore opportunity")
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
        do {
            remoteContracts = try await supabase.fetch(SupabaseTable.contracts)
        } catch {
            // Expected: Supabase may not be configured — fall back to local contracts
            CrashReporter.shared.reportError("OpportunityFilter contract fetch failed (using local): \(error.localizedDescription)")
        }
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
                try? await supabase.insert(SupabaseTable.wealthOpportunities, record: dto)
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
