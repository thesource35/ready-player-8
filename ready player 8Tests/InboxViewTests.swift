//
//  InboxViewTests.swift
//  Phase 14 — Notifications & Activity Feed
//
//  InboxView is a SwiftUI view; we don't render it. These tests cover the
//  helper logic the view depends on so future refactors can't silently break
//  the icon mapping or relative-time formatting.
//

import Testing
import Foundation
@testable import ready_player_8

struct InboxViewHelperTests {

    // MARK: - Category icon mapping

    @Test func categoryIconMappingCoversD16PushSet() {
        // These are the three categories that produce APNs pushes (D-16),
        // each must have a distinct, unambiguous icon.
        #expect(NotificationRow.iconFor("bid_deadline") == "clock.fill")
        #expect(NotificationRow.iconFor("safety_alert") == "exclamationmark.triangle.fill")
        #expect(NotificationRow.iconFor("assigned_task") == "checkmark.circle.fill")
    }

    @Test func categoryIconMappingHandlesDocument() {
        #expect(NotificationRow.iconFor("document") == "doc.fill")
    }

    @Test func categoryIconMappingFallsBackToBell() {
        #expect(NotificationRow.iconFor("generic") == "bell.fill")
        #expect(NotificationRow.iconFor("totally-unknown-category") == "bell.fill")
    }

    // MARK: - Relative time formatting

    @Test func relativeTimeReturnsEmptyForNil() {
        #expect(NotificationRow.relativeTime(nil) == "")
    }

    @Test func relativeTimeReturnsEmptyForGarbage() {
        #expect(NotificationRow.relativeTime("not-an-iso-date") == "")
    }

    @Test func relativeTimeReturnsNonEmptyForValidISO() {
        let iso = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
        let s = NotificationRow.relativeTime(iso)
        #expect(s.isEmpty == false)
    }
}

struct ProjectActivityViewHelperTests {

    @Test func activityIconForBidDeadline() {
        #expect(ProjectActivityView.iconFor("bid_deadline") == "clock.fill")
    }

    @Test func activityIconFallback() {
        #expect(ProjectActivityView.iconFor("anything-else") == "bolt.fill")
    }

    @Test func summaryStripsCsPrefix() {
        let e = SupabaseActivityEvent(
            id: "x", projectId: "p", entityType: "cs_rfis", entityId: "r",
            action: "insert", category: "generic", actorId: nil, createdAt: nil
        )
        #expect(ProjectActivityView.summaryFor(e) == "rfis insert")
    }

    @Test func mockEventsAreNonEmpty() {
        let mock = ProjectActivityView.mockEvents(projectId: "test-pid")
        #expect(mock.count >= 1)
        #expect(mock.allSatisfy { $0.projectId == "test-pid" })
    }
}
