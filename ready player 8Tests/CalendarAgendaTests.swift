import XCTest
@testable import ready_player_8

// RED stub for Phase 17 Plan 04 (iOS calendar agenda).
//
// Plan 04 MUST create:
//   - AgendaViewModel (loads SupabaseProjectTask rows, exposes groupedByDay)
//   - SupabaseProjectTask DTO (SupabaseService.swift)
//   - SupabaseService.fetchProjectTasks(projectId:) async throws -> [SupabaseProjectTask]
//
// Target behavior:
//   func test_agendaGroupsItemsByDay() — instantiate AgendaViewModel with 5 mock
//   SupabaseProjectTask rows spanning 3 days; assert .groupedByDay.count == 3.
final class CalendarAgendaTests: XCTestCase {
    func test_agendaGroupsItemsByDay() {
        XCTFail("RED — implement in Plan 17-04: AgendaViewModel.groupedByDay must bucket 5 tasks across 3 days into 3 sections")
    }
}
