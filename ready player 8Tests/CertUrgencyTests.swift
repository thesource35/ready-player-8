import XCTest
@testable import ready_player_8

final class CertUrgencyTests: XCTestCase {

    private func dateString(daysFromNow: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!)
    }

    // MARK: - Urgency tier tests

    func testSafe_moreThan30Days() {
        XCTAssertEqual(certUrgency(expiresAt: dateString(daysFromNow: 60)), .safe)
    }

    func testWarning_between7And30Days() {
        XCTAssertEqual(certUrgency(expiresAt: dateString(daysFromNow: 20)), .warning)
    }

    func testUrgent_within7Days() {
        XCTAssertEqual(certUrgency(expiresAt: dateString(daysFromNow: 5)), .urgent)
    }

    func testExpired_pastDate() {
        XCTAssertEqual(certUrgency(expiresAt: dateString(daysFromNow: -1)), .expired)
    }

    func testExpired_today() {
        XCTAssertEqual(certUrgency(expiresAt: dateString(daysFromNow: 0)), .expired)
    }

    func testSafe_nilExpiry() {
        XCTAssertEqual(certUrgency(expiresAt: nil), .safe)
    }

    // MARK: - Pulse tests

    func testPulse_expired() {
        XCTAssertTrue(CertUrgency.expired.shouldPulse)
    }

    func testNoPulse_warning() {
        XCTAssertFalse(CertUrgency.warning.shouldPulse)
    }

    func testNoPulse_safe() {
        XCTAssertFalse(CertUrgency.safe.shouldPulse)
    }

    // MARK: - Deep-link parsing tests

    func testDeepLinkParsing_validCertId() {
        let userInfo: [AnyHashable: Any] = ["cert_id": "abc-123"]
        XCTAssertEqual(parseCertDeepLink(userInfo: userInfo), "abc-123")
    }

    func testDeepLinkParsing_missingCertId() {
        let userInfo: [AnyHashable: Any] = ["other": "value"]
        XCTAssertNil(parseCertDeepLink(userInfo: userInfo))
    }
}
