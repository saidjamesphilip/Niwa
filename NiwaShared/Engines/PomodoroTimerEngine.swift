import Foundation
import SwiftData
import Observation

enum TimerState: Equatable {
    case idle
    case working
    case paused
    case shortBreak
    case longBreak
}

@Observable
final class PomodoroTimerEngine {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine

    private(set) var state: TimerState = .idle
    private(set) var completedWorkSessions: Int = 0

    // Date-based tracking (no drift)
    private var sessionStartDate: Date?
    private var pausedElapsed: TimeInterval = 0
    private var pauseStartDate: Date?
    private var currentSession: TimerSession?

    // UI update timer
    private var displayTimer: Timer?

    // Computed from UserProfile
    private(set) var workDuration: TimeInterval = TimeInterval(XPConstants.defaultWorkMinutes * 60)
    private(set) var shortBreakDuration: TimeInterval = TimeInterval(XPConstants.defaultShortBreakMinutes * 60)
    private(set) var longBreakDuration: TimeInterval = TimeInterval(XPConstants.defaultLongBreakMinutes * 60)
    private(set) var sessionsBeforeLongBreak: Int = XPConstants.defaultSessionsBeforeLongBreak

    // Observable for UI
    private(set) var remainingSeconds: TimeInterval = 0
    private(set) var totalDuration: TimeInterval = 0

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalDuration)
    }

    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        loadSettings()
        resumeIncompleteSession()
    }

    // MARK: - Controls

    func start() {
        guard state == .idle else { return }
        beginSession(type: .work, duration: workDuration)
    }

    func pause() {
        guard state == .working else { return }
        pauseStartDate = Date()
        state = .paused
        stopDisplayTimer()
    }

    func resume() {
        guard state == .paused, let pauseStart = pauseStartDate else { return }
        pausedElapsed += Date().timeIntervalSince(pauseStart)
        pauseStartDate = nil
        state = .working
        startDisplayTimer()
    }

    func skip() {
        if state == .working || state == .paused {
            currentSession?.wasSkipped = true
            currentSession?.completedAt = Date()
            try? modelContext.save()
        }
        resetToIdle()
    }

    // MARK: - Session Management

    private func beginSession(type: SessionType, duration: TimeInterval) {
        let session = TimerSession(type: type, duration: duration)
        modelContext.insert(session)
        try? modelContext.save()

        currentSession = session
        sessionStartDate = Date()
        pausedElapsed = 0
        pauseStartDate = nil
        totalDuration = duration
        remainingSeconds = duration

        switch type {
        case .work:
            state = .working
        case .shortBreak:
            state = .shortBreak
        case .longBreak:
            state = .longBreak
        }

        startDisplayTimer()
    }

    private func completeSession() {
        guard let session = currentSession else { return }

        session.completedAt = Date()
        try? modelContext.save()

        switch session.type {
        case .work:
            completedWorkSessions += 1
            gamificationEngine.awardXP(source: .timer, amount: XPConstants.pomodoroComplete, context: modelContext)

            // Determine next break
            if completedWorkSessions % sessionsBeforeLongBreak == 0 {
                beginSession(type: .longBreak, duration: longBreakDuration)
            } else {
                beginSession(type: .shortBreak, duration: shortBreakDuration)
            }

        case .shortBreak, .longBreak:
            resetToIdle()
        }
    }

    private func resetToIdle() {
        state = .idle
        stopDisplayTimer()
        sessionStartDate = nil
        pausedElapsed = 0
        pauseStartDate = nil
        currentSession = nil
        remainingSeconds = 0
        totalDuration = 0
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateRemainingTime()
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func updateRemainingTime() {
        guard let startDate = sessionStartDate else { return }

        let elapsed = Date().timeIntervalSince(startDate) - pausedElapsed
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

        let elapsed = Date().timeIntervalSince(session.startedAt) - session.pausedElapsed
        let remaining = session.duration - elapsed

        if remaining > 0 {
            currentSession = session
            sessionStartDate = session.startedAt
            pausedElapsed = session.pausedElapsed
            totalDuration = session.duration
            remainingSeconds = remaining

            switch session.type {
            case .work: state = .working
            case .shortBreak: state = .shortBreak
            case .longBreak: state = .longBreak
            }

            startDisplayTimer()
        } else {
            // Session expired while app was closed
            session.completedAt = Date()
            if session.type == .work && !session.wasSkipped {
                gamificationEngine.awardXP(source: .timer, amount: XPConstants.pomodoroComplete, context: modelContext)
                completedWorkSessions += 1
            }
            try? modelContext.save()
        }
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }

        workDuration = TimeInterval(profile.pomoDurationMinutes * 60)
        shortBreakDuration = TimeInterval(profile.shortBreakMinutes * 60)
        longBreakDuration = TimeInterval(profile.longBreakMinutes * 60)
        sessionsBeforeLongBreak = profile.sessionsBeforeLongBreak
    }

    deinit {
        displayTimer?.invalidate()
    }
}
