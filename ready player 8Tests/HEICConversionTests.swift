// HEICConversionTests.swift — Phase 13 Document Management
// Verifies HEICConverter round-trips a real HEIC fixture into JPEG bytes
// and that invalid input throws AppError.

import Testing
import Foundation
@testable import ready_player_8

struct HEICConversionTests {

    private func fixtureURL(_ name: String, ext: String) -> URL? {
        // Bundle.module is unavailable for this target (no resources block);
        // walk up from #file to find the Fixtures directory at runtime.
        let here = URL(fileURLWithPath: #filePath)
        let fixtures = here.deletingLastPathComponent().appendingPathComponent("Fixtures")
        let candidate = fixtures.appendingPathComponent("\(name).\(ext)")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    @Test func heicToJpegProducesJpegBytes() throws {
        guard let url = fixtureURL("sample", ext: "heic") else {
            // Fixture missing — skip rather than fail (CI environments may strip resources).
            return
        }
        let data = try Data(contentsOf: url)
        let jpeg = try HEICConverter.heicToJpeg(data)
        #expect(jpeg.count > 0)
        // JPEG SOI marker = 0xFF 0xD8
        let prefix = Array(jpeg.prefix(2))
        #expect(prefix == [0xFF, 0xD8])
    }

    @Test func heicToJpegThrowsOnGarbageInput() {
        do {
            _ = try HEICConverter.heicToJpeg(Data([0x00, 0x01, 0x02, 0x03]))
            #expect(Bool(false), "expected throw on invalid input")
        } catch is AppError {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "wrong error type: \(error)")
        }
    }

    @Test func documentValidatorAcceptsAllowedTypes() throws {
        try DocumentValidator.validate(size: 100, mime: "application/pdf")
        try DocumentValidator.validate(size: 100, mime: "image/jpeg")
        try DocumentValidator.validate(size: 100, mime: "image/heic")
    }

    @Test func documentValidatorRejectsOversize() {
        do {
            try DocumentValidator.validate(size: 60_000_000, mime: "application/pdf")
            #expect(Bool(false), "expected fileTooLarge")
        } catch AppError.fileTooLarge {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "wrong error: \(error)")
        }
    }

    @Test func documentValidatorRejectsBadMime() {
        do {
            try DocumentValidator.validate(size: 100, mime: "application/zip")
            #expect(Bool(false), "expected unsupportedFileType")
        } catch AppError.unsupportedFileType {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "wrong error: \(error)")
        }
    }
}
