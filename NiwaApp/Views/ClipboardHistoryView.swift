import SwiftUI
import SwiftData

struct ClipboardHistoryView: View {
    @Query(sort: \ClipboardEntry.copiedAt, order: .reverse) private var entries: [ClipboardEntry]

    let clipboardMonitor: ClipboardMonitor

    var body: some View {
        if entries.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(entries, id: \.id) { entry in
                        ClipboardRowView(entry: entry, clipboardMonitor: clipboardMonitor)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.vertical, DesignTokens.Spacing.xs)
            }
            .frame(maxHeight: 300)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "clipboard")
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.5))
            Text("Copy something to see it here")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }
}

private struct ClipboardRowView: View {
    let entry: ClipboardEntry
    let clipboardMonitor: ClipboardMonitor

    @State private var isHovering = false
    @State private var justCopied = false

    private var preview: String {
        let trimmed = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(100))
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(entry.copiedAt)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return entry.copiedAt.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        Button {
            clipboardMonitor.reCopy(entry)
            withAnimation(.easeInOut(duration: 0.15)) {
                justCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { justCopied = false }
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preview)
                        .font(DesignTokens.Typography.bodyFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(timeAgo)
                        if entry.text.count > 50 {
                            Text("·")
                            Text("\(entry.text.count) chars")
                        }
                    }
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                }

                Spacer()

                if justCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: isHovering ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
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
        .accessibilityLabel("Copy: \(entry.text.prefix(30))")
    }
}
