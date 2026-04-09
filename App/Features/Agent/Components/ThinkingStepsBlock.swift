import SwiftUI

/// Agent 消息气泡内的"思考步骤"折叠块.
///
/// 对应 prototype `.chat-row .thinking`:
/// dashed 边框 + 小号字 + 每步带状态色（done 绿 / running 紫 / pending 灰）.
/// 每步前加 ✓ / ◦ / ! 标记便于快速扫描.
struct ThinkingStepsBlock: View {
    let steps: [AgentThinkingStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(spacing: 6) {
                    Text(marker(for: step.status))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(color(for: step.status))
                    Text(step.text)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                .foregroundStyle(Theme.border)
        }
        .clipShape(.rect(cornerRadius: 8))
    }

    private func marker(for status: AgentThinkingStep.Status) -> String {
        switch status {
        case .done:    "✓"
        case .running: "◦"
        case .pending: "·"
        case .failed:  "!"
        }
    }

    private func color(for status: AgentThinkingStep.Status) -> Color {
        switch status {
        case .done:    Theme.typeTodo
        case .running: Theme.typeCommand
        case .pending: Theme.textDimmer
        case .failed:  .red
        }
    }
}

#Preview {
    ThinkingStepsBlock(steps: [
        .init(text: "调用 memory: 敦敏、Marshall、ODM", status: .done),
        .init(text: "检索今早 Series A 会议纪要", status: .done),
        .init(text: "分析 Marshall 的沟通偏好", status: .running),
        .init(text: "参考上周四 ODM 讨论的措辞", status: .pending)
    ])
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
