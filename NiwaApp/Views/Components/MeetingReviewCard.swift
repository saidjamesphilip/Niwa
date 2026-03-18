import SwiftUI

struct MeetingReviewCard: View {
    let eventTitle: String
    let onRate: (Int) -> Void
    let onSubmitNotes: (String) -> Void
    var onDismiss: (() -> Void)? = nil

    @State private var selectedRating: Int? = nil
    @State private var notes: String = ""
    @State private var showNotes: Bool = false
    @State private var notesSubmitted: Bool = false
    @State private var isComplete: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("\(eventTitle) just ended — how was it?")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            // Rating buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                ratingButton(rating: 0, icon: "😕", label: "Bad", color: DesignTokens.Colors.textMuted)
                ratingButton(rating: 1, icon: "😐", label: "OK", color: Color(red: 224/255, green: 172/255, blue: 58/255))
                ratingButton(rating: 2, icon: "😊", label: "Good", color: DesignTokens.Colors.secondary)
            }

            // Notes field (shown after rating)
            if showNotes && !notesSubmitted {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Quick notes...", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.plain)
                        .font(DesignTokens.Typography.captionFont)
                        .padding(DesignTokens.Spacing.sm)
                        .background(DesignTokens.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))

                    Button("Done") {
                        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onSubmitNotes(trimmed)
                            notesSubmitted = true
                        }
                    }
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? DesignTokens.Colors.textMuted
                        : DesignTokens.Colors.primary)
                    .buttonStyle(.plain)
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if notesSubmitted {
                Text("Notes saved +\(XPConstants.meetingNotes) XP")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .onAppear { scheduleAutoDismiss() }
            }

            // Skip notes — auto-dismiss after rating only
            if showNotes && !notesSubmitted && !isComplete {
                Button("Skip notes") {
                    isComplete = true
                    scheduleAutoDismiss()
                }
                .font(.system(size: 9))
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .opacity(isComplete ? 0.6 : 1.0)
    }

    private func scheduleAutoDismiss() {
        isComplete = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onDismiss?()
        }
    }

    private func ratingButton(rating: Int, icon: String, label: String, color: Color) -> some View {
        Button {
            guard selectedRating == nil else { return }
            selectedRating = rating
            showNotes = true
            onRate(rating)
        } label: {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(selectedRating == rating ? color : DesignTokens.Colors.textMuted)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                selectedRating == rating
                    ? color.opacity(0.15)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            .opacity(selectedRating != nil && selectedRating != rating ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(selectedRating != nil)
    }
}
