import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class NoteManager {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private var appErrorState: AppErrorState?

    private(set) var notes: [NiwaNote] = []

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine, appErrorState: AppErrorState) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        self.appErrorState = appErrorState
        refreshNotes()
    }

    static let noteColorCount = 5

    func createNote(content: String = "") -> NiwaNote {
        let nextColor = ((notes.first?.colorIndex ?? -1) + 1) % Self.noteColorCount
        let note = NiwaNote(content: content, colorIndex: nextColor)
        modelContext.insert(note)
        save()
        gamificationEngine.awardXP(source: .note, amount: XPConstants.noteCreate, context: modelContext)
        refreshNotes()
        return note
    }

    func updateNote(_ note: NiwaNote, content: String) {
        note.content = content
        note.updatedAt = Date()
        save()
        refreshNotes()
    }

    func deleteNote(_ note: NiwaNote) {
        modelContext.delete(note)
        save()
        refreshNotes()
    }

    func refreshNotes() {
        let descriptor = FetchDescriptor<NiwaNote>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        notes = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            // Retry once
            do {
                try modelContext.save()
            } catch {
                appErrorState?.showError("Unable to save notes. Please restart Niwa.")
                print("[NoteManager] Save failed after retry: \(error)")
            }
        }
    }
}
