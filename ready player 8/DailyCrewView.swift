import SwiftUI

// MARK: - Phase 15: Daily Crew Stand-Up (TEAM-05)
// Phase 23-01: Project picker replaces the `mockProjects.first` stub from
// quick task 260414-n4w. projectId is now internal state (AppStorage-backed)
// so DailyCrewView can be instantiated zero-arg from NavTab routing.

private struct DailyCrewPayload: Encodable {
    let project_id: String
    let assignment_date: String
    let member_ids: [String]
    let notes: String?
}

struct DailyCrewView: View {
    // Phase 23-01: projectId becomes internal; persists last selection across launches.
    @AppStorage("ConstructOS.Team.LastDailyCrewProjectId") private var selectedProjectId: String = ""
    @State private var projects: [SupabaseProject] = []
    @State private var date: Date = Date()
    @State private var members: [SupabaseTeamMember] = []
    @State private var selected: Set<String> = []
    @State private var notes: String = ""
    @State private var saving = false
    @State private var toast: String?
    @State private var lastSavedSelected: Set<String> = []
    @State private var lastSavedNotes: String = ""
    @State private var showUnsavedAlert = false
    @State private var pendingProjectId: String?
    @State private var appError: AppError?

    private let supabase = SupabaseService.shared

    private var displayProjects: [SupabaseProject] {
        supabase.isConfigured && !projects.isEmpty ? projects : mockSupabaseProjects
    }

    private var selectedProject: SupabaseProject? {
        displayProjects.first { $0.id == selectedProjectId }
    }

