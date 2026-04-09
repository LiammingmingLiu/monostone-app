import SwiftUI

/// Agent tab 自定义导航栏.
///
/// 结构:
/// - 脉动头像（青绿圆点 + 外发光）
/// - "Agent" 标题
/// - 在线状态绿点 + 模型 + context 天数
///
/// 头像脉动用 TimelineView 驱动, 周期 2s.
struct AgentNavBar: View {
    let agentModel: String
    let contextDaysLoaded: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            pulsingAvatar
            VStack(alignment: .leading, spacing: 2) {
                Text("Agent")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 5) {
                    Circle()
                        .fill(Theme.typeTodo)
                        .frame(width: 5, height: 5)
                        .shadow(color: Theme.typeTodo.opacity(0.6), radius: 3)
                    Text("在线 · \(agentModel) · 已加载 \(contextDaysLoaded) 天 context")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: - Pulsing avatar

    private var pulsingAvatar: some View {
        ZStack {
            if !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let phase = (t.truncatingRemainder(dividingBy: 2.0)) / 2.0
                    Circle()
                        .stroke(Theme.accent, lineWidth: 0.5)
                        .scaleEffect(1.0 + phase * 0.4)
                        .opacity(1.0 - phase)
                }
                .frame(width: 34, height: 34)
            }
            Circle()
                .fill(Theme.accent.opacity(0.12))
                .overlay { Circle().stroke(Theme.accent, lineWidth: 0.5) }
                .frame(width: 34, height: 34)
                .shadow(color: Theme.accent.opacity(0.2), radius: 6)
        }
    }
}

#Preview {
    VStack {
        AgentNavBar(agentModel: "Claude Opus 4.6", contextDaysLoaded: 42)
        Spacer()
    }
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
