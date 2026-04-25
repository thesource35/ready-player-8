// BackendConfigSheetTests.swift — Phase 30.1 (AUTH-GATE-04, backlog 999.3)
//
// Pure-logic tests for ContentView.swift's validateBaseURL() and
// classifyKeyPrefix() helpers added in Plan 30.1-01.
//
// Per Phase 22 / 29.1 / 30 precedent (see STATE.md), full
// `xcodebuild test` is blocked by pre-existing async errors in
// ready_player_8Tests.swift. This file is COMPILE-ONLY verified —
// the goal is that no errors reference this file in `xcodebuild build`.
// When the underlying test-target async errors are fixed, these tests
// will run on the existing CI workflow with no further changes.

import Testing
import Foundation
@testable import ready_player_8

struct BackendConfigSheetValidationTests {

    // MARK: - validateBaseURL: empty / whitespace

    @Test func emptyStringRejected() {
        switch validateBaseURL("") {
        case .failure(let err): #expect(err == .empty)
        case .success: Issue.record("Expected .failure(.empty)")
        }
    }

    @Test func whitespaceOnlyRejected() {
        switch validateBaseURL("   ") {
        case .failure(let err): #expect(err == .empty)
        case .success: Issue.record("Expected .failure(.empty) for whitespace-only input")
        }
    }

    // MARK: - validateBaseURL: malformed inputs

    @Test func nonURLRejected() {
        switch validateBaseURL("not a url") {
        case .failure(let err): #expect(err == .malformed)
        case .success: Issue.record("Expected .failure(.malformed)")
        }
    }

    @Test func nonHTTPSchemeRejected() {
        switch validateBaseURL("ftp://example.com") {
        case .failure(let err): #expect(err == .malformed)
        case .success: Issue.record("Expected .failure(.malformed) for ftp scheme")
        }
    }

    // MARK: - validateBaseURL: insecure scheme (T-30.1-04)

    @Test func httpNonLocalhostRejected() {
        switch validateBaseURL("http://evil.example.com") {
        case .failure(let err): #expect(err == .insecureScheme)
        case .success: Issue.record("Expected .failure(.insecureScheme) for http non-localhost (T4)")
        }
    }

    // MARK: - validateBaseURL: dev allowance for localhost

    @Test func httpLocalhostAccepted() {
        switch validateBaseURL("http://localhost:54321") {
        case .success(let url): #expect(url.host?.lowercased() == "localhost")
        case .failure(let err): Issue.record("Expected .success for http://localhost, got \(err)")
        }
    }

    @Test func httpLoopbackIPAccepted() {
        switch validateBaseURL("http://127.0.0.1:54321") {
        case .success(let url): #expect(url.host == "127.0.0.1")
        case .failure(let err): Issue.record("Expected .success for http://127.0.0.1, got \(err)")
        }
    }

    // MARK: - validateBaseURL: https accepted (production case)

    @Test func httpsSupabaseProjectAccepted() {
        switch validateBaseURL("https://abcd.supabase.co") {
        case .success(let url): #expect(url.host?.contains("supabase.co") == true)
        case .failure(let err): Issue.record("Expected .success for https://abcd.supabase.co, got \(err)")
        }
    }

    @Test func leadingTrailingWhitespaceTrimmedBeforeValidation() {
        switch validateBaseURL("  https://abcd.supabase.co  ") {
        case .success(let url): #expect(url.host?.contains("supabase.co") == true)
        case .failure(let err): Issue.record("Expected .success after trim, got \(err)")
        }
    }

    // MARK: - classifyKeyPrefix: nil-result cases

    @Test func typicalAnonJWTReturnsNil() {
        // Real-world Supabase anon keys are JWTs starting with "eyJhbGciOi..."
        let anonJWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbm9uIn0.signature"
        #expect(classifyKeyPrefix(anonJWT) == nil)
    }

    @Test func emptyKeyReturnsNil() {
        #expect(classifyKeyPrefix("") == nil)
    }

    // MARK: - classifyKeyPrefix: service-role detection (T-30.1-02)

    @Test func sbSecretPrefixDetected() {
        #expect(classifyKeyPrefix("sb_secret_abc123") == .serviceRoleSuspected)
    }

    @Test func serviceRoleSubstringDetected() {
        // A JWT decoded payload literally containing "service_role" should warn.
        let jwtLikeWithRole = "eyJrb2xlIjoic2VydmljZV9yb2xlIn0.payload.signature"
        #expect(classifyKeyPrefix(jwtLikeWithRole) == .serviceRoleSuspected)
    }
}
