import SwiftUI

struct NoteEditorView: View {
    let note: NiwaNote
    let noteManager: NoteManager
    let onBack: () -> Void

    @State private var content: String
    @FocusState private var isEditing: Bool

    init(note: NiwaNote, noteManager: NoteManager, onBack: @escaping () -> Void) {
        self.note = note
        self.noteManager = noteManager
        self.onBack = onBack
        self._content = State(initialValue: note.content)
    }

    private var wordCount: Int {
        content.split(separator: " ").count
    }

    private var charCount: Int {
        content.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: save) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Notes")
                            .font(DesignTokens.Typography.captionFont)
                    }
                    .foregroundStyle(DesignTokens.Colors.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text("\(wordCount) words")
                    Text("·")
                    Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()
                .padding(.horizontal, DesignTokens.Spacing.md)

            TextEditor(text: $content)
                .font(DesignTokens.Typography.bodyFont)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .frame(maxHeight: 260)
                .focused($isEditing)
                .onAppear { isEditing = true }
        }
        .onDisappear {
            saveContent()
        }
    }

    private func save() {
        saveContent()
        onBack()
    }

    private func saveContent() {
        if content != note.content {
            noteManager.updateNote(note, content: content)
        }
    }
}
