import Foundation

/// 某一天的统计记录。
///
/// `dateKey` 使用稳定的 `yyyy-MM-dd` 字符串，避免跨时区展示时重新解释日期导致历史错位。
/// 统计只记录本地使用结果，不包含任何个人身份信息。
public struct DailyStatsDay: Codable, Equatable, Identifiable, Sendable {
    public let dateKey: String
    public let completedFocusSessions: Int
    public let completedBreaks: Int
    public let totalFocusSeconds: TimeInterval
    public let totalBreakSeconds: TimeInterval

    public var id: String {
        dateKey
    }

    public init(
        dateKey: String,
        completedFocusSessions: Int,
        completedBreaks: Int,
        totalFocusSeconds: TimeInterval,
        totalBreakSeconds: TimeInterval
    ) {
        self.dateKey = dateKey
        self.completedFocusSessions = completedFocusSessions
        self.completedBreaks = completedBreaks
        self.totalFocusSeconds = totalFocusSeconds
        self.totalBreakSeconds = totalBreakSeconds
    }

    /// 用于补齐没有记录的日期，让趋势图能保持连续的 7 天横轴。
    public static func empty(dateKey: String) -> DailyStatsDay {
        DailyStatsDay(
            dateKey: dateKey,
            completedFocusSessions: 0,
            completedBreaks: 0,
            totalFocusSeconds: 0,
            totalBreakSeconds: 0
        )
    }
}

private extension DailyStatsDay {
    var hasActivity: Bool {
        completedFocusSessions > 0 ||
            completedBreaks > 0 ||
            totalFocusSeconds > 0 ||
            totalBreakSeconds > 0
    }
}

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
        static let history = "dailyStatsHistory"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private var currentDateKey: String
    private var history: [String: DailyStatsDay]

    public private(set) var completedFocusSessions: Int
    public private(set) var completedBreaks: Int
    public private(set) var totalFocusSeconds: TimeInterval
    public private(set) var totalBreakSeconds: TimeInterval

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: Date = Date()) {
        self.defaults = defaults
        self.calendar = calendar
        history = Self.loadHistory(from: defaults)

        let todayKey = Self.dateKey(for: now, calendar: calendar)
        let storedDateKey = defaults.string(forKey: Keys.dateKey)
        currentDateKey = todayKey

        // 旧版本只保存“当前日”字段。升级后先把旧字段合并进历史，避免用户当天数据丢失。
        if let storedDateKey {
            let legacyDay = Self.legacyDay(from: defaults, dateKey: storedDateKey)
            if legacyDay.hasActivity {
                history[storedDateKey] = legacyDay
            }
        }

        let today = history[todayKey] ?? .empty(dateKey: todayKey)
        completedFocusSessions = today.completedFocusSessions
        completedBreaks = today.completedBreaks
        totalFocusSeconds = today.totalFocusSeconds
        totalBreakSeconds = today.totalBreakSeconds
        persist()
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

    /// 返回连续的最近若干天统计，按时间从旧到新排序。
    ///
    /// 没有记录的日期会补零，避免趋势图因为缺少某天而横轴跳动。
    public func recentDays(count: Int, endingAt date: Date = Date()) -> [DailyStatsDay] {
        guard count > 0 else {
            return []
        }

        ensureToday(now: date)
        let endOfRange = calendar.startOfDay(for: date)

        return (0..<count).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: endOfRange) else {
                return nil
            }

            let key = Self.dateKey(for: day, calendar: calendar)
            return history[key] ?? .empty(dateKey: key)
        }
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
        guard currentDateKey != todayKey else {
            return
        }

        history[currentDateKey] = currentDay
        currentDateKey = todayKey

        let today = history[todayKey] ?? .empty(dateKey: todayKey)
        completedFocusSessions = today.completedFocusSessions
        completedBreaks = today.completedBreaks
        totalFocusSeconds = today.totalFocusSeconds
        totalBreakSeconds = today.totalBreakSeconds
        persist()
    }

    private func persist() {
        history[currentDateKey] = currentDay
        persistHistory()
        defaults.set(currentDateKey, forKey: Keys.dateKey)
        defaults.set(completedFocusSessions, forKey: Keys.completedFocusSessions)
        defaults.set(completedBreaks, forKey: Keys.completedBreaks)
        defaults.set(totalFocusSeconds, forKey: Keys.totalFocusSeconds)
        defaults.set(totalBreakSeconds, forKey: Keys.totalBreakSeconds)
    }

    private var currentDay: DailyStatsDay {
        DailyStatsDay(
            dateKey: currentDateKey,
            completedFocusSessions: completedFocusSessions,
            completedBreaks: completedBreaks,
            totalFocusSeconds: totalFocusSeconds,
            totalBreakSeconds: totalBreakSeconds
        )
    }

    private func persistHistory() {
        guard let data = try? JSONEncoder().encode(Array(history.values)) else {
            return
        }

        defaults.set(data, forKey: Keys.history)
    }

    private static func loadHistory(from defaults: UserDefaults) -> [String: DailyStatsDay] {
        guard
            let data = defaults.data(forKey: Keys.history),
            let days = try? JSONDecoder().decode([DailyStatsDay].self, from: data)
        else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: days.map { ($0.dateKey, $0) })
    }

    private static func legacyDay(from defaults: UserDefaults, dateKey: String) -> DailyStatsDay {
        DailyStatsDay(
            dateKey: dateKey,
            completedFocusSessions: defaults.integer(forKey: Keys.completedFocusSessions),
            completedBreaks: defaults.integer(forKey: Keys.completedBreaks),
            totalFocusSeconds: defaults.double(forKey: Keys.totalFocusSeconds),
            totalBreakSeconds: defaults.double(forKey: Keys.totalBreakSeconds)
        )
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
