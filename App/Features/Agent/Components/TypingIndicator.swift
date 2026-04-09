import SwiftUI

/// Agent 正在思考时的 3 点波浪跳动动画.
///
/// 对应 prototype `@keyframes typing-bounce`:
/// - 每个点在 1.4s 周期内从 opacity 0.3 + translateY 0 → opacity 1 + translateY(-4)
/// - 第 2、3 个点分别延迟 0.15s / 0.3s, 形成波浪
///
/// 使用 `TimelineView(.animation)` 驱动, 避免用 `@State` + `withAnimation(repeatForever)`
/// 在 view 消失时 leak 定时器.
struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let period: TimeInterval = 1.4
    private let dotSize: CGFloat = 6
    private let maxLift: CGFloat = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    let delay = Double(index) * 0.15
                    let phase = ((t - delay).truncatingRemainder(dividingBy: period)) / period
                    Circle()
                        .fill(Theme.textDim)
                        .frame(width: dotSize, height: dotSize)
                        .opacity(dotOpacity(phase: phase))
                        .offset(y: dotOffset(phase: phase))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.panel)
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
                .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
            )
            .accessibilityLabel("Agent 正在响应")
        }
    }

    /// 根据 phase (0.0 ~ 1.0) 计算 opacity (触发在 30% 时达到峰值)
    private func dotOpacity(phase: Double) -> Double {
        if reduceMotion { return 0.7 }
        // bell curve peaking at 0.3
        let p = phase < 0 ? phase + 1 : phase
        let distance = abs(p - 0.3)
        return 0.3 + (1.0 - min(distance * 3, 1.0)) * 0.7
    }

    /// 根据 phase 计算 translateY (触发在 30% 时达到 -maxLift)
    private func dotOffset(phase: Double) -> CGFloat {
        if reduceMotion { return 0 }
        let p = phase < 0 ? phase + 1 : phase
        let distance = abs(p - 0.3)
        let lift = (1.0 - min(distance * 3, 1.0))
        return -maxLift * lift
    }
}

#Preview {
    HStack {
        TypingIndicator()
        Spacer()
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
