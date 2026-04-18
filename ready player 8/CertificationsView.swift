import SwiftUI

// MARK: - Phase 15: Certifications (TEAM-03) — driver's-license layout

let CERT_NAMES = ["OSHA 10","OSHA 30","First Aid/CPR","Forklift","Crane Operator","MEWP","Welding"]

// MARK: - Urgency Model (internal for XCTest access)

enum CertUrgency: String {
    case safe, warning, urgent, expired

    var shouldPulse: Bool {
        self == .expired
    }
}

func certUrgency(expiresAt: String?) -> CertUrgency {
    guard let s = expiresAt else { return .safe }
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    guard let d = f.date(from: s) else { return .safe }
    let days = Calendar.current.dateComponents([.day],
        from: Calendar.current.startOfDay(for: Date()),
        to: Calendar.current.startOfDay(for: d)).day ?? 0
    if days <= 0 { return .expired }
    if days <= 7 { return .urgent }
    if days <= 30 { return .warning }
    return .safe
}

func urgencyColor(_ urgency: CertUrgency) -> Color {
    switch urgency {
    case .safe: return Theme.green
    case .warning: return Theme.gold
    case .urgent, .expired: return .red
    }
}

func parseCertDeepLink(userInfo: [AnyHashable: Any]) -> String? {
    userInfo["cert_id"] as? String
}

// MARK: - Encodable Payloads

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
    @State private var editingCert: SupabaseCertification?
    @State private var pulseOpacity: Double = 0.5

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

            summaryBanner

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
        .onAppear { pulseOpacity = 1.0 }
        .sheet(isPresented: $showingAdd) {
            AddCertSheet(members: members) { Task { await load() } }
        }
        .sheet(item: $editingCert) { cert in
            EditCertSheet(cert: cert) { Task { await load() } }
        }
    }

    // MARK: - Summary Banner (D-19)

    private var summaryBanner: some View {
        let expired = certs.filter { certUrgency(expiresAt: $0.expires_at) == .expired }.count
        let expiring30 = certs.filter {
            let u = certUrgency(expiresAt: $0.expires_at)
            return u == .warning || u == .urgent
        }.count

        return Group {
            if expired > 0 || expiring30 > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(expired > 0 ? .red : Theme.gold)
                    Text(bannerText(expired: expired, expiring: expiring30))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.text)
                    Spacer()
                }
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(10)
                .padding(.horizontal, 24)
                .accessibilityLabel("Alert: \(bannerText(expired: expired, expiring: expiring30))")
            }
        }
    }

    private func bannerText(expired: Int, expiring: Int) -> String {
        var parts: [String] = []
        if expiring > 0 { parts.append("\(expiring) expiring within 30 days") }
        if expired > 0 { parts.append("\(expired) expired") }
        return parts.joined(separator: " · ")
    }

    // MARK: - License Card

    private func licenseCard(_ cert: SupabaseCertification) -> some View {
        let urgency = certUrgency(expiresAt: cert.expires_at)

        return VStack(alignment: .leading, spacing: 12) {
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
                    .foregroundColor(urgencyColor(urgency))
            }

            // Urgency badge (D-18)
            HStack(spacing: 8) {
                Circle()
                    .fill(urgencyColor(urgency))
                    .frame(width: 10, height: 10)
                    .opacity(urgency.shouldPulse ? pulseOpacity : 1.0)
                    .animation(urgency.shouldPulse ?
                        .easeInOut(duration: 2).repeatForever(autoreverses: true) : .default,
                        value: pulseOpacity)
                    .accessibilityLabel(urgencyAccessibilityLabel(urgency))
                Text(urgencyLabel(urgency))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(urgencyColor(urgency))
                Spacer()
                // Renewal CTA (D-20, D-28)
                Button(action: { editingCert = cert }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Update Cert")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accent)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .premiumGlow(cornerRadius: 14, color: Theme.gold)
    }

    // MARK: - Helpers

    private func urgencyLabel(_ u: CertUrgency) -> String {
        switch u {
        case .safe: return "VALID"
        case .warning: return "EXPIRING SOON"
        case .urgent: return "EXPIRING"
        case .expired: return "EXPIRED"
        }
    }

    private func urgencyAccessibilityLabel(_ u: CertUrgency) -> String {
        switch u {
        case .safe: return "Valid — more than 30 days until expiry"
        case .warning: return "Expiring soon — within 30 days — warning"
        case .urgent: return "Expiring within 7 days — urgent"
        case .expired: return "Expired — critical"
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "expired": return .red
        case "revoked": return Theme.muted
        default: return Theme.gold
        }
    }

    private var urgentCertCount: Int {
        certs.filter {
            let u = certUrgency(expiresAt: $0.expires_at)
            return u == .expired || u == .urgent
        }.count
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
        // Wire badge count for ContentView cert badge (Phase 23 relay key)
        UserDefaults.standard.set(urgentCertCount, forKey: "ConstructOS.CertBadgeCount")
    }
}

// MARK: - Edit Cert Sheet (D-28, D-29)

struct EditCertSheet: View {
    let cert: SupabaseCertification
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var expiresAt: Date
    @State private var errorMessage: String?

    init(cert: SupabaseCertification, onSaved: @escaping () -> Void) {
        self.cert = cert
        self.onSaved = onSaved
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        _expiresAt = State(initialValue: f.date(from: cert.expires_at ?? "") ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Certification") {
                    Text(cert.name).foregroundColor(Theme.text)
                    if let issuer = cert.issuer {
                        Text("Issued by: \(issuer)").foregroundColor(Theme.muted)
                    }
                }
                Section("Renewal") {
                    DatePicker("New Expiry Date", selection: $expiresAt, displayedComponents: .date)
                }
                // D-29: Optional document attachment prompt
                Section("Documentation (Optional)") {
                    Text("Attach new cert scan from Documents")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                }
                if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                }
            }
            .navigationTitle("Update Certification")
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
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let newExpiry = f.string(from: expiresAt)
        Task {
            do {
                // D-28: update expires_at + flip status to active
                try await SupabaseService.shared.update(
                    "cs_certifications",
                    id: cert.id,
                    record: ["expires_at": newExpiry, "status": "active"]
                )
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
                return
            }
            await MainActor.run {
                onSaved()
                dismiss()
            }
        }
    }
}

// MARK: - Add Cert Sheet

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
