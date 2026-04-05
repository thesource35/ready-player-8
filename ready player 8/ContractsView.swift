import SwiftUI

// MARK: - ========== ContractsView.swift ==========

struct ContractsView: View {
    @State private var contracts: [SupabaseContract] = loadJSON("ConstructOS.Contracts.DataRaw", default: [SupabaseContract]())
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var filterStage = "All"
    @State private var showAddSheet = false
    @State private var selectedContract: SupabaseContract?

    private let stageFilters = ["All", "Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation", "Awarded", "Lost"]
    private let supabase = SupabaseService.shared

    private var displayContracts: [SupabaseContract] {
        var list = supabase.isConfigured ? contracts : mockSupabaseContracts
        if filterStage != "All" {
            list = list.filter { $0.stage == filterStage }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.client.localizedCaseInsensitiveContains(searchText)
                    || $0.sector.localizedCaseInsensitiveContains(searchText)
                    || $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    private var activeBidCount: Int {
        displayContracts.filter { $0.stage == "Open For Bid" || $0.stage == "Prequalifying Teams" }.count
    }
    private var totalWatchers: Int { displayContracts.reduce(0) { $0 + $1.watchCount } }
    private var avgScore: Double {
        guard !displayContracts.isEmpty else { return 0 }
        return Double(displayContracts.reduce(0) { $0 + $1.score }) / Double(displayContracts.count)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                contractsHeader
                contractStatsRow
                contractFilterBar
                if isLoading {
                    contractsLoading
                } else if let err = errorMessage {
                    contractsError(err)
                } else if displayContracts.isEmpty {
                    contractsEmpty
                } else {
                    contractList
                }
            }
            .padding(16)
        }
        .refreshable { await loadContracts() }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showAddSheet) {
            AddContractSheet { newContract in
                Task { await saveContract(newContract) }
            }
        }
        .task { await loadContracts() }
        .onChange(of: contracts) { _, newValue in
            saveJSON("ConstructOS.Contracts.DataRaw", value: newValue)
        }
        .onChange(of: filterStage) { _, newStage in
            guard supabase.isConfigured, newStage != "All" else { return }
            Task {
                do {
                    let query: [String: String] = ["stage": "eq.\(newStage)"]
                    let remote: [SupabaseContract] = try await supabase.fetch("cs_contracts", query: query)
                    await MainActor.run { contracts = remote }
                } catch {
                    CrashReporter.shared.reportError("Contracts filter refetch failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Sub-views

    private var contractsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CONTRACTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(Theme.gold)
                Text("Bid Pipeline")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                if !supabase.isConfigured {
                    Label("Demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button { showAddSheet = true } label: {
                    Label("Add Contract", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.gold)
                        .cornerRadius(8)
                }
                .disabled(!supabase.isConfigured)
                .opacity(supabase.isConfigured ? 1 : 0.5)

                Text("\(displayContracts.count) opportunities")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.gold)
    }

    private var contractStatsRow: some View {
        HStack(spacing: 10) {
            contractStatChip(value: "\(activeBidCount)", label: "ACTIVE BIDS", color: Theme.gold)
            contractStatChip(value: "\(totalWatchers)", label: "WATCHERS", color: Theme.cyan)
            contractStatChip(
                value: avgScore > 0 ? String(format: "%.0f", avgScore) : "—",
                label: "AVG SCORE",
                color: Theme.green
            )
        }
    }

    private var contractFilterBar: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 14))
                TextField("Search title, client, sector...", text: $searchText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.gold)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stageFilters, id: \.self) { f in
                        Button { filterStage = f } label: {
                            Text(f)
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(filterStage == f ? Theme.bg : Theme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filterStage == f ? Theme.gold : Theme.surface)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(filterStage == f ? Color.clear : Theme.border.opacity(0.5), lineWidth: 0.8)
                                )
                        }
                    }
                }
            }
        }
    }

    private var contractList: some View {
        VStack(spacing: 10) {
            ForEach(displayContracts) { contract in
                ContractCard(contract: contract, onUpdate: { updated in
                    Task { await updateContract(updated) }
                }, onDelete: { id in
                    Task { await deleteContract(id: id) }
                })
            }
        }
    }

    private var contractsLoading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.gold)
            Text("Loading contracts...").font(.system(size: 13)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(40)
    }

    private func contractsError(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 28)).foregroundColor(Theme.red)
            Text(message).font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            Button("Retry") { Task { await loadContracts() } }
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.gold)
        }
        .frame(maxWidth: .infinity).padding(40).background(Theme.surface).cornerRadius(14)
    }

    private var contractsEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.badge.plus").font(.system(size: 36)).foregroundColor(Theme.muted.opacity(0.5))
            Text(filterStage == "All" && searchText.isEmpty ? "No contracts yet" : "No matching contracts")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.muted)
            if filterStage == "All" && searchText.isEmpty {
                Button("Add first contract") { showAddSheet = true }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.gold)
                    .disabled(!supabase.isConfigured)
            }
        }
        .frame(maxWidth: .infinity).padding(40).background(Theme.surface).cornerRadius(14)
    }

    // MARK: - Data

    private func loadContracts() async {
        guard supabase.isConfigured else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do { contracts = try await supabase.fetch(SupabaseTable.contracts) }
        catch { errorMessage = error.localizedDescription }
    }

    private func saveContract(_ contract: SupabaseContract) async {
        do { try await supabase.insert(SupabaseTable.contracts, record: contract); await loadContracts() }
        catch { errorMessage = error.localizedDescription }
    }

    private func updateContract(_ contract: SupabaseContract) async {
        guard let id = contract.id else { return }
        do { try await supabase.update(SupabaseTable.contracts, id: id, record: contract); await loadContracts() }
        catch { errorMessage = error.localizedDescription }
    }

    private func deleteContract(id: String) async {
        do { try await supabase.delete(SupabaseTable.contracts, id: id); contracts.removeAll { $0.id == id } }
        catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Contract Card

private struct ContractCard: View {
    let contract: SupabaseContract
    let onUpdate: (SupabaseContract) -> Void
    let onDelete: (String) -> Void
    @State private var showDetail = false

    var stageColor: Color {
        switch contract.stage {
        case "Open For Bid": return Theme.gold
        case "Awarded": return Theme.green
        case "Lost": return Theme.red
        case "Negotiation": return Theme.cyan
        default: return Theme.muted
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(contract.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.text)
                            .multilineTextAlignment(.leading)
                        Text("\(contract.client) · \(contract.location)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(contract.stage.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(stageColor)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(stageColor.opacity(0.12))
                            .cornerRadius(4)
                        Text("\(contract.score)")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(Theme.gold)
                    }
                }

                HStack(spacing: 14) {
                    contractChip(icon: "tag", text: contract.sector, color: Theme.purple)
                    contractChip(icon: "dollarsign.circle", text: contract.budget, color: Theme.green)
                    contractChip(icon: "calendar", text: "Due \(contract.bidDue)", color: Theme.muted)
                }

                HStack {
                    Label("\(contract.bidders) bidders", systemImage: "person.3")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Label("\(contract.watchCount) watching", systemImage: "eye")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    if !contract.liveFeedStatus.isEmpty {
                        Label(contract.liveFeedStatus, systemImage: "dot.radiowaves.left.and.right")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.cyan)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: stageColor)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ContractDetailSheet(contract: contract, onUpdate: onUpdate, onDelete: onDelete)
        }
    }

    private func contractChip(icon: String, text: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.10))
            .cornerRadius(5)
    }
}

