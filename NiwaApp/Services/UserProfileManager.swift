import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class UserProfileManager {
    /// Exposed read-only for data export. Use service methods for mutations.
    let modelContext: ModelContext
    private(set) var cachedProfile: UserProfile?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cachedProfile = Self.fetchProfile(from: modelContext)
    }

    var profile: UserProfile? { cachedProfile }

    func isWithinWorkHours(date: Date = Date()) -> Bool {
        guard let profile else { return false }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let current = hour * 60 + minute
        let start = profile.workHoursStartHour * 60 + profile.workHoursStartMinute
        let end = profile.workHoursEndHour * 60 + profile.workHoursEndMinute
        return current >= start && current < end
    }

    func isLunchTime(date: Date = Date()) -> Bool {
        guard let profile else { return false }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let current = hour * 60 + minute
        let start = profile.lunchStartHour * 60 + profile.lunchStartMinute
        let end = profile.lunchEndHour * 60 + profile.lunchEndMinute
        return current >= start && current < end
    }

    func save() {
        try? modelContext.save()
    }

    /// Re-fetch profile from store (call after reset)
    func reload() {
        cachedProfile = Self.fetchProfile(from: modelContext)
    }

    /// Delete all data and create a fresh UserProfile. Returns true on success.
    func resetAllData() -> Bool {
        do {
            try modelContext.delete(model: NiwaTask.self)
            try modelContext.delete(model: NiwaNote.self)
            try modelContext.delete(model: TimerSession.self)
            try modelContext.delete(model: HealthEvent.self)
            try modelContext.delete(model: XPEvent.self)
            try modelContext.delete(model: MeetingReview.self)
            try modelContext.delete(model: UserProfile.self)
            modelContext.insert(UserProfile())
            try modelContext.save()
            reload()
            return true
        } catch {
            return false
        }
    }

    /// Seed demo tasks and a welcome note for first-launch or post-reset.
    func seedDemoContent() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)

        let task1 = NiwaTask(title: "Try completing a task for +15 XP", sortOrder: 0, priority: .high, dueDate: today)
        let task2 = NiwaTask(title: "Start a focus timer to earn XP", sortOrder: 1, priority: .medium, dueDate: tomorrow)
        let task3 = NiwaTask(title: "Log a health habit below", sortOrder: 2, priority: .low, dueDate: nextWeek)
        modelContext.insert(task1)
        modelContext.insert(task2)
        modelContext.insert(task3)

        let demoNote = NiwaNote(
            content: "Welcome to Niwa! Use notes to jot down quick thoughts. Your garden grows as you stay productive.",
            colorIndex: 0
        )
        modelContext.insert(demoNote)
        try? modelContext.save()
    }

    private static func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? context.fetch(descriptor).first
    }
}
