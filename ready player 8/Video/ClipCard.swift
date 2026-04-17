// Phase 22-08: Clip card tile for the Cameras section.
//
// Renders a single VideoAsset with status-aware UI per UI-SPEC:
// - ready: poster area + tap opens VideoClipPlayer
// - transcoding: gold shimmer + "Transcoding..." copy
// - uploading: gold progress + "Uploading . {percent}%" copy
// - failed: red X + "Retry transcode" button (visible 24h from asset.createdAt per D-33)
//
// Purple PORTAL badge when asset.portalVisible == true.
// Cyan DRONE pill when asset.sourceType == .drone (D-22 informational).
// Context menu for owner/admin actions (D-39).
// 200ms ease-out status animation per UI-SPEC.

import SwiftUI

struct ClipCard: View {
    let asset: VideoAsset
    let canManage: Bool
    let onPlay: () -> Void
    var onRetry: (() -> Void)?
    var onTogglePortal: ((Bool) -> Void)?
    var onDelete: (() -> Void)?

    /// D-33: Retry button visible only within 24h of creation.
    private var retryVisible: Bool {
        asset.status == .failed && Date().timeIntervalSince(asset.createdAt) < 86400
    }

    private var displayName: String {
        asset.name ?? {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            return fmt.string(from: asset.startedAt)
        }()
    }

    private var durationLabel: String? {
        guard let dur = asset.durationS, dur > 0 else { return nil }
        let mins = Int(dur) / 60
        let secs = Int(dur) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 16:9 poster / status area
            ZStack(alignment: .topLeading) {
                Theme.panel
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)

                // Status-specific overlays
                switch asset.status {
                case .ready:
                    // Green READY badge
                    statusBadge("READY", color: Theme.green)
                        .padding(8)

                case .transcoding:
                    // Gold shimmer overlay
                    Theme.gold.opacity(0.15)
                    VStack(spacing: 6) {
                        ProgressView()
                            .tint(Theme.gold)
                        Text("Transcoding\u{2026}")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.gold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .uploading:
                    VStack(spacing: 6) {
                        ProgressView()
                            .tint(Theme.gold)
                        Text("Uploading\u{2026}")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.gold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .failed:
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.red)
                        Text("FAILED")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.red)
                        if retryVisible, let onRetry {
                            Button("Retry transcode") { onRetry() }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Duration overlay (bottom-right) for ready clips
                if asset.status == .ready, let dur = durationLabel {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(dur)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.text)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.panel.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(6)
                        }
                    }
                }

                // Badge pills (top-right)
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Spacer()
                        if asset.portalVisible {
                            badgePill("PORTAL", color: Theme.purple)
                        }
                        if asset.sourceType == .drone {
                            badgePill("DRONE", color: Theme.cyan)
                        }
                    }
                }
                .padding(8)
            }

            // Name + metadata row
            HStack {
                Text(displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Spacer()
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
        // 200ms status transition animation (UI-SPEC)
        .animation(.easeOut(duration: 0.2), value: asset.status)
        .onTapGesture {
            if asset.status == .ready { onPlay() }
        }
        .contextMenu {
            if canManage {
                if asset.sourceType != .drone {
                    Button {
                        onTogglePortal?(!asset.portalVisible)
                    } label: {
                        Label(
                            asset.portalVisible ? "Remove from portal" : "Share with portal",
                            systemImage: asset.portalVisible ? "eye.slash" : "eye"
                        )
                    }
                } else {
                    // D-22: Drone footage can't be shared via portal
                    Button(action: {}) {
                        Label("Drone footage can't be shared via portal in this release.", systemImage: "info.circle")
                    }
                    .disabled(true)
                }

                Divider()

                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete clip", systemImage: "trash")
                }
            }
        }
        .accessibilityLabel("\(displayName), \(asset.status.rawValue)")
    }

    // MARK: - Helpers

    private func statusBadge(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Theme.panel.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func badgePill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .heavy))
            .tracking(1)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