// MARK: - Contract Detail Sheet

private struct ContractDetailSheet: View {
    let contract: SupabaseContract
    let onUpdate: (SupabaseContract) -> Void
    let onDelete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var edited: SupabaseContract
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    init(contract: SupabaseContract, onUpdate: @escaping (SupabaseContract) -> Void, onDelete: @escaping (String) -> Void) {
        self.contract = contract; self.onUpdate = onUpdate; self.onDelete = onDelete
        _edited = State(initialValue: contract)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isEditing { contractEditForm } else { contractDetailBody }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Contract" : contract.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing { edited = contract; isEditing = false } else { dismiss() }
                    }
                    .foregroundColor(Theme.gold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") { onUpdate(edited); isEditing = false; dismiss() }
                            .foregroundColor(Theme.gold).fontWeight(.bold)
                    } else {
                        Menu {
                            Button("Edit") { isEditing = true }
                            Button("Delete", role: .destructive) { showDeleteConfirm = true }
                        } label: {
                            Image(systemName: "ellipsis.circle").foregroundColor(Theme.gold)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete \(contract.title)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = contract.id { onDelete(id) }
                dismiss()
            }
        }
    }

    private var contractDetailBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow("Client", contract.client)
            detailRow("Location", contract.location)
            detailRow("Sector", contract.sector)
            detailRow("Stage", contract.stage)
            detailRow("Package", contract.package)
            detailRow("Budget", contract.budget)
            detailRow("Bid Due", contract.bidDue)
            detailRow("Bidders", "\(contract.bidders)")
            detailRow("Score", "\(contract.score)")
            detailRow("Watching", "\(contract.watchCount)")
            if !contract.liveFeedStatus.isEmpty { detailRow("Live Feed", contract.liveFeedStatus) }
        }
        .padding(16).background(Theme.surface).cornerRadius(14)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium)).foregroundColor(Theme.muted).frame(width: 80, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.text)
        }
    }

    private var contractEditForm: some View {
        VStack(spacing: 14) {
            contractFormField("Title", text: $edited.title)
            contractFormField("Client", text: $edited.client)
            contractFormField("Location", text: $edited.location)
            contractFormField("Sector", text: $edited.sector)
            contractFormField("Package", text: $edited.package)
            contractFormField("Budget", text: $edited.budget)
            contractFormField("Bid Due", text: $edited.bidDue)
            contractFormField("Live Feed Status", text: $edited.liveFeedStatus)

            VStack(alignment: .leading, spacing: 8) {
                Text("STAGE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                Picker("Stage", selection: $edited.stage) {
                    ForEach(["Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation", "Awarded", "Lost"], id: \.self) { Text($0) }
                }
                .accentColor(Theme.gold)
            }
        }
        .padding(16).background(Theme.surface).cornerRadius(14)
    }
}

