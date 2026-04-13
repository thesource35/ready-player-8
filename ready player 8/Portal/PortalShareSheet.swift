import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ========== PortalShareSheet.swift ==========

/// Quick share sheet for creating and sharing portal links from project detail (D-25).
/// Creates a portal link, copies to clipboard, and presents the system share sheet.
struct PortalShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Optional project ID — if provided, skips the project selector
    var projectId: String?

    // MARK: - State

    @State private var selectedProjectId: String = ""
    @State private var projects: [SupabaseProject] = []
    @State private var selectedTemplate = "full_progress"
    @State private var selectedExpiry: Int? = 30
    @State private var clientEmail = ""
    @State private var isCreating = false
    @State private var createdURL: String?
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private let supabase = SupabaseService.shared

    private let templates: [(id: String, label: String, icon: String)] = [
        ("executive_summary", "Executive Summary", "doc.plaintext"),
        ("full_progress", "Full Progress", "chart.bar.doc.horizontal"),
        ("photo_update", "Photo Update", "camera.fill"),
    ]

    private let expiryOptions: [(label: String, days: Int?)] = [
        ("7 days", 7),
        ("30 days", 30),
        ("90 days", 90),
        ("Never", nil),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Project selector (if not in project context)
                    if projectId == nil {
                        projectSelector
                    }

                    // Template picker
                    templatePicker

                    // Quick expiry selector
                    expiryPicker

                    // Client email (optional, D-09)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Client Email (optional)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.text)
                        Text("Receive notifications when they view the portal")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                        TextField("client@example.com", text: $clientEmail)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 14))
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Error display
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 4)
                    }

                    // Create & Share button
                    createButton
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Share Portal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.muted)
                }
            }
            .alert("Portal link copied to clipboard!", isPresented: $showSuccessAlert) {
                Button("Share") {
                    if let url = createdURL {
                        presentShareSheet(url: url)
                    }
                }
                Button("Done") { dismiss() }
            } message: {
                if let url = createdURL {
                    Text(url)
                }
            }
            .task { await loadProjects() }
        }
    }

    // MARK: - Sub-views

    private var projectSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Select Project")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            if projects.isEmpty {
                Text("Loading projects...")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
            } else {
                Picker("Project", selection: $selectedProjectId) {
                    Text("Choose a project...").tag("")
                    ForEach(projects) { project in
                        Text(project.name)
                            .tag(project.id ?? "")
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Portal Template")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            ForEach(templates, id: \.id) { template in
                Button {
                    selectedTemplate = template.id
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: template.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(selectedTemplate == template.id ? Theme.accent : Theme.muted)
                            .frame(width: 24)
                        Text(template.label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        if selectedTemplate == template.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(12)
                    .background(selectedTemplate == template.id ? Theme.accent.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var expiryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Link Expiry")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            HStack(spacing: 8) {
                ForEach(expiryOptions, id: \.label) { option in
                    Button {
                        selectedExpiry = option.days
                    } label: {
                        Text(option.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selectedExpiry == option.days ? .white : Theme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedExpiry == option.days ? Theme.accent : Theme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var createButton: some View {
        Button {
            Task { await createAndShare() }
        } label: {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                }
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.white)
                Text(isCreating ? "Creating..." : "Create & Share")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canCreate ? Theme.accent : Theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!canCreate || isCreating)
    }

    private var canCreate: Bool {
        let pid = projectId ?? selectedProjectId
        return !pid.isEmpty
    }

    // MARK: - Data Operations

    private func loadProjects() async {
        // Set initial project ID if provided
        if let pid = projectId {
            selectedProjectId = pid
        }
        // Load projects for selector
        do {
            projects = try await supabase.fetch("cs_projects")
        } catch {
            print("[PortalShareSheet] Failed to load projects: \(error.localizedDescription)")
        }
    }

    private func createAndShare() async {
        let pid = projectId ?? selectedProjectId
        guard !pid.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        do {
            // Generate a URL-friendly slug from project
            let project = projects.first { $0.id == pid }
            let slugBase = (project?.name ?? "project")
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            let slug = "\(slugBase)-\(String(UUID().uuidString.prefix(6)).lowercased())"
            let companySlug = supabase.currentOrgId
                .lowercased()
                .prefix(12)
                .filter { $0.isLetter || $0.isNumber || $0 == "-" }

            let result = try await supabase.createPortalLink(
                projectId: pid,
                slug: slug,
                companySlug: String(companySlug),
                template: selectedTemplate,
                expiryDays: selectedExpiry,
                clientEmail: clientEmail.isEmpty ? nil : clientEmail
            )

            let url = "https://app.constructionos.com/portal/\(companySlug)/\(slug)"
            createdURL = url

            // Copy to clipboard
            UIPasteboard.general.string = url

            showSuccessAlert = true
            print("[PortalShareSheet] Created portal link: \(url) (token: \(result.link.token))")
        } catch {
            errorMessage = "Failed to create portal: \(error.localizedDescription)"
            print("[PortalShareSheet] Create failed: \(error.localizedDescription)")
        }

        isCreating = false
    }

    // MARK: - System Share Sheet

    private func presentShareSheet(url: String) {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootController = windowScene.windows.first?.rootViewController else {
            return
        }
        let activityVC = UIActivityViewController(
            activityItems: [URL(string: url) ?? url],
            applicationActivities: nil
        )
        // Find the topmost presented controller
        var topController = rootController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        topController.present(activityVC, animated: true)
        #endif
    }
}
