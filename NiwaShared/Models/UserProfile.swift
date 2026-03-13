import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var totalXP: Int
    var currentLevel: Int

    // Work hours
    var workHoursStartHour: Int
    var workHoursStartMinute: Int
    var workHoursEndHour: Int
    var workHoursEndMinute: Int

    // Lunch window
    var lunchStartHour: Int
    var lunchStartMinute: Int
    var lunchEndHour: Int
    var lunchEndMinute: Int

    // Health reminders
    var healthRemindersEnabled: Bool
    var waterIntervalMinutes: Int
    var standIntervalMinutes: Int

    // Pomodoro
    var pomoDurationMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var sessionsBeforeLongBreak: Int

    // Floating window
    var floatingWindowEnabled: Bool
    var alwaysOnTop: Bool

    // Appearance: 0 = system, 1 = light, 2 = dark
    var appearanceMode: Int

    // Personalization
    var displayName: String
    var lastGreetingDate: Date?

    // Sounds
    var soundVolume: Double
    var soundsEnabled: Bool
    var soundTimerComplete: String
    var soundBreakComplete: String
    var soundTaskComplete: String
    var soundLevelUp: String
    var soundHealthReminder: String
    var soundXPEarned: String

    init() {
        self.id = UUID()
        self.totalXP = 0
        self.currentLevel = 0

        self.workHoursStartHour = XPConstants.defaultWorkStartHour
        self.workHoursStartMinute = XPConstants.defaultWorkStartMinute
        self.workHoursEndHour = XPConstants.defaultWorkEndHour
        self.workHoursEndMinute = XPConstants.defaultWorkEndMinute

        self.lunchStartHour = XPConstants.defaultLunchStartHour
        self.lunchStartMinute = XPConstants.defaultLunchStartMinute
        self.lunchEndHour = XPConstants.defaultLunchEndHour
        self.lunchEndMinute = XPConstants.defaultLunchEndMinute

        self.healthRemindersEnabled = true
        self.waterIntervalMinutes = XPConstants.defaultWaterIntervalMinutes
        self.standIntervalMinutes = XPConstants.defaultStandIntervalMinutes

        self.pomoDurationMinutes = XPConstants.defaultWorkMinutes
        self.shortBreakMinutes = XPConstants.defaultShortBreakMinutes
        self.longBreakMinutes = XPConstants.defaultLongBreakMinutes
        self.sessionsBeforeLongBreak = XPConstants.defaultSessionsBeforeLongBreak

        self.floatingWindowEnabled = false
        self.alwaysOnTop = false
        self.appearanceMode = 0

        self.displayName = ""
        self.lastGreetingDate = nil

        self.soundVolume = 0.7
        self.soundsEnabled = true
        self.soundTimerComplete = "GentleBell"
        self.soundBreakComplete = "SoftDoubleTap"
        self.soundTaskComplete = "SoftPop"
        self.soundLevelUp = "GardenFanfare"
        self.soundHealthReminder = "WaterDrop"
        self.soundXPEarned = "TinyShimmer"
    }
}
