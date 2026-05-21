import XCTest
@testable import SleepEyeCore

final class TimerCoreTests: XCTestCase {
    func testStartFocusUsesPresetDuration() {
        let start = Date(timeIntervalSince1970: 1_000)
        let core = TimerCore()

        core.startFocus(preset: .pomodoro, now: start)

        let snapshot = core.snapshot(now: start.addingTimeInterval(10))
        XCTAssertEqual(snapshot.phase, .focusing)
        XCTAssertEqual(snapshot.sessionKind, .focus)
        XCTAssertEqual(snapshot.remainingSeconds, TimerPreset.pomodoro.focusDuration - 10)
        XCTAssertEqual(snapshot.completedFocusSessions, 0)
    }

    func testFocusCompletionStartsBreakAndCountsOneFocusSession() {
        let start = Date(timeIntervalSince1970: 2_000)
        let core = TimerCore(selectedPreset: .eyeCare)
        core.startFocus(now: start)

        let event = core.tick(now: start.addingTimeInterval(TimerPreset.eyeCare.focusDuration))

        XCTAssertEqual(event, .focusCompleted)
        let snapshot = core.snapshot(now: start.addingTimeInterval(TimerPreset.eyeCare.focusDuration))
        XCTAssertEqual(snapshot.phase, .resting)
        XCTAssertEqual(snapshot.sessionKind, .rest)
        XCTAssertEqual(snapshot.remainingSeconds, TimerPreset.eyeCare.breakDuration)
        XCTAssertEqual(snapshot.completedFocusSessions, 1)
    }

    func testPauseAndResumeKeepRemainingTimeStable() {
        let start = Date(timeIntervalSince1970: 3_000)
        let core = TimerCore(selectedPreset: .pomodoro)
        core.startFocus(now: start)

        core.pause(now: start.addingTimeInterval(60))
        XCTAssertEqual(core.snapshot(now: start.addingTimeInterval(120)).phase, .paused)
        XCTAssertEqual(core.snapshot(now: start.addingTimeInterval(120)).remainingSeconds, TimerPreset.pomodoro.focusDuration - 60)

        core.resume(now: start.addingTimeInterval(300))
        let snapshot = core.snapshot(now: start.addingTimeInterval(360))
        XCTAssertEqual(snapshot.phase, .focusing)
        XCTAssertEqual(snapshot.remainingSeconds, TimerPreset.pomodoro.focusDuration - 120)
    }

    func testExtendingRunningBreakAdjustsTotalDurationAndProgress() {
        let start = Date(timeIntervalSince1970: 3_500)
        let core = TimerCore(selectedPreset: .eyeCare)
        core.startBreak(now: start)

        core.extendCurrentSession(by: 60)

        let snapshot = core.snapshot(now: start.addingTimeInterval(10))
        XCTAssertEqual(snapshot.phase, .resting)
        XCTAssertEqual(snapshot.remainingSeconds, TimerPreset.eyeCare.breakDuration + 50)
        XCTAssertEqual(snapshot.totalSeconds, TimerPreset.eyeCare.breakDuration + 60)
        XCTAssertEqual(snapshot.progress, 10 / (TimerPreset.eyeCare.breakDuration + 60), accuracy: 0.0001)
    }

    func testExtendingPausedSessionAdjustsTotalDurationAndKeepsPausedState() {
        let start = Date(timeIntervalSince1970: 3_600)
        let core = TimerCore(selectedPreset: .pomodoro)
        core.startFocus(now: start)

        core.pause(now: start.addingTimeInterval(120))
        core.extendCurrentSession(by: 60)

        let snapshot = core.snapshot(now: start.addingTimeInterval(300))
        XCTAssertEqual(snapshot.phase, .paused)
        XCTAssertEqual(snapshot.remainingSeconds, TimerPreset.pomodoro.focusDuration - 60)
        XCTAssertEqual(snapshot.totalSeconds, TimerPreset.pomodoro.focusDuration + 60)
    }

    func testBreakCompletionAutoStartsNextFocusWhenEnabled() {
        let start = Date(timeIntervalSince1970: 4_000)
        let core = TimerCore(selectedPreset: .eyeCare, autoStartNextRound: true)
        core.startBreak(now: start)

        let event = core.tick(now: start.addingTimeInterval(TimerPreset.eyeCare.breakDuration))

        XCTAssertEqual(event, .breakCompleted)
        XCTAssertEqual(core.snapshot(now: start.addingTimeInterval(TimerPreset.eyeCare.breakDuration)).phase, .focusing)
    }

    func testBreakCompletionStopsWhenAutoStartIsDisabled() {
        let start = Date(timeIntervalSince1970: 5_000)
        let core = TimerCore(selectedPreset: .eyeCare, autoStartNextRound: false)
        core.startBreak(now: start)

        let event = core.tick(now: start.addingTimeInterval(TimerPreset.eyeCare.breakDuration))

        XCTAssertEqual(event, .breakCompleted)
        XCTAssertEqual(core.snapshot(now: start.addingTimeInterval(TimerPreset.eyeCare.breakDuration)).phase, .idle)
    }
}
