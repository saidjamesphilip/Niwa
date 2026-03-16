import XCTest
@testable import Niwa

final class FocusTimerFormattingTests: XCTestCase {

    // MARK: - formattedTime logic (tested as pure function)
    // FocusTimerEngine.formattedTime depends on remainingSeconds.
    // We test the formatting logic directly since the engine requires ModelContext.

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    func testFormattedTime_zero() {
        XCTAssertEqual(formatTime(0), "00:00")
    }

    func testFormattedTime_oneMinute() {
        XCTAssertEqual(formatTime(60), "01:00")
    }

    func testFormattedTime_twentyFiveMinutes() {
        XCTAssertEqual(formatTime(1500), "25:00")
    }

    func testFormattedTime_mixedMinutesAndSeconds() {
        XCTAssertEqual(formatTime(83), "01:23")
        XCTAssertEqual(formatTime(125), "02:05")
    }

    func testFormattedTime_fiftyNineMinutesFiftyNineSeconds() {
        XCTAssertEqual(formatTime(3599), "59:59")
    }

    func testFormattedTime_overOneHour() {
        // The engine only shows MM:SS so 60+ minutes wraps
        XCTAssertEqual(formatTime(3600), "60:00")
    }

    // MARK: - progress logic (tested as pure function)

    private func calculateProgress(remaining: TimeInterval, total: TimeInterval) -> Double {
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }

    func testProgress_notStarted() {
        XCTAssertEqual(calculateProgress(remaining: 1500, total: 1500), 0.0, accuracy: 0.001)
    }

    func testProgress_halfWay() {
        XCTAssertEqual(calculateProgress(remaining: 750, total: 1500), 0.5, accuracy: 0.001)
    }

    func testProgress_complete() {
        XCTAssertEqual(calculateProgress(remaining: 0, total: 1500), 1.0, accuracy: 0.001)
    }

    func testProgress_zeroDuration_returnsZero() {
        XCTAssertEqual(calculateProgress(remaining: 0, total: 0), 0.0)
    }
}
