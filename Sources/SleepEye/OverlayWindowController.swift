import AppKit
import SleepEyeCore
import SwiftUI

/// 管理屏幕顶部的非激活浮层窗口。
///
/// 这里使用 `NSPanel` 而不是普通 SwiftUI Window，是因为护眼提醒需要贴近系统顶部区域、
/// 不抢焦点，并且在全屏空间中尽量作为辅助提示出现。所有 AppKit 细节都收拢在这个类里，
/// 避免 SwiftUI 视图直接理解窗口层级和多显示器定位。
@MainActor
final class OverlayWindowController {
    private var panel: NSPanel?

    /// 根据当前计时快照决定显示或隐藏顶部浮层。
    ///
    /// 专注阶段只在最后一分钟展示，避免长期占据屏幕注意力；休息阶段持续展示，
    /// 让用户明确知道当前应该离开屏幕。
    func update(for snapshot: TimerSnapshot, reminderStrength: ReminderStrength) {
        guard let presentation = presentation(for: snapshot, reminderStrength: reminderStrength) else {
            hide()
            return
        }

        show(snapshot: snapshot, title: presentation.title, subtitle: presentation.subtitle)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func show(snapshot: TimerSnapshot, title: String, subtitle: String) {
        let panel = panel ?? makePanel()
        self.panel = panel

        panel.contentView = NSHostingView(
            rootView: OverlayBannerView(snapshot: snapshot, title: title, subtitle: subtitle)
        )
        position(panel)
        panel.orderFrontRegardless()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 86),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false

        // 允许浮层跟随到全屏空间；如果系统不允许显示，系统通知仍是兜底。
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        return panel
    }

    private func position(_ panel: NSPanel) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? .zero
        let size = panel.frame.size
        let topPadding: CGFloat = 10
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - topPadding
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func presentation(
        for snapshot: TimerSnapshot,
        reminderStrength: ReminderStrength
    ) -> (title: String, subtitle: String)? {
        switch snapshot.phase {
        case .resting:
            let subtitle = reminderStrength == .gentle ? "看远处 20 秒，让眼睛缓一下。" : "起身、眨眼、看远处，休息不是偷懒。"
            return ("休息时间", subtitle)
        case .focusing where snapshot.remainingSeconds <= 60:
            return ("即将休息", "还有 \(snapshot.remainingText)，可以准备收尾。")
        case .paused where reminderStrength == .strong:
            return ("计时已暂停", "恢复后会继续当前阶段。")
        default:
            return nil
        }
    }
}
