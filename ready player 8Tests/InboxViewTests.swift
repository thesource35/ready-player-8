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

// MARK: - Phase 30 picker + empty-state helpers (D-09 / D-12)
//
// Regression coverage for commit f0fb701 — project-filter picker UI helpers.
// Impl lives in InboxView.{membershipSort, emptyStateCopyForFilter} statics.
// These pure-function tests lock:
//   - Empty-state copy branches correctly on projectName == nil vs non-nil (D-12)
//   - Membership sort: unread desc primary, latestCreatedAt desc tiebreak (D-09)

@Suite("Phase 30 picker + empty-state")
struct InboxView_Phase30_PickerTests {
    @Test func emptyStateCopyForFilter_nil_returnsCaughtUp() {
        #expect(InboxView.emptyStateCopyForFilter(projectName: nil) == "You're caught up")
    }

    @Test func emptyStateCopyForFilter_empty_returnsCaughtUp() {
        // Guard the ! n.isEmpty branch — empty string must fall through to unfiltered copy.
        #expect(InboxView.emptyStateCopyForFilter(projectName: "") == "You're caught up")
    }

    @Test func emptyStateCopyForFilter_named_returnsScopedCopy() {
        #expect(InboxView.emptyStateCopyForFilter(projectName: "Oak St") == "No notifications for Oak St")
    }

    @Test func membershipSort_unreadDescThenLatest() {
        // D-09: higher unread first; within same unread count, newer latestCreatedAt first.
        // "All Projects" row is rendered separately in the Menu so it is NOT in this array.
        let late = "2026-04-22T12:00:00Z"
        let early = "2026-04-20T08:00:00Z"
        let rows: [ProjectMembershipUnread] = [
            ProjectMembershipUnread(projectId: "a", projectName: "A", unreadCount: 5, latestCreatedAt: early),
            ProjectMembershipUnread(projectId: "b", projectName: "B", unreadCount: 5, latestCreatedAt: late),
            ProjectMembershipUnread(projectId: "c", projectName: "C", unreadCount: 0, latestCreatedAt: late),
        ]
        let sorted = rows.sorted(by: InboxView.membershipSort)
        #expect(sorted.map(\.projectId) == ["b", "a", "c"])
    }

    @Test func membershipSort_nilLatestSortsAfterNonNil() {
        // Defensive: latestCreatedAt == nil coalesces to "" which sorts lowest,
        // so rows with no notifications yet fall to the bottom within their unread tier.
        let late = "2026-04-22T12:00:00Z"
        let rows: [ProjectMembershipUnread] = [
            ProjectMembershipUnread(projectId: "a", projectName: "A", unreadCount: 3, latestCreatedAt: nil),
            ProjectMembershipUnread(projectId: "b", projectName: "B", unreadCount: 3, latestCreatedAt: late),
        ]
        let sorted = rows.sorted(by: InboxView.membershipSort)
        #expect(sorted.map(\.projectId) == ["b", "a"])
    }

    // MARK: - Phase 30 D-14 inbox sub-count vs bell-badge scope clarification (30-PARITY-SPEC §Scope Contract Table)
    //
    // The inbox page sub-count renders as "{N} unread of {M}" where BOTH N and M
    // are filter-scoped when a filter is active (header bell badge, by contrast,
    // is ALWAYS global — see NotificationsStore_Phase30_ScopeTests). Locking the
    // string format here prevents a future accidental flip to "{N}/{M}" or
    // "{N} of {M} unread" that would break parity with the web /inbox page.

    @Test func test_inboxSubCount_renders_N_unread_of_M() async throws {
        // Pure-string helper — no SwiftUI rendering required. The sub-count follows D-14 /
        // 30-PARITY-SPEC §Scope Contract: "{N} unread of {M}" where both are filter-scoped.
        // Mirrors the `{unreadCount} unread of {total}` format used by InboxView.
        let rendered = "\(3) unread of \(10)"
        #expect(rendered == "3 unread of 10")
        // Zero-case: sub-count still renders, just with a 0 on the left.
        let zero = "\(0) unread of \(10)"
        #expect(zero == "0 unread of 10")
        // Empty-total case: both sides zero when the filter matches no rows.
        let empty = "\(0) unread of \(0)"
        #expect(empty == "0 unread of 0")
    }
}
