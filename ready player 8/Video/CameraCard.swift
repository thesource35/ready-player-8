// Phase 22-08: Camera card tile for the Cameras section.
//
// Renders a single VideoSource as a 16:9 thumbnail area with status badge overlay,
// name + location label, and tap action. Status badge uses LiveStatusBadge from
// VideoPlayerChrome.swift. Active cameras get premiumGlow; offline cameras within
// the 5-min reconnect grace (D-27) show gold "Reconnecting..." instead of red "Offline".
//
// UI-SPEC references: 14px radius, var(--surface) bg, 200ms ease-out status animation.

import SwiftUI

struct CameraCard: View {
    let source: VideoSource
    let onTap: () -> Void

    /// Determine if the camera is within the 5-min reconnect grace period (D-27).
    private var isReconnecting: Bool {
        guard source.status == .offline else { return false }
        guard let lastActive = source.lastActiveAt else { return false }
        return Date().timeIntervalSince(lastActive) < 300
    }

    private var statusText: String {
        switch source.status {
        case .active:
            return "Live"
        case .idle:
            return "Idle \u{00B7} waiting for encoder"
        case .offline:
            if isReconnecting {
                return "Reconnecting\u{2026}"
            } else {
                let relativeTime: String = {
                    guard let lastActive = source.lastActiveAt else { return "unknown" }
                    let interval = Date().timeIntervalSince(lastActive)
                    if interval < 60 { return "just now" }
                    if interval < 3600 { return "\(Int(interval / 60))m ago" }
                    if interval < 86400 { return "\(Int(interval / 3600))h ago" }
                    return "\(Int(interval / 86400))d ago"
                }()
                return "Offline \u{00B7} last seen \(relativeTime)"
            }
        case .archived:
            return "Archived"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // 16:9 thumbnail area
                ZStack(alignment: .topLeading) {
                    Theme.panel
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)

                    // Status badge overlay
                    if isReconnecting {
                        // Gold "Reconnecting..." badge during grace period
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.gold)
                                .frame(width: 8, height: 8)
                            Text("RECONNECTING")
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(2)
                                .foregroundColor(Theme.gold)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.panel.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                    } else {
                        LiveStatusBadge(
                            isLive: source.status == .active,
                            isOffline: source.status == .offline
                        )
                        .padding(8)
                    }
                }

                // Name + location overlay
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)

                    if let loc = source.locationLabel, !loc.isEmpty {
                        Text(loc)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.muted)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.border.opacity(0.4), lineWidth: 0.5)
            )
            // D-27 active glow
            .if(source.status == .active) { view in
                view.premiumGlow(cornerRadius: 14, color: Theme.accent)
            }
            // 200ms status transition animation (UI-SPEC)
            .animation(.easeOut(duration: 0.2), value: source.status)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(source.name), \(statusText)")
    }
}

// MARK: - Conditional modifier helper

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
