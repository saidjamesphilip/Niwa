import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class UserProfileManager {
    let context: ModelContext
    private(set) var cachedProfile: UserProfile?

    init(modelContext: ModelContext) {
        self.context = modelContext
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
        try? context.save()
    }

    /// Re-fetch profile from store (call after reset)
    func reload() {
        cachedProfile = Self.fetchProfile(from: context)
    }

    private static func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? context.fetch(descriptor).first
    }
}
