import Foundation

/// 计时器当前所处的展示阶段。
///
/// UI 只消费这个枚举，不直接读取 `TimerCore` 的内部字段。
/// 这样后续调整状态机内部实现时，不会把 SwiftUI 视图一起拖乱。
public enum TimerPhase: String, Codable, Equatable, Sendable {
    case idle
    case focusing
    case resting
    case paused

    /// 面向用户的中文状态名称。
    public var title: String {
        switch self {
        case .idle:
            "空闲"
        case .focusing:
            "专注中"
        case .resting:
            "休息中"
        case .paused:
            "已暂停"
        }
    }
}

/// 当前正在执行的会话类型。
///
/// 暂停状态会保留原本的会话类型，用于恢复后继续进入专注或休息。
public enum TimerSessionKind: String, Codable, Equatable, Sendable {
    case focus
    case rest
}

/// UI 每秒读取的一份稳定快照。
///
/// 快照把“剩余时间、总时长、进度、阶段”等数据打包好，
/// 视图层只负责展示，不再重复计算计时规则。
public struct TimerSnapshot: Equatable, Sendable {
    public let phase: TimerPhase
    public let sessionKind: TimerSessionKind?
    public let preset: TimerPreset
    public let remainingSeconds: TimeInterval
    public let totalSeconds: TimeInterval
    public let progress: Double
    public let completedFocusSessions: Int

    public init(
        phase: TimerPhase,
        sessionKind: TimerSessionKind?,
        preset: TimerPreset,
        remainingSeconds: TimeInterval,
        totalSeconds: TimeInterval,
        progress: Double,
        completedFocusSessions: Int
    ) {
        self.phase = phase
        self.sessionKind = sessionKind
        self.preset = preset
        self.remainingSeconds = remainingSeconds
        self.totalSeconds = totalSeconds
        self.progress = min(max(progress, 0), 1)
        self.completedFocusSessions = completedFocusSessions
    }

    /// 菜单栏和浮层使用的 `MM:SS` 文案。
    public var remainingText: String {
        let rounded = Int(remainingSeconds.rounded(.up))
        let minutes = max(0, rounded) / 60
        let seconds = max(0, rounded) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// 计时阶段结束时抛给应用层的事件。
///
/// `TimerCore` 只负责准确判断事件，通知、浮层和声音都由 App 层决定，
/// 避免核心逻辑依赖 macOS 框架。
public enum TimerEvent: Equatable, Sendable {
    case focusCompleted
    case breakCompleted
}
