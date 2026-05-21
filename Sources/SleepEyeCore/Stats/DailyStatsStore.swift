import Foundation

/// 当天统计数据的一份只读快照。
///
/// UI 层只消费快照，不直接理解 `UserDefaults` 的键名和日期切换规则。
/// 后续如果从 `UserDefaults` 迁到 JSON 或 SQLite，视图层可以保持稳定。
public struct DailyStatsSnapshot: Equatable, Sendable {
    public let completedFocusSessions: Int
    public let completedBreaks: Int
    public let totalFocusSeconds: TimeInterval
    public let totalBreakSeconds: TimeInterval

    public init(
        completedFocusSessions: Int,
        completedBreaks: Int,
        totalFocusSeconds: TimeInterval,
        totalBreakSeconds: TimeInterval
    ) {
        self.completedFocusSessions = completedFocusSessions
        self.completedBreaks = completedBreaks
        self.totalFocusSeconds = totalFocusSeconds
        self.totalBreakSeconds = totalBreakSeconds
    }
}

/// 持久化当天的轻量使用统计。
///
/// 统计不属于计时状态机本身：计时核心只负责阶段流转，今天完成了几轮、
/// 休息了几次、累计专注多久属于产品层数据。
/// 这里用 `UserDefaults` 保存，足够支撑本地工具的 MVP 统计展示。
@MainActor
public final class DailyStatsStore {
    private enum Keys {
        static let dateKey = "dailyStatsDateKey"
        static let completedFocusSessions = "dailyStatsCompletedFocusSessions"
        static let completedBreaks = "dailyStatsCompletedBreaks"
        static let totalFocusSeconds = "dailyStatsTotalFocusSeconds"
        static let totalBreakSeconds = "dailyStatsTotalBreakSeconds"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    public private(set) var completedFocusSessions: Int
    public private(set) var completedBreaks: Int
    public private(set) var totalFocusSeconds: TimeInterval
    public private(set) var totalBreakSeconds: TimeInterval

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: Date = Date()) {
        self.defaults = defaults
        self.calendar = calendar

        let todayKey = Self.dateKey(for: now, calendar: calendar)
        let storedDateKey = defaults.string(forKey: Keys.dateKey)

        if storedDateKey == todayKey {
            completedFocusSessions = defaults.integer(forKey: Keys.completedFocusSessions)
            completedBreaks = defaults.integer(forKey: Keys.completedBreaks)
            totalFocusSeconds = defaults.double(forKey: Keys.totalFocusSeconds)
            totalBreakSeconds = defaults.double(forKey: Keys.totalBreakSeconds)
        } else {
            completedFocusSessions = 0
            completedBreaks = 0
            totalFocusSeconds = 0
            totalBreakSeconds = 0
            defaults.set(todayKey, forKey: Keys.dateKey)
            persist()
        }
    }

    /// 当前统计快照。
    public var snapshot: DailyStatsSnapshot {
        DailyStatsSnapshot(
            completedFocusSessions: completedFocusSessions,
            completedBreaks: completedBreaks,
            totalFocusSeconds: totalFocusSeconds,
            totalBreakSeconds: totalBreakSeconds
        )
    }

    /// 返回指定时间对应的当天快照。
    ///
    /// 主界面会定期刷新，如果跨过午夜但用户没有完成新的轮次，也应该看到统计归零。
    public func currentSnapshot(now: Date = Date()) -> DailyStatsSnapshot {
        ensureToday(now: now)
        return snapshot
    }

    /// 记录一次自然完成的专注轮次。
    public func recordFocusCompleted(duration: TimeInterval = 0, now: Date = Date()) {
        ensureToday(now: now)
        completedFocusSessions += 1
        totalFocusSeconds += max(0, duration)
        persist()
    }

    /// 记录一次自然完成的休息。
    public func recordBreakCompleted(duration: TimeInterval = 0, now: Date = Date()) {
        ensureToday(now: now)
        completedBreaks += 1
        totalBreakSeconds += max(0, duration)
        persist()
    }

    private func ensureToday(now: Date) {
        let todayKey = Self.dateKey(for: now, calendar: calendar)
        guard defaults.string(forKey: Keys.dateKey) != todayKey else {
            return
        }

        completedFocusSessions = 0
        completedBreaks = 0
        totalFocusSeconds = 0
        totalBreakSeconds = 0
        defaults.set(todayKey, forKey: Keys.dateKey)
        persist()
    }

    private func persist() {
        defaults.set(completedFocusSessions, forKey: Keys.completedFocusSessions)
        defaults.set(completedBreaks, forKey: Keys.completedBreaks)
        defaults.set(totalFocusSeconds, forKey: Keys.totalFocusSeconds)
        defaults.set(totalBreakSeconds, forKey: Keys.totalBreakSeconds)
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
