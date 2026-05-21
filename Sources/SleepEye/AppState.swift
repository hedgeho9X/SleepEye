import AppKit
import Combine
import Foundation
import SleepEyeCore

/// 应用层状态容器。
///
/// `AppState` 连接纯逻辑的 `TimerCore`、本地设置、系统通知和顶部浮层。
/// SwiftUI 视图只通过这里发起用户动作，避免菜单栏视图直接修改计时器内部状态。
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var snapshot: TimerSnapshot
    @Published private(set) var dailyStats: DailyStatsSnapshot

    let settings: SettingsStore

    private let core: TimerCore
    private let dailyStatsStore: DailyStatsStore
    private let notificationScheduler: NotificationScheduler
    private let overlayWindowController: OverlayWindowController
    private let fullScreenBreakWindowController: FullScreenBreakWindowController
    private var ticker: Timer?

    init(
        core: TimerCore = TimerCore(),
        settings: SettingsStore? = nil,
        dailyStatsStore: DailyStatsStore? = nil,
        notificationScheduler: NotificationScheduler = NotificationScheduler(),
        overlayWindowController: OverlayWindowController? = nil,
        fullScreenBreakWindowController: FullScreenBreakWindowController? = nil
    ) {
        let settings = settings ?? SettingsStore()
        let dailyStatsStore = dailyStatsStore ?? DailyStatsStore()
        let overlayWindowController = overlayWindowController ?? OverlayWindowController()
        let fullScreenBreakWindowController = fullScreenBreakWindowController ?? FullScreenBreakWindowController()

        self.core = core
        self.settings = settings
        self.dailyStatsStore = dailyStatsStore
        self.notificationScheduler = notificationScheduler
        self.overlayWindowController = overlayWindowController
        self.fullScreenBreakWindowController = fullScreenBreakWindowController
        snapshot = core.snapshot()
        dailyStats = dailyStatsStore.currentSnapshot()

        core.autoStartNextRound = settings.autoStartNextRound
        startTicker()
    }

    deinit {
        ticker?.invalidate()
    }

    /// 菜单栏图标使用的 SF Symbol 名称。
    ///
    /// 这里只返回系统图标名，真实展示由 `MenuBarExtra` 负责。
    var menuBarSymbol: String {
        switch snapshot.phase {
        case .idle:
            "eye"
        case .focusing:
            "timer"
        case .resting:
            "eye.circle"
        case .paused:
            "pause.circle"
        }
    }

    /// 菜单栏入口显示的文字。
    ///
    /// 只显示小图标时，在刘海屏或菜单栏图标很多的机器上很容易被系统挤掉。
    /// 开发阶段先显示文字/剩余时间，让用户能明确找到入口；后续打包版再提供“仅图标”选项。
    var menuBarTitle: String {
        switch snapshot.phase {
        case .idle:
            "SleepEye"
        case .focusing, .resting, .paused:
            snapshot.remainingText
        }
    }

    var canPause: Bool {
        snapshot.phase == .focusing || snapshot.phase == .resting
    }

    var canResume: Bool {
        snapshot.phase == .paused
    }

    /// 使用当前设置里的预设开始一轮专注。
    func startSelectedPreset() {
        core.autoStartNextRound = settings.autoStartNextRound
        core.startFocus(preset: settings.selectedPreset)
        refresh()
    }

    /// 暂停当前阶段。
    func pause() {
        core.pause()
        refresh()
    }

    /// 从暂停状态恢复。
    func resume() {
        core.resume()
        refresh()
    }

    /// 停止计时并隐藏顶部浮层。
    func stop() {
        core.stop()
        refresh()
    }

    /// 用户主动选择立刻休息。
    ///
    /// 这个动作不会增加完成番茄数，因为它代表用户中断了当前专注。
    func startBreakNow() {
        core.startBreak()
        refresh()
        if settings.autoOpenBreakFullscreen {
            showFullScreenBreakCountdown()
        }
    }

    /// 打开沉浸式全屏休息倒计时。
    ///
    /// 这个动作只由用户点击休息提示条触发，避免应用主动全屏打断当前任务。
    func showFullScreenBreakCountdown() {
        guard snapshot.phase == .resting else {
            return
        }

        fullScreenBreakWindowController.show(
            snapshot: snapshot,
            onEndBreak: { [weak self] in
                self?.skipBreak()
            },
            onExtendBreak: { [weak self] in
                self?.extendCurrentSession(by: 60)
            }
        )
    }

    /// 结束当前休息，根据自动下一轮设置决定是否进入专注。
    func skipBreak() {
        core.autoStartNextRound = settings.autoStartNextRound
        core.skipBreak()
        refresh()
    }

    /// 延长当前阶段。
    ///
    /// 在专注末尾点击它，相当于“稍后提醒”；在休息中点击它，相当于“再休息一会儿”。
    func extendCurrentSession(by interval: TimeInterval) {
        core.extendCurrentSession(by: interval)
        refresh()
    }

    private func startTicker() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleTick()
            }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func handleTick() {
        core.autoStartNextRound = settings.autoStartNextRound
        let previousSnapshot = core.snapshot()
        let event = core.tick()
        refresh()

        switch event {
        case .focusCompleted:
            dailyStatsStore.recordFocusCompleted(duration: previousSnapshot.totalSeconds)
            dailyStats = dailyStatsStore.snapshot
            notificationScheduler.deliverFocusCompleted()
            if settings.autoOpenBreakFullscreen {
                showFullScreenBreakCountdown()
            }
        case .breakCompleted:
            dailyStatsStore.recordBreakCompleted(duration: previousSnapshot.totalSeconds)
            dailyStats = dailyStatsStore.snapshot
            notificationScheduler.deliverBreakCompleted(autoStartedNextRound: settings.autoStartNextRound)
        case .none:
            break
        }
    }

    private func refresh() {
        snapshot = core.snapshot()
        dailyStats = dailyStatsStore.currentSnapshot()
        overlayWindowController.update(
            for: snapshot,
            reminderStrength: settings.reminderStrength,
            onRestPromptTapped: { [weak self] in
                self?.showFullScreenBreakCountdown()
            }
        )
        fullScreenBreakWindowController.update(for: snapshot)
    }
}
