import Foundation
import SwiftData

enum XPSource: String, Codable {
    case task
    case timer
    case note
    case water
    case stand
}

@Model
final class XPEvent {
    var id: UUID
    var sourceRaw: String
    var amount: Int
    var earnedAt: Date

    var source: XPSource {
        get { XPSource(rawValue: sourceRaw) ?? .task }
        set { sourceRaw = newValue.rawValue }
    }

    init(source: XPSource, amount: Int) {
        self.id = UUID()
        self.sourceRaw = source.rawValue
        self.amount = amount
        self.earnedAt = Date()
    }
}
