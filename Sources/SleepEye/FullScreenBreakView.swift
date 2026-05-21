import SleepEyeCore
import SwiftUI

/// 全屏休息页的可观察状态。
///
/// 全屏窗口会持续存在，只更新这里的快照。相比每秒替换 `NSHostingView`，
/// 这种做法能让圆环获得连续动画，视觉上不会一格一格跳。
final class FullScreenBreakViewModel: ObservableObject {
    @Published var snapshot: TimerSnapshot

    init(snapshot: TimerSnapshot) {
        self.snapshot = snapshot
    }

    /// 更新休息倒计时。
    ///
    /// 不在这里包全局动画，避免倒计时数字出现补间；圆环自己只动画进度。
    func update(snapshot: TimerSnapshot) {
        self.snapshot = snapshot
    }
}

/// 白绿风格的全屏休息倒计时。
///
/// 当前产品策略是休息开始默认进入全屏，但界面必须始终保留明确出口。
/// 护眼工具要帮助用户离开屏幕，而不是制造“被锁住”的压力。
struct FullScreenBreakView: View {
    @ObservedObject var model: FullScreenBreakViewModel
    let onEndBreak: () -> Void
    let onExtendBreak: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 30) {
                topBar

                Spacer(minLength: 16)

                VStack(spacing: 12) {
                    Text("休息一下")
                        .font(.system(size: 50, weight: .bold, design: .rounded))

                    Text("看向远处，放松肩颈，给眼睛一段真正离开屏幕的时间。")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                countdownRing
                restSuggestions
                actionButtons

                Spacer(minLength: 16)
            }
            .padding(48)
        }
    }

    private var background: some View {
        ZStack {
            SleepEyePalette.restBackground

            LinearGradient(
                colors: [
                    SleepEyePalette.restBackground,
                    SleepEyePalette.restBackgroundSoft,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var snapshot: TimerSnapshot {
        model.snapshot
    }

    private var topBar: some View {
        HStack {
            Label("SleepEye Break", systemImage: "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SleepEyePalette.restAccent)

            Spacer()

            Text("Enter 结束 · Esc 返回提示条")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(SleepEyePalette.restSurface, in: Capsule())
        }
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(SleepEyePalette.restRingTrack, lineWidth: 18)

            Circle()
                .trim(from: 0, to: snapshot.progress)
                .stroke(
                    SleepEyePalette.restAccent,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: snapshot.progress)

            VStack(spacing: 10) {
                Text(snapshot.remainingText)
                    .font(.system(size: 92, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                Text("剩余休息时间")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 330, height: 330)
    }

    private var restSuggestions: some View {
        HStack(spacing: 12) {
            suggestionItem(icon: "mountain.2", title: "看远处", subtitle: "让眼肌放松")
            suggestionItem(icon: "figure.stand", title: "站起来", subtitle: "肩颈离开桌面")
            suggestionItem(icon: "drop", title: "喝口水", subtitle: "顺手眨眨眼")
        }
        .frame(maxWidth: 720)
    }

    private func suggestionItem(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(SleepEyePalette.restAccent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SleepEyePalette.restSurface, in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                onEndBreak()
            } label: {
                Label("结束休息", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Button {
                onExtendBreak()
            } label: {
                Label("再休息 1 分钟", systemImage: "plus.circle")
            }
            .controlSize(.large)

            Button {
                onDismiss()
            } label: {
                Label("回到提示条", systemImage: "minus.circle")
            }
            .controlSize(.large)
            .keyboardShortcut(.cancelAction)
        }
        .tint(SleepEyePalette.restAccent)
    }
}
