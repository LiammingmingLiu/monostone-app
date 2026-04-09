import SwiftUI

/// Agent 回复下方的快捷按钮 pill 组.
///
/// 对应 prototype `.chat-actions`:
/// 青绿边框透明底的 pill, 点击 `scale(0.96)` 反馈 + toast.
struct QuickActionsRow: View {
    let actions: [AgentQuickAction]
    let onTap: (AgentQuickAction) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(actions) { action in
                Button {
                    onTap(action)
                } label: {
                    Text(action.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(Color.clear)
                        .overlay {
                            Capsule()
                                .strokeBorder(Theme.accent, lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    QuickActionsRow(
        actions: [
            .init(label: "查看全文",     toastMessage: "打开"),
            .init(label: "改得正式一点", toastMessage: "重写中"),
            .init(label: "直接发送",     toastMessage: "已发送")
        ],
        onTap: { _ in }
    )
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
