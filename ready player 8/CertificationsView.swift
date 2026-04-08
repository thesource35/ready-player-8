import SwiftUI

// MARK: - Phase 15: Certifications (TEAM-03) — driver's-license layout

let CERT_NAMES = ["OSHA 10","OSHA 30","First Aid/CPR","Forklift","Crane Operator","MEWP","Welding"]

private struct NewCertPayload: Encodable {
    let member_id: String
    let name: String
    let issuer: String?
    let expires_at: String?
    let status: String
}

struct CertificationsView: View {
    @State private var certs: [SupabaseCertification] = []
    @State private var members: [SupabaseTeamMember] = []
    @State private var showingAdd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(certs.count) CERTIFICATIONS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Spacer()
                Button(action: { showingAdd = true }) {
                    Label("Add Certification", systemImage: "plus")
                }
                .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 24)

            if certs.isEmpty {
                VStack(spacing: 8) {
                    Text("No certifications tracked")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text("Track OSHA, trade licenses, and safety credentials. We'll alert you 30 days before any cert expires.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(certs) { cert in licenseCard(cert) }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingAdd) {
            AddCertSheet(members: members) { Task { await load() } }
        }
    }

    private func licenseCard(_ cert: SupabaseCertification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cert.name.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Theme.text)
                    if let issuer = cert.issuer {
                        Text(issuer).font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                }
                Spacer()
                Text(cert.status.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(statusColor(cert.status))
            }
            // EXPIRES — visually dominant per UI spec (license-card layout)
            VStack(alignment: .leading, spacing: 4) {
                Text("EXPIRES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Theme.muted)
                Text(cert.expires_at ?? "—")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(expiryColor(cert.expires_at))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .premiumGlow(cornerRadius: 14, color: Theme.gold)
    }

    private func expiryColor(_ s: String?) -> Color {
        guard let s = s else { return Theme.muted }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: s) else { return Theme.text }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
        if days < 0 { return .red }
        if days <= 30 { return Theme.gold }
        return Theme.green
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "expired": return .red
        case "revoked": return Theme.muted
        default: return Theme.gold
        }
    }

    private func load() async {
        certs = await DataSyncManager.shared.syncTable(
            "cs_certifications",
            localKey: "ConstructOS.Team.CertsCache",
            defaultValue: [SupabaseCertification]()
        )
        members = await DataSyncManager.shared.syncTable(
            "cs_team_members",
            localKey: "ConstructOS.Team.MembersCache",
            defaultValue: [SupabaseTeamMember]()
        )
    }
}

struct AddCertSheet: View {
    var members: [SupabaseTeamMember]
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var memberId: String = ""
    @State private var name: String = ""
    @State private var customName: String = ""
    @State private var issuer: String = ""
    @State private var expiresAt: Date = Date().addingTimeInterval(60*60*24*365)
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Member", selection: $memberId) {
                    Text("—").tag("")
                    ForEach(members) { Text($0.name).tag($0.id) }
                }
                Picker("Certification", selection: $name) {
                    Text("Custom…").tag("")
                    ForEach(CERT_NAMES, id: \.self) { Text($0).tag($0) }
                }
                if name.isEmpty {
                    TextField("Custom name", text: $customName)
                }
                TextField("Issuing Body", text: $issuer)
                DatePicker("Expires", selection: $expiresAt, displayedComponents: .date)
                if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                }
            }
            .navigationTitle("New Certification")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let finalName = name.isEmpty ? customName.trimmingCharacters(in: .whitespacesAndNewlines) : name
        if memberId.isEmpty { errorMessage = "Member is required"; return }
        if finalName.isEmpty { errorMessage = "Certification name is required"; return }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let payload = NewCertPayload(
            member_id: memberId,
            name: finalName,
            issuer: issuer.isEmpty ? nil : issuer,
            expires_at: f.string(from: expiresAt),
            status: "active"
        )
        Task {
            do {
                try await SupabaseService.shared.insert("cs_certifications", record: payload)
            } catch {
                // best effort
            }
            await MainActor.run {
                onSaved()
                dismiss()
            }
        }
    }
}
