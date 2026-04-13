import SwiftUI

// MARK: - ========== PortalManagementView.swift ==========

/// Bulk portal management screen listing all portal links grouped by project (D-25).
/// Supports swipe actions for copy URL, revoke, and delete.
struct PortalManagementView: View {
    @State private var portalLinks: [SupabasePortalConfig] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    @State private var showRevokeAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedConfig: SupabasePortalConfig?
    @State private var copiedLinkId: String?

    private let supabase = SupabaseService.shared

    // MARK: - Computed Properties

    /// Group portal links by project ID for section display
    private var groupedLinks: [(projectId: String, links: [SupabasePortalConfig])] {
        let grouped = Dictionary(grouping: portalLinks) { $0.projectId }
        return grouped.map { (projectId: $0.key, links: $0.value) }
            .sorted { $0.projectId < $1.projectId }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                header
                if isLoading {
                    loadingView
                } else if let err = errorMessage {
                    errorView(err)
                } else if portalLinks.isEmpty {
                    emptyView
                } else {
                    portalList
                }
            }
            .padding(16)
        }
        .refreshable { await loadPortalLinks() }
        .background(Theme.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            PortalShareSheet()
        }
        .alert("Revoke Link", isPresented: $showRevokeAlert, presenting: selectedConfig) { config in
            Button("Cancel", role: .cancel) { }
            Button("Revoke", role: .destructive) {
                Task { await revokeLink(config) }
            }
        } message: { _ in
            Text("This will immediately disable access for anyone with this link. This action cannot be undone.")
        }
        .alert("Delete Link", isPresented: $showDeleteAlert, presenting: selectedConfig) { config in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await deleteLink(config) }
            }
        } message: { _ in
            Text("This portal link will be permanently removed.")
        }
        .task { await loadPortalLinks() }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PORTAL LINKS")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.muted)
                Text("Client Portals")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Theme.text)
            }
            Spacer()
            Text("\(portalLinks.count)")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Theme.accent)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Theme.accent)
            Text("Loading portal links...")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.red)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadPortalLinks() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Theme.muted)
            Text("No portal links yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.text)
            Text("Share project progress with your clients.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
            Button {
                showShareSheet = true
            } label: {
                Text("Create Your First Portal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var portalList: some View {
        ForEach(groupedLinks, id: \.projectId) { group in
            Section {
                ForEach(group.links, id: \.linkId) { config in
                    NavigationLink {
                        PortalConfigView(config: config)
                    } label: {
                        portalRow(config)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            copyPortalURL(config)
                        } label: {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }
                        .tint(Theme.cyan)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedConfig = config
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            selectedConfig = config
                            showRevokeAlert = true
                        } label: {
                            Label("Revoke", systemImage: "xmark.shield")
                        }
                        .tint(Theme.red)
                    }
                }
            } header: {
                Text("Project: \(group.projectId)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 8)
            }
        }
    }

    private func portalRow(_ config: SupabasePortalConfig) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(config.slug)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Spacer()
                statusBadge(config)
            }
            HStack(spacing: 12) {
                Label(config.template.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "doc.text")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                if let created = config.createdAt {
                    Label(formatDate(created), systemImage: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                }
            }
            if copiedLinkId == config.linkId {
                Text("URL copied!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.green)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusBadge(_ config: SupabasePortalConfig) -> some View {
        let (color, label) = portalStatus(config)
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
        }
    }

    // MARK: - Status Logic (D-94)

    private func portalStatus(_ config: SupabasePortalConfig) -> (Color, String) {
        if config.isDeleted == true {
            return (Theme.red, "Deleted")
        }
        // Check if link is revoked by looking at local state
        // (In production, we'd join with shared links table)
        return (Theme.green, "Active")
    }

    // MARK: - Helpers

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }
        let display = DateFormatter()
        display.dateStyle = .medium
        return display.string(from: date)
    }

    private func copyPortalURL(_ config: SupabasePortalConfig) {
        let url = "https://app.constructionos.com/portal/\(config.companySlug)/\(config.slug)"
        UIPasteboard.general.string = url
        withAnimation {
            copiedLinkId = config.linkId
        }
        // Auto-clear copied indicator after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation { copiedLinkId = nil }
            }
        }
    }

    // MARK: - Data Operations

    private func loadPortalLinks() async {
        isLoading = true
        errorMessage = nil
        do {
            portalLinks = try await supabase.fetchPortalLinks()
        } catch {
            errorMessage = error.localizedDescription
            print("[PortalManagement] Failed to load links: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func revokeLink(_ config: SupabasePortalConfig) async {
        do {
            try await supabase.revokePortalLink(linkId: config.linkId)
            await loadPortalLinks() // Refresh list
        } catch {
            errorMessage = "Failed to revoke: \(error.localizedDescription)"
            print("[PortalManagement] Revoke failed: \(error.localizedDescription)")
        }
    }

    private func deleteLink(_ config: SupabasePortalConfig) async {
        guard let configId = config.id else { return }
        do {
            // Soft delete: mark is_deleted = true (D-116)
            var updated = config
            updated.isDeleted = true
            try await supabase.update("cs_portal_config", id: configId, record: updated)
            await loadPortalLinks() // Refresh list
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            print("[PortalManagement] Delete failed: \(error.localizedDescription)")
        }
    }
}
