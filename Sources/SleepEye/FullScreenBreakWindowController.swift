import AppKit
import SleepEyeCore
import SwiftUI

/// 管理用户主动打开的全屏休息倒计时窗口。
///
/// 它和顶部提示条分开管理：提示条是轻提醒，全屏窗口是用户确认后的沉浸式休息。
/// 窗口使用普通 `NSWindow` 的无边框全屏尺寸，不进入系统独立 Space，
/// 避免开发模式下产生难以关闭的全屏状态。
@MainActor
final class FullScreenBreakWindowController {
    private var window: NSWindow?
    private var viewModel: FullScreenBreakViewModel?
    private var onEndBreak: (() -> Void)?
    private var onExtendBreak: (() -> Void)?

    var isVisible: Bool {
        window?.isVisible == true
    }

    /// 显示全屏休息倒计时。
    func show(
        snapshot: TimerSnapshot,
        onEndBreak: @escaping () -> Void,
        onExtendBreak: @escaping () -> Void
    ) {
        guard snapshot.phase == .resting else {
            hide()
            return
        }

        self.onEndBreak = onEndBreak
        self.onExtendBreak = onExtendBreak

        let window = window ?? makeWindow()
        self.window = window
        updateContent(for: snapshot)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 根据最新快照刷新倒计时。
    ///
    /// 如果休息已经结束，窗口会自动关闭，避免倒计时停在旧状态。
    func update(for snapshot: TimerSnapshot) {
        guard isVisible else {
            return
        }

        guard snapshot.phase == .resting else {
            hide()
            return
        }

        updateContent(for: snapshot)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        let screenFrame = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? .zero
        let window = FullScreenBreakWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false

        // 让窗口覆盖当前桌面和全屏空间；用户仍然可以通过按钮退出，不会被系统全屏模式困住。
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return window
    }

    private func updateContent(for snapshot: TimerSnapshot) {
        guard let window else {
            return
        }

        position(window)

        if let viewModel {
            viewModel.update(snapshot: snapshot)
        } else {
            let viewModel = FullScreenBreakViewModel(snapshot: snapshot)
            self.viewModel = viewModel
            window.contentView = NSHostingView(
                rootView: FullScreenBreakView(
                    model: viewModel,
                    onEndBreak: { [weak self] in
                        self?.onEndBreak?()
                    },
                    onExtendBreak: { [weak self] in
                        self?.onExtendBreak?()
                    },
                    onDismiss: { [weak self] in
                        self?.hide()
                    }
                )
            )
        }
    }

    private func position(_ window: NSWindow) {
        let screenFrame = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? .zero
        window.setFrame(screenFrame, display: true)
    }
}

private final class FullScreenBreakWindow: NSWindow {
    /// 无边框窗口默认不一定能成为 key window；这里明确允许，确保全屏里的按钮可以点击。
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
