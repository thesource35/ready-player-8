import Foundation
import SwiftUI

// MARK: - ========== PowerThinkingView.swift ==========

// Think at the level of the outcome you want, not the level of the problem you have


struct PowerThinkingView: View {
    // MARK: - State
    @AppStorage("ConstructOS.Wealth.DecisionJournalRaw") private var journalRaw: String = ""
    @AppStorage("ConstructOS.Wealth.CustomScenariosRaw") private var customScenariosRaw: String = ""
    @AppStorage("ConstructOS.Wealth.QuestionResponsesRaw") private var questionResponsesRaw: String = ""

     private var journalEntries: [DecisionJournalEntry] = loadJSON(StorageKey.decisionJournalRaw, default: [DecisionJournalEntry]())
     private var customScenarios: [SecondOrderItem] = loadJSON(StorageKey.customScenariosRaw, default: [SecondOrderItem]())
    @State private var questionResponses: [String: String] = [:]
    @State private var showJournalSheet = false
    @State private var showScenarioSheet = false
    @State private var filterMode: String = "All"
    @State private var editingEntry: DecisionJournalEntry?

    private let supabase = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                powerQuestionOfTheDay
                thinkingModesPanel
                decisionJournalPanel
                powerQuestionsPanel
                yesFilterPanel
                secondOrderPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showJournalSheet) {
            DecisionJournalSheet(entry: editingEntry) { entry in
                if let idx = journalEntries.firstIndex(where: { $0.id == entry.id }) {
                    journalEntries[idx] = entry
                } else {
                    journalEntries.insert(entry, at: 0)
                }
                saveJournal()
                editingEntry = nil
            }
        }
        .sheet(isPresented: $showScenarioSheet) {
            CustomScenarioSheet { scenario in
                customScenarios.insert(scenario, at: 0)
                saveCustomScenarios()
            }
        }
        .onAppear { loadPersistedState() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("⚡").font(.system(size: 18))
                    Text("POWER THINK").font(.system(size: 11, weight: .bold)).tracking(4).foregroundColor(Theme.green)
                }
                Text("Power Thinking Framework")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                Text("Think at the level of the outcome you want")
                    .font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                let count = journalEntries.count
                Text("\(count)").font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.green)
                Text("DECISIONS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                Text("LOGGED").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(wealthGradientSurface)
        .cornerRadius(16)
        .premiumGlow(cornerRadius: 16, color: Theme.green)
    }

    // MARK: - Power Question of the Day

    private var powerQuestionOfTheDay: some View {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let todayQuestion = powerQuestions[dayOfYear % powerQuestions.count]
        let responseKey = "day_\(dayOfYear)"

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "POWER QUESTION OF THE DAY")
                Spacer()
                Text("Q\(dayOfYear % powerQuestions.count + 1)")
                    .font(.system(size: 9, weight: .bold)).foregroundColor(wealthGold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(wealthGold.opacity(0.12)).cornerRadius(4)
            }

            Text(todayQuestion)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.text)

            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR RESPONSE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(Theme.muted)
                TextField("Journal your thinking here...", text: Binding(
                    get: { questionResponses[responseKey] ?? "" },
                    set: {
                        questionResponses[responseKey] = $0
                        saveQuestionResponses()
                    }
                ), axis: .vertical)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .lineLimit(3...6)
                .padding(10).background(Theme.panel).cornerRadius(8)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Thinking Modes

    private var thinkingModesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthSectionHeader(icon: "⚡", title: "POWER THINKING FRAMEWORK",
                                subtitle: "Think at the level of the outcome you want, not the level of the problem you have")

            WealthLensLabel(text: "THINKING MODES")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(thinkingModes, id: \.name) { mode in
                    ThinkingModeCard(mode: mode)
                }
            }
        }
    }

    // MARK: - Decision Journal

    private var decisionJournalPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "DECISION JOURNAL")
                Spacer()
                Button {
                    editingEntry = nil
                    showJournalSheet = true
                } label: {
                    Label("New Entry", systemImage: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.green)
                        .cornerRadius(6)
                }
            }

            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(["All", "Strategic", "Leverage", "Visionary", "Execution"], id: \.self) { mode in
                        Button { withAnimation { filterMode = mode } } label: {
                            Text(mode)
                                .font(.system(size: 10, weight: .bold)).tracking(0.5)
                                .foregroundColor(filterMode == mode ? Theme.bg : Theme.muted)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(filterMode == mode ? Theme.green : Theme.panel)
                                .cornerRadius(6)
                        }
                    }
                }
            }

            let filtered = filterMode == "All" ? journalEntries : journalEntries.filter { $0.thinkingMode == filterMode }

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Text("📓").font(.system(size: 28))
                    Text("No decisions logged yet").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                    Text("Tap 'New Entry' to log your first strategic decision")
                        .font(.system(size: 11)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(24)
            } else {
                ForEach(filtered) { entry in
                    journalEntryCard(entry)
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    private func journalEntryCard(_ entry: DecisionJournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                Text(entry.thinkingMode)
                    .font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundColor(modeColor(entry.thinkingMode))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(modeColor(entry.thinkingMode).opacity(0.12))
                    .cornerRadius(4)
            }
            if !entry.decision.isEmpty {
                Text(entry.decision).font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(2)
            }
            HStack {
                Text(entry.createdAt, style: .date).font(.system(size: 9)).foregroundColor(Theme.muted)
                Spacer()
                outcomeStatusBadge(entry.outcomeStatus)
                Button {
                    editingEntry = entry
                    showJournalSheet = true
                } label: {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundColor(Theme.muted)
                }
                .accessibilityLabel("Edit journal entry")
            }
        }
        .padding(12).background(Theme.panel.opacity(0.5)).cornerRadius(10)
    }

    private func outcomeStatusBadge(_ status: String) -> some View {
        let color: Color = status == "success" ? Theme.green : status == "failed" ? Theme.red : Theme.muted
        return Text(status.uppercased())
            .font(.system(size: 8, weight: .bold)).tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.10)).cornerRadius(3)
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Strategic": return Theme.gold
        case "Leverage": return Theme.cyan
        case "Visionary": return Theme.purple
        case "Execution": return Theme.green
        default: return Theme.muted
        }
    }

    // MARK: - Power Questions

    private var powerQuestionsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "BILLIONAIRE POWER QUESTIONS")
            Text("Ask these before every major decision. Answers in seconds kill millions in opportunity cost.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)
            ForEach(powerQuestions.indices, id: \.self) { i in
                PowerQuestionRow(number: i + 1, question: powerQuestions[i])
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.green)
    }

    // MARK: - Yes Filter

    private var yesFilterPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            WealthLensLabel(text: "THE YES FILTER — 7 GATES")
            Text("Every opportunity must pass all 7 gates before it receives a yes.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)
            ForEach(yesFilterGates.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(wealthGold.opacity(0.15)).frame(width: 26, height: 26)
                        Text("\(i + 1)").font(.system(size: 11, weight: .heavy)).foregroundColor(wealthGold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(yesFilterGates[i].gate).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        Text(yesFilterGates[i].question).font(.system(size: 11)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                if i < yesFilterGates.count - 1 { Divider().overlay(Theme.border.opacity(0.3)) }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: wealthGold)
    }

    // MARK: - Second Order

    private var secondOrderPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                WealthLensLabel(text: "SECOND-ORDER CONSEQUENCE MAP")
                Spacer()
                Button { showScenarioSheet = true } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                }
            }
            Text("Billionaires don't just ask what happens next — they ask what happens after that.")
                .font(.system(size: 11)).foregroundColor(Theme.muted)

            ForEach(secondOrderExamples, id: \.decision) { item in
                SecondOrderRow(item: item)
            }
            ForEach(customScenarios, id: \.decision) { item in
                SecondOrderRow(item: item)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = journalRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([DecisionJournalEntry].self, from: data) {
            journalEntries = decoded
        }
        if let data = customScenariosRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([CodableSecondOrderItem].self, from: data) {
            customScenarios = decoded.map { SecondOrderItem(decision: $0.decision, first: $0.first, second: $0.second) }
        }
        if let data = questionResponsesRaw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            questionResponses = decoded
        }
    }

    private func saveJournal() {
        if let data = try? JSONEncoder().encode(journalEntries) {
            journalRaw = String(data: data, encoding: .utf8) ?? ""
        }
        // Sync to Supabase
        if supabase.isConfigured, let entry = journalEntries.first {
            Task {
                let dto = SupabaseDecisionJournal(
                    title: entry.title,
                    context: entry.context,
                    thinkingMode: entry.thinkingMode,
                    decision: entry.decision,
                    firstOrder: entry.firstOrder,
                    secondOrder: entry.secondOrder,
                    gatesPassed: entry.gatesPassed,
                    outcomeStatus: entry.outcomeStatus
                )
                try? await supabase.insert(SupabaseTable.decisionJournal, record: dto)
            }
        }
    }

    private func saveCustomScenarios() {
        let codable = customScenarios.map { CodableSecondOrderItem(decision: $0.decision, first: $0.first, second: $0.second) }
        if let data = try? JSONEncoder().encode(codable) {
            customScenariosRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func saveQuestionResponses() {
        if let data = try? JSONEncoder().encode(questionResponses) {
            questionResponsesRaw = String(data: data, encoding: .utf8) ?? ""
        }
    }
}

// MARK: - Codable wrapper for SecondOrderItem

private struct CodableSecondOrderItem: Codable {
    let decision: String; let first: String; let second: String
}

// MARK: - Decision Journal Sheet

struct DecisionJournalSheet: View {
    let entry: DecisionJournalEntry?
    let onSave: (DecisionJournalEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var context = ""
    @State private var thinkingMode = "Strategic"
    @State private var decision = ""
    @State private var firstOrder = ""
    @State private var secondOrder = ""
    @State private var gatesPassed = 0
    @State private var outcomeStatus = "pending"

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        journalField("TITLE", text: $title, placeholder: "e.g. Accept the hospital bid")
                        journalField("CONTEXT", text: $context, placeholder: "What's the situation?")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("THINKING MODE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            HStack(spacing: 6) {
                                ForEach(["Strategic", "Leverage", "Visionary", "Execution"], id: \.self) { mode in
                                    Button { thinkingMode = mode } label: {
                                        Text(mode)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(thinkingMode == mode ? Theme.bg : Theme.muted)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(thinkingMode == mode ? Theme.green : Theme.surface)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }

                        journalField("DECISION", text: $decision, placeholder: "What did you decide?")
                        journalField("FIRST-ORDER CONSEQUENCE", text: $firstOrder, placeholder: "What happens immediately?")
                        journalField("SECOND-ORDER CONSEQUENCE", text: $secondOrder, placeholder: "What happens after that?")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("YES FILTER GATES PASSED").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            HStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { i in
                                    Button { gatesPassed = i + 1 } label: {
                                        ZStack {
                                            Circle().fill(i < gatesPassed ? wealthGold : Theme.panel).frame(width: 30, height: 30)
                                            Text("\(i + 1)").font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(i < gatesPassed ? Theme.bg : Theme.muted)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("OUTCOME").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            HStack(spacing: 6) {
                                ForEach(["pending", "success", "failed", "learning"], id: \.self) { status in
                                    Button { outcomeStatus = status } label: {
                                        Text(status.capitalized)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(outcomeStatus == status ? Theme.bg : Theme.muted)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(outcomeStatus == status ? statusColor(status) : Theme.surface)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(entry == nil ? "New Decision" : "Edit Decision")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let saved = DecisionJournalEntry(
                            id: entry?.id ?? UUID(),
                            title: title.isEmpty ? "Untitled Decision" : title,
                            context: context,
                            thinkingMode: thinkingMode,
                            decision: decision,
                            firstOrder: firstOrder,
                            secondOrder: secondOrder,
                            gatesPassed: gatesPassed,
                            outcomeStatus: outcomeStatus,
                            createdAt: entry?.createdAt ?? Date(),
                            reviewedAt: entry != nil ? Date() : nil
                        )
                        onSave(saved)
                        dismiss()
                    }
                    .foregroundColor(Theme.green).fontWeight(.bold)
                }
            }
            .onAppear {
                if let e = entry {
                    title = e.title; context = e.context; thinkingMode = e.thinkingMode
                    decision = e.decision; firstOrder = e.firstOrder; secondOrder = e.secondOrder
                    gatesPassed = e.gatesPassed; outcomeStatus = e.outcomeStatus
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func journalField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 13)).foregroundColor(Theme.text)
                .lineLimit(1...4)
                .padding(12).background(Theme.surface).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "success": return Theme.green
        case "failed": return Theme.red
        case "learning": return Theme.purple
        default: return Theme.muted
        }
    }
}

// MARK: - Custom Scenario Sheet

struct CustomScenarioSheet: View {
    let onAdd: (SecondOrderItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var decision = ""
    @State private var first = ""
    @State private var second = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DECISION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                        TextField("The decision being considered", text: $decision)
                            .font(.system(size: 13)).foregroundColor(Theme.text)
                            .padding(12).background(Theme.surface).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FIRST-ORDER CONSEQUENCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                        TextField("What happens immediately", text: $first)
                            .font(.system(size: 13)).foregroundColor(Theme.text)
                            .padding(12).background(Theme.surface).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SECOND-ORDER CONSEQUENCE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                        TextField("What happens after that", text: $second)
                            .font(.system(size: 13)).foregroundColor(Theme.text)
                            .padding(12).background(Theme.surface).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.8), lineWidth: 0.8))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add Scenario")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Theme.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(SecondOrderItem(decision: decision.isEmpty ? "Untitled" : decision, first: first, second: second))
                        dismiss()
                    }
                    .foregroundColor(Theme.green).fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
