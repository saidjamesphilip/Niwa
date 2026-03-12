import Foundation
import SwiftData
import Observation

@Observable
final class NoteManager {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
    }

    func createNote(content: String = "") -> NiwaNote {
        let note = NiwaNote(content: content)
        modelContext.insert(note)
        try? modelContext.save()
        gamificationEngine.awardXP(source: .note, amount: XPConstants.noteCreate, context: modelContext)
        return note
    }

    func updateNote(_ note: NiwaNote, content: String) {
        note.content = content
        note.updatedAt = Date()
        try? modelContext.save()
    }

    func deleteNote(_ note: NiwaNote) {
        modelContext.delete(note)
        try? modelContext.save()
    }
}
