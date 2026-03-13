import AppKit
import SwiftData
import Observation

enum SoundEvent: String, CaseIterable {
    case timerComplete = "Timer Complete"
    case breakComplete = "Break Complete"
    case taskComplete = "Task Complete"
    case levelUp = "Level Up"
    case healthReminder = "Health Reminder"
    case xpEarned = "XP Earned"

    var icon: String {
        switch self {
        case .timerComplete: return "bell.fill"
        case .breakComplete: return "cup.and.saucer.fill"
        case .taskComplete: return "checkmark.circle.fill"
        case .levelUp: return "star.fill"
        case .healthReminder: return "heart.fill"
        case .xpEarned: return "sparkles"
        }
    }

    var options: [String] {
        switch self {
        case .timerComplete: return ["GentleBell", "DoubleChime", "WoodBlock"]
        case .breakComplete: return ["SoftDoubleTap", "RisingTone", "SoftPop"]
        case .taskComplete: return ["SoftPop", "StringPluck", "MicroDing"]
        case .levelUp: return ["GardenFanfare", "Bloom", "RisingTone"]
        case .healthReminder: return ["WaterDrop", "GardenBird", "SoftTick"]
        case .xpEarned: return ["TinyShimmer", "MicroDing", "SoftTick"]
        }
    }

    /// Human-readable display name for a sound file name
    static func displayName(for sound: String) -> String {
        // Convert camelCase to spaced: "GentleBell" → "Gentle Bell"
        var result = ""
        for char in sound {
            if char.isUppercase && !result.isEmpty {
                result += " "
            }
            result += String(char)
        }
        return result
    }
}

@MainActor
@Observable
final class SoundManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func play(_ event: SoundEvent) {
        guard let profile = fetchProfile(), profile.soundsEnabled else { return }

        let soundName: String
        switch event {
        case .timerComplete: soundName = profile.soundTimerComplete
        case .breakComplete: soundName = profile.soundBreakComplete
        case .taskComplete: soundName = profile.soundTaskComplete
        case .levelUp: soundName = profile.soundLevelUp
        case .healthReminder: soundName = profile.soundHealthReminder
        case .xpEarned: soundName = profile.soundXPEarned
        }

        playBundledSound(soundName)
    }

    func preview(_ soundName: String) {
        playBundledSound(soundName)
    }

    func soundName(for event: SoundEvent) -> String {
        guard let profile = fetchProfile() else { return event.options[0] }
        switch event {
        case .timerComplete: return profile.soundTimerComplete
        case .breakComplete: return profile.soundBreakComplete
        case .taskComplete: return profile.soundTaskComplete
        case .levelUp: return profile.soundLevelUp
        case .healthReminder: return profile.soundHealthReminder
        case .xpEarned: return profile.soundXPEarned
        }
    }

    func setSound(for event: SoundEvent, to soundName: String) {
        guard let profile = fetchProfile() else { return }
        switch event {
        case .timerComplete: profile.soundTimerComplete = soundName
        case .breakComplete: profile.soundBreakComplete = soundName
        case .taskComplete: profile.soundTaskComplete = soundName
        case .levelUp: profile.soundLevelUp = soundName
        case .healthReminder: profile.soundHealthReminder = soundName
        case .xpEarned: profile.soundXPEarned = soundName
        }
        try? modelContext.save()
    }

    func volume() -> Double {
        fetchProfile()?.soundVolume ?? 0.7
    }

    func setVolume(_ value: Double) {
        guard let profile = fetchProfile() else { return }
        profile.soundVolume = max(0, min(1, value))
        try? modelContext.save()
    }

    private func playBundledSound(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "aiff") else {
            print("[SoundManager] Sound file not found: \(name).aiff")
            return
        }
        if let sound = NSSound(contentsOf: url, byReference: true) {
            sound.volume = Float(fetchProfile()?.soundVolume ?? 0.7)
            sound.play()
        }
    }

    private func fetchProfile() -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? modelContext.fetch(descriptor).first
    }
}
