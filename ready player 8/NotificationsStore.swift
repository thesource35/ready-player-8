// Phase 14 — NotificationsStore
//
// Owns the iOS notifications list + unread count. Polls every 20 seconds while
// active. (The existing app uses a homegrown WebSocket Realtime path tied to
// specific tables; rather than entangle that, we poll — same UX, simpler.)
//
// Mock fallback: when SupabaseService is not configured OR no user is signed
// in, the store serves a tiny set of demo notifications so screenshots and
// dev builds always show something useful.

import Foundation
import SwiftUI
import Combine

@MainActor
final class NotificationsStore: ObservableObject {

    // MARK: Published state
    @Published private(set) var notifications: [SupabaseNotification] = []
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?

    // Phase 30 — D-05/D-08/D-10: UI-observable filter state + membership list powering
    // the InboxView toolbar Menu picker. Widened from `private var` for @ObservedObject binding.
    @Published private(set) var projectFilter: String?
    @Published private(set) var memberships: [ProjectMembershipUnread] = []

    // Phase 30 — D-10: AppStorage key for persistent project filter. Namespace matches
    // the existing ConstructOS.Notifications.* keys from Phase 14.
    static let lastFilterKey = "ConstructOS.Notifications.LastFilterProjectId"

    // MARK: Internals
    private var pollTask: Task<Void, Never>?
    private var currentUserId: String?
    private let pollInterval: TimeInterval = 20

    // Phase 30 D-16 — Realtime handle + polling-fallback flag.
    // `realtimeHandle` is nil in mock mode, or when Realtime permanently fails and
    // the store has downgraded to polling. `usingFallbackPolling` guards against
    // starting the 20s poll loop twice.
    private var realtimeHandle: NotificationsRealtimeHandle?
    private var usingFallbackPolling = false

    // MARK: Lifecycle

    /// Begin observing notifications for the given user. Prefers Supabase Realtime
    /// (postgres_changes on cs_notifications, filter user_id=eq.{uid}) and only
    /// falls back to 20-second polling after 3 consecutive WebSocket failures.
    /// If `userId` is nil OR Supabase is not configured, the store serves mock
    /// data and skips network calls.
    func start(userId: String?, projectId: String? = nil) async {
        stop()
        self.currentUserId = userId

        // Phase 30 — D-10/D-11: rehydrate persisted filter and silently recover
        // from stale ids (project the user is no longer a member of).
        let persisted = UserDefaults.standard.string(forKey: Self.lastFilterKey)
        await loadMemberships(userId: userId)
        let validIds = Set(memberships.map(\.projectId))
        if let p = persisted, validIds.contains(p) {
            self.projectFilter = p
        } else {
            if persisted != nil {
                UserDefaults.standard.removeObject(forKey: Self.lastFilterKey)
            }
            self.projectFilter = nil
        }
        // Explicit caller arg still wins over rehydrated state — route through setFilter
        // so persistence stays consistent with direct UI selections (preserves Phase 14 behavior).
        if let projectId {
            await setFilter(projectId)
        }

        guard SupabaseService.shared.isConfigured, let uid = userId else {
            applyMockData()
            return
        }

        await refresh()

        // D-16: prefer Realtime; only fall back to 20s polling if Realtime permanently fails.
        // Matches web HeaderBell.tsx subscribe-and-refresh semantics byte-for-byte.
        let handle = SupabaseService.shared.subscribeToNotifications(
            userId: uid,
            onChange: { [weak self] in
                Task { @MainActor [weak self] in await self?.refresh() }
            },
            onPermanentFailure: { [weak self] in
                Task { @MainActor [weak self] in self?.startPollingFallback(uid: uid) }
            }
        )

        if let handle {
            self.realtimeHandle = handle
        } else {
            // Realtime unavailable (e.g. baseURL/apiKey missing) — start polling directly.
            startPollingFallback(uid: uid)
        }
    }

    func stop() {
        realtimeHandle?.cancel()
        realtimeHandle = nil
        pollTask?.cancel()
        pollTask = nil
        usingFallbackPolling = false
    }

