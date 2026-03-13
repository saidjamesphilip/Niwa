import SwiftUI

enum ContentTab: String, CaseIterable {
    case tasks = "Tasks"
    case notes = "Notes"
}

struct ContentTabView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var noteManager: NoteManager

    @State private var selectedTab: ContentTab = .tasks

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control
            HStack(spacing: 0) {
                ForEach(ContentTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(DesignTokens.Animation.viewTransition) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(DesignTokens.Typography.captionFont)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? DesignTokens.Colors.primary
                                    : DesignTokens.Colors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                selectedTab == tab
                                    ? DesignTokens.Colors.backgroundSecondary
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
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
                TaskListView()
            case .notes:
                NotesListView()
            }
        }
    }
}
