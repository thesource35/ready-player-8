import CoreLocation
import Foundation

/// Injectable wrapper around CLLocationManager so field-capture flows can be
/// unit-tested without touching the real Core Location stack.
///
/// Phase 16 Wave 0 scaffold — real implementation lands in Wave 2.
protocol LocationProviding {
    func requestWhenInUseAuthorization()
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestFreshLocation(timeout: TimeInterval) async throws -> CLLocation
    var lastKnownLocation: CLLocation? { get }
}
