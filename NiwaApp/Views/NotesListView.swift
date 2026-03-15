import SwiftUI
import SwiftData

struct NotesListView: View {
    let noteManager: NoteManager
    var contentMaxHeight: CGFloat = 600

    @State private var expandedNoteId: UUID?
    @State private var editingContent = ""
    @State private var newNoteContent = ""
    @State private var showAllNotes = false
    @FocusState private var isAddFieldFocused: Bool
    @FocusState private var isEditorFocused: Bool

    private let visibleLimit = 7

    private static let noteColors: [Color] = [
        Color(red: 224/255, green: 122/255, blue: 95/255),  // Terracotta (primary)
        Color(red: 129/255, green: 178/255, blue: 154/255), // Sage (secondary)
        Color(red: 168/255, green: 130/255, blue: 196/255), // Lavender
        Color(red: 224/255, green: 172/255, blue: 58/255),  // Amber
        Color(red: 100/255, green: 165/255, blue: 210/255), // Sky
    ]

    private func noteColor(for note: NiwaNote) -> Color {
        Self.noteColors[note.colorIndex % Self.noteColors.count]
    }

    private var visibleNotes: [NiwaNote] {
        if showAllNotes || noteManager.notes.count <= visibleLimit {
            return noteManager.notes
        }
        return Array(noteManager.notes.prefix(visibleLimit))
    }

    private var hiddenCount: Int {
        max(0, noteManager.notes.count - visibleLimit)
    }

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
                        expandNote(note)
                    }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()
                .padding(.horizontal, DesignTokens.Spacing.md)

            if noteManager.notes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(visibleNotes, id: \.id) { note in
                            if expandedNoteId == note.id {
                                expandedNoteRow(note)
                            } else {
                                collapsedNoteRow(note)
                            }
                        }

                        // Show more
                        if !showAllNotes && hiddenCount > 0 {
                            Button {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    showAllNotes = true
                                }
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                    Text("Show \(hiddenCount) more")
                                        .font(DesignTokens.Typography.captionFont)
                                }
                                .foregroundStyle(DesignTokens.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.xs)
                            }
                            .buttonStyle(.plain)
                        }

                        // Show less
                        if showAllNotes && noteManager.notes.count > visibleLimit {
                            Button {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    showAllNotes = false
                                }
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 9))
                                    Text("Show less")
                                        .font(DesignTokens.Typography.captionFont)
                                }
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.xs)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .frame(height: contentMaxHeight)
            }
        }
    }

    // MARK: - Collapsed Note Row

    private func collapsedNoteRow(_ note: NiwaNote) -> some View {
        NoteRowView(
            note: note,
            color: noteColor(for: note),
            onTap: { expandNote(note) },
            onDelete: { noteManager.deleteNote(note) }
        )
    }

    // MARK: - Expanded Note (Inline Editor)

    private func expandedNoteRow(_ note: NiwaNote) -> some View {
        VStack(spacing: 0) {
            // Editor area
            TextEditor(text: $editingContent)
                .font(DesignTokens.Typography.bodyFont)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .frame(minHeight: 60, maxHeight: 160)
                .focused($isEditorFocused)

            // Toolbar
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("\(editingContent.split(separator: " ").count) words")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.textMuted)

                Text("·")
                    .foregroundStyle(DesignTokens.Colors.textMuted)

                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.textMuted)

                Spacer()

                Button {
                    saveAndCollapse(note)
                } label: {
                    Text("Done")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(DesignTokens.Colors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(DesignTokens.Colors.backgroundSecondary.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .strokeBorder(noteColor(for: note).opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(noteColor(for: note))
                .frame(width: 3)
                .padding(.vertical, 4)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .onAppear { isEditorFocused = true }
    }

    // MARK: - Actions

    private func expandNote(_ note: NiwaNote) {
        withAnimation(DesignTokens.Animation.viewTransition) {
            // Save previous expanded note if any
            if let currentId = expandedNoteId,
               let currentNote = noteManager.notes.first(where: { $0.id == currentId }) {
                if editingContent != currentNote.content {
                    noteManager.updateNote(currentNote, content: editingContent)
                }
            }
            expandedNoteId = note.id
            editingContent = note.content
        }
    }

    private func saveAndCollapse(_ note: NiwaNote) {
        if editingContent != note.content {
            noteManager.updateNote(note, content: editingContent)
        }
        withAnimation(DesignTokens.Animation.viewTransition) {
            expandedNoteId = nil
            editingContent = ""
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            PlantView(level: 0)
                .scaleEffect(0.45)
                .frame(width: 40, height: 40)
                .opacity(0.6)

            Text("Jot down a thought to help your garden grow")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Note Row View (with color bar)

private struct NoteRowView: View {
    let note: NiwaNote
    let color: Color
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
                // Color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 28)

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
                            .foregroundStyle(DesignTokens.Colors.danger.opacity(0.6))
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
