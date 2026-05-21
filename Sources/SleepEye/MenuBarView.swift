import AppKit
import SleepEyeCore
import SwiftUI

/// 菜单栏弹出面板。
///
/// 面板保持操作密度：用户能快速看到剩余时间，并完成开始、暂停、休息、跳过等动作。
/// 更详细的偏好配置放到 Settings 窗口中，避免菜单栏变成复杂控制台。
struct MenuBarView: View {
    @ObservedObject private var appState: AppState
    @ObservedObject private var settings: SettingsStore

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ProgressView(value: appState.snapshot.progress)
                .progressViewStyle(.linear)
                .tint(progressColor)

            presetPicker
            controls

            Divider()

            footerActions
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: appState.menuBarSymbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(progressColor)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.snapshot.phase.title)
                    .font(.headline)
                Text(appState.snapshot.preset.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(appState.snapshot.remainingText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }

    private var presetPicker: some View {
        Picker("预设", selection: $settings.selectedPresetID) {
            ForEach(TimerPreset.builtIn) { preset in
                Text(preset.title).tag(preset.id)
            }
        }
        .pickerStyle(.menu)
        .disabled(appState.snapshot.phase != .idle)
        .help("计时中暂不切换预设，避免当前轮次含义变得不清楚。")
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if appState.snapshot.phase == .idle {
                    Button {
                        appState.startSelectedPreset()
                    } label: {
                        Label("开始", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else if appState.canResume {
                    Button {
                        appState.resume()
                    } label: {
                        Label("继续", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        appState.pause()
                    } label: {
                        Label("暂停", systemImage: "pause.fill")
                    }
                }

                Button(role: .destructive) {
                    appState.stop()
                } label: {
                    Label("停止", systemImage: "stop.fill")
                }
                .disabled(appState.snapshot.phase == .idle)
            }

            HStack(spacing: 8) {
                Button {
                    appState.startBreakNow()
                } label: {
                    Label("立即休息", systemImage: "eye")
                }
                .disabled(appState.snapshot.phase == .resting)

                Button {
                    appState.extendCurrentSession(by: 5 * 60)
                } label: {
                    Label("延后 5 分钟", systemImage: "clock.arrow.circlepath")
                }
                .disabled(appState.snapshot.phase == .idle)
            }

            if appState.snapshot.phase == .resting {
                Button {
                    appState.skipBreak()
                } label: {
                    Label("结束休息", systemImage: "forward.end.fill")
                }
            }
        }
    }

    private var footerActions: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日完成 \(appState.snapshot.completedFocusSessions) 轮")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(settings.reminderStrength.title)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "gearshape")
            }
            .help("打开设置")

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("退出 SleepEye")
        }
    }

    private var progressColor: Color {
        switch appState.snapshot.phase {
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
