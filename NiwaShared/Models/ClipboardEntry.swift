import Foundation
import SwiftData

@Model
final class ClipboardEntry {
    var id: UUID
    var text: String
    var copiedAt: Date

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.copiedAt = Date()
    }
}
