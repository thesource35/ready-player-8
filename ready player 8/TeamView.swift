import SwiftUI

// MARK: - Phase 15: Team & Crew — Constants

let TRADES = ["Concrete","Steel","MEP","Framing","Finishes","Electrical","Plumbing","HVAC","Roofing","Crane","General"]
let TEAM_MEMBER_KINDS = ["internal","subcontractor","vendor"]

// MARK: - TeamMemberDraft (form validation, defense-in-depth with DB constraints)

struct TeamMemberDraft {
    var kind: String
    var name: String
    var role: String?
    var trade: String?

    func validate() -> (isValid: Bool, message: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return (false, "Name is required") }
        if trimmed.count > 200 { return (false, "Name too long") }
        if !TEAM_MEMBER_KINDS.contains(kind) { return (false, "Invalid kind") }
        return (true, "")
    }
}

// MARK: - Encodable payload for inserts (snake_case matches DB columns)

private struct NewTeamMemberPayload: Encodable {
    let kind: String
    let name: String
    let role: String?
    let trade: String?
}

// MARK: - TeamView

struct TeamView: View {
    @AppStorage("ConstructOS.Team.SubTab") private var subTab: String = "members"
    @State private var members: [SupabaseTeamMember] = []
    @State private var assignments: [SupabaseProjectAssignment] = []
    @State private var showingAdd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("TEAM")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(Theme.text)
                Spacer()
                Picker("", selection: $subTab) {
                    Text("Members").tag("members")
                    Text("Assignments").tag("assignments")
                    Text("Certifications").tag("certifications")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Group {
                if subTab == "members" { membersList }
                else if subTab == "assignments" { assignmentsList }
                else { CertificationsView() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        .task { await load() }
        .sheet(isPresented: $showingAdd) {
            AddTeamMemberSheet { Task { await load() } }
        }
    }

    private var membersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(members.count) MEMBERS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Spacer()
                Button(action: { showingAdd = true }) {
                    Label("Add Member", systemImage: "plus")
                }
                .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 24)

            if members.isEmpty {
                emptyState(
                    heading: "No team members yet",
                    body: "Add your first internal staffer, sub, or vendor to start assigning crews to projects."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(members) { m in memberRow(m) }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func memberRow(_ m: SupabaseTeamMember) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(m.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.text)
                HStack(spacing: 8) {
                    Text(m.kind.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(kindColor(m.kind))
                    if let trade = m.trade {
                        Text("·").foregroundColor(Theme.muted)
                        Text(trade).font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                    if let company = m.company {
                        Text("·").foregroundColor(Theme.muted)
                        Text(company).font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                }
            }
            Spacer()
            if let role = m.role {
                Text(role).font(.system(size: 12)).foregroundColor(Theme.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .premiumGlow(cornerRadius: 14, color: Theme.accent)
    }

    private func kindColor(_ kind: String) -> Color {
        switch kind {
        case "internal": return Theme.cyan
        case "subcontractor": return Theme.purple
        default: return Theme.muted
        }
    }

    private var assignmentsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(assignments.count) ASSIGNMENTS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Spacer()
            }
            .padding(.horizontal, 24)

            if assignments.isEmpty {
                emptyState(
                    heading: "No active assignments",
                    body: "Assign a member to a project to track who's on what. Members can hold roles on multiple projects."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(assignments) { a in
                            HStack {
                                Text(String(a.member_id.prefix(8)) + "…")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.text)
                                Spacer()
                                if let role = a.role_on_project {
                                    Text(role).font(.system(size: 12)).foregroundColor(Theme.muted)
                                }
                                Text(a.status.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Theme.gold)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface)
                            .premiumGlow(cornerRadius: 14, color: Theme.accent)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func emptyState(heading: String, body: String) -> some View {
        VStack(spacing: 8) {
            Text(heading)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.text)
            Text(body)
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private func load() async {
        members = await DataSyncManager.shared.syncTable(
            "cs_team_members",
            localKey: "ConstructOS.Team.MembersCache",
            defaultValue: [SupabaseTeamMember]()
        )
        assignments = await DataSyncManager.shared.syncTable(
            "cs_project_assignments",
            localKey: "ConstructOS.Team.AssignmentsCache",
            defaultValue: [SupabaseProjectAssignment]()
        )
    }
}

// MARK: - AddTeamMemberSheet

struct AddTeamMemberSheet: View {
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = TeamMemberDraft(kind: "internal", name: "", role: nil, trade: nil)
    @State private var errorMessage: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Kind", selection: $draft.kind) {
                    ForEach(TEAM_MEMBER_KINDS, id: \.self) { Text($0.capitalized).tag($0) }
                }
                TextField("Name", text: $draft.name)
                TextField("Role", text: Binding(
                    get: { draft.role ?? "" },
                    set: { draft.role = $0.isEmpty ? nil : $0 }
                ))
                Picker("Trade", selection: Binding(
                    get: { draft.trade ?? "" },
                    set: { draft.trade = $0.isEmpty ? nil : $0 }
                )) {
                    Text("—").tag("")
                    ForEach(TRADES, id: \.self) { Text($0).tag($0) }
                }
                if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                }
            }
            .navigationTitle("New Member")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(saving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let r = draft.validate()
        if !r.isValid { errorMessage = r.message; return }
        saving = true
        let payload = NewTeamMemberPayload(
            kind: draft.kind,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            role: draft.role,
            trade: draft.trade
        )
        Task {
            do {
                try await SupabaseService.shared.insert("cs_team_members", record: payload)
            } catch {
                // Best-effort — caller refreshes from cache on dismiss
            }
            await MainActor.run {
                saving = false
                onSaved()
                dismiss()
            }
        }
    }
}
