// Phase 22: Observable video list manager, Phase 13/21 pattern (DataSyncManager cousin).
//
// Caches per-project VideoSource and VideoAsset arrays in UserDefaults (stale-while-revalidate).
// UI observes @Published sourcesByProject / assetsByProject dictionaries keyed by project UUID.
// D-28 soft-cap helper (20 cameras/org, warn at 16) lives here so Cameras UI can render banner state.

import Foundation
import Combine

@MainActor
final class VideoSyncManager: ObservableObject {
    static let shared = VideoSyncManager()

    @Published var sourcesByProject: [UUID: [VideoSource]] = [:]
    @Published var assetsByProject: [UUID: [VideoAsset]] = [:]
    @Published var syncingProjects: Set<UUID> = []

    private let userDefaults = UserDefaults.standard
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    // MARK: - Cache key helpers (D-26 namespace)

    private func sourcesCacheKey(_ projectId: UUID) -> String {
        "ConstructOS.Video.SourcesCache.\(projectId.uuidString)"
    }

    private func assetsCacheKey(_ projectId: UUID) -> String {
        "ConstructOS.Video.AssetsCache.\(projectId.uuidString)"
    }

    // MARK: - Sync

    /// Load cached values first (instant UI), then refresh from Supabase.
    /// Does NOT throw — errors are logged and stale cache remains visible (Phase 13 pattern).
    func syncProject(_ projectId: UUID, service: SupabaseService) async {
        // 1. Load cache immediately so UI paints with stale-but-shown data
        if let data = userDefaults.data(forKey: sourcesCacheKey(projectId)),
           let cached = try? decoder.decode([VideoSource].self, from: data) {
            sourcesByProject[projectId] = cached
        }
        if let data = userDefaults.data(forKey: assetsCacheKey(projectId)),
           let cached = try? decoder.decode([VideoAsset].self, from: data) {
            assetsByProject[projectId] = cached
        }

        // 2. Kick remote refresh
        syncingProjects.insert(projectId)
        defer { syncingProjects.remove(projectId) }

        do {
            async let remoteSources = service.fetchVideoSources(projectId: projectId)
            async let remoteAssets = service.fetchVideoAssets(projectId: projectId, kind: nil)
            let (sources, assets) = try await (remoteSources, remoteAssets)
            sourcesByProject[projectId] = sources
            assetsByProject[projectId] = assets
            if let data = try? encoder.encode(sources) {
                userDefaults.set(data, forKey: sourcesCacheKey(projectId))
            }
            if let data = try? encoder.encode(assets) {
                userDefaults.set(data, forKey: assetsCacheKey(projectId))
            }
        } catch {
            print("[VideoSync] sync failed for project \(projectId): \(error)")
            CrashReporter.shared.reportError("VideoSyncManager.syncProject(\(projectId.uuidString)): \(error.localizedDescription)")
        }
    }

    // MARK: - Optimistic mutations (UI echoes before server round-trip)

    /// Optimistically insert/replace a source in-memory; next sync reconciles.
    func upsertSource(_ src: VideoSource) {
        var list = sourcesByProject[src.projectId] ?? []
        list.removeAll { $0.id == src.id }
        list.insert(src, at: 0)
        sourcesByProject[src.projectId] = list
    }

    /// Optimistically insert/replace an asset in-memory; next sync reconciles.
    func upsertAsset(_ asset: VideoAsset) {
        var list = assetsByProject[asset.projectId] ?? []
        list.removeAll { $0.id == asset.id }
        list.insert(asset, at: 0)
        assetsByProject[asset.projectId] = list
    }

    /// Remove a source from the local list (UI echoes the delete before server confirms).
    func removeSource(id: UUID, from projectId: UUID) {
        var list = sourcesByProject[projectId] ?? []
        list.removeAll { $0.id == id }
        sourcesByProject[projectId] = list
    }

    /// Remove an asset from the local list.
    func removeAsset(id: UUID, from projectId: UUID) {
        var list = assetsByProject[projectId] ?? []
        list.removeAll { $0.id == id }
        assetsByProject[projectId] = list
    }

    // MARK: - Camera soft cap (D-28)

    /// Returns flags for the Cameras section banner. `atCap` shows "limit reached";
    /// `nearCap` shows yellow "approaching limit" warning at 16 of 20.
    nonisolated func softCapStatus(forOrgCameras count: Int) -> (atCap: Bool, nearCap: Bool) {
        (atCap: count >= 20, nearCap: count >= 16)
    }
}
