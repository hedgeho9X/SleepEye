import Foundation

/// 持久化当天的轻量使用统计。
///
/// 统计不属于计时状态机本身：计时核心只负责阶段流转，今天完成了几轮、
/// 休息了几次属于产品层数据。这里用 `UserDefaults` 保存，足够支撑菜单栏里的轻量展示。
@MainActor
public final class DailyStatsStore {
    private enum Keys {
        static let dateKey = "dailyStatsDateKey"
        static let completedFocusSessions = "dailyStatsCompletedFocusSessions"
        static let completedBreaks = "dailyStatsCompletedBreaks"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    public private(set) var completedFocusSessions: Int
    public private(set) var completedBreaks: Int

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: Date = Date()) {
        self.defaults = defaults
        self.calendar = calendar

        let todayKey = Self.dateKey(for: now, calendar: calendar)
        let storedDateKey = defaults.string(forKey: Keys.dateKey)

        if storedDateKey == todayKey {
            completedFocusSessions = defaults.integer(forKey: Keys.completedFocusSessions)
            completedBreaks = defaults.integer(forKey: Keys.completedBreaks)
        } else {
            completedFocusSessions = 0
            completedBreaks = 0
            defaults.set(todayKey, forKey: Keys.dateKey)
            defaults.set(0, forKey: Keys.completedFocusSessions)
            defaults.set(0, forKey: Keys.completedBreaks)
        }
    }

    /// 记录一次自然完成的专注轮次。
    public func recordFocusCompleted(now: Date = Date()) {
        ensureToday(now: now)
        completedFocusSessions += 1
        defaults.set(completedFocusSessions, forKey: Keys.completedFocusSessions)
    }

    /// 记录一次自然完成的休息。
    public func recordBreakCompleted(now: Date = Date()) {
        ensureToday(now: now)
        completedBreaks += 1
        defaults.set(completedBreaks, forKey: Keys.completedBreaks)
    }

    private func ensureToday(now: Date) {
        let todayKey = Self.dateKey(for: now, calendar: calendar)
        guard defaults.string(forKey: Keys.dateKey) != todayKey else {
            return
        }

        completedFocusSessions = 0
        completedBreaks = 0
        defaults.set(todayKey, forKey: Keys.dateKey)
        defaults.set(0, forKey: Keys.completedFocusSessions)
        defaults.set(0, forKey: Keys.completedBreaks)
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
