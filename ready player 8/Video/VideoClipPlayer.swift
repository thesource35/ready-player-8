// Phase 22: SwiftUI wrapper over AVPlayerViewController for VOD playback.
//
// Distinct from LiveStreamView per D-18. Uses Supabase signed-HLS-manifest URL
// via VideoPlaybackAuth.vodManifestUrl() (rewrites SAS URIs into signed segment
// URLs server-side per 22-04 RESEARCH Pattern 3).
//
// Design decisions honored:
// - D-18: separate component from LiveStreamView
// - D-19: optional portalToken support for portal viewers
// - D-26: last-played asset id persisted under ConstructOS.Video.LastPlayedAssetId.{projectId}
//   (opportunistic resume — safe to skip if the saved offset is stale)
// - D-34(b): portal viewers get streaming-only — no download affordance is exposed
// - D-35: boot muted every session (user unmute NOT persisted)
// - D-36: cellular-aware preferredPeakBitRate; HD override session-scoped
//
// Unlike the live variant, VOD uses AVPlayer's default
// `automaticallyWaitsToMinimizeStalling = true` (the sensible default for VOD).

import SwiftUI
import AVKit
import Combine

struct VideoClipPlayer: View {
    let asset: VideoAsset
    var portalToken: String? = nil

    @State private var manifestURL: URL?
    @State private var hdOverride: Bool = false
    @State private var loadError: AppError?
    @StateObject private var quality = CellularQualityMonitor.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black

            switch asset.status {
            case .ready:
                if let url = manifestURL {
                    VodAVPlayerRepresentable(
                        url: url,
                        isPortal: portalToken != nil,
                        peakBitRate: quality.preferredPeakBitRate(hdOverride: hdOverride),
                        resumeKey: ConstructOS.Video.lastPlayedAssetIdKey(projectId: asset.projectId),
                        assetId: asset.id
                    )
                } else if loadError != nil {
                    errorView
                } else {
                    ProgressView("Preparing clip…")
                        .tint(Theme.accent)
                        .foregroundColor(Theme.text)
                }

            case .transcoding:
                transcodingPlaceholder

            case .uploading:
                uploadingPlaceholder

            case .failed:
                failedPlaceholder
            }

            // Cellular HD toggle (only for auth'd viewers on cellular)
            HStack {
                Spacer()
                if quality.isCellular && portalToken == nil && asset.status == .ready {
                    HDToggleButton(hdOverride: $hdOverride)
                }
            }
            .padding(12)
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task(id: asset.id) {
            // Re-mint manifest URL each mount (defensive against stale signed URLs).
            guard asset.status == .ready else { return }
            do {
                let url = try VideoPlaybackAuth.vodManifestUrl(
                    assetId: asset.id,
                    portalToken: portalToken
                )
                self.manifestURL = url
            } catch let err as AppError {
                self.loadError = err
                print("[VideoClipPlayer] manifest URL failed: \(err.localizedDescription)")
            } catch {
                self.loadError = .unknown(error.localizedDescription)
            }
        }
    }

    private var displayName: String {
        asset.name ?? formattedStartedAt
    }

    private var formattedStartedAt: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: asset.startedAt)
    }

    private var errorView: some View {
        VStack(spacing: 8) {
            Text("Couldn't load this clip. Refresh and try again — if this keeps happening, contact support.")
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(16)
        }
    }

    private var transcodingPlaceholder: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(Theme.accent)
            Text("Transcoding · about a minute left")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.muted)
                .tracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var uploadingPlaceholder: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(Theme.accent)
            Text("Uploading…")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.muted)
                .tracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var failedPlaceholder: some View {
        VStack(spacing: 8) {
            Text("Transcode failed")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.red)
                .tracking(2)
            Text(asset.lastError ?? "This clip couldn't be prepared. The owner can retry from the Cameras section.")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - AVPlayerViewController wrapper (VOD, portal-aware)

private struct VodAVPlayerRepresentable: UIViewControllerRepresentable {
    let url: URL
    let isPortal: Bool
    let peakBitRate: Double
    let resumeKey: String
    let assetId: UUID

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredPeakBitRate = peakBitRate // D-36
        let player = AVPlayer(playerItem: playerItem)
        // VOD: leave automaticallyWaitsToMinimizeStalling at default (true).
        player.isMuted = true // D-35: boot muted every session
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        // D-34(b) portal is streaming-only: no download affordance exposed (we don't add share sheets).
        // VOD scrub IS allowed in portal (unlike live head-only) per UI-SPEC — keep requiresLinearPlayback = false.
        vc.allowsPictureInPicturePlayback = !isPortal
        vc.entersFullScreenWhenPlaybackBegins = false

        // Opportunistic resume: if we have a saved offset for this asset, seek.
        if let savedData = UserDefaults.standard.dictionary(forKey: resumeKey),
           let savedIdString = savedData["asset_id"] as? String,
           savedIdString == assetId.uuidString,
           let seconds = savedData["seconds"] as? Double, seconds > 1 {
            let target = CMTime(seconds: seconds, preferredTimescale: 600)
            player.seek(to: target)
        }

        // Persist offset every 5 seconds while playing (D-26 resume support).
        let interval = CMTime(seconds: 5, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let secs = CMTimeGetSeconds(time)
            guard secs.isFinite, secs >= 0 else { return }
            UserDefaults.standard.set(
                ["asset_id": assetId.uuidString, "seconds": secs],
                forKey: resumeKey
            )
        }

        player.play()
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.player?.currentItem?.preferredPeakBitRate = peakBitRate
    }
}
