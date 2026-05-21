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
    }

    /// 当前设置对应的计时预设。找不到旧标识时会回退到经典番茄钟。
    var selectedPreset: TimerPreset {
        TimerPreset.preset(for: selectedPresetID)
    }
}
