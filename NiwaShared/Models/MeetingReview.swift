import Foundation
import SwiftData

@Model
final class MeetingReview {
    var id: UUID
    @Attribute(.unique) var eventIdentifier: String
    var rating: Int
    var notes: String
    var ratingXPAwarded: Bool
    var notesXPAwarded: Bool
    var reviewedAt: Date
    var eventTitle: String

    init(eventIdentifier: String, rating: Int, eventTitle: String) {
        self.id = UUID()
        self.eventIdentifier = eventIdentifier
        self.rating = rating
        self.notes = ""
        self.ratingXPAwarded = false
        self.notesXPAwarded = false
        self.reviewedAt = Date()
        self.eventTitle = eventTitle
    }
}
