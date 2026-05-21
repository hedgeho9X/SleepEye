import XCTest
@testable import SleepEyeCore

@MainActor
final class DailyStatsStoreTests: XCTestCase {
    func testLoadsExistingStatsForSameDay() {
        let suiteName = "DailyStatsStoreTests.sameDay.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let date = makeDate(year: 2026, month: 5, day: 22)
        let store = DailyStatsStore(defaults: defaults, calendar: .gregorianUTC, now: date)
        store.recordFocusCompleted(duration: TimeInterval(25 * 60), now: date)
        store.recordBreakCompleted(duration: TimeInterval(5 * 60), now: date)

        let reloaded = DailyStatsStore(defaults: defaults, calendar: .gregorianUTC, now: date)

        XCTAssertEqual(reloaded.completedFocusSessions, 1)
        XCTAssertEqual(reloaded.completedBreaks, 1)
        XCTAssertEqual(reloaded.totalFocusSeconds, TimeInterval(25 * 60))
        XCTAssertEqual(reloaded.totalBreakSeconds, TimeInterval(5 * 60))
    }

    func testResetsStatsWhenDayChanges() {
        let suiteName = "DailyStatsStoreTests.dayChange.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstDay = makeDate(year: 2026, month: 5, day: 22)
        let secondDay = makeDate(year: 2026, month: 5, day: 23)
        let store = DailyStatsStore(defaults: defaults, calendar: .gregorianUTC, now: firstDay)
        store.recordFocusCompleted(now: firstDay)

        let reloaded = DailyStatsStore(defaults: defaults, calendar: .gregorianUTC, now: secondDay)

        XCTAssertEqual(reloaded.completedFocusSessions, 0)
        XCTAssertEqual(reloaded.completedBreaks, 0)
        XCTAssertEqual(reloaded.totalFocusSeconds, 0)
        XCTAssertEqual(reloaded.totalBreakSeconds, 0)
    }

    func testCurrentSnapshotResetsAtMidnightWithoutNewRecords() {
        let suiteName = "DailyStatsStoreTests.midnight.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstDay = makeDate(year: 2026, month: 5, day: 22)
        let secondDay = makeDate(year: 2026, month: 5, day: 23)
        let store = DailyStatsStore(defaults: defaults, calendar: .gregorianUTC, now: firstDay)
        store.recordFocusCompleted(duration: TimeInterval(20 * 60), now: firstDay)

        let snapshot = store.currentSnapshot(now: secondDay)

        XCTAssertEqual(snapshot.completedFocusSessions, 0)
        XCTAssertEqual(snapshot.totalFocusSeconds, 0)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        DateComponents(
            calendar: .gregorianUTC,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        ).date!
    }
}

private extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
