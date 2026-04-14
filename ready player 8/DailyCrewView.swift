import SwiftUI

// MARK: - Phase 15: Daily Crew Stand-Up (TEAM-05)

private struct DailyCrewPayload: Encodable {
    let project_id: String
    let assignment_date: String
    let member_ids: [String]
    let notes: String?
}

struct DailyCrewView: View {
    let projectId: String
    @State private var date: Date = Date()
    @State private var members: [SupabaseTeamMember] = []
    @State private var selected: Set<String> = []
    @State private var notes: String = ""
    @State private var saving = false
    @State private var toast: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DAILY CREW")
                .font(.system(size: 14, weight: .semibold))
                .tracking(2)
                .foregroundColor(Theme.muted)

            DatePicker("Date", selection: $date, displayedComponents: .date)
                .onChange(of: date) { _, _ in Task { await loadCrew() } }

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

            Button(action: { Task { await save() } }) {
                Text("Save Crew")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(saving)

            if let toast = toast {
                Text(toast)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.gold)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        .task { await loadMembers(); await loadCrew() }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func loadMembers() async {
        members = await DataSyncManager.shared.syncTable(
            "cs_team_members",
            localKey: "ConstructOS.Team.MembersCache",
            defaultValue: [SupabaseTeamMember]()
        )
    }

    private func loadCrew() async {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let dateStr = f.string(from: date)
        let rows: [SupabaseDailyCrew] = await DataSyncManager.shared.syncTable(
            "cs_daily_crew",
            localKey: "ConstructOS.Team.DailyCrewCache",
            defaultValue: [SupabaseDailyCrew]()
        )
        if let row = rows.first(where: { $0.project_id == projectId && $0.assignment_date == dateStr }) {
            selected = Set(row.member_ids)
            notes = row.notes ?? ""
        } else {
            selected = []
            notes = ""
        }
    }

    private func save() async {
        saving = true
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let payload = DailyCrewPayload(
            project_id: projectId,
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
            await MainActor.run { toast = "Crew saved for \(f.string(from: date))" }
        } catch {
            await MainActor.run { toast = "Couldn't save crew. Check your connection and try again." }
        }
        await MainActor.run { saving = false }
    }
}
