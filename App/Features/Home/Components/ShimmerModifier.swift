import SwiftUI

/// 卡片 processing 状态的 shimmer 扫光效果.
///
/// 对应 prototype `pages-and-interactions.md §H2 卡片骨架屏 Shimmer`:
/// - 宽度 30% 的白光条从左滑到右
/// - 周期 2.5s 无限循环
/// - 只在 `isActive == true` 时跑动画
///
/// 使用 `TimelineView(.animation)` 而不是手写 `@State` + `.onAppear` 启动的方式,
/// 避免 view 销毁时 leak 定时器;
/// `prefersReducedMotion` 状态下自动关闭动画（accessibility 要求）.
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && !reduceMotion {
                    TimelineView(.animation) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let phase = (t.truncatingRemainder(dividingBy: 2.5)) / 2.5
                        GeometryReader { proxy in
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Theme.accent.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: proxy.size.width * 0.3)
                            // -0.3 ~ 1.0 让光条完全扫出右边界
                            .offset(x: proxy.size.width * (phase * 1.3 - 0.3))
                        }
                    }
                    .allowsHitTesting(false)
                    .clipped()
                }
            }
    }
}

extension View {
    /// 当 `isActive` 为 true 时在 view 上叠加 shimmer 扫光.
    /// 遵循 `accessibilityReduceMotion` 环境变量.
    func shimmering(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 14)
        .fill(Theme.panel)
        .frame(width: 300, height: 100)
        .shimmering(isActive: true)
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
