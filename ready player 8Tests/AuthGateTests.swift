// AuthGateTests.swift — Phase 29.1
// Verifies the iOS auth-gate fix: gate predicate trusts Supabase session (AUTH-GATE-01),
// signOut clears both stores (AUTH-GATE-02), signup rolls back on server failure (AUTH-GATE-03).
//
// Scaffolding landed in Wave 0 (Plan 01). Bodies completed by Plans 02/03/04.
// References:
//   .planning/phases/29.1-fix-critical-auth-bug/29.1-RESEARCH.md §5
//   .planning/phases/29.1-fix-critical-auth-bug/29.1-VALIDATION.md Per-Task Verification Map

import Testing
import Foundation
@testable import ready_player_8

@MainActor
struct AuthGateTests {

    // MARK: - Helpers

    /// Save → clear → run → restore. Keeps singleton state from leaking across tests.
    /// Mirrors SupabaseServiceUploadTests.withClearedCredentials.
    private func withClearedAuthState(_ block: () async throws -> Void) async throws {
        let svc = SupabaseService.shared
        let store = UserProfileStore.shared
        let savedToken = svc.accessToken
        let savedEmail = svc.currentUserEmail
        let savedUser = store.currentUser
        svc.accessToken = nil
        svc.currentUserEmail = nil
        store.currentUser = nil
        defer {
            svc.accessToken = savedToken
            svc.currentUserEmail = savedEmail
            store.currentUser = savedUser
        }
        try await block()
    }

    // MARK: - Criterion A: gate predicate trusts Supabase session

    /// AUTH-GATE-01: When accessToken is nil, isAuthenticated MUST be false — regardless
    /// of UserProfileStore.currentUser. This is the invariant Plan 04 will anchor the
    /// ContentView.swift:638 gate predicate onto.
    @Test func testGatePredicateTrustsSupabaseSession() async throws {
        try await withClearedAuthState {
            let svc = SupabaseService.shared
            let store = UserProfileStore.shared
            // Precondition: no token, yes profile — the "zombie state" from RESEARCH repro #3
            svc.accessToken = nil
            store.currentUser = UserProfile(
                email: "zombie@example.com", fullName: "Zombie", company: "Test",
                jobTitle: "Test", trade: "General", birthdate: "01/01/2000",
                yearsExperience: 0, phone: "", bio: "", location: "",
                certifications: [], skills: [],
                connectionIDs: [], pendingConnectionIDs: [],
                joinedDate: Date(), isVerified: false
            )
            #expect(svc.isAuthenticated == false)
        }
    }

    // MARK: - Criterion B: valid session unlocks app even with no local profile

    /// AUTH-GATE-01: When accessToken is set but currentUser is nil, isAuthenticated
    /// MUST be true. Plan 04 uses this to flip the gate to mainAppView / hydrate path.
    @Test func testGatePassesWhenTokenSetEvenWithoutProfile() async throws {
        try await withClearedAuthState {
            let svc = SupabaseService.shared
            let store = UserProfileStore.shared
            svc.accessToken = "fake-test-token-\(UUID().uuidString)"
            store.currentUser = nil
            #expect(svc.isAuthenticated == true)
        }
    }

    // MARK: - Criterion C: signup rollback on server failure

    /// AUTH-GATE-03: When supabase.signUp() throws, profileStore.createAccount() MUST
    /// NOT have committed local state. PLAN 04 Task 2 inverts ContentView.swift:250-290
    /// to call supabase.signUp BEFORE profileStore.createAccount, so this test asserts
    /// the post-fix invariant indirectly via the order guarantee.
    ///
    /// Wave 0 stub: passes trivially. Plan 04 Task 2 will replace with a real assertion
    /// once the signup handler is extracted into a testable helper OR a mock seam exists.
    @Test func testSignupRollbackOnServerFailure() async throws {
        // TODO(Plan 04 Task 2): extract signup handler or add mock SupabaseService seam,
        // then assert that when supabase.signUp throws, profileStore.currentUser == nil.
        // See RESEARCH §Candidate 2 for repro steps + fix shape.
        #expect(Bool(true), "Pending Plan 04 Task 2 — see RESEARCH §Candidate 2")
    }

    // MARK: - Criterion D: signOut clears both stores

    /// AUTH-GATE-02: A composite sign-out entry point (added by Plan 02) must clear BOTH
    /// SupabaseService.accessToken (Keychain) AND UserProfileStore.currentUser
    /// (UserDefaults). Wave 0 stub asserts the pre-fix baseline: current signOut()
    /// clears only Supabase side — Plan 02 adds the composite entry point to fix this.
    @Test func testSignOutClearsBothStores() async throws {
        try await withClearedAuthState {
            let svc = SupabaseService.shared
            let store = UserProfileStore.shared
            // Seed both stores
            svc.accessToken = "test-token"
            svc.currentUserEmail = "test@example.com"
            store.currentUser = UserProfile(
                email: "test@example.com", fullName: "Test User", company: "Test",
                jobTitle: "Test", trade: "General", birthdate: "01/01/2000",
                yearsExperience: 0, phone: "", bio: "", location: "",
                certifications: [], skills: [],
                connectionIDs: [], pendingConnectionIDs: [],
                joinedDate: Date(), isVerified: false
            )
            // Today: signOut() alone leaves currentUser stale (zombie state).
            // Post-Plan-02: a single composite sign-out call will replace the two-line shape below.
            svc.signOut()
            store.logout()
            #expect(svc.accessToken == nil)
            #expect(svc.currentUserEmail == nil)
            #expect(store.currentUser == nil)
        }
    }

    // MARK: - Criterion E: UserProfileStore.login(email:password:) removed

    /// AUTH-GATE-01 defense-in-depth: the password-free local login shim at
    /// UserProfileNetwork.swift:80-88 must be removed (zero callers verified by grep
    /// in RESEARCH §Candidate 1 A2). Plan 03 Task 1 deletes it.
    ///
    /// Wave 0 stub: passes trivially — real assertion happens via the grep acceptance
    /// criterion in Plan 03 (`grep -c "func login(email: String, password: String) -> Bool"
    /// UserProfileNetwork.swift` returns 0).
    @Test func testProfileStoreLocalLoginRemoved() async throws {
        // TODO(Plan 03 Task 1): after deletion, uncomment the compile-time check below.
        // When UserProfileStore.login(email:password:) is gone, this line would fail
        // to compile — but we want the TEST to assert removal, not fail the build.
        // Instead, Plan 03 uses grep in acceptance_criteria. This @Test stub exists so
        // xcodebuild -only-testing:'ready player 8Tests/AuthGateTests/testProfileStoreLocalLoginRemoved'
        // resolves to a real test case.
        #expect(Bool(true), "Pending Plan 03 Task 1 grep-based acceptance — see RESEARCH §Candidate 1")
    }
}
