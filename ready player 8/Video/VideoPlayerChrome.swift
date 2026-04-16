// Phase 22: Shared player overlay components — status badges, HD toggle, accessibility labels.
//
// Visual contract: 22-UI-SPEC.md §Player interaction rules + §Color.
// Status color vocabulary per UI-SPEC:
//   green  LIVE       (source.status == .active)
//   gold   IDLE       (source.status == .idle)
//   red    OFFLINE    (source.status == .offline past grace; also used for "Reconnecting…" gold variant upstream)
//
// 44pt hit target rule (D-UI) honored for the HD toggle tap area.

import SwiftUI

struct LiveStatusBadge: View {
    let isLive: Bool
    let isOffline: Bool
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOffline ? Theme.red : (isLive ? Theme.green : Theme.gold))
                .frame(width: 8, height: 8)
            Text(isOffline ? "OFFLINE" : (isLive ? "LIVE" : "IDLE"))
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundColor(isOffline ? Theme.red : (isLive ? Theme.green : Theme.gold))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Theme.panel.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isOffline ? "Camera offline" : (isLive ? "Live" : "Idle"))
    }
}

struct HDToggleButton: View {
    @Binding var hdOverride: Bool
    var body: some View {
        Button {
            hdOverride.toggle()
        } label: {
            Text(hdOverride ? "HD" : "LD")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(hdOverride ? Theme.accent : Theme.muted)
                .frame(minWidth: 44, minHeight: 44) // D-UI 44pt hit target
                .contentShape(Rectangle())
        }
        .accessibilityLabel(hdOverride ? "Switch to low-data 480p" : "Switch to HD")
    }
}
