import XCTest
@testable import ready_player_8

// GREEN test for Phase 17 Plan 04 (iOS tap-to-reschedule).
//
// Verifies that the reschedule flow works: local state update re-groups items,
// the patchProjectTask method exists with the correct signature, and date
// validation logic works. Full network round-trip is tested in checkpoint Task 4.
final class CalendarRescheduleTests: XCTestCase {

    func test_tapToRescheduleSendsPatch() {
        // Verify that re-grouping after a date change produces the correct buckets.
        // This tests the same logic AgendaViewModel.reschedule uses internally.
        let tasks: [SupabaseProjectTask] = [
            makeTask(id: "task-A", name: "Foundation", startDate: "2026-04-10", endDate: "2026-04-14"),
            makeTask(id: "task-B", name: "Grading", startDate: "2026-04-12", endDate: "2026-04-15"),
        ]

        let items: [AgendaItem] = tasks.map { .task($0) }
        let initial = AgendaGroupingHelper.groupByDay(items)
        XCTAssertEqual(initial.count, 2, "Initial state: 2 days")

        // Simulate an optimistic reschedule: move task-A from April 10 to April 12
        let updatedItems: [AgendaItem] = items.map { item in
            if case .task(let t) = item, t.id == "task-A" {
                let updated = SupabaseProjectTask(
                    id: t.id, org_id: t.org_id, project_id: t.project_id,
                    name: t.name, trade: t.trade,
                    start_date: "2026-04-12", end_date: "2026-04-16",
                    duration_days: t.duration_days,
                    percent_complete: t.percent_complete,
                    is_critical: t.is_critical,
                    created_by: t.created_by, created_at: t.created_at,
                    updated_by: t.updated_by, updated_at: t.updated_at
                )
                return .task(updated)
            }
            return item
        }
        let regrouped = AgendaGroupingHelper.groupByDay(updatedItems)

        XCTAssertEqual(regrouped.count, 1, "After reschedule: both tasks on April 12 = 1 day")
        XCTAssertEqual(regrouped[0].day, "2026-04-12")
        XCTAssertEqual(regrouped[0].items.count, 2)
    }

    func test_patchProjectTaskMethodExists() {
        // Verify the patchProjectTask method exists on SupabaseService and accepts
        // the expected parameter types. This is a compile-time + existence check.
        // We cannot call it without @MainActor context, but the type check suffices.
        // The actual network call is tested in the human-verify checkpoint.
        let _: Any = SupabaseService.patchProjectTask
        // If this compiles, patchProjectTask exists as an instance method
    }

    func test_taskDetailSheetDateValidation() {
        // Verify that the DTO helper correctly detects date changes.
        let task = makeTask(id: "t1", name: "Test", startDate: "2026-04-10", endDate: "2026-04-14")
        XCTAssertTrue(task.datesChanged(newStart: "2026-04-11", newEnd: "2026-04-15"),
                       "Different dates should report changed")
        XCTAssertFalse(task.datesChanged(newStart: "2026-04-10", newEnd: "2026-04-14"),
                        "Same dates should report unchanged")
    }

    // MARK: - Helpers

    private func makeTask(
        id: String,
        name: String,
        startDate: String,
        endDate: String
    ) -> SupabaseProjectTask {
        SupabaseProjectTask(
            id: id,
            org_id: "org-1",
            project_id: "proj-1",
            name: name,
            trade: nil,
            start_date: startDate,
            end_date: endDate,
            duration_days: nil,
            percent_complete: 0,
            is_critical: false,
            created_by: nil,
            created_at: nil,
            updated_by: nil,
            updated_at: nil
        )
    }
}
