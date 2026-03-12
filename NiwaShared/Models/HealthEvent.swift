import Foundation
import SwiftData

enum HealthEventType: String, Codable {
    case water
    case stand
}

@Model
final class HealthEvent {
    var id: UUID
    var typeRaw: String
    var confirmedAt: Date?
    var snoozedUntil: Date?
    var standingStartedAt: Date?
    var standingDuration: TimeInterval?

    var type: HealthEventType {
        get { HealthEventType(rawValue: typeRaw) ?? .water }
        set { typeRaw = newValue.rawValue }
    }

    init(type: HealthEventType) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.confirmedAt = nil
        self.snoozedUntil = nil
        self.standingStartedAt = nil
        self.standingDuration = nil
    }
}
