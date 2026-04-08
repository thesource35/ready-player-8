import XCTest
import CoreLocation
@testable import ready_player_8

/// Phase 16 Wave 2 — FIELD-01 capture orchestration tests.
final class FieldLocationCaptureTests: XCTestCase {

    private func makeLocation(lat: Double = 37.7749, lng: Double = -122.4194,
                              accuracy: Double = 5) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                   altitude: 0,
                   horizontalAccuracy: accuracy,
                   verticalAccuracy: -1,
                   timestamp: Date())
    }

    // MARK: - ensurePermission

    func test_ensurePermission_denied_throwsPermissionDenied() async {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .denied
        let capture = FieldLocationCapture(provider: mock)

        do {
            try await capture.ensurePermission()
            XCTFail("Expected AppError.permissionDenied")
        } catch let error as AppError {
            if case .permissionDenied = error { /* ok */ } else {
                XCTFail("Expected .permissionDenied, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }

    func test_ensurePermission_restricted_throwsPermissionDenied() async {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .restricted
        let capture = FieldLocationCapture(provider: mock)

        do {
            try await capture.ensurePermission()
            XCTFail("Expected throw")
        } catch let error as AppError {
            guard case .permissionDenied = error else {
                XCTFail("Expected .permissionDenied, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AppError")
        }
    }

    func test_ensurePermission_authorized_succeeds() async throws {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .authorizedWhenInUse
        let capture = FieldLocationCapture(provider: mock)
        try await capture.ensurePermission()
    }

    func test_ensurePermission_notDetermined_requestsAuthorization() async {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .notDetermined
        let capture = FieldLocationCapture(provider: mock)
        // Should request and then (since mock stays notDetermined) throw
        do {
            try await capture.ensurePermission()
            XCTFail("Expected throw on still-undetermined")
        } catch is AppError {
            XCTAssertEqual(mock.requestAuthorizationCallCount, 1)
        } catch {
            XCTFail("Expected AppError")
        }
    }

    // MARK: - captureLocation

    func test_captureLocation_freshFix_returnsFreshSource() async throws {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .authorizedWhenInUse
        let loc = makeLocation()
        mock.freshResult = .success(loc)

        let capture = FieldLocationCapture(provider: mock)
        let captured = try await capture.captureLocation()

        XCTAssertEqual(captured.source, .fresh)
        XCTAssertEqual(captured.lat, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(captured.lng, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(captured.accuracyM, 5, accuracy: 0.01)
        // captured_at must be set near "now" (within 5s)
        XCTAssertLessThan(abs(captured.capturedAt.timeIntervalSinceNow), 5)
    }

    func test_captureLocation_timeoutWithLastKnown_returnsStaleSource() async throws {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .authorizedWhenInUse
        mock.freshResult = .timeout
        let stale = makeLocation(lat: 40.0, lng: -74.0, accuracy: 100)
        mock.lastKnownLocation = stale

        let capture = FieldLocationCapture(provider: mock)
        let captured = try await capture.captureLocation()

        XCTAssertEqual(captured.source, .staleLastKnown)
        XCTAssertEqual(captured.lat, 40.0, accuracy: 0.0001)
        XCTAssertEqual(captured.lng, -74.0, accuracy: 0.0001)
    }

    func test_captureLocation_timeoutNoLastKnown_throwsValidationFailed() async {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .authorizedWhenInUse
        mock.freshResult = .timeout
        mock.lastKnownLocation = nil

        let capture = FieldLocationCapture(provider: mock)
        do {
            _ = try await capture.captureLocation()
            XCTFail("Expected throw")
        } catch let error as AppError {
            guard case .validationFailed = error else {
                XCTFail("Expected .validationFailed, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AppError")
        }
    }

    func test_captureLocation_capturedAtIsShutterTime_notUploadTime() async throws {
        let mock = MockLocationProvider()
        mock.authorizationStatus = .authorizedWhenInUse
        mock.freshResult = .success(makeLocation())

        let capture = FieldLocationCapture(provider: mock)
        let before = Date()
        let captured = try await capture.captureLocation()
        let after = Date()

        XCTAssertGreaterThanOrEqual(captured.capturedAt.timeIntervalSince1970,
                                    before.timeIntervalSince1970 - 0.1)
        XCTAssertLessThanOrEqual(captured.capturedAt.timeIntervalSince1970,
                                 after.timeIntervalSince1970 + 0.1)
    }

    // MARK: - GpsSource raw values (DB enum compat)

    func test_gpsSource_rawValuesMatchDatabaseEnum() {
        XCTAssertEqual(GpsSource.fresh.rawValue, "fresh")
        XCTAssertEqual(GpsSource.staleLastKnown.rawValue, "stale_last_known")
        XCTAssertEqual(GpsSource.manualPin.rawValue, "manual_pin")
    }
}
