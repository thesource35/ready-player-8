import XCTest
@testable import ready_player_8

// RED stub for Phase 17 Plan 04 (iOS tap-to-reschedule).
//
// Plan 04 MUST create:
//   - TaskDetailSheet (SwiftUI sheet with start/end date pickers)
//   - SupabaseService.patchProjectTask(id:start:end:) async throws
//
// Target behavior:
//   func test_tapToRescheduleSendsPatch() — mock SupabaseService.patchProjectTask,
//   simulate sheet save with newStart/newEnd, assert patchProjectTask called once
//   with matching id + dates.
final class CalendarRescheduleTests: XCTestCase {
    func test_tapToRescheduleSendsPatch() {
        XCTFail("RED — implement in Plan 17-04: TaskDetailSheet save must call SupabaseService.patchProjectTask once with the new start/end")
    }
}
