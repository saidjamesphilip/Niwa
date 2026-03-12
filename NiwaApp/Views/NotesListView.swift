import SwiftUI
import SwiftData

struct NotesListView: View {
    @Query(sort: \NiwaNote.updatedAt, order: .reverse) private var notes: [NiwaNote]

    let noteManager: NoteManager

    @State private var selectedNote: NiwaNote?
    @State private var newNoteContent = ""
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Quick-create
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .font(.system(size: 16))

                TextField("New note...", text: $newNoteContent)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Typography.bodyFont)
                    .focused($isAddFieldFocused)
                    .onSubmit {
                        guard !newNoteContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let note = noteManager.createNote(content: newNoteContent)
                        newNoteContent = ""
                        selectedNote = note
                    }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()
                .padding(.horizontal, DesignTokens.Spacing.md)

            if let selectedNote {
                NoteEditorView(
                    note: selectedNote,
                    noteManager: noteManager,
                    onBack: { self.selectedNote = nil }
                )
            } else if notes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(notes, id: \.id) { note in
                            noteRow(note)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "note.text")
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.5))
            Text("Jot down a quick thought")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }

    private func noteRow(_ note: NiwaNote) -> some View {
        NoteRowView(note: note, onTap: { selectedNote = note }, onDelete: { noteManager.deleteNote(note) })
    }
}

// Separate view for hover state
private struct NoteRowView: View {
    let note: NiwaNote
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private var preview: String {
        let trimmed = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Empty note" : String(trimmed.prefix(60))
    }

    private var wordCount: Int {
        note.content.split(separator: " ").count
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preview)
                        .font(DesignTokens.Typography.bodyFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        Text("·")
                        Text("\(wordCount) words")
                    }
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                }

                Spacer()

                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.Colors.textMuted.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(isHovering ? DesignTokens.Colors.backgroundSecondary.opacity(0.5) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
