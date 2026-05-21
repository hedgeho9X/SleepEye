import SleepEyeCore
import SwiftUI

/// 设置窗口。
///
/// MVP 设置保持克制，只暴露会影响提醒节奏的关键项。
/// 更复杂的主题、统计和开机启动可以在后续 feature 中独立加入。
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("计时") {
                Picker("默认预设", selection: $settings.selectedPresetID) {
                    ForEach(settings.selectablePresets) { preset in
                        VStack(alignment: .leading) {
                            Text(preset.title)
                            Text(preset.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(preset.id)
                    }
                }

                Stepper(value: $settings.customFocusMinutes, in: 1...180) {
                    HStack {
                        Text("自定义工作时长")
                        Spacer()
                        Text("\(settings.customFocusMinutes) 分钟")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: $settings.customBreakMinutes, in: 1...60) {
                    HStack {
                        Text("自定义休息时长")
                        Spacer()
                        Text("\(settings.customBreakMinutes) 分钟")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Text("选择“自定义”预设后，下一轮会使用这里设置的工作和休息时长。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("休息结束后自动进入下一轮", isOn: $settings.autoStartNextRound)
                Toggle("休息开始时自动打开全屏倒计时", isOn: $settings.autoOpenBreakFullscreen)
            }

            Section("提醒") {
                Picker("提醒强度", selection: $settings.reminderStrength) {
                    ForEach(ReminderStrength.allCases) { strength in
                        Text(strength.title).tag(strength)
                    }
                }

                Text(settings.reminderStrength.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
    }
}
