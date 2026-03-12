import Foundation
import SwiftData

@Model
final class NiwaNote {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(content: String = "") {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
