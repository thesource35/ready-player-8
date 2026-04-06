import Charts
import Foundation
import SwiftUI

// MARK: - ========== PsychologyDecoderView.swift ==========

// Identify and reprogram the mental patterns separating you from wealth at scale


struct PsychologyDecoderView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.PsychologyScore") private var psychologyScore: Double = 0
    @AppStorage("ConstructOS.Wealth.MindsetAnswers") private var mindsetAnswersRaw: String = ""
    @AppStorage("ConstructOS.Wealth.PsychHistoryRaw") private var psychHistoryRaw: String = ""
    @AppStorage("ConstructOS.Wealth.AffirmationStreak") private var affirmationStreak: Int = 0
    @AppStorage("ConstructOS.Wealth.LastAffirmationDate") private var lastAffirmationDate: String = ""
    @AppStorage("ConstructOS.Wealth.ResolvedBeliefs") private var resolvedBeliefsRaw: String = ""

    @State private var mindsetAnswers: [Int: Int] = [:]
    @State private var showMindsetCalibration = false
    @State private var psychHistory: [PsychologySession] = []
    @State private var resolvedBeliefs: Set<String> = []

    private let supabase = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                psychologyScorePanel
                scoreHistoryPanel
                dailyAffirmationPanel
                archetypesPanel
                beliefDecoderPanel
                identityPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showMindsetCalibration) {
            MindsetCalibrationSheet(answers: $mindsetAnswers) {
                psychologyScore = computePsychologyScore(from: mindsetAnswers)
                saveMindsetAnswers()
                savePsychologySession()
                showMindsetCalibration = false
            }
        }
        .onAppear { loadPersistedState() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🧠").font(.system(size: 18))
                    Text("PSYCHOLOGY").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.purple)
                }
                Text("Wealth Psychology Decoder")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Identify and reprogram limiting wealth patterns")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                WealthScoreRing(score: psychologyScore, label: "PSYCH", color: Theme.purple, size: 56)
                Text(psychologyProfileLabel(for: psychologyScore))
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(Theme.purple)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: Theme.purple)
    }

    // MARK: - Psychology Score Panel

    private var psychologyScorePanel: some View {
        VStack(spacing: 12) {
            WealthSectionHeader(icon: "🧠", title: "WEALTH PSYCHOLOGY DECODER",
                                subtitle: "Identify and reprogram the mental patterns separating you from wealth at scale")

            HStack(spacing: 14) {
                WealthScoreRing(score: psychologyScore, label: "PSYCH", color: Theme.purple, size: 80)
                VStack(alignment: .leading, spacing: 6) {
                    Text(psychologyProfileLabel(for: psychologyScore))
                        .font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.text)
                    Text(psychologyProfileDescription(for: psychologyScore))
                        .font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(3)
                    Button { showMindsetCalibration = true } label: {
                        Text(psychologyScore == 0 ? "Run Decoder →" : "Recalibrate →")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.purple)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(14).background(Theme.surface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: Theme.purple)
        }
    }

    // MARK: - Score History Chart

    private var scoreHistoryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "PSYCHOLOGY SCORE HISTORY")

            if psychHistory.count < 2 {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(Theme.purple)
                    Text("Complete 2+ calibrations to see your score trend over time")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface).cornerRadius(12)
            } else {
                Chart {
                    ForEach(psychHistory) { session in
                        LineMark(
                            x: .value("Date", session.createdAt),
                            y: .value("Score", session.score)
                        )
                        .foregroundStyle(Theme.purple)
                        .symbol(Circle())

                        AreaMark(
                            x: .value("Date", session.createdAt),
                            y: .value("Score", session.score)
                        )
                        .foregroundStyle(Theme.purple.opacity(0.1))
                    }

                    RuleMark(y: .value("Target", 80))
                        .foregroundStyle(wealthGold.opacity(0.4))
                        .lineStyle(StrokeStyle(dash: [5, 5]))
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
                .premiumGlow(cornerRadius: 12, color: Theme.purple)

                if let latest = psychHistory.first, psychHistory.count >= 2 {
                    let previous = psychHistory[1]
                    let delta = latest.score - previous.score
                    HStack(spacing: 8) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(delta >= 0 ? Theme.green : Theme.red)
                        Text(String(format: "%+.0f points since last calibration", delta))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(delta >= 0 ? Theme.green : Theme.red)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background((delta >= 0 ? Theme.green : Theme.red).opacity(0.08)).cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Daily Affirmation

    private var dailyAffirmationPanel: some View {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let todayStatement = identityStatements[dayOfYear % identityStatements.count]
        let todayStr = formatToday()
        let alreadyRead = lastAffirmationDate == todayStr

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "TODAY'S AFFIRMATION")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 11)).foregroundColor(wealthGold)
                    Text("\(affirmationStreak) day streak")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(wealthGold)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("◈").font(.system(size: 14)).foregroundColor(wealthGold)
                Text(todayStatement)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.text)
                    .italic()

                Button {
                    if !alreadyRead {
                        lastAffirmationDate = todayStr
                        affirmationStreak += 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: alreadyRead ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(alreadyRead ? Theme.green : Theme.muted)
                        Text(alreadyRead ? "Read Today" : "Mark as Read")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(alreadyRead ? Theme.green : Theme.text)
                    }
                }
                .disabled(alreadyRead)
            }
            .padding(14).background(wealthGradientSurface).cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: wealthGold)
        }
    }

    // MARK: - Archetypes

    private var archetypesPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            WealthLensLabel(text: "WEALTH ARCHETYPES")
            ForEach(wealthArchetypes, id: \.name) { archetype in
                WealthArchetypeCard(archetype: archetype, isActive: archetype.minScore <= Int(psychologyScore))
            }
        }
    }

    // MARK: - Limiting Belief Decoder

    private var beliefDecoderPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "LIMITING BELIEF DECODER")
                Spacer()
                let resolved = resolvedBeliefs.count
                let total = limitingBeliefs.count
                Text("\(resolved)/\(total) resolved")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(resolved == total ? Theme.green : Theme.muted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3).fill(Theme.green)
                        .frame(width: geo.size.width * CGFloat(resolvedBeliefs.count) / CGFloat(max(limitingBeliefs.count, 1)), height: 4)
                }
            }
            .frame(height: 4)

            ForEach(limitingBeliefs, id: \.belief) { item in
                HStack(spacing: 10) {
                    Button {
                        withAnimation {
                            if resolvedBeliefs.contains(item.belief) {
                                resolvedBeliefs.remove(item.belief)
                            } else {
                                resolvedBeliefs.insert(item.belief)
                            }
                            saveResolvedBeliefs()
                        }
                    } label: {
                        Image(systemName: resolvedBeliefs.contains(item.belief) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(resolvedBeliefs.contains(item.belief) ? Theme.green : Theme.muted)
                    }
                    .accessibilityLabel(resolvedBeliefs.contains(item.belief) ? "Mark belief as unresolved" : "Mark belief as resolved")
                    LimitingBeliefRow(item: item)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.purple)
    }

    // MARK: - Identity Reprogramming

    private var identityPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "IDENTITY REPROGRAMMING")
            Text("Read aloud daily. Repetition rewires the neural pathways that govern financial decisions.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)
            ForEach(identityStatements, id: \.self) { statement in
                HStack(spacing: 8) {
                    Text("◈").font(.system(size: 10)).foregroundColor(wealthGold)
                    Text(statement).font(.system(size: 12, weight: .medium)).foregroundColor(Theme.text)
                }
            }
        }
        .padding(14).background(wealthGradientSurface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = mindsetAnswersRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            mindsetAnswers = decoded
        }
        if let data = psychHistoryRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([PsychologySession].self, from: data) {
            psychHistory = decoded
        }
        if let data = resolvedBeliefsRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            resolvedBeliefs = Set(decoded)
        }
        // Check if streak should reset
        let todayStr = formatToday()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayStr = formatter.string(from: yesterday)
        if lastAffirmationDate != todayStr && lastAffirmationDate != yesterdayStr {
            affirmationStreak = 0
        }
    }

    private func saveMindsetAnswers() {
        if let data = try? JSONEncoder().encode(mindsetAnswers) {
            mindsetAnswersRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func savePsychologySession() {
        let session = PsychologySession(
            id: UUID(),
            score: psychologyScore,
            profileLabel: psychologyProfileLabel(for: psychologyScore),
            createdAt: Date()
        )
        psychHistory.insert(session, at: 0)
        if let data = try? JSONEncoder().encode(psychHistory) {
            psychHistoryRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured {
            Task {
                let dto = SupabasePsychologySession(
                    score: session.score,
                    profileLabel: session.profileLabel
                )
                try? await supabase.insert(SupabaseTable.psychologySessions, record: dto)
            }
        }
    }

    private func saveResolvedBeliefs() {
        if let data = try? JSONEncoder().encode(Array(resolvedBeliefs)) {
            resolvedBeliefsRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func formatToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Mindset Calibration Sheet

struct MindsetCalibrationSheet: View {
    @Binding var answers: [Int: Int]
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestion = 0

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if currentQuestion < mindsetQuestions.count {
                    calibrationQuestion
                } else {
                    calibrationComplete
                }
            }
            .navigationTitle("Wealth Psychology Decoder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var calibrationQuestion: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                HStack {
                    Text("Question \(currentQuestion + 1) of \(mindsetQuestions.count)")
                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                    Spacer()
                    Text("\(Int(Double(currentQuestion) / Double(mindsetQuestions.count) * 100))%")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.purple)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3).fill(Theme.purple)
                            .frame(width: geo.size.width * CGFloat(currentQuestion) / CGFloat(mindsetQuestions.count), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 20)

            Text(mindsetQuestions[currentQuestion].0)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(mindsetQuestions[currentQuestion].1.indices, id: \.self) { i in
                    Button {
                        answers[currentQuestion] = i
                        withAnimation {
                            if currentQuestion < mindsetQuestions.count - 1 {
                                currentQuestion += 1
                            } else {
                                onComplete()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(["A", "B", "C", "D"][i])
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Theme.bg)
                                .frame(width: 26, height: 26)
                                .background(Theme.purple)
                                .clipShape(Circle())
                            Text(mindsetQuestions[currentQuestion].1[i])
                                .font(.system(size: 13))
                                .foregroundColor(Theme.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(14)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .premiumGlow(cornerRadius: 12, color: Theme.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding(.top, 20)
    }

    private var calibrationComplete: some View {
        VStack(spacing: 20) {
            Text("🧠").font(.system(size: 56))
            Text("Calibration Complete").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
            Text("Your Wealth Psychology Score has been calculated.\nReturn to the Decoder to view your full profile.")
                .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            Button("View My Profile") { onComplete() }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(Theme.purple).cornerRadius(10)
        }
        .padding(30)
    }
}
