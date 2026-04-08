import XCTest
@testable import ready_player_8

/// Phase 16 Wave 2 — FIELD-01/02 DTO + pin-edit payload coverage.
final class PhotoLocationEditTests: XCTestCase {

    // MARK: - DocumentEntityType raw values match Postgres enum

    func test_documentEntityType_newCases_rawValuesMatchDatabaseEnum() {
        XCTAssertEqual(DocumentEntityType.dailyLog.rawValue, "daily_log")
        XCTAssertEqual(DocumentEntityType.safetyIncident.rawValue, "safety_incident")
        XCTAssertEqual(DocumentEntityType.punchItem.rawValue, "punch_item")
    }

    func test_documentEntityType_legacyCasesUnchanged() {
        XCTAssertEqual(DocumentEntityType.project.rawValue, "project")
        XCTAssertEqual(DocumentEntityType.changeOrder.rawValue, "change_order")
    }

    func test_documentEntityType_allCasesCountSeven() {
        XCTAssertEqual(DocumentEntityType.allCases.count, 7)
    }

    // MARK: - SupabaseDocument DTO GPS round-trip

    private func sampleDoc(withGPS: Bool) -> SupabaseDocument {
        SupabaseDocument(
            id: "doc-1",
            orgId: "org-1",
            versionChainId: "doc-1",
            versionNumber: 1,
            isCurrent: true,
            filename: "x.jpg",
            mimeType: "image/jpeg",
            sizeBytes: 1024,
            storagePath: "org-1/punch_item/abc/doc-1.jpg",
            uploadedBy: "u@e.com",
            createdAt: "2026-04-08T00:00:00Z",
            gpsLat: withGPS ? 37.7749 : nil,
            gpsLng: withGPS ? -122.4194 : nil,
            gpsAccuracyM: withGPS ? 5 : nil,
            gpsSource: withGPS ? "fresh" : nil,
            capturedAt: withGPS ? "2026-04-08T00:00:00Z" : nil
        )
    }

    func test_supabaseDocument_gpsFields_roundTripViaJSON() throws {
        let original = sampleDoc(withGPS: true)
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        let data = try enc.encode(original)

        // Confirm snake_case keys are present.
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(json["gps_lat"])
        XCTAssertNotNil(json["gps_lng"])
        XCTAssertNotNil(json["gps_accuracy_m"])
        XCTAssertNotNil(json["gps_source"])
        XCTAssertNotNil(json["captured_at"])

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try dec.decode(SupabaseDocument.self, from: data)

        XCTAssertEqual(decoded.gpsLat, 37.7749)
        XCTAssertEqual(decoded.gpsLng, -122.4194)
        XCTAssertEqual(decoded.gpsSource, "fresh")
        XCTAssertEqual(decoded.capturedAt, "2026-04-08T00:00:00Z")
    }

    func test_supabaseDocument_nullGPSFields_decodeFromLegacyRow() throws {
        // Simulate a pre-Phase-16 row with none of the new fields present.
        let legacyJSON = """
        {
          "id": "doc-1",
          "org_id": "org-1",
          "version_chain_id": "doc-1",
          "version_number": 1,
          "is_current": true,
          "filename": "x.jpg",
          "mime_type": "image/jpeg",
          "size_bytes": 1024,
          "storage_path": "org-1/project/abc/doc-1.jpg",
          "uploaded_by": "u@e.com",
          "created_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let doc = try dec.decode(SupabaseDocument.self, from: legacyJSON)

        XCTAssertNil(doc.gpsLat)
        XCTAssertNil(doc.gpsLng)
        XCTAssertNil(doc.gpsSource)
        XCTAssertNil(doc.capturedAt)
        XCTAssertFalse(doc.isStaleGPS)
        XCTAssertFalse(doc.isManualPin)
    }

    // MARK: - Manual pin edit payload (D-07)

    func test_manualPinUpdatePayload_flipsGpsSourceToManualPin() {
        let payload = FieldPhotoUpload.manualPinUpdatePayload(
            newLat: 40.0,
            newLng: -74.0,
            updatedBy: "user-xyz"
        )
        XCTAssertEqual(payload["gps_source"], "manual_pin")
        XCTAssertEqual(payload["gps_lat"], "40.0")
        XCTAssertEqual(payload["gps_lng"], "-74.0")
        XCTAssertEqual(payload["updated_by"], "user-xyz")
        XCTAssertNotNil(payload["updated_at"])
    }

    // MARK: - applyCapturedLocation

    func test_applyCapturedLocation_populatesAllGPSFields() {
        var doc = sampleDoc(withGPS: false)
        let captured = CapturedLocation(
            lat: 37.0,
            lng: -122.0,
            accuracyM: 8,
            source: .staleLastKnown,
            capturedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        FieldPhotoUpload.applyCapturedLocation(to: &doc, location: captured)
        XCTAssertEqual(doc.gpsLat, 37.0)
        XCTAssertEqual(doc.gpsLng, -122.0)
        XCTAssertEqual(doc.gpsAccuracyM, 8)
        XCTAssertEqual(doc.gpsSource, "stale_last_known")
        XCTAssertNotNil(doc.capturedAt)
        XCTAssertTrue(doc.isStaleGPS)
    }

    // MARK: - Badge helper

    func test_gpsBadgeLabel_returnsStaleForStaleLastKnown() {
        var doc = sampleDoc(withGPS: true)
        doc.gpsSource = "stale_last_known"
        XCTAssertEqual(FieldPhotoUpload.gpsBadgeLabel(for: doc), "stale GPS")
    }

    func test_gpsBadgeLabel_returnsManualPinForManualPin() {
        var doc = sampleDoc(withGPS: true)
        doc.gpsSource = "manual_pin"
        XCTAssertEqual(FieldPhotoUpload.gpsBadgeLabel(for: doc), "manual pin")
    }

    func test_gpsBadgeLabel_returnsNilForFresh() {
        var doc = sampleDoc(withGPS: true)
        doc.gpsSource = "fresh"
        XCTAssertNil(FieldPhotoUpload.gpsBadgeLabel(for: doc))
    }

    func test_gpsBadgeLabel_returnsNilForLegacy() {
        let doc = sampleDoc(withGPS: false)
        XCTAssertNil(FieldPhotoUpload.gpsBadgeLabel(for: doc))
    }
}
