// FieldLocationCapture.swift — Phase 16 Wave 2 (FIELD-01)
// ConstructionOS
//
// Capture orchestration: permission gate, fresh-fix race with 10s timeout,
// stale-last-known fallback, manual-pin support, AppError mapping.
//
// All location work is testable via the injected `LocationProviding`.

import CoreLocation
import Foundation

/// Source of a captured GPS coordinate. Raw values match the
/// `cs_gps_source` Postgres enum (D-02).
enum GpsSource: String, Codable, Hashable {
    case fresh
    case staleLastKnown = "stale_last_known"
    case manualPin = "manual_pin"
}

/// Immutable result of a capture attempt.
struct CapturedLocation: Hashable {
    let lat: Double
    let lng: Double
    let accuracyM: Double
    let source: GpsSource
    let capturedAt: Date
}

/// Orchestrates a single photo-capture's location resolution.
///
/// Behavior (D-05, D-06, D-08):
///  - permission denied/restricted → `AppError.permissionDenied`
///  - permission granted, fresh fix in <10s → `.fresh`
///  - permission granted, timeout with `lastKnownLocation` → `.staleLastKnown`
///  - permission granted, timeout with no last-known → `AppError.validationFailed`
///  - `capturedAt` is the shutter time (Date() at call), NOT the upload time.
final class FieldLocationCapture {

    private let provider: LocationProviding
    private let freshTimeout: TimeInterval

    init(provider: LocationProviding, freshTimeout: TimeInterval = 10) {
        self.provider = provider
        self.freshTimeout = freshTimeout
    }

    /// Throws `AppError.permissionDenied` if Core Location access is not granted.
    /// For `notDetermined`, requests authorization once and re-checks; if the
    /// status remains undetermined the call still throws — UI should re-invoke
    /// after the OS prompt resolves.
    func ensurePermission() async throws {
        switch provider.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return
        case .denied, .restricted:
            throw AppError.permissionDenied(feature: "Location")
        case .notDetermined:
            provider.requestWhenInUseAuthorization()
            switch provider.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                return
            default:
                throw AppError.permissionDenied(feature: "Location")
            }
        @unknown default:
            throw AppError.permissionDenied(feature: "Location")
        }
    }

    /// Race a fresh-fix request against `freshTimeout`. On timeout, fall back
    /// to `lastKnownLocation` if available, else throw.
    func captureLocation() async throws -> CapturedLocation {
        // Capture shutter time before any async work — D-08.
        let shutter = Date()

        do {
            let loc = try await provider.requestFreshLocation(timeout: freshTimeout)
            return CapturedLocation(
                lat: loc.coordinate.latitude,
                lng: loc.coordinate.longitude,
                accuracyM: loc.horizontalAccuracy,
                source: .fresh,
                capturedAt: shutter
            )
        } catch {
            if let stale = provider.lastKnownLocation {
                return CapturedLocation(
                    lat: stale.coordinate.latitude,
                    lng: stale.coordinate.longitude,
                    accuracyM: stale.horizontalAccuracy,
                    source: .staleLastKnown,
                    capturedAt: shutter
                )
            }
            throw AppError.validationFailed(field: "location", reason: "location unavailable")
        }
    }
}
