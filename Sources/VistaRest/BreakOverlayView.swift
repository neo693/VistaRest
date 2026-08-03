import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: model.state.phase == .longBreak ? "figure.walk" : "eye")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color(red: 0.98, green: 0.52, blue: 0.34))

                Text(model.state.phase == .longBreak ? "离开屏幕" : "看远处")
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)

                Text(model.breakInstruction)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.72))

                Text(model.formattedRemaining)
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))

                Text("不需要盯着倒计时")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))

                HStack(spacing: 12) {
                    Button(model.state.isRunning ? "暂停" : "继续休息") {
                        model.toggleRunning()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("跳过这次") {
                        model.skipCurrentPhase()
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.8))
                }
            }
            .frame(width: 420, height: 360)
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
