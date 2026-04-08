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

    // MARK: Internals
    private var pollTask: Task<Void, Never>?
    private var currentUserId: String?
    private var projectFilter: String?
    private let pollInterval: TimeInterval = 20

    // MARK: Lifecycle

    /// Begin polling for the given user. If `userId` is nil OR Supabase is not
    /// configured, the store serves mock data and skips network calls.
    func start(userId: String?, projectId: String? = nil) async {
        stop()
        self.currentUserId = userId
        self.projectFilter = projectId

        guard SupabaseService.shared.isConfigured, let uid = userId else {
            applyMockData()
            return
        }

        await refresh()

        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pollInterval * 1_000_000_000))
                if Task.isCancelled { return }
                await self.refresh()
            }
            _ = uid // silence unused warning when polling never runs
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
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
