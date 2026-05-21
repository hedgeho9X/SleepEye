import SleepEyeCore
import SwiftUI

/// 顶部提示条的共享布局参数。
///
/// 提示条需要跨过屏幕顶部中间区域，视觉上包住摄像头附近的信息密集区。
/// 因此宽度按屏幕尺寸动态收敛，避免外接小屏时溢出，也避免大屏上过分铺开。
enum OverlayBannerLayout {
    static let panelHeight: CGFloat = 96
    static let contentHeight: CGFloat = 88
    static let cornerRadius: CGFloat = 30

    static func panelWidth(for screenFrame: CGRect) -> CGFloat {
        let availableWidth = max(360, screenFrame.width - 32)
        let preferredWidth = min(760, max(640, screenFrame.width * 0.56))
        return min(preferredWidth, availableWidth)
    }
}

/// 顶部提示条的可观察展示状态。
///
/// 窗口控制器每秒只更新这里的字段，而不是重新创建整棵 SwiftUI 视图树。
/// 这样进度条可以拿到连续的旧值和新值，线性动画才会真正丝滑。
final class OverlayBannerViewModel: ObservableObject {
    @Published var snapshot: TimerSnapshot
    @Published var title: String
    @Published var subtitle: String
    @Published var actionTitle: String?

    var onActivate: (() -> Void)?

    init(
        snapshot: TimerSnapshot,
        title: String,
        subtitle: String,
        actionTitle: String?,
        onActivate: (() -> Void)?
    ) {
        self.snapshot = snapshot
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.onActivate = onActivate
    }

    /// 更新提示条内容，并让进度数值参与 SwiftUI 的线性动画。
    func update(
        snapshot: TimerSnapshot,
        title: String,
        subtitle: String,
        actionTitle: String?,
        onActivate: (() -> Void)?
    ) {
        withAnimation(.linear(duration: 1.0)) {
            self.snapshot = snapshot
        }
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.onActivate = onActivate
    }
}

/// 顶部圆角浮层的 SwiftUI 内容。
///
/// 这个视图只负责展示，窗口层级、定位和全屏空间兼容交给 `OverlayWindowController`。
struct OverlayBannerView: View {
    @ObservedObject var model: OverlayBannerViewModel

    var body: some View {
        Button {
            model.onActivate?()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.title)
                            .font(.system(size: 20, weight: .semibold))
                            .lineLimit(1)
                        Text(model.subtitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(snapshot.remainingText)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        if let actionTitle = model.actionTitle {
                            Text(actionTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(iconColor)
                                .lineLimit(1)
                        }
                    }
                }

                OverlayProgressBar(progress: snapshot.progress, color: iconColor)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .frame(height: OverlayBannerLayout.contentHeight)
            .background(
                .regularMaterial,
                in: RoundedRectangle(
                    cornerRadius: OverlayBannerLayout.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: OverlayBannerLayout.cornerRadius,
                    style: .continuous
                )
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        // 没有可执行动作时只关闭命中测试，不使用 disabled，避免系统把整条提示染成灰色。
        .allowsHitTesting(model.onActivate != nil)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var snapshot: TimerSnapshot {
        model.snapshot
    }

    private var iconName: String {
        switch snapshot.phase {
        case .resting:
            "eye.fill"
        case .paused:
            "pause.circle"
        case .focusing:
            "timer"
        case .idle:
            "moon.zzz"
        }
    }

    private var iconColor: Color {
        switch snapshot.phase {
        case .resting:
            .green
        case .paused:
            .orange
        case .focusing:
            .blue
        case .idle:
            .secondary
        }
    }
}

private struct OverlayProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color.opacity(0.18))

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(progress))
            }
        }
        .frame(height: 10)
        .animation(.linear(duration: 1.0), value: progress)
    }
}
