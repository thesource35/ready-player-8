import Charts
import Foundation
import SwiftUI

// MARK: - ========== LeverageSystemView.swift ==========

// Wealth is built by compounding leverage, not compounding hours


struct LeverageSystemView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.LeverageScores") private var leverageScoresRaw: String = ""
    @AppStorage("ConstructOS.Wealth.LeverageHistoryRaw") private var leverageHistoryRaw: String = ""
    @AppStorage("ConstructOS.Wealth.PlaybookProgressRaw") private var playbookProgressRaw: String = ""
    @AppStorage("ConstructOS.Wealth.MilestonesRaw") private var milestonesRaw: String = ""

    @State private var leverageScores: [String: Double] = [:]
    @State private var leverageHistory: [LeverageSnapshot] = []
    @State private var playbookProgress: [Int: Set<Int>] = [:]  // week -> set of completed item indices
    @State private var unlockedMilestones: Set<String> = []

    private let supabase = SupabaseService.shared

    private var totalLeverageScore: Double {
        leverageCategories.reduce(0.0) { $0 + (leverageScores[$1.id] ?? $1.defaultScore) } / Double(leverageCategories.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                leverageOverviewPanel
                leverageSlidersPanel
                leverageHistoryPanel
                milestonesPanel
                leverageFormulasPanel
                leveragePlaybookPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { loadPersistedState() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🔱").font(.system(size: 18))
                    Text("LEVERAGE").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.cyan)
                }
                Text("Leverage System")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Compound leverage, not hours")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                WealthScoreRing(score: totalLeverageScore, label: "LEVER", color: Theme.cyan, size: 56)
                Text(leverageLabel(totalLeverageScore))
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.cyan)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: Theme.cyan)
    }

    // MARK: - Leverage Overview

    private var leverageOverviewPanel: some View {
        VStack(spacing: 12) {
            WealthSectionHeader(icon: "🔱", title: "LEVERAGE SYSTEM",
                                subtitle: "Wealth is built by compounding leverage, not compounding hours")

            HStack(spacing: 14) {
                WealthScoreRing(score: totalLeverageScore, label: "LEVER", color: Theme.cyan, size: 80)
                VStack(alignment: .leading, spacing: 4) {
                    Text(leverageLabel(totalLeverageScore)).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                    Text(leverageDescription(totalLeverageScore)).font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(3)
                }
            }
            .padding(14).background(Theme.surface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: Theme.cyan)
        }
    }

    // MARK: - Leverage Category Sliders

    private var leverageSlidersPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "LEVERAGE PROFILE — RATE YOUR CURRENT POSITION")
                Spacer()
                Button {
                    saveSnapshot()
                } label: {
                    Text("Save Snapshot")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(Theme.cyan)
                }
            }

            VStack(spacing: 12) {
                ForEach(leverageCategories, id: \.id) { cat in
                    LeverageSliderRow(
                        category: cat,
                        score: Binding(
                            get: { leverageScores[cat.id] ?? cat.defaultScore },
                            set: { leverageScores[cat.id] = $0; saveLeverageScores() }
                        )
                    )
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Leverage History Chart

    private var leverageHistoryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "LEVERAGE GROWTH HISTORY")

            if leverageHistory.count < 2 {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(Theme.cyan)
                    Text("Save 2+ snapshots to see your leverage growth over time")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface).cornerRadius(12)
            } else {
                Chart {
                    ForEach(leverageHistory.sorted(by: { $0.createdAt < $1.createdAt })) { snapshot in
                        LineMark(
                            x: .value("Date", snapshot.createdAt),
                            y: .value("Total", snapshot.totalScore)
                        )
                        .foregroundStyle(Theme.cyan)
                        .symbol(Circle())
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))").font(.system(size: 8)).foregroundColor(Theme.muted)
                            }
                        }
                    }
                }
                .frame(height: 140)
                .padding(14).background(Theme.surface).cornerRadius(12)
                .premiumGlow(cornerRadius: 12, color: Theme.cyan)

                // Category breakdown for latest
                if let latest = leverageHistory.first {
                    HStack(spacing: 6) {
                        ForEach(leverageCategories, id: \.id) { cat in
                            let score = latest.scores[cat.id] ?? cat.defaultScore
                            VStack(spacing: 3) {
                                Text(cat.icon).font(.system(size: 14))
                                Text("\(Int(score))").font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(leverageScoreColor(score))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(leverageScoreColor(score).opacity(0.08))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Milestones

    private var milestonesPanel: some View {
        let milestones: [(id: String, label: String, icon: String, achieved: Bool)] = [
            ("first70", "First category above 70", "🏅", leverageCategories.contains { (leverageScores[$0.id] ?? $0.defaultScore) >= 70 }),
            ("all50", "All categories above 50", "🎖", leverageCategories.allSatisfy { (leverageScores[$0.id] ?? $0.defaultScore) >= 50 }),
            ("total75", "Total leverage above 75", "🏆", totalLeverageScore >= 75),
            ("all70", "All categories above 70", "👑", leverageCategories.allSatisfy { (leverageScores[$0.id] ?? $0.defaultScore) >= 70 }),
            ("total90", "Total leverage above 90", "💎", totalLeverageScore >= 90),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "LEVERAGE MILESTONES")

            let achieved = milestones.filter(\.achieved).count
            Text("\(achieved) of \(milestones.count) unlocked")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(achieved == milestones.count ? Theme.green : Theme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(milestones, id: \.id) { m in
                    HStack(spacing: 8) {
                        Text(m.icon).font(.system(size: 20)).opacity(m.achieved ? 1 : 0.3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.label).font(.system(size: 10, weight: .bold))
                                .foregroundColor(m.achieved ? Theme.text : Theme.muted.opacity(0.5))
                            Text(m.achieved ? "UNLOCKED" : "LOCKED")
                                .font(.system(size: 8, weight: .bold)).tracking(1)
                                .foregroundColor(m.achieved ? Theme.green : Theme.muted.opacity(0.3))
                        }
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(m.achieved ? Theme.green.opacity(0.06) : Theme.panel.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(m.achieved ? Theme.green.opacity(0.3) : Color.clear, lineWidth: 0.8))
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Leverage Formulas

    private var leverageFormulasPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "LEVERAGE MULTIPLIER FORMULAS")
            ForEach(leverageFormulas, id: \.formula) { item in
                HStack(alignment: .top, spacing: 12) {
                    Text(item.icon).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.formula).font(.system(size: 12, weight: .heavy)).foregroundColor(wealthGold)
                        Text(item.description).font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                }
                .padding(10).background(Theme.panel.opacity(0.5)).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Interactive Playbook

    private let playbookActions: [[String]] = [
        ["Map three friction points in lowest-scoring category", "Eliminate one friction point", "Document findings and next steps"],
        ["Build or buy one automated system", "Document one SOP for a repeatable process", "Make one strategic hire or delegation move"],
        ["Identify top 5 referral sources", "Send personalized outreach to each", "Create a structured follow-up rhythm calendar"],
        ["Research AI/automation tools for your workflow", "Implement one tool this week", "Measure time saved (target 5+ hours)"],
    ]

    private var leveragePlaybookPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "30-DAY LEVERAGE ACTIVATION PLAYBOOK")

            ForEach(0..<leveragePlaybook.count, id: \.self) { weekIdx in
                let weekComplete = playbookProgress[weekIdx] ?? []
                let totalActions = playbookActions[weekIdx].count
                let completePct = totalActions > 0 ? Double(weekComplete.count) / Double(totalActions) * 100 : 0

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week \(weekIdx + 1)").font(.system(size: 12, weight: .bold)).foregroundColor(wealthGold)
                        Spacer()
                        Text("\(Int(completePct))%")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(completePct >= 100 ? Theme.green : Theme.muted)
                    }

                    Text(leveragePlaybook[weekIdx]).font(.system(size: 11)).foregroundColor(Theme.muted)

                    ForEach(playbookActions[weekIdx].indices, id: \.self) { actionIdx in
                        let isComplete = weekComplete.contains(actionIdx)
                        Button {
                            var updated = playbookProgress[weekIdx] ?? []
                            if isComplete { updated.remove(actionIdx) } else { updated.insert(actionIdx) }
                            playbookProgress[weekIdx] = updated
                            savePlaybookProgress()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(isComplete ? Theme.green : Theme.muted)
                                Text(playbookActions[weekIdx][actionIdx])
                                    .font(.system(size: 11))
                                    .foregroundColor(isComplete ? Theme.muted : Theme.text)
                                    .strikethrough(isComplete)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Week progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Theme.border.opacity(0.3)).frame(height: 3)
                            RoundedRectangle(cornerRadius: 2).fill(completePct >= 100 ? Theme.green : wealthGold)
                                .frame(width: geo.size.width * completePct / 100, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(12).background(Theme.panel.opacity(0.4)).cornerRadius(10)

                if weekIdx < leveragePlaybook.count - 1 { Divider().overlay(Theme.border.opacity(0.3)) }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: - Helpers

    private func leverageScoreColor(_ score: Double) -> Color {
        switch score {
        case 70...100: return Theme.green
        case 40..<70:  return wealthGold
        default:       return Theme.red
        }
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = leverageScoresRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            leverageScores = decoded
        }
        if let data = leverageHistoryRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([LeverageSnapshot].self, from: data) {
            leverageHistory = decoded
        }
        if let data = playbookProgressRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) {
            playbookProgress = decoded.reduce(into: [:]) { result, pair in
                if let key = Int(pair.key) { result[key] = Set(pair.value) }
            }
        }
        if let data = milestonesRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            unlockedMilestones = Set(decoded)
        }
    }

    private func saveLeverageScores() {
        if let data = try? JSONEncoder().encode(leverageScores) {
            leverageScoresRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func saveSnapshot() {
        let snapshot = LeverageSnapshot(
            id: UUID(),
            scores: leverageScores,
            totalScore: totalLeverageScore,
            createdAt: Date()
        )
        leverageHistory.insert(snapshot, at: 0)
        if let data = try? JSONEncoder().encode(leverageHistory) {
            leverageHistoryRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured {
            Task {
                let dto = SupabaseLeverageSnapshot(totalScore: snapshot.totalScore)
                try? await supabase.insert(SupabaseTable.leverageSnapshots, record: dto)
            }
        }
    }

    private func savePlaybookProgress() {
        let encodable = playbookProgress.reduce(into: [String: [Int]]()) { result, pair in
            result[String(pair.key)] = Array(pair.value)
        }
        if let data = try? JSONEncoder().encode(encodable) {
            playbookProgressRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }
}
