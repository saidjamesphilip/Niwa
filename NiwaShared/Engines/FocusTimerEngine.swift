import Foundation
import SwiftData
import Observation

enum FocusTimerState: Equatable {
    case idle
    case focusing
    case complete
}

@MainActor
@Observable
final class FocusTimerEngine {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine

    private(set) var state: FocusTimerState = .idle
    private(set) var selectedMinutes: Int = 25
    private(set) var remainingSeconds: TimeInterval = 0
    private(set) var totalDuration: TimeInterval = 0
    private(set) var todayCompletedSessions: Int = 0
    private(set) var lastAwardedXP: Int = 0

    private(set) var presets: [Int] = XPConstants.defaultFocusPresets

    private var sessionStartDate: Date?
    private var currentSession: TimerSession?
    private var displayTimer: Timer?
    private var completeResetTask: Task<Void, Never>?

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalDuration)
    }

    var formattedTime: String {
        let total = Int(remainingSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        loadSettings()
        loadTodayCount()
        resumeIncompleteSession()
    }

    // MARK: - Controls

    func start(minutes: Int) {
        guard state == .idle else { return }
        selectedMinutes = minutes
        let duration = TimeInterval(minutes * 60)

        let session = TimerSession(type: .focus, duration: duration, durationMinutes: minutes)
        modelContext.insert(session)
        try? modelContext.save()

        currentSession = session
        sessionStartDate = Date()
        totalDuration = duration
        remainingSeconds = duration
        state = .focusing
        startDisplayTimer()
    }

    func cancel() {
        guard state == .focusing else { return }
        currentSession?.wasSkipped = true
        currentSession?.completedAt = Date()
        try? modelContext.save()
        resetToIdle()
    }

    /// Force-reset to idle regardless of current state (used by Reset All Data)
    func forceReset() {
        if let session = currentSession, session.completedAt == nil {
            session.wasSkipped = true
            session.completedAt = Date()
            try? modelContext.save()
        }
        resetToIdle()
        todayCompletedSessions = 0
        lastAwardedXP = 0
        loadSettings()
    }

    // MARK: - Session Completion

    private func completeSession() {
        guard let session = currentSession else { return }

        session.completedAt = Date()
        try? modelContext.save()

        let xp = session.durationMinutes * XPConstants.focusXPPerMinute
        gamificationEngine.awardXP(source: .timer, amount: xp, context: modelContext)

        lastAwardedXP = xp
        todayCompletedSessions += 1
        stopDisplayTimer()
        state = .complete

        completeResetTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                resetToIdle()
            }
        }
    }

    private func resetToIdle() {
        completeResetTask?.cancel()
        completeResetTask = nil
        state = .idle
        stopDisplayTimer()
        sessionStartDate = nil
        currentSession = nil
        remainingSeconds = 0
        totalDuration = 0
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func updateRemainingTime() {
        guard let startDate = sessionStartDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, totalDuration - elapsed)
        remainingSeconds = remaining
        if remaining <= 0 {
            completeSession()
        }
    }

    // MARK: - Persistence

    private func resumeIncompleteSession() {
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { $0.completedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        guard let session = try? modelContext.fetch(descriptor).first else { return }

        guard session.typeRaw == "focus" else {
            session.wasSkipped = true
            session.completedAt = Date()
            try? modelContext.save()
            return
        }

        let elapsed = Date().timeIntervalSince(session.startedAt)
        let remaining = session.duration - elapsed

        if remaining > 0 {
            currentSession = session
            sessionStartDate = session.startedAt
            totalDuration = session.duration
            remainingSeconds = remaining
            selectedMinutes = session.durationMinutes
            state = .focusing
            startDisplayTimer()
        } else {
            session.completedAt = Date()
            if !session.wasSkipped {
                let xp = session.durationMinutes * XPConstants.focusXPPerMinute
                gamificationEngine.awardXP(source: .timer, amount: xp, context: modelContext)
                todayCompletedSessions += 1
            }
            try? modelContext.save()
        }
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        presets = profile.focusPresetMinutes
    }

    private func loadTodayCount() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let focusRaw = "focus"
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate {
                $0.completedAt != nil &&
                $0.wasSkipped == false &&
                $0.typeRaw == focusRaw &&
                $0.completedAt! >= startOfDay
            }
        )
        todayCompletedSessions = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
