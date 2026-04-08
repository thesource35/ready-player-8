import CoreLocation
import Foundation
@testable import ready_player_8

/// Configurable mock for `LocationProviding` used across Phase 16 tests.
final class MockLocationProvider: LocationProviding {
    enum FreshResult {
        case success(CLLocation)
        case denied
        case timeout
        case failure(Error)
    }

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var lastKnownLocation: CLLocation?
    var freshResult: FreshResult = .timeout
    private(set) var requestAuthorizationCallCount = 0
    private(set) var requestFreshCallCount = 0

    func requestWhenInUseAuthorization() {
        requestAuthorizationCallCount += 1
    }

    func requestFreshLocation(timeout: TimeInterval) async throws -> CLLocation {
        requestFreshCallCount += 1
        switch freshResult {
        case .success(let loc):
            return loc
        case .denied:
            throw NSError(domain: kCLErrorDomain, code: CLError.denied.rawValue)
        case .timeout:
            throw NSError(domain: "MockLocationProvider", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Timed out after \(timeout)s"])
        case .failure(let err):
            throw err
        }
    }
}
