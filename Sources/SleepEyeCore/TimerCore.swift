import Foundation

/// SleepEye 的核心计时状态机。
///
/// 这个类型不依赖 SwiftUI、AppKit 或系统通知，方便单元测试。
/// 计时以“当前阶段的目标结束时间”为准，而不是把剩余秒数每秒减一。
/// 这样即使系统睡眠、应用短暂卡顿或菜单栏刷新延迟，恢复后仍能得到真实剩余时间。
public final class TimerCore {
    private(set) public var selectedPreset: TimerPreset
    public var autoStartNextRound: Bool

    private var activeSessionKind: TimerSessionKind?
    private var targetEndDate: Date?
    private var pausedRemainingSeconds: TimeInterval?
    private var pausedSessionKind: TimerSessionKind?
    private(set) public var completedFocusSessions: Int

    public init(
        selectedPreset: TimerPreset = .pomodoro,
        autoStartNextRound: Bool = true,
        completedFocusSessions: Int = 0
    ) {
        self.selectedPreset = selectedPreset
        self.autoStartNextRound = autoStartNextRound
        self.completedFocusSessions = completedFocusSessions
    }

    /// 开始一轮新的专注计时。
    ///
    /// 传入 `now` 是为了让测试可以完全控制时间，避免单元测试依赖真实时钟。
    public func startFocus(preset: TimerPreset? = nil, now: Date = Date()) {
        if let preset {
            selectedPreset = preset
        }

        activeSessionKind = .focus
        targetEndDate = now.addingTimeInterval(selectedPreset.focusDuration)
        pausedRemainingSeconds = nil
        pausedSessionKind = nil
    }

    /// 立即进入休息阶段。
    ///
    /// 这个能力对应菜单里的“立即休息”，用于用户感觉眼睛累时主动中断专注。
    public func startBreak(now: Date = Date()) {
        activeSessionKind = .rest
        targetEndDate = now.addingTimeInterval(selectedPreset.breakDuration)
        pausedRemainingSeconds = nil
        pausedSessionKind = nil
    }

    /// 暂停当前阶段，并记录暂停时的剩余时间。
    ///
    /// 暂停不能只记录一个布尔值，因为恢复时需要知道原来是专注还是休息。
    public func pause(now: Date = Date()) {
        guard let activeSessionKind, let targetEndDate else {
            return
        }

        pausedSessionKind = activeSessionKind
        pausedRemainingSeconds = max(0, targetEndDate.timeIntervalSince(now))
        self.activeSessionKind = nil
        self.targetEndDate = nil
    }

    /// 从暂停状态恢复，继续原本的专注或休息阶段。
    public func resume(now: Date = Date()) {
        guard let pausedSessionKind, let pausedRemainingSeconds else {
            return
        }

        activeSessionKind = pausedSessionKind
        targetEndDate = now.addingTimeInterval(pausedRemainingSeconds)
        self.pausedSessionKind = nil
        self.pausedRemainingSeconds = nil
    }

    /// 跳过当前休息并根据设置决定是否进入下一轮专注。
    ///
    /// 这个方法只对休息阶段有意义；专注阶段调用时不会强行结束专注。
    public func skipBreak(now: Date = Date()) {
        guard currentSessionKind == .rest else {
            return
        }

        if autoStartNextRound {
            startFocus(now: now)
        } else {
            stop()
        }
    }

    /// 延长当前阶段。
    ///
    /// 主要用于“稍后休息”或“延长休息”。如果当前处于暂停状态，
    /// 则只增加暂停记录里的剩余时间，不会意外恢复计时。
    public func extendCurrentSession(by interval: TimeInterval) {
        if let targetEndDate {
            self.targetEndDate = targetEndDate.addingTimeInterval(interval)
        } else if let pausedRemainingSeconds {
            self.pausedRemainingSeconds = pausedRemainingSeconds + interval
        }
    }

    /// 停止所有计时并回到空闲状态。
    public func stop() {
        activeSessionKind = nil
        targetEndDate = nil
        pausedRemainingSeconds = nil
        pausedSessionKind = nil
    }

    /// 让状态机推进到指定时间，并在阶段结束时返回对应事件。
    ///
    /// App 层每秒调用一次即可；如果因为系统睡眠隔了很久才调用，
    /// 这里仍会根据目标结束时间判断是否完成。
    @discardableResult
    public func tick(now: Date = Date()) -> TimerEvent? {
        guard let activeSessionKind, let targetEndDate, now >= targetEndDate else {
            return nil
        }

        switch activeSessionKind {
        case .focus:
            completedFocusSessions += 1
            startBreak(now: now)
            return .focusCompleted
        case .rest:
            if autoStartNextRound {
                startFocus(now: now)
            } else {
                stop()
            }
            return .breakCompleted
        }
    }
}

public extension TimerCore {
    /// 当前实际会话类型；暂停时返回暂停前的会话类型。
    var currentSessionKind: TimerSessionKind? {
        activeSessionKind ?? pausedSessionKind
    }

    /// 按当前时间生成展示快照。
    func snapshot(now: Date = Date()) -> TimerSnapshot {
        let phase = currentPhase
        let sessionKind = currentSessionKind
        let totalSeconds = totalDuration(for: sessionKind)
        let remainingSeconds = remainingDuration(now: now)
        let progress: Double

        if totalSeconds > 0 {
            progress = 1 - (remainingSeconds / totalSeconds)
        } else {
            progress = 0
        }

        return TimerSnapshot(
            phase: phase,
            sessionKind: sessionKind,
            preset: selectedPreset,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            progress: progress,
            completedFocusSessions: completedFocusSessions
        )
    }
}

private extension TimerCore {
    /// 根据内部字段推导 UI 阶段，避免外部直接理解状态组合。
    var currentPhase: TimerPhase {
        if pausedRemainingSeconds != nil {
            return .paused
        }

        switch activeSessionKind {
        case .focus:
            return .focusing
        case .rest:
            return .resting
        case .none:
            return .idle
        }
    }

    func totalDuration(for sessionKind: TimerSessionKind?) -> TimeInterval {
        switch sessionKind {
        case .focus:
            selectedPreset.focusDuration
        case .rest:
            selectedPreset.breakDuration
        case .none:
            0
        }
    }

    /// 计算当前阶段剩余时间。
    ///
    /// 这里统一裁剪到非负值，避免 UI 在系统延迟时显示 `-00:01` 这类奇怪文案。
    func remainingDuration(now: Date) -> TimeInterval {
        if let pausedRemainingSeconds {
            return max(0, pausedRemainingSeconds)
        }

        guard let targetEndDate else {
            return 0
        }

        return max(0, targetEndDate.timeIntervalSince(now))
    }
}