    /// Polling fallback used when Realtime is unavailable or has failed
    /// permanently (3 consecutive WebSocket errors). Preserves the Phase-14
    /// UX — the list stays eventually-consistent with a 20s cadence — so
    /// users on flaky WiFi still see new notifications without manual refresh.
    private func startPollingFallback(uid: String) {
        guard !usingFallbackPolling else { return }
        usingFallbackPolling = true
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pollInterval * 1_000_000_000))
                if Task.isCancelled { return }
                await self.refresh()
            }
            _ = uid
        }
    }

    // Swift 6 strict-concurrency note: `NotificationsRealtimeHandle.cancel()` is declared
    // `nonisolated` in SupabaseService.swift (Phase 30 Task 1). That is the ONLY reason the
    // following deinit compiles on a @MainActor class. If cancel() is ever moved back to
    // MainActor, this deinit MUST switch to the `Task.detached { [handle] in handle?.cancel() }`
    // pattern — otherwise the Swift-6 compiler will reject the call from deinit.
    deinit {
        realtimeHandle?.cancel()  // nonisolated — safe from @MainActor deinit
        pollTask?.cancel()        // Task.cancel() is Sendable + nonisolated by design
    }

    /// Manual refresh (called by pull-to-refresh + on-resume).
    func refresh() async {
        guard SupabaseService.shared.isConfigured, let uid = currentUserId else {
            applyMockData()
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            async let listTask = SupabaseService.shared.fetchNotifications(
                userId: uid, projectId: projectFilter, limit: 50
            )
            async let countTask = SupabaseService.shared.fetchUnreadCount(
                userId: uid, projectId: projectFilter
            )
            let (list, count) = try await (listTask, countTask)
            self.notifications = list
            self.unreadCount = count
            self.lastError = nil
        } catch {
            self.lastError = (error as? AppError)?.localizedDescription ?? "Failed to load notifications"
        }
    }

    // MARK: Phase 30 — project-filter management (D-05/D-10/D-11)

    /// Persist and apply a filter selection. Pass nil to clear filter.
    /// Triggers a refresh so the list reflects the new filter immediately.
    /// Phase 30 D-17: emits the filter-changed analytics event at the END of
    /// the method, diff-gated so set-to-same-value is a no-op for analytics
    /// and so hydration paths (which write `self.projectFilter` directly on
    /// launch) cannot fire the event.
    func setFilter(_ projectId: String?) async {
        // D-17: capture prior value BEFORE mutation so analytics sees the diff.
        let prev = self.projectFilter
        self.projectFilter = projectId
        if let pid = projectId {
            UserDefaults.standard.set(pid, forKey: Self.lastFilterKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.lastFilterKey)
        }
        await refresh()

        // D-17: emit ONLY on actual change. Hydration paths set
        // `self.projectFilter` directly (see start(userId:) rehydrate block) so
        // no event fires on app launch. Set-to-same-value is also a no-op.
        if prev != projectId {
            emitFilterChangedAnalytics(from: prev, to: projectId)
        }
    }

    /// D-17: PII-free analytics emit helper for the filter-changed event.
    /// Payload keys are EXACTLY ["from_project_id", "to_project_id", "unread_count_at_change"].
    /// `nil` from/to serialize to the literal "all" sentinel (matches web emitter).
    /// `unread_count_at_change` is captured AFTER refresh() so it reflects the
    /// post-change unread count. AnalyticsEngine.shared.track accepts
    /// [String: String] only, so the Int count is serialized as its String form
    /// — downstream consumers (Vercel/analytics dashboards) parse the numeric.
    private func emitFilterChangedAnalytics(from: String?, to: String?) {
        let payload: [String: String] = [
            "from_project_id": from ?? "all",
            "to_project_id": to ?? "all",
            "unread_count_at_change": String(max(0, self.unreadCount)),
        ]
        AnalyticsEngine.shared.track("inbox_filter_changed", properties: payload)
    }

    /// Reload the user's project memberships + per-project unread chips.
    /// Mock fallback preserves UI previews when Supabase is not configured.
    func loadMemberships(userId: String?) async {
        guard SupabaseService.shared.isConfigured, let uid = userId else {
            memberships = SupabaseService.mockMemberships
            return
        }
        do {
            memberships = try await SupabaseService.shared.fetchProjectMembershipsWithUnread(userId: uid)
        } catch {
            memberships = []
        }
    }

    // MARK: Mutations (optimistic — local state changes first, network in background)

    func markRead(_ id: String) async {
        if let idx = notifications.firstIndex(where: { $0.id == id }), notifications[idx].readAt == nil {
            notifications[idx].readAt = Self.nowISO8601()
            recomputeUnread()
        }
        guard SupabaseService.shared.isConfigured else { return }
        do { try await SupabaseService.shared.markNotificationRead(id: id) }
        catch { self.lastError = (error as? AppError)?.localizedDescription ?? "Mark-read failed" }
    }

    func markDismissed(_ id: String) async {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].dismissedAt = Self.nowISO8601()
            // Hide from the local list
            notifications.removeAll { $0.id == id }
            recomputeUnread()
        }
        guard SupabaseService.shared.isConfigured else { return }
        do { try await SupabaseService.shared.markNotificationDismissed(id: id) }
        catch { self.lastError = (error as? AppError)?.localizedDescription ?? "Dismiss failed" }
    }

    /// Mark every visible unread notification as read. Respects the current
    /// project filter (D-12).
    func markAllRead() async {
        let now = Self.nowISO8601()
        for i in notifications.indices where notifications[i].readAt == nil {
            notifications[i].readAt = now
        }
        unreadCount = 0
        guard SupabaseService.shared.isConfigured, let uid = currentUserId else { return }
        do { try await SupabaseService.shared.markAllNotificationsRead(userId: uid, projectId: projectFilter) }
        catch { self.lastError = (error as? AppError)?.localizedDescription ?? "Mark-all-read failed" }
    }

    // MARK: Display helpers

    /// Header bell badge text — capped at "99+" per D-13.
    var displayBadge: String {
        Self.formatBadge(unreadCount)
    }

    static func formatBadge(_ n: Int) -> String {
        if n <= 0 { return "" }
        if n > 99 { return "99+" }
        return String(n)
    }

    // MARK: Private

    private func recomputeUnread() {
        unreadCount = notifications.filter { $0.readAt == nil && $0.dismissedAt == nil }.count
    }

    private func applyMockData() {
        notifications = NotificationsStore.mockNotifications
        recomputeUnread()
    }

    private static func nowISO8601() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    // MARK: Mock data
    static let mockNotifications: [SupabaseNotification] = [
        SupabaseNotification(
            id: "mock-n-1",
            userId: "mock-user",
            eventId: "mock-e-1",
            projectId: "mock-project-1",
            category: "bid_deadline",
            title: "Bid deadline approaching",
            body: "contracts: Civic Center Phase 2 — due in 1 day",
            entityType: "cs_contracts",
            entityId: "mock-contract-1",
            readAt: nil,
            dismissedAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-2 * 3600))
        ),
        SupabaseNotification(
            id: "mock-n-2",
            userId: "mock-user",
            eventId: "mock-e-2",
            projectId: "mock-project-1",
            category: "safety_alert",
            title: "Safety alert",
            body: "safety_incidents: Near-miss reported on Level 4",
            entityType: "cs_safety_incidents",
            entityId: "mock-incident-1",
            readAt: nil,
            dismissedAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-5 * 3600))
        ),
        SupabaseNotification(
            id: "mock-n-3",
            userId: "mock-user",
            eventId: "mock-e-3",
            projectId: "mock-project-2",
            category: "assigned_task",
            title: "New assignment",
            body: "rfis: RFI-042 assigned to you",
            entityType: "cs_rfis",
            entityId: "mock-rfi-42",
            readAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-20 * 3600)),
            dismissedAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-28 * 3600))
        ),
    ]
}
