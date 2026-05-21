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

    let settings: SettingsStore

    private let core: TimerCore
    private let notificationScheduler: NotificationScheduler
    private let overlayWindowController: OverlayWindowController
    private var ticker: Timer?

    init(
        core: TimerCore = TimerCore(),
        settings: SettingsStore? = nil,
        notificationScheduler: NotificationScheduler = NotificationScheduler(),
        overlayWindowController: OverlayWindowController? = nil
    ) {
        let settings = settings ?? SettingsStore()
        let overlayWindowController = overlayWindowController ?? OverlayWindowController()

        self.core = core
        self.settings = settings
        self.notificationScheduler = notificationScheduler
        self.overlayWindowController = overlayWindowController
        snapshot = core.snapshot()

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
        let event = core.tick()
        refresh()

        switch event {
        case .focusCompleted:
            notificationScheduler.deliverFocusCompleted()
        case .breakCompleted:
            notificationScheduler.deliverBreakCompleted(autoStartedNextRound: settings.autoStartNextRound)
        case .none:
            break
        }
    }

    private func refresh() {
        snapshot = core.snapshot()
        overlayWindowController.update(for: snapshot, reminderStrength: settings.reminderStrength)
    }
}
