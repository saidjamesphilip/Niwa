import Foundation
import SwiftData

enum SessionType: String, Codable {
    case work
    case shortBreak
    case longBreak
}

@Model
final class TimerSession {
    var id: UUID
    var typeRaw: String
    var duration: TimeInterval
    var startedAt: Date
    var completedAt: Date?
    var wasSkipped: Bool
    var pausedElapsed: TimeInterval

    var type: SessionType {
        get { SessionType(rawValue: typeRaw) ?? .work }
        set { typeRaw = newValue.rawValue }
    }

    init(type: SessionType, duration: TimeInterval) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.duration = duration
        self.startedAt = Date()
        self.completedAt = nil
        self.wasSkipped = false
        self.pausedElapsed = 0
    }
}
