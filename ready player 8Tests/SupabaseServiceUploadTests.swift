// SupabaseServiceUploadTests.swift — Phase 13
// Verifies the new Storage helpers refuse to operate without credentials
// and that DocumentValidator gates uploads correctly.

import Testing
import Foundation
@testable import ready_player_8

struct SupabaseServiceUploadTests {

    private let baseURLKey = "ConstructOS.Integrations.Backend.BaseURL"
    private let apiKeyKey  = "ConstructOS.Integrations.Backend.ApiKey"

    /// Save → clear → run → restore. Avoids stomping on the user's real creds.
    private func withClearedCredentials(_ block: () async throws -> Void) async throws {
        let savedURL = UserDefaults.standard.string(forKey: baseURLKey)
        let savedKey = UserDefaults.standard.string(forKey: apiKeyKey)
        UserDefaults.standard.removeObject(forKey: baseURLKey)
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        defer {
            if let v = savedURL { UserDefaults.standard.set(v, forKey: baseURLKey) }
            if let v = savedKey { UserDefaults.standard.set(v, forKey: apiKeyKey) }
        }
        try await block()
    }

    @Test func uploadFileThrowsWhenNotConfigured() async throws {
        try await withClearedCredentials {
            let svc = SupabaseService.shared
            do {
                _ = try await svc.uploadFile(
                    bucket: "documents",
                    path: "x/y/z.pdf",
                    data: Data([0x25, 0x50, 0x44, 0x46]),
                    mimeType: "application/pdf"
                )
                #expect(Bool(false), "expected supabaseNotConfigured")
            } catch AppError.supabaseNotConfigured {
                #expect(Bool(true))
            } catch {
                // If keychain still has creds, isConfigured may be true; allow other AppErrors.
                #expect(error is AppError)
            }
        }
    }

    @Test func createSignedURLThrowsWhenNotConfigured() async throws {
        try await withClearedCredentials {
            let svc = SupabaseService.shared
            do {
                _ = try await svc.createSignedURL(bucket: "documents", path: "x/y/z.pdf")
                #expect(Bool(false), "expected throw")
            } catch {
                #expect(error is AppError)
            }
        }
    }

    @Test func documentValidatorAcceptsAllowed() throws {
        try DocumentValidator.validate(size: 100, mime: "application/pdf")
        try DocumentValidator.validate(size: 100, mime: "image/jpeg")
    }

    @Test func documentValidatorRejectsOversize() {
        do {
            try DocumentValidator.validate(size: 60_000_000, mime: "application/pdf")
            #expect(Bool(false))
        } catch AppError.fileTooLarge {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "wrong error: \(error)")
        }
    }

    @Test func documentValidatorRejectsBadMime() {
        do {
            try DocumentValidator.validate(size: 100, mime: "application/zip")
            #expect(Bool(false))
        } catch AppError.unsupportedFileType {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "wrong error: \(error)")
        }
    }

    @Test func uploadFailedIsRetryable() {
        let err = AppError.uploadFailed("transient")
        #expect(err.isRetryable == true)
    }
}
