import Combine
import Foundation
import SleepEyeCore

/// 管理 SleepEye 的本地设置。
///
/// 这里先使用 `UserDefaults`，因为 MVP 配置项少、数据结构简单，
/// 引入数据库只会增加迁移和维护成本。所有设置都保存在本机，不需要账号或后端。
@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let selectedPresetID = "selectedPresetID"
        static let autoStartNextRound = "autoStartNextRound"
        static let reminderStrength = "reminderStrength"
        static let customFocusMinutes = "customFocusMinutes"
        static let customBreakMinutes = "customBreakMinutes"
    }

    private enum Limits {
        static let focusMinutes = 1...180
        static let breakMinutes = 1...60
    }

    private let defaults: UserDefaults

    /// 当前选中的预设标识。只保存标识，不直接保存整个预设，避免内置预设文案变更时破坏兼容性。
    @Published var selectedPresetID: String {
        didSet {
            defaults.set(selectedPresetID, forKey: Keys.selectedPresetID)
        }
    }

    /// 休息结束后是否自动进入下一轮专注。
    ///
    /// 默认开启，让番茄钟形成自然循环；用户也可以关闭，休息结束后回到空闲。
    @Published var autoStartNextRound: Bool {
        didSet {
            defaults.set(autoStartNextRound, forKey: Keys.autoStartNextRound)
        }
    }

    /// 提醒强度。MVP 中只影响提醒表现，不做强制拦截。
    @Published var reminderStrength: ReminderStrength {
        didSet {
            defaults.set(reminderStrength.rawValue, forKey: Keys.reminderStrength)
        }
    }

    /// 用户自定义的每轮工作时长，单位为分钟。
    ///
    /// 使用分钟而不是秒，是因为设置页面向普通使用者；秒级配置后续可以作为高级选项再加。
    @Published var customFocusMinutes: Int {
        didSet {
            customFocusMinutes = Self.clamp(customFocusMinutes, to: Limits.focusMinutes)
            defaults.set(customFocusMinutes, forKey: Keys.customFocusMinutes)
        }
    }

    /// 用户自定义的每轮休息时长，单位为分钟。
    @Published var customBreakMinutes: Int {
        didSet {
            customBreakMinutes = Self.clamp(customBreakMinutes, to: Limits.breakMinutes)
            defaults.set(customBreakMinutes, forKey: Keys.customBreakMinutes)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        selectedPresetID = defaults.string(forKey: Keys.selectedPresetID) ?? TimerPreset.pomodoro.id

        if defaults.object(forKey: Keys.autoStartNextRound) == nil {
            autoStartNextRound = true
        } else {
            autoStartNextRound = defaults.bool(forKey: Keys.autoStartNextRound)
        }

        let strengthValue = defaults.string(forKey: Keys.reminderStrength) ?? ReminderStrength.standard.rawValue
        reminderStrength = ReminderStrength(rawValue: strengthValue) ?? .standard

        let storedFocusMinutes = defaults.object(forKey: Keys.customFocusMinutes) as? Int ?? 25
        let storedBreakMinutes = defaults.object(forKey: Keys.customBreakMinutes) as? Int ?? 5
        customFocusMinutes = Self.clamp(storedFocusMinutes, to: Limits.focusMinutes)
        customBreakMinutes = Self.clamp(storedBreakMinutes, to: Limits.breakMinutes)
    }

    /// 当前设置对应的计时预设。
    ///
    /// 自定义预设每次从最新设置生成，确保用户刚改完时长后，下一轮立即生效。
    var selectedPreset: TimerPreset {
        if selectedPresetID == TimerPreset.customID {
            return customPreset
        }

        return TimerPreset.preset(for: selectedPresetID)
    }

    /// 自定义预设的展示模型。它不写入核心层静态列表，因为时长来自用户设置。
    var customPreset: TimerPreset {
        TimerPreset(
            id: TimerPreset.customID,
            title: "\(customFocusMinutes) / \(customBreakMinutes) 自定义",
            focusDuration: TimeInterval(customFocusMinutes * 60),
            breakDuration: TimeInterval(customBreakMinutes * 60),
            description: "按你设定的工作和休息时长执行。"
        )
    }

    /// 设置页和菜单栏使用的完整预设列表。
    var selectablePresets: [TimerPreset] {
        TimerPreset.builtIn + [customPreset]
    }

    private static func clamp(_ value: Int, to limits: ClosedRange<Int>) -> Int {
        min(max(value, limits.lowerBound), limits.upperBound)
    }
}
