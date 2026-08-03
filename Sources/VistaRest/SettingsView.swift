import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            timingTab
                .tabItem {
                    Label("计时", systemImage: "timer")
                }

            reminderTab
                .tabItem {
                    Label("提醒", systemImage: "bell")
                }

            privacyTab
                .tabItem {
                    Label("本地数据", systemImage: "externaldrive")
                }
        }
        .frame(width: 480, height: 430)
        .padding()
    }

    private var timingTab: some View {
        Form {
            Section("模式") {
                Picker("默认模式", selection: Binding(
                    get: { model.preferences.mode },
                    set: { model.selectMode($0) }
                )) {
                    ForEach(TimerMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .disabled(model.state.phase != .idle)

                if model.state.phase != .idle {
                    Text("当前计时结束后才能切换模式")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("护眼模式") {
                Stepper(value: binding(for: \AppPreferences.eyeCareWorkMinutes), in: 1...120) {
                    LabeledContent("工作时长", value: "\(model.preferences.eyeCareWorkMinutes) 分钟")
                }
                Stepper(value: binding(for: \AppPreferences.microBreakSeconds), in: 5...300, step: 5) {
                    LabeledContent("微休息", value: "\(model.preferences.microBreakSeconds) 秒")
                }
            }

            Section("经典番茄") {
                Stepper(value: binding(for: \AppPreferences.pomodoroWorkMinutes), in: 1...120) {
                    LabeledContent("工作时长", value: "\(model.preferences.pomodoroWorkMinutes) 分钟")
                }
                Stepper(value: binding(for: \AppPreferences.pomodoroShortBreakMinutes), in: 1...60) {
                    LabeledContent("短休息", value: "\(model.preferences.pomodoroShortBreakMinutes) 分钟")
                }
                Stepper(value: binding(for: \AppPreferences.pomodoroLongBreakMinutes), in: 1...90) {
                    LabeledContent("长休息", value: "\(model.preferences.pomodoroLongBreakMinutes) 分钟")
                }
            }

            Section("深度工作") {
                Stepper(value: binding(for: \AppPreferences.deepWorkMinutes), in: 5...180, step: 5) {
                    LabeledContent("总工作时长", value: "\(model.preferences.deepWorkMinutes) 分钟")
                }
                Stepper(value: deepIntervalBinding, in: 5...120, step: 5) {
                    LabeledContent("远眺间隔", value: "\(model.preferences.deepBreakIntervalMinutes) 分钟")
                }
                Stepper(value: binding(for: \AppPreferences.deepLongBreakMinutes), in: 1...90) {
                    LabeledContent("长休息", value: "\(model.preferences.deepLongBreakMinutes) 分钟")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var reminderTab: some View {
        Form {
            Section("提醒强度") {
                Picker("提醒方式", selection: Binding(
                    get: { model.preferences.reminderStyle },
                    set: { value in
                        model.updatePreferences { preferences in
                            preferences.reminderStyle = value
                        }
                    }
                )) {
                    ForEach(ReminderStyle.allCases) { style in
                        VStack(alignment: .leading) {
                            Text(style.title)
                            Text(style.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(style)
                    }
                }

                Toggle("提示音", isOn: Binding(
                    get: { model.preferences.soundEnabled },
                    set: { value in model.updatePreferences { $0.soundEnabled = value } }
                ))
            }

            Section("计时行为") {
                Toggle("自动开始下一阶段", isOn: Binding(
                    get: { model.preferences.autoStartNextPhase },
                    set: { value in model.updatePreferences { $0.autoStartNextPhase = value } }
                ))
                Text("关闭后，工作或休息结束时会停在下一阶段，等你手动开始。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("菜单栏") {
                Toggle("显示剩余时间", isOn: Binding(
                    get: { model.preferences.showRemainingInMenuBar },
                    set: { value in model.updatePreferences { $0.showRemainingInMenuBar = value } }
                ))
                Text("关闭后，菜单栏只显示远眺图标。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var privacyTab: some View {
        Form {
            Section("本地存储") {
                Text("远眺不会要求登录。计时状态、今日统计和设置仅保存在这台 Mac 的 UserDefaults 中。")
                    .fixedSize(horizontal: false, vertical: true)

                Button("删除本机数据", role: .destructive) {
                    model.deleteLocalData()
                }
            }
        }
        .formStyle(.grouped)
    }

    private var deepIntervalBinding: Binding<Int> {
        Binding(
            get: { model.preferences.deepBreakIntervalMinutes },
            set: { value in
                model.updatePreferences {
                    $0.deepBreakIntervalMinutes = min(max(5, value), max(5, $0.deepWorkMinutes))
                }
            }
        )
    }

    private func binding<Value>(for keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { model.preferences[keyPath: keyPath] },
            set: { value in
                model.updatePreferences { $0[keyPath: keyPath] = value }
            }
        )
    }
}
