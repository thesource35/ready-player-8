// Phase 22: iOS cellular-aware playback quality (D-36, D-26 DefaultQuality).
//
// Singleton that observes NWPathMonitor for cellular vs wifi and exposes a
// `preferredPeakBitRate(hdOverride:)` helper that LiveStreamView / VideoClipPlayer
// apply to AVPlayerItem.preferredPeakBitRate.
//
// D-36 rule: on cellular default to 480p (1.5 Mbps) unless the user toggles HD
// override (session-scoped, does NOT persist per D-35's no-persistence stance
// for playback preferences). ConstructOS.Video.DefaultQuality AppStorage value
// takes priority if explicitly set to ld/sd/hd; 'auto' (default) delegates to
// the cellular/wifi decision.

import Foundation
import Network
import Combine

@MainActor
final class CellularQualityMonitor: ObservableObject {
    static let shared = CellularQualityMonitor()

    @Published var isCellular: Bool = false
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "ConstructOS.Video.NWPath", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let cellular = path.usesInterfaceType(.cellular)
            Task { @MainActor in self?.isCellular = cellular }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit { monitor.cancel() }

    /// D-36: default 480p (1.5 Mbps) on cellular, HD (6 Mbps) on wifi.
    /// hdOverride=true overrides to HD for the current session only (not persisted).
    /// ConstructOS.Video.DefaultQuality AppStorage overrides everything if set to ld/sd/hd.
    func preferredPeakBitRate(hdOverride: Bool = false) -> Double {
        let stored = UserDefaults.standard.string(forKey: ConstructOS.Video.defaultQualityKey) ?? "auto"
        switch stored {
        case "hd": return 6_000_000
        case "sd": return 3_000_000
        case "ld": return 1_500_000
        default: // auto
            if hdOverride { return 6_000_000 }
            return isCellular ? 1_500_000 : 6_000_000
        }
    }

    /// Human-readable label for the active quality (for overlay display).
    func currentQualityLabel(hdOverride: Bool = false) -> String {
        let bitRate = preferredPeakBitRate(hdOverride: hdOverride)
        if bitRate <= 1_500_000 { return "LD 480p" }
        if bitRate <= 3_000_000 { return "SD 720p" }
        return "HD"
    }
}
