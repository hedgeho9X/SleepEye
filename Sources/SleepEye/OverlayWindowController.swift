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
    private var bannerViewModel: OverlayBannerViewModel?

    /// 根据当前计时快照决定显示或隐藏顶部浮层。
    ///
    /// 专注阶段只在最后一分钟展示，避免长期占据屏幕注意力；休息阶段持续展示，
    /// 让用户明确知道当前应该离开屏幕。
    func update(
        for snapshot: TimerSnapshot,
        reminderStrength: ReminderStrength,
        onRestPromptTapped: @escaping () -> Void
    ) {
        guard let presentation = presentation(for: snapshot, reminderStrength: reminderStrength) else {
            hide()
            return
        }

        let isRestPrompt = snapshot.phase == .resting
        show(
            snapshot: snapshot,
            title: presentation.title,
            subtitle: presentation.subtitle,
            actionTitle: isRestPrompt ? "点开休息" : nil,
            onActivate: isRestPrompt ? onRestPromptTapped : nil
        )
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func show(
        snapshot: TimerSnapshot,
        title: String,
        subtitle: String,
        actionTitle: String?,
        onActivate: (() -> Void)?
    ) {
        let panel = panel ?? makePanel()
        self.panel = panel
        resize(panel)

        if let bannerViewModel {
            bannerViewModel.update(
                snapshot: snapshot,
                title: title,
                subtitle: subtitle,
                actionTitle: actionTitle,
                onActivate: onActivate
            )
        } else {
            let bannerViewModel = OverlayBannerViewModel(
                snapshot: snapshot,
                title: title,
                subtitle: subtitle,
                actionTitle: actionTitle,
                onActivate: onActivate
            )
            self.bannerViewModel = bannerViewModel
            panel.contentView = NSHostingView(rootView: OverlayBannerView(model: bannerViewModel))
        }

        position(panel)
        panel.orderFrontRegardless()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: OverlayBannerLayout.panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        // 提示条需要贴近摄像头区域出现，使用 statusBar 层级才能浮在菜单栏中部之上。
        // 宽度被限制在屏幕中央一小段，避免遮住左右菜单与系统状态图标。
        panel.level = .statusBar
        // 窗口本身保持 clear 只用于裁出圆角外沿；提示条可见内容使用不透明背景。
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false

        // 允许浮层跟随到全屏空间；如果系统不允许显示，系统通知仍是兜底。
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        return panel
    }

    private func resize(_ panel: NSPanel) {
        let screenFrame = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? .zero
        let size = NSSize(
            width: OverlayBannerLayout.panelWidth(for: screenFrame),
            height: OverlayBannerLayout.panelHeight
        )

        guard panel.frame.size != size else {
            return
        }

        panel.setFrame(NSRect(origin: panel.frame.origin, size: size), display: true)
    }

    private func position(_ panel: NSPanel) {
        let screenFrame = NSScreen.main?.frame ?? NSScreen.screens.first?.frame ?? .zero
        let size = panel.frame.size
        let topPadding: CGFloat = -4
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
