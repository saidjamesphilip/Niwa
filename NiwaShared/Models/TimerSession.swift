import Foundation
import SwiftData

enum SessionType: String, Codable {
    case focus
}

@Model
final class TimerSession {
    var id: UUID
    var typeRaw: String
    var duration: TimeInterval
    var durationMinutes: Int
    var startedAt: Date
    var completedAt: Date?
    var wasSkipped: Bool

    var type: SessionType {
        get { SessionType(rawValue: typeRaw) ?? .focus }
        set { typeRaw = newValue.rawValue }
    }

    init(type: SessionType, duration: TimeInterval, durationMinutes: Int = 0) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.duration = duration
        self.durationMinutes = durationMinutes
        self.startedAt = Date()
        self.completedAt = nil
        self.wasSkipped = false
    }
}
