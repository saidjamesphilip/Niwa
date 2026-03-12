import Foundation
import SwiftData

@Model
final class NiwaTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int
    var createdAt: Date

    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.completedAt = nil
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
