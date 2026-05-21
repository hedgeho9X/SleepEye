import AppKit
import SleepEyeCore
import SwiftUI

/// SleepEye 的主应用页面。
///
/// 菜单栏适合快速操作，但 release 版本还需要一个完整窗口承载状态、统计和设置摘要。
/// 这个页面复用 `AppState`，避免主窗口和菜单栏各自维护一套计时状态。
struct DashboardView: View {
    @ObservedObject private var appState: AppState
    @ObservedObject private var settings: SettingsStore

    init(appState: AppState) {
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusSection
                    statsSection
                    settingsSection
                }
                .padding(22)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 560)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SleepEyePalette.restAccent)
                .frame(width: 36, height: 36)
                .background(SleepEyePalette.restAccent.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("SleepEye")
                    .font(.title3.weight(.semibold))
                Text("今日 \(appState.dailyStats.completedFocusSessions) 轮专注 · \(durationText(appState.dailyStats.totalFocusSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("设置", systemImage: "gearshape")
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }

    private var statusSection: some View {
        HStack(spacing: 22) {
            DashboardProgressRing(
                progress: appState.snapshot.progress,
                color: phaseColor,
                remainingText: appState.snapshot.remainingText,
                phaseTitle: appState.snapshot.phase.title
            )

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.snapshot.phase.title)
                        .font(.title.weight(.semibold))
                    Text(displayedPreset.title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("工作 \(durationText(displayedPreset.focusDuration)) · 休息 \(durationText(displayedPreset.breakDuration))")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                controlPanel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if appState.snapshot.phase == .idle {
                    Button {
                        appState.startSelectedPreset()
                    } label: {
                        Label("开始专注", systemImage: "play.fill")
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

            HStack(spacing: 10) {
                Button {
                    appState.startBreakNow()
                } label: {
                    Label("立即休息", systemImage: "circle")
                }
                .disabled(appState.snapshot.phase == .resting)

                Button {
                    appState.extendCurrentSession(by: 5 * 60)
                } label: {
                    Label("延后 5 分钟", systemImage: "clock.arrow.circlepath")
                }
                .disabled(appState.snapshot.phase == .idle)

                if appState.snapshot.phase == .resting {
                    Button {
                        appState.showFullScreenBreakCountdown()
                    } label: {
                        Label("打开休息页", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                }
            }
        }
        .controlSize(.large)
        .tint(phaseColor)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("今日统计", systemImage: "chart.bar")

            LazyVGrid(columns: metricColumns, spacing: 12) {
                StatMetricView(
                    title: "完成专注",
                    value: "\(appState.dailyStats.completedFocusSessions)",
                    unit: "轮",
                    systemImage: "checkmark.circle"
                )
                StatMetricView(
                    title: "完成休息",
                    value: "\(appState.dailyStats.completedBreaks)",
                    unit: "次",
                    systemImage: "circle.dotted"
                )
                StatMetricView(
                    title: "专注时长",
                    value: durationText(appState.dailyStats.totalFocusSeconds),
                    unit: "",
                    systemImage: "timer"
                )
                StatMetricView(
                    title: "休息时长",
                    value: durationText(appState.dailyStats.totalBreakSeconds),
                    unit: "",
                    systemImage: "leaf"
                )
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("节奏设置", systemImage: "slider.horizontal.3")

            VStack(alignment: .leading, spacing: 14) {
                Picker("默认预设", selection: $settings.selectedPresetID) {
                    ForEach(settings.selectablePresets) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                }
                .disabled(appState.snapshot.phase != .idle)

                if settings.selectedPresetID == TimerPreset.customID && appState.snapshot.phase == .idle {
                    HStack(spacing: 18) {
                        Stepper(value: $settings.customFocusMinutes, in: 1...180) {
                            Text("工作 \(settings.customFocusMinutes) 分钟")
                                .monospacedDigit()
                        }

                        Stepper(value: $settings.customBreakMinutes, in: 1...60) {
                            Text("休息 \(settings.customBreakMinutes) 分钟")
                                .monospacedDigit()
                        }
                    }
                }

                Toggle("休息结束后自动进入下一轮", isOn: $settings.autoStartNextRound)
                Toggle("休息开始时自动打开全屏倒计时", isOn: $settings.autoOpenBreakFullscreen)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
    }

    private var displayedPreset: TimerPreset {
        appState.snapshot.phase == .idle ? settings.selectedPreset : appState.snapshot.preset
    }

    private var phaseColor: Color {
        switch appState.snapshot.phase {
        case .resting:
            SleepEyePalette.restAccent
        case .paused:
            .orange
        case .focusing:
            .blue
        case .idle:
            .secondary
        }
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded(.down))
        if minutes <= 0 {
            return "0 分钟"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0, remainingMinutes > 0 {
            return "\(hours) 小时 \(remainingMinutes) 分钟"
        } else if hours > 0 {
            return "\(hours) 小时"
        } else {
            return "\(remainingMinutes) 分钟"
        }
    }
}

private struct DashboardProgressRing: View {
    let progress: Double
    let color: Color
    let remainingText: String
    let phaseTitle: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.13), lineWidth: 16)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            VStack(spacing: 4) {
                Text(remainingText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                Text(phaseTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 190, height: 190)
    }
}

private struct StatMetricView: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SleepEyePalette.restAccent)
                .frame(width: 30, height: 30)
                .background(SleepEyePalette.restAccent.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}
