// CLLocationProvider.swift — Phase 16 Wave 2 (FIELD-01)
// ConstructionOS
//
// Production `LocationProviding` impl wrapping CLLocationManager. Uses an
// async continuation to bridge CLLocationManagerDelegate callbacks, with a
// Task.sleep race for timeout semantics. Threat T-16-LOC: when-in-use only,
// authorization requested at capture time.

import CoreLocation
import Foundation

final class CLLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {

    private let manager: CLLocationManager
    private var pendingContinuation: CheckedContinuation<CLLocation, Error>?
    private let queue = DispatchQueue(label: "ConstructOS.Field.CLLocationProvider")

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - LocationProviding

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    var lastKnownLocation: CLLocation? {
        manager.location
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestFreshLocation(timeout: TimeInterval) async throws -> CLLocation {
        try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask { [weak self] in
                guard let self else { throw AppError.unknown("provider deallocated") }
                return try await self.requestSingleFix()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AppError.validationFailed(field: "location",
                                                reason: "fresh-fix timeout after \(Int(timeout))s")
            }
            // First completed task wins.
            guard let result = try await group.next() else {
                throw AppError.validationFailed(field: "location", reason: "no result")
            }
            group.cancelAll()
            return result
        }
    }

    // MARK: - Single fix bridge

    private func requestSingleFix() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocation, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    cont.resume(throwing: AppError.unknown("provider deallocated"))
                    return
                }
                // Coalesce: if a previous request is in-flight, fail the new one.
                if self.pendingContinuation != nil {
                    cont.resume(throwing: AppError.validationFailed(
                        field: "location", reason: "another request in flight"))
                    return
                }
                self.pendingContinuation = cont
                DispatchQueue.main.async {
                    self.manager.requestLocation()
                }
            }
        }
    }

    private func resumePending(with result: Result<CLLocation, Error>) {
        queue.async { [weak self] in
            guard let self, let cont = self.pendingContinuation else { return }
            self.pendingContinuation = nil
            switch result {
            case .success(let loc): cont.resume(returning: loc)
            case .failure(let err): cont.resume(throwing: err)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        resumePending(with: .success(loc))
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        resumePending(with: .failure(error))
    }
}
