import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            timerCard
            actionButtons
            Divider()
            todaySummary
            Divider()
            footer
        }
        .padding(18)
        .frame(width: 340)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color(red: 0.95, green: 0.32, blue: 0.2))

            VStack(alignment: .leading, spacing: 2) {
                Text("远眺")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(model.phaseTitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.state.phase != .idle {
                Text(model.currentMode.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var timerCard: some View {
        VStack(spacing: 10) {
            Text(model.formattedRemaining)
                .font(.system(size: 44, weight: .light, design: .monospaced))
                .frame(maxWidth: .infinity)

            ProgressView(value: model.progress)
                .tint(Color(red: 0.95, green: 0.32, blue: 0.2))

            if model.state.phase == .idle {
                Text(model.preferences.mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !model.state.isRunning {
                Text("已暂停")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 6)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(model.primaryActionTitle) {
                model.toggleRunning()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.95, green: 0.32, blue: 0.2))

            if model.state.phase == .working {
                Button("提前休息") {
                    model.takeBreakNow()
                }
                .buttonStyle(.bordered)
            } else if model.state.phase.isBreak {
                Button("跳过这次") {
                    model.skipCurrentPhase()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("今日")
                    .font(.headline)
                Spacer()
                Text(model.formattedFocusedTime)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 18) {
                summaryItem(title: "护眼休息", value: "\(model.stats.completedBreaks) 次", symbol: "eye")
                summaryItem(title: "最长连续", value: formatLongestFocus, symbol: "chart.bar.xaxis")
                summaryItem(title: "跳过", value: "\(model.stats.skippedCount) 次", symbol: "forward.end")
            }
        }
    }

    private var formatLongestFocus: String {
        let seconds = model.stats.longestFocusSeconds
        if seconds < 60 { return String(format: "%d 秒", seconds) }
        return String(format: "%d 分钟", seconds / 60)
    }

    private func summaryItem(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .medium))
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Button("设置") {
                SettingsWindowController.shared.show(model: model)
            }
            .buttonStyle(.link)

            Button("重置") {
                model.reset()
            }
            .buttonStyle(.link)

            Spacer()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.link)
        }
        .font(.caption)
    }
}
