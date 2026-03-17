import SwiftUI
import EventKit

struct MeetingsListView: View {
    let calendarManager: CalendarManager
    let contentMaxHeight: CGFloat

    @State private var expandedReviewId: String?
    @State private var dismissedPendingId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !calendarManager.isAuthorized {
                    emptyStateNoAccess
                } else if calendarManager.todayEvents.isEmpty {
                    emptyStateNoMeetings
                } else {
                    meetingsList
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .frame(maxHeight: contentMaxHeight)
        .onAppear {
            if !calendarManager.isAuthorized && !calendarManager.authorizationDenied {
                calendarManager.requestAccess()
            }
        }
    }

    // MARK: - Meetings List

    @ViewBuilder
    private var meetingsList: some View {
        // Auto-prompt banner
        if let pending = calendarManager.pendingReview,
           let pendingId = pending.eventIdentifier,
           dismissedPendingId != pendingId,
           !calendarManager.hasReview(for: pendingId) {
            MeetingReviewCard(
                eventTitle: pending.title ?? "Meeting",
                onRate: { rating in
                    calendarManager.submitRating(for: pending, rating: rating)
                },
                onSubmitNotes: { notes in
                    calendarManager.submitNotes(for: pendingId, notes: notes)
                }
            )
            .padding(.bottom, DesignTokens.Spacing.sm)

            Button {
                dismissedPendingId = pendingId
            } label: {
                Text("Dismiss")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.bottom, DesignTokens.Spacing.sm)
        }

        // Current meetings
        let current = calendarManager.currentEvents
        if !current.isEmpty {
            sectionHeader("Now")
            ForEach(current, id: \.eventIdentifier) { event in
                meetingRow(event: event, state: .current)
            }
        }

        // Upcoming meetings
        let upcoming = calendarManager.upcomingEvents
        if !upcoming.isEmpty {
            sectionHeader("Upcoming")
            ForEach(upcoming, id: \.eventIdentifier) { event in
                meetingRow(event: event, state: .upcoming)
            }
        }

        // Past meetings
        let past = calendarManager.pastEvents
        if !past.isEmpty {
            sectionHeader("Earlier")
            ForEach(past, id: \.eventIdentifier) { event in
                let identifier = event.eventIdentifier ?? ""
                let reviewed = calendarManager.hasReview(for: identifier)

                VStack(spacing: 0) {
                    meetingRow(event: event, state: reviewed ? .reviewed : .pastUnreviewed)

                    if expandedReviewId == identifier && !reviewed {
                        MeetingReviewCard(
                            eventTitle: event.title ?? "Meeting",
                            onRate: { rating in
                                calendarManager.submitRating(for: event, rating: rating)
                            },
                            onSubmitNotes: { notes in
                                calendarManager.submitNotes(for: identifier, notes: notes)
                            }
                        )
                        .padding(.top, DesignTokens.Spacing.xs)
                    }
                }
            }
        }
    }

    // MARK: - Meeting Row

    private enum MeetingState {
        case upcoming, current, pastUnreviewed, reviewed
    }

    private func meetingRow(event: EKEvent, state: MeetingState) -> some View {
        let barColor: Color = switch state {
        case .upcoming: DesignTokens.Colors.secondary
        case .current: DesignTokens.Colors.primary
        case .pastUnreviewed: DesignTokens.Colors.textMuted
        case .reviewed: DesignTokens.Colors.textMuted
        }

        return HStack(spacing: DesignTokens.Spacing.sm) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(barColor)
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled")
                    .font(DesignTokens.Typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        state == .reviewed
                            ? DesignTokens.Colors.textMuted
                            : DesignTokens.Colors.textPrimary
                    )

                Text(timeLabel(for: event, state: state))
                    .font(.system(size: 10))
                    .foregroundStyle(
                        state == .current
                            ? DesignTokens.Colors.secondary
                            : DesignTokens.Colors.textMuted
                    )
            }

            Spacer()

            switch state {
            case .upcoming:
                if isSoon(event) {
                    Text("soon")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(DesignTokens.Colors.primary)
                        .clipShape(Capsule())
                }
            case .current:
                Circle()
                    .fill(DesignTokens.Colors.primary)
                    .frame(width: 6, height: 6)
            case .pastUnreviewed:
                Button {
                    let identifier = event.eventIdentifier ?? ""
                    expandedReviewId = expandedReviewId == identifier ? nil : identifier
                } label: {
                    Text("Review")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
                .buttonStyle(.plain)
            case .reviewed:
                if let identifier = event.eventIdentifier,
                   let rev = calendarManager.review(for: identifier) {
                    Text(ratingIcon(rev.rating))
                        .font(.system(size: 12))
                        .opacity(0.6)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .background(
            state == .current
                ? DesignTokens.Colors.backgroundSecondary
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(DesignTokens.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xs)
    }

    private func timeLabel(for event: EKEvent, state: MeetingState) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        switch state {
        case .current:
            let end = formatter.string(from: event.endDate)
            return "Now · ends at \(end)"
        case .upcoming:
            let start = formatter.string(from: event.startDate)
            let duration = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
            return "\(start) · \(duration) min"
        case .pastUnreviewed, .reviewed:
            let start = formatter.string(from: event.startDate)
            let end = formatter.string(from: event.endDate)
            return "\(start) – \(end)"
        }
    }

    private func isSoon(_ event: EKEvent) -> Bool {
        let now = Date()
        let diff = event.startDate.timeIntervalSince(now)
        return diff > 0 && diff <= 15 * 60
    }

    private func ratingIcon(_ rating: Int) -> String {
        switch rating {
        case 0: return "😕"
        case 1: return "😐"
        case 2: return "😊"
        default: return "😐"
        }
    }

    // MARK: - Empty States

    private var emptyStateNoAccess: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()
            PlantView(level: 0)
                .scaleEffect(0.45)
                .frame(width: 40, height: 40)
                .opacity(0.6)

            if calendarManager.authorizationDenied {
                Text("Connect your calendar in System Settings")
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                    .multilineTextAlignment(.center)

                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.primary)
                .buttonStyle(.plain)
            } else {
                Button("Tap to enable calendar access") {
                    calendarManager.requestAccess()
                }
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.primary)
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
    }

    private var emptyStateNoMeetings: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()
            PlantView(level: 0)
                .scaleEffect(0.45)
                .frame(width: 40, height: 40)
                .opacity(0.6)
            Text("No meetings today — focus time!")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
    }
}
