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
                    ForEach(TimerPreset.builtIn) { preset in
                        VStack(alignment: .leading) {
                            Text(preset.title)
                            Text(preset.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(preset.id)
                    }
                }

                Toggle("休息结束后自动进入下一轮", isOn: $settings.autoStartNextRound)
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
