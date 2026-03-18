import Foundation
import EventKit
import SwiftData
import Observation

@MainActor
@Observable
final class CalendarManager {
    private let eventStore = EKEventStore()
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private var refreshTimer: Timer?

    private(set) var todayEvents: [EKEvent] = []
    private(set) var isAuthorized: Bool = false
    private(set) var authorizationDenied: Bool = false
    private(set) var pendingReview: EKEvent?

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine

        checkAuthorization()
        startRefreshTimer()
        observeCalendarChanges()
    }

    // MARK: - Authorization

    func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthorized = granted
                self.authorizationDenied = !granted
                if granted {
                    self.refreshEvents()
                }
            }
        }
    }

    private func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            isAuthorized = true
            refreshEvents()
        case .denied, .restricted:
            authorizationDenied = true
        case .notDetermined:
            break
        case .writeOnly:
            authorizationDenied = true
        @unknown default:
            break
        }
    }

    /// Reset calendar state so the Meetings tab shows the empty/permission state again.
    func resetState() {
        todayEvents = []
        pendingReview = nil
        isAuthorized = false
        authorizationDenied = false
        checkAuthorization()
    }

    // MARK: - Event Fetching

    func refreshEvents() {
        guard isAuthorized else { return }

        let dayStart = XPConstants.habitDayStart()
        let calendar = Calendar.current
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let predicate = eventStore.predicateForEvents(
            withStart: dayStart,
            end: dayEnd,
            calendars: nil
        )

        todayEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        updatePendingReview()
    }

    // MARK: - Event Categorization

    var upcomingEvents: [EKEvent] {
        let now = Date()
        return todayEvents.filter { $0.startDate > now }
    }

    var currentEvents: [EKEvent] {
        let now = Date()
        return todayEvents.filter { $0.startDate <= now && $0.endDate > now }
    }

    var pastEvents: [EKEvent] {
        let now = Date()
        return todayEvents.filter { $0.endDate <= now }
    }

    var meetingsReviewedThisWeek: Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        let descriptor = FetchDescriptor<MeetingReview>(
            predicate: #Predicate { $0.reviewedAt >= sevenDaysAgo }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    // MARK: - Meeting Reviews

    func review(for eventIdentifier: String) -> MeetingReview? {
        let descriptor = FetchDescriptor<MeetingReview>(
            predicate: #Predicate { $0.eventIdentifier == eventIdentifier }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func hasReview(for eventIdentifier: String) -> Bool {
        review(for: eventIdentifier) != nil
    }

    func submitRating(for event: EKEvent, rating: Int) {
        let identifier = event.eventIdentifier ?? ""
        guard !identifier.isEmpty else { return }

        if let existing = review(for: identifier) {
            guard !existing.ratingXPAwarded else { return }
            existing.ratingXPAwarded = true
            try? modelContext.save()
        } else {
            let meetingReview = MeetingReview(
                eventIdentifier: identifier,
                rating: rating,
                eventTitle: event.title ?? "Untitled"
            )
            meetingReview.ratingXPAwarded = true
            modelContext.insert(meetingReview)
            try? modelContext.save()
        }

        gamificationEngine.awardXP(source: .meeting, amount: XPConstants.meetingRate, context: modelContext)
        updatePendingReview()
    }

    func submitNotes(for eventIdentifier: String, notes: String) {
        guard !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let existing = review(for: eventIdentifier) else { return }
        guard !existing.notesXPAwarded else { return }

        existing.notes = notes
        existing.notesXPAwarded = true
        try? modelContext.save()

        gamificationEngine.awardXP(source: .meeting, amount: XPConstants.meetingNotes, context: modelContext)
    }

    // MARK: - Pending Review

    private func updatePendingReview() {
        let now = Date()
        let thirtyMinAgo = now.addingTimeInterval(-30 * 60)

        pendingReview = pastEvents
            .filter { event in
                guard let endDate = event.endDate, endDate >= thirtyMinAgo else { return false }
                let identifier = event.eventIdentifier ?? ""
                return !identifier.isEmpty && !hasReview(for: identifier)
            }
            .last
    }

    // MARK: - Refresh Timer

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEvents()
            }
        }
    }

    private func observeCalendarChanges() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEvents()
            }
        }
    }
}
