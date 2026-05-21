import SleepEyeCore
import SwiftUI

/// 顶部胶囊浮层的 SwiftUI 内容。
///
/// 这个视图只负责展示，窗口层级、定位和全屏空间兼容交给 `OverlayWindowController`。
struct OverlayBannerView: View {
    let snapshot: TimerSnapshot
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onActivate: (() -> Void)?

    var body: some View {
        Button {
            onActivate?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 26, height: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(snapshot.remainingText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        if let actionTitle {
                            Text(actionTitle)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(iconColor)
                                .lineLimit(1)
                        }
                    }
                }

                ProgressView(value: snapshot.progress)
                    .progressViewStyle(.linear)
                    .tint(iconColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(onActivate == nil)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 360)
        .background(.regularMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch snapshot.phase {
        case .resting:
            "eye"
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
