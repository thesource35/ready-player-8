import XCTest
@testable import ready_player_8

final class TeamServiceTests: XCTestCase {
    func testTeamMemberFormRejectsEmptyName() {
        let draft = TeamMemberDraft(kind: "internal", name: "  ", role: nil, trade: "Concrete")
        let result = draft.validate()
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.message.lowercased().contains("name"))
    }

    func testTeamMemberFormAcceptsValidInput() {
        let draft = TeamMemberDraft(kind: "internal", name: "Jane Foreman", role: "Foreman", trade: "Concrete")
        XCTAssertTrue(draft.validate().isValid)
    }

    func testTeamMemberFormRejectsBadKind() {
        let draft = TeamMemberDraft(kind: "ghost", name: "Jane", role: nil, trade: nil)
        XCTAssertFalse(draft.validate().isValid)
    }
}
