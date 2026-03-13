import Foundation
import SwiftData

@Model
final class NiwaNote {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var colorIndex: Int

    init(content: String = "", colorIndex: Int = 0) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.colorIndex = colorIndex
    }
}