    private var isDirty: Bool {
        selected != lastSavedSelected || notes != lastSavedNotes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DAILY CREW")
                .font(.system(size: 14, weight: .semibold))
                .tracking(2)
                .foregroundColor(Theme.muted)

            // Phase 23-05 D-19: Offline/demo-mode indicator
            if !supabase.isConfigured {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 12))
                    Text("Demo mode — connect Supabase to save")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Theme.gold)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Theme.gold.opacity(0.1))
                .cornerRadius(8)
                .accessibilityLabel("Demo mode active. Connect Supabase in the Hub tab to save crew assignments.")
            }

            // Phase 23-01: Project picker (replaces parameterized projectId).
            projectPicker

            if displayProjects.isEmpty {
                Text("No projects yet — create one in the Projects tab first.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .accessibilityLabel("Crew assignment date")
                    .onChange(of: date) { _, _ in
                        Task {
                            if isDirty { await save() }
                            await loadCrew()
                        }
                    }

                Text("WHO'S ON SITE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)

                if members.isEmpty {
                    Text("No team members yet — add members in the Team tab first.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(members) { m in
                                Button(action: { toggle(m.id) }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: selected.contains(m.id) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(selected.contains(m.id) ? Theme.accent : Theme.muted)
                                            .font(.system(size: 20))
                                        Text(m.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.text)
                                        if let trade = m.trade {
                                            Text("· \(trade)")
                                                .font(.system(size: 12))
                                                .foregroundColor(Theme.muted)
                                        }
                                        Spacer()
                                    }
                                    .frame(minHeight: 48) // ≥44pt tap target per UI spec
                                    .padding(.horizontal, 12)
                                    .background(Theme.surface)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(m.name)\(m.trade.map { ", \($0)" } ?? ""), \(selected.contains(m.id) ? "assigned to crew" : "not assigned")")
                            }
                        }
                    }
                }

                Text("SCOPE & NOTES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                TextField("What's the crew working on? Any blockers, deliveries, inspections?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Theme.surface)
                    .cornerRadius(8)
                    .accessibilityLabel("Scope and notes for today's crew")

                Button(action: { Task { await save() } }) {
                    HStack(spacing: 8) {
                        if saving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(saving ? "Saving..." : "Save Crew")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(saving ? Theme.muted : Theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(saving || selectedProjectId.isEmpty)
                .accessibilityLabel("Save crew assignments")
                .accessibilityValue(saving ? "Saving in progress" : (toast?.contains("saved") == true ? "Saved successfully" : "Ready to save"))

                if let toast = toast {
                    Text(toast)
                        .font(.system(size: 12))
                        .foregroundColor(toast.contains("saved") ? Theme.green : Theme.gold)
                        .accessibilityLabel(toast)
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: 3_000_000_000)
                                await MainActor.run { self.toast = nil }
                            }
                        }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        .task {
            await loadProjects()
            // Auto-select first project if none persisted (mirrors ProjectsView default behavior).
            if selectedProjectId.isEmpty, let first = displayProjects.first?.id {
                selectedProjectId = first
            }
            // Phase 23: Consume date relay from AgendaListView cross-nav (D-13)
            if let relayDate = UserDefaults.standard.string(forKey: "ConstructOS.Team.DailyCrewDateRelay") {
                UserDefaults.standard.removeObject(forKey: "ConstructOS.Team.DailyCrewDateRelay")
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                if let parsed = f.date(from: relayDate) {
                    date = parsed
                }
            }
            await loadMembers()
            await loadCrew()
        }
        .confirmationDialog("You have unsaved changes", isPresented: $showUnsavedAlert) {
            Button("Save & Switch") {
                Task {
                    await save()
                    if let pid = pendingProjectId {
                        selectedProjectId = pid
                        pendingProjectId = nil
                        await loadCrew()
                    }
                }
            }
            Button("Discard Changes", role: .destructive) {
                if let pid = pendingProjectId {
                    selectedProjectId = pid
                    pendingProjectId = nil
                    Task { await loadCrew() }
                }
            }
            Button("Cancel", role: .cancel) {
                pendingProjectId = nil
            }
        }
        .alert("Error", isPresented: Binding(
            get: { appError != nil },
            set: { if !$0 { appError = nil } }
        )) {
            Button("OK") { appError = nil }
            if let err = appError, err.isRetryable {
                Button("Retry") {
                    appError = nil
                    Task { await save() }
                }
            }
        } message: {
            if let err = appError {
                Text(err.localizedDescription)
            }
        }
    }

    // MARK: - Sub-views

    private var projectPicker: some View {
        Menu {
            ForEach(displayProjects) { p in
                Button(action: {
                    if let pid = p.id {
                        if isDirty {
                            pendingProjectId = pid
                            showUnsavedAlert = true
                        } else {
                            selectedProjectId = pid
                            Task { await loadCrew() }
                        }
                    }
                }) {
                    Text(p.name)
                }
            }
        } label: {
            HStack {
                Text(selectedProject?.name ?? "Select project…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.text)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Theme.surface)
            .cornerRadius(8)
            .accessibilityLabel("Select project, currently \(selectedProject?.name ?? "none selected")")
            .accessibilityHint("Double tap to choose a different project")
        }
    }

    // MARK: - Actions

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func loadProjects() async {
        guard supabase.isConfigured else { return }
        do {
            let remote: [SupabaseProject] = try await supabase.fetch(
                "cs_projects",
                orderBy: "created_at",
                ascending: false
            )
            await MainActor.run { projects = remote }
        } catch {
            // Fallback to mock via displayProjects computed property.
            CrashReporter.shared.reportError("DailyCrew loadProjects failed: \(error.localizedDescription)")
        }
    }

    private func loadMembers() async {
        members = await DataSyncManager.shared.syncTable(
            "cs_team_members",
            localKey: "ConstructOS.Team.MembersCache",
            defaultValue: [SupabaseTeamMember]()
        )
    }

    private func loadCrew() async {
        guard !selectedProjectId.isEmpty else {
            selected = []
            notes = ""
            return
        }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let dateStr = f.string(from: date)
        let rows: [SupabaseDailyCrew] = await DataSyncManager.shared.syncTable(
            "cs_daily_crew",
            localKey: "ConstructOS.Team.DailyCrewCache",
            defaultValue: [SupabaseDailyCrew]()
        )
        if let row = rows.first(where: { $0.project_id == selectedProjectId && $0.assignment_date == dateStr }) {
            selected = Set(row.member_ids)
            notes = row.notes ?? ""
        } else {
            selected = []
            notes = ""
        }
        lastSavedSelected = selected
        lastSavedNotes = notes
    }

    private func save() async {
        guard !selectedProjectId.isEmpty else {
            toast = "Pick a project first."
            return
        }
        saving = true
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let payload = DailyCrewPayload(
            project_id: selectedProjectId,
            assignment_date: f.string(from: date),
            member_ids: Array(selected),
            notes: notes.isEmpty ? nil : notes
        )
        do {
            // TEAM-05 / INT-04: Natural key is (project_id, assignment_date) — upsert prevents 409 on edit.
            try await SupabaseService.shared.upsert(
                "cs_daily_crew",
                record: payload,
                onConflict: "project_id,assignment_date"
            )
            await MainActor.run {
                toast = "Crew saved for \(f.string(from: date))"
                lastSavedSelected = selected
                lastSavedNotes = notes
            }
        } catch let err as AppError {
            await MainActor.run {
                appError = err
                toast = err.localizedDescription
            }
        } catch {
            let mapped = AppError.network(underlying: error)
            await MainActor.run {
                appError = mapped
                toast = mapped.localizedDescription
            }
        }
        await MainActor.run { saving = false }
    }
}
