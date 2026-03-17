import SwiftUI

enum ContentTab: String, CaseIterable {
    case tasks = "Tasks"
    case notes = "Notes"
    case meetings = "Meetings"
}

struct ContentTabView: View {
    let taskManager: TaskManager
    let noteManager: NoteManager
    let calendarManager: CalendarManager

    var contentMaxHeight: CGFloat = 600

    @State private var selectedTab: ContentTab = .tasks

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control
            HStack(spacing: 0) {
                ForEach(ContentTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(DesignTokens.Typography.captionFont)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? DesignTokens.Colors.primary
                                    : DesignTokens.Colors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .background(
                                selectedTab == tab
                                    ? DesignTokens.Colors.backgroundSecondary
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.xs)

            Divider()
                .background(DesignTokens.Colors.subtle)

            // Tab content
            switch selectedTab {
            case .tasks:
                TaskListView(taskManager: taskManager, contentMaxHeight: contentMaxHeight)
            case .notes:
                NotesListView(noteManager: noteManager, contentMaxHeight: contentMaxHeight)
            case .meetings:
                MeetingsListView(calendarManager: calendarManager, contentMaxHeight: contentMaxHeight)
            }
        }
    }
}
