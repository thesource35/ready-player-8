// Phase 29 LIVE-12 — Drone-asset queries split into 24h (scrubber) vs older (library).
//
// Reuses Phase 22's VideoAsset model. All reads via authenticated
// SupabaseService.shared (T-29-RLS-CLIENT mitigation — never service-role; RLS
// enforces org_id scope automatically).
//
// Partition rule (D-09 / LIVE-12):
//   within24h   = source_type='drone' AND created_at >  now() - interval '24h'
//   olderThan24h = source_type='drone' AND created_at <= now() - interval '24h'
// Phase 22's 30-day retention cron handles the upper bound, so we don't add one here.

import Foundation
import Combine

@MainActor
final class DroneAssetsStore: ObservableObject {

    // MARK: - Published state

    /// Clips within the last 24 hours — shown in `DroneScrubberTimeline`.
    @Published private(set) var within24h: [VideoAsset] = []

    /// Clips older than 24 hours (up to Phase 22's 30d retention ceiling) —
    /// shown in `ProjectDroneLibrarySheet`.
    @Published private(set) var olderThan24h: [VideoAsset] = []

    @Published private(set) var loading: Bool = false
    @Published private(set) var error: AppError?

    // MARK: - Config

    private let projectId: String

    init(projectId: String) {
        self.projectId = projectId
    }

    // MARK: - API

    /// Fetch drone clips for this project, ready-only, newest first, then
    /// partition by the 24-hour cutoff client-side.
    ///
    /// The query runs through the generic `SupabaseService.fetch` with
    /// PostgREST `eq.` filters — the same idiom Phase 22's VideoSyncManager
    /// uses (no new network layer, no service-role credential).
    func refresh() async {
        guard !projectId.isEmpty else { return }
        loading = true
        defer { loading = false }

        let cutoff24h = Date().addingTimeInterval(-24 * 60 * 60)

        do {
            let all: [VideoAsset] = try await SupabaseService.shared.fetch(
                "cs_video_assets",
                query: [
                    "project_id":  "eq.\(projectId)",
                    "source_type": "eq.drone",
                    "status":      "eq.ready"
                ],
                orderBy: "created_at",
                ascending: false
            )

            var recent: [VideoAsset] = []
            var older: [VideoAsset] = []
            for asset in all {
                if asset.createdAt > cutoff24h {
                    recent.append(asset)
                } else {
                    older.append(asset)
                }
            }
            within24h = recent
            olderThan24h = older
            error = nil
        } catch let e as AppError {
            error = e
        } catch let e as SupabaseError {
            // Map SupabaseError to AppError so views have a single surface.
            switch e {
            case .notConfigured:
                error = .supabaseNotConfigured
            case .httpError(let code, let body):
                error = .supabaseHTTP(statusCode: code, body: body)
            case .decodingError(let underlying):
                error = .decoding(underlying: underlying)
            case .encodingError(let underlying):
                error = .encoding(underlying: underlying)
            }
        } catch {
            self.error = AppError.unknown(error.localizedDescription)
        }
    }

    /// Append a single asset optimistically after a successful upload so the
    /// scrubber shows it immediately without waiting for the next `refresh()`.
    /// Duplicates (same id) are de-duped; order is newest-first.
    func optimisticInsert(_ asset: VideoAsset) {
        guard asset.sourceType == .drone else { return }
        let cutoff24h = Date().addingTimeInterval(-24 * 60 * 60)
        if asset.createdAt > cutoff24h {
            var list = within24h
            list.removeAll { $0.id == asset.id }
            list.insert(asset, at: 0)
            within24h = list
        } else {
            var list = olderThan24h
            list.removeAll { $0.id == asset.id }
            list.insert(asset, at: 0)
            olderThan24h = list
        }
    }
}
