// Phase 22-08: Cameras section rendered inside ProjectDetail.
//
// Container that lists live cameras (CameraCard grid) and recent clips (ClipCard list),
// with soft-cap banner (D-28), empty states per UI-SPEC, and Add Camera / Upload Clip CTAs.
//
// Accepts projectId + orgId. Syncs via VideoSyncManager on appear.
// 24px outer padding, 32px section gap to sibling sections (UI-SPEC Spacing).

import SwiftUI

struct CamerasSection: View {
    let projectId: String
    let orgId: String

    @StateObject private var sync = VideoSyncManager.shared

    // Sheet states
    @State private var showAddCamera = false
    @State private var showUploadClip = false
    @State private var expandedSourceId: UUID?
    @State private var expandedAssetId: UUID?

    private var projectUUID: UUID? { UUID(uuidString: projectId) }
    private var orgUUID: UUID? { UUID(uuidString: orgId) }

    private var sources: [VideoSource] {
        guard let pid = projectUUID else { return [] }
        return (sync.sourcesByProject[pid] ?? [])
            .filter { $0.kind == .fixedCamera && $0.status != .archived }
    }

    private var assets: [VideoAsset] {
        guard let pid = projectUUID else { return [] }
        return (sync.assetsByProject[pid] ?? [])
            .filter { $0.kind == .vod }
            .sorted { $0.startedAt > $1.startedAt }
    }

    // D-28 soft cap (all fixed cameras in org, not just this project)
    private var fixedCameraCount: Int {
        let allSources: [VideoSource] = sync.sourcesByProject.values.flatMap { $0 }
        let fixedActive = allSources.filter { (src: VideoSource) -> Bool in
            src.kind == .fixedCamera && src.status != .archived && src.orgId == orgUUID
        }
        return fixedActive.count
    }

    private var softCap: (atCap: Bool, nearCap: Bool) {
        sync.softCapStatus(forOrgCameras: fixedCameraCount)
    }

    private var isSyncing: Bool {
        guard let pid = projectUUID else { return false }
        return sync.syncingProjects.contains(pid)
    }

    // Supabase configured?
    private var isConfigured: Bool { SupabaseService.shared.isConfigured }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Soft-cap banner (D-28)
            if softCap.atCap {
                softCapBanner(isLimitReached: true)
            } else if softCap.nearCap {
                softCapBanner(isLimitReached: false)
            }

            // Header
            HStack {
                Text("Cameras")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.text)
                Spacer()
                Button {
                    showUploadClip = true
                } label: {
                    Label("Upload clip", systemImage: "arrow.up.doc")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                }
                Button {
                    showAddCamera = true
                } label: {
                    Label("Add camera", systemImage: "video.badge.plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(softCap.atCap ? Theme.muted.opacity(0.3) : Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(softCap.atCap)
            }

            // Content
            if !isConfigured {
                // Preview mode (Supabase not configured)
                emptyState(
                    heading: "Preview mode",
                    body: "You're viewing a test stream. Configure your Supabase integration in Command \u{2192} Integrations to register real cameras."
                )
            } else if sources.isEmpty && assets.isEmpty {
                // No cameras + no clips
                emptyState(
                    heading: "No cameras yet",
                    body: "Register a jobsite camera to start streaming, or upload a recorded clip. Live streams use Mux; uploads transcode in the background."
                )
            } else {
                // Live Cameras subsection
                if sources.isEmpty {
                    emptyState(
                        heading: "No live cameras",
                        body: "You have \(assets.count) recorded clips below. Add a camera to watch the site in real time."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LIVE CAMERAS")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.muted)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(sources) { source in
                                if expandedSourceId == source.id {
                                    // Expanded: show live player
                                    VStack(spacing: 8) {
                                        LiveStreamView(source: source)
                                        Button("Close") { expandedSourceId = nil }
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.muted)
                                    }
                                } else {
                                    CameraCard(source: source) {
                                        expandedSourceId = source.id
                                    }
                                }
                            }
                        }
                    }
                }

                // Recent Clips subsection
                if assets.isEmpty && !sources.isEmpty {
                    emptyState(
                        heading: "No clips yet",
                        body: "Recorded clips from this project will appear here for 30 days. Upload a file or wait for a live session to archive."
                    )
                } else if !assets.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RECENT CLIPS")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.muted)

                        ForEach(assets) { asset in
                            if expandedAssetId == asset.id {
                                VStack(spacing: 8) {
                                    VideoClipPlayer(asset: asset)
                                    Button("Close") { expandedAssetId = nil }
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.muted)
                                }
                            } else {
                                ClipCard(
                                    asset: asset,
                                    canManage: true, // D-39: role check would be here in production
                                    onPlay: { expandedAssetId = asset.id },
                                    onRetry: {
                                        // TODO: Wire retry transcode API call
                                    },
                                    onTogglePortal: { visible in
                                        Task {
                                            try? await SupabaseService.shared.toggleAssetPortalVisible(
                                                assetId: asset.id,
                                                visible: visible
                                            )
                                            if let pid = projectUUID {
                                                await sync.syncProject(pid, service: SupabaseService.shared)
                                            }
                                        }
                                    },
                                    onDelete: {
                                        Task {
                                            try? await SupabaseService.shared.deleteVideoAsset(id: asset.id)
                                            sync.removeAsset(id: asset.id, from: asset.projectId)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }

            // Loading indicator
            if isSyncing {
                HStack {
                    ProgressView()
                        .tint(Theme.accent)
                    Text("Syncing cameras\u{2026}")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.muted)
                }
            }
        }
        .padding(24)
        .background(Theme.surface)
        .cornerRadius(14)
        .task {
            guard let pid = projectUUID else { return }
            await sync.syncProject(pid, service: SupabaseService.shared)
        }
        .sheet(isPresented: $showAddCamera) {
            AddCameraWizard(projectId: projectId, orgId: orgId) {
                // Re-sync after wizard completes
                Task {
                    if let pid = projectUUID {
                        await sync.syncProject(pid, service: SupabaseService.shared)
                    }
                }
            }
        }
        .sheet(isPresented: $showUploadClip) {
            ClipUploadSheet(projectId: projectId, orgId: orgId) {
                Task {
                    if let pid = projectUUID {
                        await sync.syncProject(pid, service: SupabaseService.shared)
                    }
                }
            }
        }
    }

    // MARK: - Sub-views

    private func emptyState(heading: String, body: String) -> some View {
        VStack(spacing: 8) {
            Text(heading)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.text)
            Text(body)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func softCapBanner(isLimitReached: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(isLimitReached ? Theme.red : Theme.gold)
            Text(isLimitReached
                 ? "Camera limit reached (20). Archive an unused camera or contact support to raise the cap."
                 : "\(fixedCameraCount) of 20 cameras used")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isLimitReached ? Theme.red : Theme.gold)
            Spacer()
            if isLimitReached {
                Button("Contact support") {
                    // Placeholder — would open support URL
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.accent)
            }
        }
        .padding(12)
        .background((isLimitReached ? Theme.red : Theme.gold).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
