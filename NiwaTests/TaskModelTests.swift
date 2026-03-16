import XCTest
@testable import Niwa

final class TaskModelTests: XCTestCase {

    // MARK: - TaskPriority

    func testTaskPriority_allCases() {
        XCTAssertEqual(TaskPriority.allCases.count, 4)
        XCTAssertEqual(TaskPriority.none.rawValue, 0)
        XCTAssertEqual(TaskPriority.low.rawValue, 1)
        XCTAssertEqual(TaskPriority.medium.rawValue, 2)
        XCTAssertEqual(TaskPriority.high.rawValue, 3)
    }

    func testTaskPriority_labels() {
        XCTAssertEqual(TaskPriority.none.label, "None")
        XCTAssertEqual(TaskPriority.low.label, "Low")
        XCTAssertEqual(TaskPriority.medium.label, "Medium")
        XCTAssertEqual(TaskPriority.high.label, "High")
    }

    func testTaskPriority_invalidRawValue_returnsNil() {
        XCTAssertNil(TaskPriority(rawValue: 5))
        XCTAssertNil(TaskPriority(rawValue: -1))
    }

    // MARK: - NiwaTask init

    func testNiwaTask_defaultInit() {
        let task = NiwaTask(title: "Test task")
        XCTAssertEqual(task.title, "Test task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertEqual(task.sortOrder, 0)
        XCTAssertEqual(task.priority, .none)
        XCTAssertNil(task.dueDate)
    }

    func testNiwaTask_customInit() {
        let task = NiwaTask(title: "Important", sortOrder: 3, priority: .high, dueDate: Date())
        XCTAssertEqual(task.title, "Important")
        XCTAssertEqual(task.sortOrder, 3)
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.priorityRaw, 3)
        XCTAssertNotNil(task.dueDate)
    }

    // MARK: - priority computed property

    func testPriority_getSet_roundTrip() {
        let task = NiwaTask(title: "Test")
        task.priority = .medium
        XCTAssertEqual(task.priorityRaw, 2)
        XCTAssertEqual(task.priority, .medium)

        task.priority = .high
        XCTAssertEqual(task.priorityRaw, 3)
        XCTAssertEqual(task.priority, .high)
    }

    // MARK: - isOverdue

    func testIsOverdue_noDueDate_returnsFalse() {
        let task = NiwaTask(title: "No deadline")
        XCTAssertFalse(task.isOverdue)
    }

    func testIsOverdue_futureDueDate_returnsFalse() {
        let future = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        let task = NiwaTask(title: "Future", dueDate: future)
        XCTAssertFalse(task.isOverdue)
    }

    func testIsOverdue_pastDueDate_returnsTrue() {
        let past = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        let task = NiwaTask(title: "Overdue", dueDate: past)
        XCTAssertTrue(task.isOverdue)
    }

    func testIsOverdue_completedTask_returnsFalse() {
        let past = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        let task = NiwaTask(title: "Done", dueDate: past)
        task.isCompleted = true
        XCTAssertFalse(task.isOverdue)
    }

    // MARK: - isDueToday

    func testIsDueToday_noDueDate_returnsFalse() {
        let task = NiwaTask(title: "No deadline")
        XCTAssertFalse(task.isDueToday)
    }

    func testIsDueToday_todayDueDate_returnsTrue() {
        let task = NiwaTask(title: "Today", dueDate: Date())
        XCTAssertTrue(task.isDueToday)
    }

    func testIsDueToday_futureDueDate_returnsFalse() {
        let future = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        let task = NiwaTask(title: "Future", dueDate: future)
        XCTAssertFalse(task.isDueToday)
    }

    func testIsDueToday_pastDueDate_returnsFalse() {
        let past = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        let task = NiwaTask(title: "Past", dueDate: past)
        XCTAssertFalse(task.isDueToday)
    }

    // MARK: - UUID uniqueness

    func testNiwaTask_uniqueIDs() {
        let task1 = NiwaTask(title: "A")
        let task2 = NiwaTask(title: "B")
        XCTAssertNotEqual(task1.id, task2.id)
    }
}
