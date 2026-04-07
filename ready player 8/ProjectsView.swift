import SwiftUI

// MARK: - ========== ProjectsView.swift ==========

struct ProjectsView: View {
    @State private var projects: [SupabaseProject] = loadJSON("ConstructOS.Projects.DataRaw", default: [SupabaseProject]())
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var filterStatus = "All"
    @State private var showAddSheet = false
    @State private var selectedProject: SupabaseProject?

    private let statusFilters = ["All", "On Track", "Ahead", "Delayed", "At Risk"]
    private let supabase = SupabaseService.shared

    private var displayProjects: [SupabaseProject] {
        var list = supabase.isConfigured ? projects : mockSupabaseProjects
        if filterStatus != "All" {
            list = list.filter { $0.status == filterStatus }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.client.localizedCaseInsensitiveContains(searchText)
                    || $0.type.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    private var activeCount: Int { displayProjects.filter { $0.status != "Delayed" }.count }
    private var avgScore: Double {
        let scores = displayProjects.compactMap { Double($0.score) }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                // Header
                projectsHeader
                // Stats row
                statsRow
                // Filter bar
                filterBar
                // Project list or states
                if isLoading {
                    loadingView
                } else if let err = errorMessage {
                    errorView(err)
                } else if displayProjects.isEmpty {
                    emptyView
                } else {
                    projectList
                }
            }
            .padding(16)
        }
        .refreshable { await loadProjects() }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showAddSheet) {
            AddProjectSheet { newProject in
                Task { await saveProject(newProject) }
            }
        }
        .task { await loadProjects() }
        .onChange(of: projects) { _, newValue in
            saveJSON("ConstructOS.Projects.DataRaw", value: newValue)
        }
        .onChange(of: filterStatus) { _, newFilter in
            guard supabase.isConfigured, newFilter != "All" else { return }
            Task {
                do {
                    let query: [String: String] = ["status": "eq.\(newFilter)"]
                    let remote: [SupabaseProject] = try await supabase.fetch("cs_projects", query: query)
                    await MainActor.run { projects = remote }
                } catch {
                    CrashReporter.shared.reportError("Projects filter refetch failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Sub-views

    private var projectsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROJECTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(Theme.accent)
                Text("Project Command")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                if !supabase.isConfigured {
                    Label("Using demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .cornerRadius(8)
                }
                .disabled(!supabase.isConfigured)
                .opacity(supabase.isConfigured ? 1 : 0.5)

                Text("\(displayProjects.count) projects")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            projectStatChip(value: "\(activeCount)", label: "ACTIVE", color: Theme.green)
            projectStatChip(value: "\(displayProjects.count)", label: "TOTAL", color: Theme.cyan)
            projectStatChip(
                value: avgScore > 0 ? String(format: "%.1f", avgScore) : "—",
                label: "AVG SCORE",
                color: Theme.gold
            )
        }
    }

    private var filterBar: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 14))
                TextField("Search projects, clients, types...", text: $searchText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.text)
                    .accentColor(Theme.accent)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.muted)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(statusFilters, id: \.self) { f in
                        Button {
                            filterStatus = f
                        } label: {
                            Text(f)
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(filterStatus == f ? Theme.bg : Theme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filterStatus == f ? Theme.accent : Theme.surface)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(filterStatus == f ? Color.clear : Theme.border.opacity(0.5), lineWidth: 0.8)
                                )
                        }
                    }
                }
            }
        }
    }

    private var projectList: some View {
        VStack(spacing: 10) {
            ForEach(displayProjects) { project in
                ProjectCard(project: project, onUpdate: { updated in
                    Task { await updateProject(updated) }
                }, onDelete: { id in
                    Task { await deleteProject(id: id) }
                })
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.accent)
            Text("Loading projects...")
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(Theme.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await loadProjects() } }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.surface)
        .cornerRadius(14)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "building.2")
                .font(.system(size: 36))
                .foregroundColor(Theme.muted.opacity(0.5))
            Text(filterStatus == "All" && searchText.isEmpty ? "No projects yet" : "No matching projects")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.muted)
            if filterStatus == "All" && searchText.isEmpty {
                Button("Add your first project") { showAddSheet = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .disabled(!supabase.isConfigured)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.surface)
        .cornerRadius(14)
    }

    // MARK: - Data

    private func loadProjects() async {
        guard supabase.isConfigured else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            projects = try await supabase.fetch(SupabaseTable.projects)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveProject(_ project: SupabaseProject) async {
        do {
            try await supabase.insert(SupabaseTable.projects, record: project)
            await loadProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateProject(_ project: SupabaseProject) async {
        guard let id = project.id else { return }
        do {
            try await supabase.update(SupabaseTable.projects, id: id, record: project)
            await loadProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteProject(id: String) async {
        do {
            try await supabase.delete(SupabaseTable.projects, id: id)
            projects.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: SupabaseProject
    let onUpdate: (SupabaseProject) -> Void
    let onDelete: (String) -> Void
    @State private var showDetail = false

    var statusColor: Color {
        switch project.status {
        case "On Track": return Theme.green
        case "Ahead": return Theme.cyan
        case "Delayed": return Theme.red
        case "At Risk": return Theme.gold
        default: return Theme.muted
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.text)
                        Text(project.client)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(project.status.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.12))
                            .cornerRadius(4)
                        if !project.score.isEmpty && project.score != "—" {
                            Text(project.score)
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(Theme.gold)
                        }
                    }
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.type)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.cyan)
                        Spacer()
                        Text("\(project.progress)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.text)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Theme.border.opacity(0.3)).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor)
                                .frame(width: geo.size.width * CGFloat(project.progress) / 100, height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                HStack {
                    Label(project.budget, systemImage: "dollarsign.circle")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Label(project.team, systemImage: "person.2")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(12)
            .premiumGlow(cornerRadius: 12, color: statusColor)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ProjectDetailSheet(project: project, onUpdate: onUpdate, onDelete: onDelete)
        }
    }
}

// MARK: - Project Detail Sheet

private struct ProjectDetailSheet: View {
    let project: SupabaseProject
    let onUpdate: (SupabaseProject) -> Void
    let onDelete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editedProject: SupabaseProject
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    init(project: SupabaseProject, onUpdate: @escaping (SupabaseProject) -> Void, onDelete: @escaping (String) -> Void) {
        self.project = project
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedProject = State(initialValue: project)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isEditing {
                            editForm
                        } else {
                            detailView
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : project.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing {
                            editedProject = project
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            onUpdate(editedProject)
                            isEditing = false
                            dismiss()
                        }
                        .foregroundColor(Theme.accent)
                        .fontWeight(.bold)
                    } else {
                        Menu {
                            Button("Edit") { isEditing = true }
                            Button("Delete", role: .destructive) { showDeleteConfirm = true }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Theme.accent)
                        }
                        .accessibilityLabel("Project actions")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete \(project.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = project.id { onDelete(id) }
                dismiss()
            }
        }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                detailRow("Client", project.client)
                detailRow("Type", project.type)
                detailRow("Status", project.status)
                detailRow("Progress", "\(project.progress)%")
                detailRow("Budget", project.budget)
                detailRow("Team", project.team)
                if !project.score.isEmpty { detailRow("Score", project.score) }
            }
            .padding(16)
            .background(Theme.surface)
            .cornerRadius(14)

            // MARK: - Phase 13 Documents
            if let pid = project.id {
                DocumentAttachmentsView(
                    entityType: .project,
                    entityId: pid,
                    orgId: SupabaseService.shared.currentOrgId
                )
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.muted)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.text)
        }
    }

    private var editForm: some View {
        VStack(spacing: 14) {
            formField("Project Name", text: $editedProject.name)
            formField("Client", text: $editedProject.client)
            formField("Type", text: $editedProject.type)
            formField("Budget", text: $editedProject.budget)
            formField("Team", text: $editedProject.team)
            formField("Score", text: $editedProject.score)

            VStack(alignment: .leading, spacing: 8) {
                Text("STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Picker("Status", selection: $editedProject.status) {
                    ForEach(["On Track", "Ahead", "Delayed", "At Risk"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PROGRESS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Text("\(editedProject.progress)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.text)
                }
                Slider(value: Binding(
                    get: { Double(editedProject.progress) },
                    set: { editedProject.progress = Int($0) }
                ), in: 0...100, step: 1)
                .accentColor(Theme.accent)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(14)
    }
}

// MARK: - Add Project Sheet

private struct AddProjectSheet: View {
    let onAdd: (SupabaseProject) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var client = ""
    @State private var type = "Commercial"
    @State private var status = "On Track"
    @State private var progress = 0
    @State private var budget = ""
    @State private var team = ""
    @State private var score = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        formField("Project Name", text: $name)
                        formField("Client", text: $client)
                        formField("Type (e.g. Commercial High-Rise)", text: $type)
                        formField("Budget (e.g. $12.4M)", text: $budget)
                        formField("Team (e.g. 24 crew)", text: $team)
                        formField("Score (optional)", text: $score)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(Theme.muted)
                            Picker("Status", selection: $status) {
                                ForEach(["On Track", "Ahead", "Delayed", "At Risk"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PROGRESS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(Theme.muted)
                                Spacer()
                                Text("\(progress)%")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.text)
                            }
                            Slider(value: Binding(
                                get: { Double(progress) },
                                set: { progress = Int($0) }
                            ), in: 0...100, step: 1)
                            .accentColor(Theme.accent)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let project = SupabaseProject(
                            id: nil, name: name, client: client,
                            type: type.isEmpty ? "General" : type,
                            status: status, progress: progress,
                            budget: budget.isEmpty ? "$0" : budget,
                            score: score.isEmpty ? "—" : score,
                            team: team.isEmpty ? "TBD" : team
                        )
                        onAdd(project)
                        dismiss()
                    }
                    .foregroundColor(name.isEmpty ? Theme.muted : Theme.accent)
                    .fontWeight(.bold)
                    .disabled(name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helpers

private func projectStatChip(value: String, label: String, color: Color) -> some View {
    VStack(spacing: 3) {
        Text(value)
            .font(.system(size: 20, weight: .heavy))
            .foregroundColor(color)
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .tracking(2)
            .foregroundColor(Theme.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Theme.surface)
    .cornerRadius(10)
    .premiumGlow(cornerRadius: 10, color: color)
}

private func formField(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundColor(Theme.muted)
        TextField(label, text: text)
            .font(.system(size: 13))
            .foregroundColor(Theme.text)
            .accentColor(Theme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.surface)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.6), lineWidth: 0.8))
    }
}

// MARK: - Mock fallback data

let mockSupabaseProjects: [SupabaseProject] = mockProjects.map {
    SupabaseProject(id: $0.id.uuidString, name: $0.name, client: $0.client, type: $0.type,
                    status: $0.status, progress: $0.progress, budget: $0.budget, score: $0.score, team: $0.team)
}
