import SleepEyeCore
import SwiftUI

/// 白绿风格的全屏休息倒计时。
///
/// 这个界面只在用户点击休息提示条后出现，不自动强制弹出。
/// 这样既能提供沉浸式休息体验，也保留用户对当前工作流的控制感。
struct FullScreenBreakView: View {
    let snapshot: TimerSnapshot
    let onEndBreak: () -> Void
    let onExtendBreak: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 1.0, blue: 0.96),
                    Color.white,
                    Color(red: 0.88, green: 0.98, blue: 0.90),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 34) {
                Spacer(minLength: 40)

                VStack(spacing: 14) {
                    Image(systemName: "eye")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.green)

                    Text("休息一下")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("看向远处，放松肩颈，让眼睛从屏幕里出来。")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.16), lineWidth: 18)

                    Circle()
                        .trim(from: 0, to: snapshot.progress)
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 8) {
                        Text(snapshot.remainingText)
                            .font(.system(size: 86, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("剩余休息时间")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 310, height: 310)

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

                Spacer(minLength: 40)
            }
            .padding(48)
        }
    }
}
