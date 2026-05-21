import Foundation

/// 表示一组专注与休息的计时预设。
///
/// SleepEye 的 MVP 只需要少量稳定预设，因此先用静态定义保持简单。
/// 后续如果要允许用户完全自定义，再把这些字段落到 `SettingsStore` 或本地数据库中。
public struct TimerPreset: Codable, Equatable, Identifiable, Sendable {
    /// 用于设置持久化和菜单选中的稳定标识，不使用标题，避免后续改文案导致旧配置失效。
    public let id: String

    /// 展示给用户看的预设名称。
    public let title: String

    /// 专注阶段时长，单位为秒。
    public let focusDuration: TimeInterval

    /// 休息阶段时长，单位为秒。
    public let breakDuration: TimeInterval

    /// 给用户的简短说明，用于设置页和菜单栏解释这个预设适合什么场景。
    public let description: String

    public init(
        id: String,
        title: String,
        focusDuration: TimeInterval,
        breakDuration: TimeInterval,
        description: String
    ) {
        self.id = id
        self.title = title
        self.focusDuration = focusDuration
        self.breakDuration = breakDuration
        self.description = description
    }
}

public extension TimerPreset {
    /// 自定义预设的稳定标识。具体时长由 `SettingsStore` 读取用户配置后动态生成。
    static let customID = "custom"

    /// 经典番茄钟：适合默认工作节奏，也是首次打开应用时的默认选择。
    static let pomodoro = TimerPreset(
        id: "pomodoro-25-5",
        title: "25 / 5 番茄钟",
        focusDuration: 25 * 60,
        breakDuration: 5 * 60,
        description: "适合普通写作、编码和学习。"
    )

    /// 长专注：适合深度工作，但仍保留明确休息窗口，避免连续盯屏过久。
    static let longFocus = TimerPreset(
        id: "long-focus-50-10",
        title: "50 / 10 长专注",
        focusDuration: 50 * 60,
        breakDuration: 10 * 60,
        description: "适合需要较长上下文的任务。"
    )

    /// 20-20-20 护眼规则：每 20 分钟看 20 英尺外 20 秒，MVP 中用 20 秒休息表达。
    static let eyeCare = TimerPreset(
        id: "eye-care-20-20",
        title: "20-20-20 护眼",
        focusDuration: 20 * 60,
        breakDuration: 20,
        description: "适合高频轻量护眼提醒。"
    )

    /// 当前版本内置的全部预设。顺序会直接影响菜单与设置页展示顺序。
    static let builtIn: [TimerPreset] = [
        .pomodoro,
        .longFocus,
        .eyeCare,
    ]

    /// 根据持久化标识查找预设；找不到时回退到经典番茄钟，避免旧配置让应用无法启动。
    static func preset(for id: String) -> TimerPreset {
        builtIn.first { $0.id == id } ?? .pomodoro
    }
}
