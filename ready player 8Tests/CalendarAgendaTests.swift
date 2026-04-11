import XCTest
@testable import ready_player_8

// GREEN test for Phase 17 Plan 04 (iOS calendar agenda).
//
// Verifies AgendaViewModel.groupByDay buckets tasks correctly by their start_date.
// Uses the pure grouping function directly to avoid MainActor/simulator host issues.
final class CalendarAgendaTests: XCTestCase {

    func test_agendaGroupsItemsByDay() {
        // 5 tasks spanning 3 distinct days
        let tasks: [SupabaseProjectTask] = [
            makeTask(id: "1", name: "Foundation", startDate: "2026-04-10", endDate: "2026-04-14"),
            makeTask(id: "2", name: "Grading", startDate: "2026-04-10", endDate: "2026-04-12"),
            makeTask(id: "3", name: "Steel", startDate: "2026-04-12", endDate: "2026-04-18"),
            makeTask(id: "4", name: "Plumbing", startDate: "2026-04-12", endDate: "2026-04-15"),
            makeTask(id: "5", name: "Electrical", startDate: "2026-04-15", endDate: "2026-04-20"),
        ]

        let items: [AgendaItem] = tasks.map { .task($0) }

        // Use the static grouping helper to avoid @MainActor ViewModel instantiation
        let grouped = AgendaGroupingHelper.groupByDay(items)

        XCTAssertEqual(grouped.count, 3, "5 tasks across 3 days should produce 3 day sections")

        // Verify days are sorted ascending
        let days = grouped.map { $0.day }
        XCTAssertEqual(days, ["2026-04-10", "2026-04-12", "2026-04-15"])

        // Verify item counts per day
        XCTAssertEqual(grouped[0].items.count, 2, "April 10 should have 2 tasks")
        XCTAssertEqual(grouped[1].items.count, 2, "April 12 should have 2 tasks")
        XCTAssertEqual(grouped[2].items.count, 1, "April 15 should have 1 task")
    }

    func test_agendaItemDateString() {
        let task = makeTask(id: "1", name: "Test", startDate: "2026-05-01", endDate: "2026-05-03")
        let item = AgendaItem.task(task)
        XCTAssertEqual(item.dateString, "2026-05-01")
        XCTAssertEqual(item.title, "Test")
    }

    // MARK: - Helpers

    private func makeTask(
        id: String,
        name: String,
        startDate: String,
        endDate: String,
        trade: String? = nil,
        percentComplete: Int = 0,
        isCritical: Bool = false
    ) -> SupabaseProjectTask {
        SupabaseProjectTask(
            id: id,
            org_id: "org-1",
            project_id: "proj-1",
            name: name,
            trade: trade,
            start_date: startDate,
            end_date: endDate,
            duration_days: nil,
            percent_complete: percentComplete,
            is_critical: isCritical,
            created_by: nil,
            created_at: nil,
            updated_by: nil,
            updated_at: nil
        )
    }
}
