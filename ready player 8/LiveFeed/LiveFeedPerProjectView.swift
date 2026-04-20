// Phase 29 — Per-project Live Feed view (real body, Wave 3).
//
// Owned by 29-06 (video, scrubber, library, upload, D-20 auto-advance).
// 29-07 fills suggestionsPlaceholder + trafficPlaceholder.
// UI-SPEC §Per-project Live Feed (iOS portrait) line 236-255 drives the layout.
//
// LIVE-02 parity: the video surface is Phase 22's VideoClipPlayer(asset:) —
// unchanged from Phase 22. Drone-typed assets flow through verbatim; nothing
// about the player itself changed in Phase 29.
//
// D-20 30s auto-advance: when a new clip lands and the user hasn't scrubbed
// in the prior 30 seconds, we switch `selectedAssetId` to the newest clip.
// If they HAVE scrubbed recently, we silently defer the swap — UI-SPEC line
// 341 says show a toast, but the toast UI lives in 29-07's notification
// chrome. We honor the guard here; the toast surface lands with 29-07.

import SwiftUI

struct LiveFeedPerProjectView: View {
    let projectId: String

    @StateObject private var store: DroneAssetsStore
    @State private var selectedAssetId: String?
    @State private var showLibrary: Bool = false
    @State private var showUpload: Bool = false

    @EnvironmentObject private var supabase: SupabaseService

    init(projectId: String) {
        self.projectId = projectId
        self._store = StateObject(wrappedValue: DroneAssetsStore(projectId: projectId))
    }

    private var lastScrubKey: String {
        LiveFeedStorageKey.lastScrubTimestamp(projectId: projectId)
    }

    var body: some View {
        if projectId.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 16) {
                videoPlayer

                DroneScrubberTimeline(
                    clips: store.within24h,
                    selectedAssetId: $selectedAssetId,
                    onScrub: { markUserScrubbed() },
                    onUploadTap: { showUpload = true }
                )

                suggestionsPlaceholder
                trafficPlaceholder

                HStack(spacing: 12) {
                    Button(action: { showLibrary = true }) {
                        Text("Library")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.surface)
                            .foregroundColor(Theme.text)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: { showUpload = true }) {
                        Text("Upload Drone Clip")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.accent)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                if let err = store.error {
                    Text(err.errorDescription ?? "Couldn't load drone clips.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.red)
                        .padding(.horizontal, 4)
                }
            }
            .task(id: projectId) {
                await store.refresh()
                advanceIfAllowed()
            }
            .onChange(of: store.within24h) { _, _ in
                advanceIfAllowed()
            }
            .sheet(isPresented: $showLibrary) {
                ProjectDroneLibrarySheet(
                    clips: store.olderThan24h,
                    isPresented: $showLibrary,
                    selectedAssetId: $selectedAssetId
                )
            }
            .sheet(isPresented: $showUpload) {
                DroneUploadSheet(
                    projectId: projectId,
                    orgId: supabase.currentOrgId,
                    sessionToken: supabase.accessToken ?? "",
                    apiBaseURL: URL(string: supabase.baseURL) ?? URL(string: "https://example.com")!,
                    isPresented: $showUpload,
                    onUploadComplete: { _ in
                        Task { await store.refresh() }
                    }
                )
            }
        }
    }

    // MARK: - Placeholders filled by 29-07

    private var suggestionsPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.surface)
            .frame(height: 140)
            .overlay(
                Text("Suggestion cards — 29-07")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 12))
            )
    }

    private var trafficPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.surface)
            .frame(height: 120)
            .overlay(
                Text("Traffic — 29-07")
                    .foregroundColor(Theme.muted)
                    .font(.system(size: 12))
            )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Projects")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Theme.text)
            Text("You don't have access to any projects yet. Contact your admin to be added.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Video player (LIVE-02 parity — Phase 22 component unchanged)

    @ViewBuilder
    private var videoPlayer: some View {
        if let id = selectedAssetId,
           let asset = firstAsset(id: id) {
            VideoClipPlayer(asset: asset)
                .frame(height: 220)
                .cornerRadius(14)
                .clipped()
        } else if let first = store.within24h.first {
            VideoClipPlayer(asset: first)
                .frame(height: 220)
                .cornerRadius(14)
                .clipped()
                .onAppear { selectedAssetId = first.id.uuidString }
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .frame(height: 220)
                .overlay(
                    VStack(spacing: 8) {
                        Text("No Drone Clips Yet")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Theme.text)
                        Text("Upload a drone clip to start analyzing site activity.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                )
        }
    }

    private func firstAsset(id: String) -> VideoAsset? {
        if let hit = store.within24h.first(where: { $0.id.uuidString == id }) {
            return hit
        }
        return store.olderThan24h.first(where: { $0.id.uuidString == id })
    }

    // MARK: - D-20 auto-advance 30s guard

    /// Seconds elapsed since the user last touched the scrubber.
    /// `.greatestFiniteMagnitude` when they have never scrubbed — treated as
    /// "old enough to auto-advance" so the first incoming clip on a fresh
    /// session does bring the user to the freshest footage.
    private func secondsSinceLastScrub() -> TimeInterval {
        let stored = UserDefaults.standard.string(forKey: lastScrubKey) ?? ""
        guard let d = ISO8601DateFormatter().date(from: stored) else {
            return .greatestFiniteMagnitude
        }
        return Date().timeIntervalSince(d)
    }

    private func markUserScrubbed() {
        let ts = ISO8601DateFormatter().string(from: Date())
        UserDefaults.standard.set(ts, forKey: lastScrubKey)
    }

    /// D-20: if a newer clip appeared AND user hasn't scrubbed in the prior
    /// 30 seconds, auto-advance. Otherwise defer silently (UI-SPEC line 341
    /// specifies a toast surface — that toast lives in 29-07's chrome and
    /// is intentionally out of scope for 29-06).
    private func advanceIfAllowed() {
        guard let newest = store.within24h.first else { return }
        guard selectedAssetId != newest.id.uuidString else { return }
        guard secondsSinceLastScrub() > 30 else {
            // User scrubbed recently — do NOT clobber their view.
            return
        }
        selectedAssetId = newest.id.uuidString
    }
}
