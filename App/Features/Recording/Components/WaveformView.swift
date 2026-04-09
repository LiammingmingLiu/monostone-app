import SwiftUI

/// 长录音页面中央的律动波形.
///
/// 对应 prototype `.wave` + `@keyframes wave`:
/// - 10 条竖条, 宽 5px, 高度 14~90px 之间律动
/// - 周期 1.2s, `ease-in-out`
/// - 每条相对前一条递增 80ms delay, 形成波浪感
///
/// 用 `TimelineView(.animation)` 驱动, 单个 view 每帧计算每条 bar 的高度.
/// 不用 `@State + withAnimation(.repeatForever)` 因为那种写法在 view 隐藏
/// 时定时器会 leak.
struct WaveformView: View {
    let barCount: Int
    let maxHeight: CGFloat
    let minHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(barCount: Int = 12, minHeight: CGFloat = 14, maxHeight: CGFloat = 90) {
        self.barCount = barCount
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 6) {
                ForEach(0..<barCount, id: \.self) { index in
                    let delay = Double(index) * 0.08
                    let phase = ((t - delay).truncatingRemainder(dividingBy: 1.2)) / 1.2
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 5, height: heightFor(phase: phase))
                        .shadow(color: Theme.accent.opacity(0.4), radius: 4)
                }
            }
            .frame(height: maxHeight)
        }
        .accessibilityLabel("正在录音")
        .accessibilityValue("波形动画")
    }

    /// phase ∈ [0, 1) 时返回 sine-wave 高度
    private func heightFor(phase: Double) -> CGFloat {
        if reduceMotion { return (maxHeight + minHeight) / 2 }
        // sine wave 从 -1 到 1, 映射到 minHeight..maxHeight
        let sine = sin(phase * .pi * 2)
        let normalized = (sine + 1) / 2 // 0..1
        return minHeight + (maxHeight - minHeight) * normalized
    }
}

#Preview {
    WaveformView()
        .padding(40)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
