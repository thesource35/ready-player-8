// Phase 14 — InboxView
// Notification list with swipe-to-dismiss, tap-to-mark-read, and toolbar
// "Mark All Read" button. Presented as a sheet from the header bell.

import SwiftUI

struct InboxView: View {
    @ObservedObject var store: NotificationsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.notifications.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.notifications) { n in
                            NotificationRow(notification: n)
                                .listRowBackground(n.isUnread ? Theme.surface : Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if n.isUnread {
                                        Task { await store.markRead(n.id) }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await store.markDismissed(n.id) }
                                    } label: {
                                        Label("Dismiss", systemImage: "trash")
                                    }
                                    if n.isUnread {
                                        Button {
                                            Task { await store.markRead(n.id) }
                                        } label: {
                                            Label("Read", systemImage: "envelope.open")
                                        }
                                        .tint(Theme.accent)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await store.refresh() }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                // Phase 30 — D-05/D-07/D-08/D-09: project-filter Menu picker.
                // Placed BEFORE "Mark All Read" so scoping a project reads left-to-right.
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Button {
                            Task { await store.setFilter(nil) }
                        } label: {
                            HStack {
                                Text("All Projects")
                                if store.projectFilter == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Divider()
                        ForEach(store.memberships.sorted(by: Self.membershipSort), id: \.projectId) { m in
                            Button {
                                Task { await store.setFilter(m.projectId) }
                            } label: {
                                HStack {
                                    Text(m.projectName)
                                    Spacer()
                                    if m.unreadCount > 0 {
                                        Text("\(m.unreadCount)")
                                            .font(.caption2.weight(.heavy))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Theme.accent.opacity(0.25))
                                            .foregroundStyle(Theme.accent)
                                            .clipShape(Capsule())
                                    }
                                    if store.projectFilter == m.projectId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentFilterLabel)
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Filter notifications by project")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Mark All Read") {
                        Task { await store.markAllRead() }
                    }
                    .disabled(store.unreadCount == 0)
                    .foregroundStyle(store.unreadCount == 0 ? Theme.muted : Theme.accent)
                }
            }
        }
    }

    // MARK: Phase 30 — picker / empty-state helpers

    /// Label shown on the toolbar Menu button — resolves current filter's project
    /// name, or "All Projects" when no filter is active.
    private var currentFilterLabel: String {
        if let pid = store.projectFilter,
           let m = store.memberships.first(where: { $0.projectId == pid }) {
            return m.projectName
        }
        return "All Projects"
    }

    /// D-09 sort order: unread count descending, tiebreak by most-recent notification
    /// timestamp descending. "All Projects" is rendered separately (pinned at top).
    static func membershipSort(lhs: ProjectMembershipUnread, rhs: ProjectMembershipUnread) -> Bool {
        if lhs.unreadCount != rhs.unreadCount { return lhs.unreadCount > rhs.unreadCount }
        return (lhs.latestCreatedAt ?? "") > (rhs.latestCreatedAt ?? "")
    }

    /// D-12 empty-state copy branching. Filtered state shows scoped message; unfiltered
    /// keeps the original "You're caught up" copy so Phase 14 behavior is preserved.
    static func emptyStateCopyForFilter(projectName: String?) -> String {
        if let n = projectName, !n.isEmpty { return "No notifications for \(n)" }
        return "You're caught up"
    }

    private var emptyState: some View {
        let filteredProjectName: String? = {
            guard let pid = store.projectFilter else { return nil }
            return store.memberships.first(where: { $0.projectId == pid })?.projectName
        }()
        return VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Theme.muted)
            Text(Self.emptyStateCopyForFilter(projectName: filteredProjectName))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.muted)
            if filteredProjectName != nil {
                Button("Show all projects") {
                    Task { await store.setFilter(nil) }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
            }
            if let err = store.lastError {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}

struct NotificationRow: View {
    let notification: SupabaseNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left edge unread indicator
            if notification.isUnread {
                Rectangle().fill(Theme.accent).frame(width: 3)
            } else {
                Color.clear.frame(width: 3)
            }
            Image(systemName: NotificationRow.iconFor(notification.category))
                .foregroundStyle(Theme.accent)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: notification.isUnread ? .heavy : .medium))
                    .foregroundStyle(Theme.text)
                if let body = notification.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                }
                Text(NotificationRow.relativeTime(notification.createdAt))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    static func iconFor(_ category: String) -> String {
        switch category {
        case "bid_deadline":  return "clock.fill"
        case "safety_alert":  return "exclamationmark.triangle.fill"
        case "assigned_task": return "checkmark.circle.fill"
        case "document":      return "doc.fill"
        default:              return "bell.fill"
        }
    }

    static func relativeTime(_ iso: String?) -> String {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
