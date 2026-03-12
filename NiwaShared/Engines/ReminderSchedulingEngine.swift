import Foundation

enum ReminderSchedulingEngine {
    /// Compute the next fire date for a reminder given current time and config.
    static func nextFireDate(
        now: Date = Date(),
        intervalMinutes: Int,
        workStartHour: Int,
        workStartMinute: Int,
        workEndHour: Int,
        workEndMinute: Int,
        lunchStartHour: Int,
        lunchStartMinute: Int,
        lunchEndHour: Int,
        lunchEndMinute: Int,
        snoozedUntil: Date? = nil
    ) -> Date {
        // If snoozed, use snooze time
        if let snooze = snoozedUntil, snooze > now {
            return snooze
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute

        let workStart = workStartHour * 60 + workStartMinute
        let workEnd = workEndHour * 60 + workEndMinute
        let lunchStart = lunchStartHour * 60 + lunchStartMinute
        let lunchEnd = lunchEndHour * 60 + lunchEndMinute

        // Before work hours → schedule at work start
        if currentMinutes < workStart {
            return calendar.date(
                bySettingHour: workStartHour,
                minute: workStartMinute + intervalMinutes,
                second: 0,
                of: now
            ) ?? now.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }

        // After work hours → schedule at tomorrow's work start + interval
        if currentMinutes >= workEnd {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            return calendar.date(
                bySettingHour: workStartHour,
                minute: workStartMinute + intervalMinutes,
                second: 0,
                of: tomorrow
            ) ?? now.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }

        // During lunch → schedule at lunch end + interval
        if currentMinutes >= lunchStart && currentMinutes < lunchEnd {
            return calendar.date(
                bySettingHour: lunchEndHour,
                minute: lunchEndMinute + intervalMinutes,
                second: 0,
                of: now
            ) ?? now.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }

        // Normal: now + interval
        let nextDate = now.addingTimeInterval(TimeInterval(intervalMinutes * 60))

        // Check if next fire would land in lunch — if so, push past lunch
        let nextHour = calendar.component(.hour, from: nextDate)
        let nextMinute = calendar.component(.minute, from: nextDate)
        let nextMinutes = nextHour * 60 + nextMinute
        if nextMinutes >= lunchStart && nextMinutes < lunchEnd {
            return calendar.date(
                bySettingHour: lunchEndHour,
                minute: lunchEndMinute + intervalMinutes,
                second: 0,
                of: now
            ) ?? nextDate
        }

        return nextDate
    }
}
