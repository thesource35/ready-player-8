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

// MARK: - Phase 30 project-filter persistence (D-10 / D-11)
//
// Regression coverage for commit f0fb701 — project-filter picker state.
// Impl lives in NotificationsStore.{projectFilter, memberships, setFilter,
// loadMemberships, lastFilterKey}. These tests lock:
//   - setFilter(…) round-trips through UserDefaults under the canonical
//     ConstructOS.Notifications.LastFilterProjectId key (D-10)
//   - start(userId:) rehydrates a valid persisted id (D-10)
//   - start(userId:) silently wipes a stale persisted id that doesn't
//     resolve to a current membership, resetting projectFilter to nil (D-11)
// Tests run in mock-mode (SupabaseService not configured); memberships are
// sourced from SupabaseService.mockMemberships which includes "mock-project-1"
// and "mock-project-2".

@MainActor
@Suite("Phase 30 project-filter persistence")
struct NotificationsStore_Phase30_FilterTests {
    init() {
        // Isolate each test from UserDefaults state bleeding across runs.
        UserDefaults.standard.removeObject(forKey: NotificationsStore.lastFilterKey)
    }

    @Test func staleFilterRecovery() async {
        // Persist an id the user is NOT a member of; start() must silently
        // wipe it and leave projectFilter nil (D-11).
        UserDefaults.standard.set("ghost-project-id", forKey: NotificationsStore.lastFilterKey)
        let store = NotificationsStore()
        await store.start(userId: nil)
        #expect(store.projectFilter == nil)
        #expect(UserDefaults.standard.string(forKey: NotificationsStore.lastFilterKey) == nil)
    }

    @Test func persistedFilterRehydrates() async {
        // A valid membership id must be rehydrated on start() (D-10).
        // "mock-project-1" is the first row in SupabaseService.mockMemberships.
        UserDefaults.standard.set("mock-project-1", forKey: NotificationsStore.lastFilterKey)
        let store = NotificationsStore()
        await store.start(userId: nil)
        #expect(store.projectFilter == "mock-project-1")
    }

    @Test func setFilterWritesUserDefaults() async {
        let store = NotificationsStore()
        await store.start(userId: nil)
        await store.setFilter("mock-project-2")
        #expect(UserDefaults.standard.string(forKey: NotificationsStore.lastFilterKey) == "mock-project-2")
        await store.setFilter(nil)
        #expect(UserDefaults.standard.string(forKey: NotificationsStore.lastFilterKey) == nil)
    }

    @Test func loadMembershipsSeedsMockRowsInMockMode() async {
        // Mock-mode must always populate memberships so the picker has content
        // even without a configured backend.
        let store = NotificationsStore()
        await store.loadMemberships(userId: nil)
        #expect(store.memberships.count == SupabaseService.mockMemberships.count)
        #expect(store.memberships.contains(where: { $0.projectId == "mock-project-1" }))
    }
}
