//
//  NotificationsStoreTests.swift
//  Phase 14 — Notifications & Activity Feed
//

import Testing
import Foundation
@testable import ready_player_8

@MainActor
struct NotificationsStoreTests {

    // MARK: - displayBadge cap (D-13)

    @Test func badgeIsEmptyForZero() {
        #expect(NotificationsStore.formatBadge(0) == "")
    }

    @Test func badgeIsEmptyForNegative() {
        #expect(NotificationsStore.formatBadge(-1) == "")
    }

    @Test func badgeIsRawNumberForOneToNinetyNine() {
        #expect(NotificationsStore.formatBadge(1) == "1")
        #expect(NotificationsStore.formatBadge(42) == "42")
        #expect(NotificationsStore.formatBadge(99) == "99")
    }

    @Test func badgeIsCappedAt99PlusForOver99() {
        #expect(NotificationsStore.formatBadge(100) == "99+")
        #expect(NotificationsStore.formatBadge(500) == "99+")
        #expect(NotificationsStore.formatBadge(99_999) == "99+")
    }

    // MARK: - Mock data invariants

    @Test func mockDataIncludesAtLeastOneUnread() {
        let unread = NotificationsStore.mockNotifications.filter { $0.isUnread }
        #expect(unread.count >= 1)
    }

    @Test func mockDataCategoriesAreValid() {
        let valid: Set<String> = ["bid_deadline", "safety_alert", "assigned_task", "generic"]
        for n in NotificationsStore.mockNotifications {
            #expect(valid.contains(n.category))
        }
    }

    // MARK: - Mock-mode lifecycle (no Supabase, no userId)

    @Test func startWithoutUserSeedsMockData() async {
        let store = await NotificationsStore()
        await store.start(userId: nil)
        let count = await store.notifications.count
        #expect(count == NotificationsStore.mockNotifications.count)
    }

    @Test func displayBadgeReflectsMockUnreadCount() async {
        let store = await NotificationsStore()
        await store.start(userId: nil)
        // Two of the three mock rows are unread (the third has readAt set)
        let badge = await store.displayBadge
        #expect(badge == "2")
    }

    // MARK: - SupabaseNotification.isUnread

    @Test func notificationIsUnreadWhenBothFieldsNil() {
        let n = SupabaseNotification(
            id: "x", userId: "u", eventId: nil, projectId: nil,
            category: "generic", title: "t", body: nil,
            entityType: nil, entityId: nil,
            readAt: nil, dismissedAt: nil, createdAt: nil
        )
        #expect(n.isUnread == true)
    }

    @Test func notificationIsReadWhenReadAtSet() {
        let n = SupabaseNotification(
            id: "x", userId: "u", eventId: nil, projectId: nil,
            category: "generic", title: "t", body: nil,
            entityType: nil, entityId: nil,
            readAt: "2026-04-07T00:00:00Z", dismissedAt: nil, createdAt: nil
        )
        #expect(n.isUnread == false)
    }

    @Test func notificationIsReadWhenDismissed() {
        let n = SupabaseNotification(
            id: "x", userId: "u", eventId: nil, projectId: nil,
            category: "generic", title: "t", body: nil,
            entityType: nil, entityId: nil,
            readAt: nil, dismissedAt: "2026-04-07T00:00:00Z", createdAt: nil
        )
        #expect(n.isUnread == false)
    }
}
