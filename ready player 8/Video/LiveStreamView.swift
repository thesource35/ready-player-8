// Phase 22: SwiftUI wrapper over AVPlayerViewController for LL-HLS live streams from Mux.
//
// Design decisions honored:
// - D-14: playback token is minted by the web API (VideoPlaybackAuth) — never forged here
// - D-18: LiveStreamView and VideoClipPlayer are DISTINCT components (this file = live only)
// - D-19: optional `portalToken` supports both logged-in and portal-viewer paths
// - D-27: reflects source.status transitions (via VideoSyncManager observation)
// - D-34(a): portal viewers see no DVR scrub (requiresLinearPlayback = true; showsPlaybackControls off)
// - D-35: every new AVPlayer boots MUTED, regardless of source.audio_enabled. User unmute is
//   session-scoped and is NEVER persisted to AppStorage.
// - D-36: cellular auto-downgrades to 480p (1.5 Mbps) via AVPlayerItem.preferredPeakBitRate;
//   HD overlay toggle overrides for the current session only.
// - LL-HLS tuning per 22-RESEARCH Pattern 4: automaticallyWaitsToMinimizeStalling = false.

import SwiftUI
import AVKit
import Combine

struct LiveStreamView: View {
    let source: VideoSource
    var portalToken: String? = nil

    @State private var token: String?
    @State private var hdOverride: Bool = false
    @State private var loadError: AppError?
    @StateObject private var quality = CellularQualityMonitor.shared
    @ObservedObject private var sync = VideoSyncManager.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black

            if let tokenValue = token,
               let playbackId = source.muxPlaybackId,
               let url = liveURL(playbackId: playbackId, token: tokenValue) {
                LiveAVPlayerRepresentable(
                    url: url,
                    isPortal: portalToken != nil,
                    hdOverride: hdOverride,
                    peakBitRate: quality.preferredPeakBitRate(hdOverride: hdOverride)
                )
            } else if loadError != nil {
                VStack(spacing: 8) {
                    Text("Couldn't start playback. Refresh and try again — if this keeps happening, contact support.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(16)
                }
            } else {
                ProgressView("Connecting to stream…")
                    .tint(Theme.accent)
                    .foregroundColor(Theme.text)
            }

            // Overlay chrome (status badge + cellular HD toggle)
            HStack {
                LiveStatusBadge(
                    isLive: source.status == .active,
                    isOffline: source.status == .offline
                )
                Spacer()
                // D-36: HD toggle only shown on cellular, and only for authenticated viewers
                // (portal mode keeps chrome minimal per D-34).
                if quality.isCellular && portalToken == nil {
                    HDToggleButton(hdOverride: $hdOverride)
                }
            }
            .padding(12)
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task {
            await fetchToken()
        }
    }

    private func liveURL(playbackId: String, token: String) -> URL? {
        URL(string: "https://stream.mux.com/\(playbackId).m3u8?token=\(token)")
    }

    private func fetchToken() async {
        do {
            let sessionToken = try await currentSessionToken()
            let mintedToken = try await VideoPlaybackAuth.fetchMuxToken(
                sourceId: source.id,
                sessionToken: sessionToken,
                portalToken: portalToken
            )
            self.token = mintedToken.token
            // Schedule refresh ~30s before expiry so playback never lapses mid-session.
            let refreshIn = max(60, mintedToken.ttl - 30)
            try? await Task.sleep(nanoseconds: UInt64(refreshIn) * 1_000_000_000)
            await fetchToken() // re-mint
        } catch let err as AppError {
            self.loadError = err
            print("[LiveStreamView] token fetch failed: \(err.localizedDescription)")
        } catch {
            self.loadError = .unknown(error.localizedDescription)
        }
    }

    /// Pull the authenticated session access token. Portal path doesn't need it so we
    /// return "" to keep VideoPlaybackAuth.fetchMuxToken happy (it won't read the value
    /// in portal mode — see VideoPlaybackAuth.swift).
    private func currentSessionToken() async throws -> String {
        if portalToken != nil { return "" }
        return await MainActor.run { SupabaseService.shared.accessToken ?? "" }
    }
}

// MARK: - AVPlayerViewController wrapper (LL-HLS tuned, portal-aware)

private struct LiveAVPlayerRepresentable: UIViewControllerRepresentable {
    let url: URL
    let isPortal: Bool
    let hdOverride: Bool
    let peakBitRate: Double

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredPeakBitRate = peakBitRate // D-36
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false // LL-HLS priority per RESEARCH Pattern 4
        player.isMuted = true // D-35: boot muted every session, regardless of source.audio_enabled
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = !isPortal // D-34(a): portal = head-only, no DVR scrub affordance
        vc.allowsPictureInPicturePlayback = !isPortal
        vc.entersFullScreenWhenPlaybackBegins = false
        if isPortal {
            // Portal mode: disable scrub affordance via requiresLinearPlayback (head-only playback).
            vc.requiresLinearPlayback = true
        }
        player.play()
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.player?.currentItem?.preferredPeakBitRate = peakBitRate
    }
}