// MARK: - Add Contract Sheet

private struct AddContractSheet: View {
    let onAdd: (SupabaseContract) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""; @State private var client = ""; @State private var location = ""
    @State private var sector = ""; @State private var stage = "Pursuit"; @State private var pkg = ""
    @State private var budget = ""; @State private var bidDue = ""; @State private var liveFeed = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        contractFormField("Contract Title", text: $title)
                        contractFormField("Client", text: $client)
                        contractFormField("Location", text: $location)
                        contractFormField("Sector (e.g. Healthcare)", text: $sector)
                        contractFormField("Package (e.g. Core & Shell)", text: $pkg)
                        contractFormField("Budget (e.g. $28M)", text: $budget)
                        contractFormField("Bid Due Date (e.g. Apr 18)", text: $bidDue)
                        contractFormField("Live Feed Status (optional)", text: $liveFeed)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("STAGE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                            Picker("Stage", selection: $stage) {
                                ForEach(["Pursuit", "Prequalifying Teams", "Open For Bid", "Negotiation"], id: \.self) { Text($0) }
                            }
                            .accentColor(Theme.gold)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Contract")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onAdd(SupabaseContract(
                            id: nil, title: title, client: client, location: location,
                            sector: sector.isEmpty ? "General" : sector, stage: stage,
                            package: pkg.isEmpty ? "TBD" : pkg, budget: budget.isEmpty ? "$0" : budget,
                            bidDue: bidDue.isEmpty ? "TBD" : bidDue, liveFeedStatus: liveFeed,
                            bidders: 0, score: 0, watchCount: 0
                        ))
                        dismiss()
                    }
                    .foregroundColor(title.isEmpty ? Theme.muted : Theme.gold)
                    .fontWeight(.bold).disabled(title.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helpers

private func contractStatChip(value: String, label: String, color: Color) -> some View {
    VStack(spacing: 3) {
        Text(value).font(.system(size: 20, weight: .heavy)).foregroundColor(color)
        Text(label).font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
    }
    .frame(maxWidth: .infinity).padding(.vertical, 12).background(Theme.surface).cornerRadius(10)
    .premiumGlow(cornerRadius: 10, color: color)
}

private func contractFormField(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label.uppercased()).font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
        TextField(label, text: text)
            .font(.system(size: 13)).foregroundColor(Theme.text).accentColor(Theme.gold)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Theme.surface).cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
    }
}
