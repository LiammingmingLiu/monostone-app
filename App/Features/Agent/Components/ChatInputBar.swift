import SwiftUI

/// Agent tab 底部的输入栏.
///
/// 结构: 麦克风按钮 + 输入胶囊 + 发送按钮.
/// - 麦克风: 长按说话（demo 阶段只 toast 提示）
/// - 输入框: TextField + focus 管理
/// - 发送按钮: 调用 `onSend` 回调, 由 store 处理
///
/// 键盘 avoidance 由 SwiftUI 默认行为处理 (输入框 focus 时自动抬起).
struct ChatInputBar: View {
    @Bindable var store: AgentStore
    @FocusState private var isFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                // 长按录音是 step 后续再做; 这里先是单击 toast 占位
            } label: {
                Circle()
                    .fill(Theme.panel)
                    .overlay { Circle().stroke(Theme.borderStrong, lineWidth: 0.5) }
                    .overlay {
                        Image(systemName: "mic")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("语音输入")

            TextField("问你的 Agent 任何事情...", text: $store.draftMessage, axis: .vertical)
                .focused($isFocused)
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.panel)
                .overlay {
                    Capsule()
                        .stroke(Theme.border, lineWidth: 0.5)
                }
                .clipShape(.capsule)
                .onSubmit {
                    if !store.draftMessage.isEmpty { onSend() }
                }

            Button {
                onSend()
                isFocused = false
            } label: {
                Circle()
                    .fill(canSend ? Theme.accent : Theme.panel)
                    .overlay {
                        Circle().stroke(
                            canSend ? Theme.accent : Theme.borderStrong,
                            lineWidth: 0.5
                        )
                    }
                    .overlay {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(canSend ? Color.black : Theme.textDimmer)
                    }
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .sensoryFeedback(.success, trigger: canSend ? 1 : 0)
            .accessibilityLabel("发送")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 0.5)
        }
    }

    private var canSend: Bool {
        !store.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputBar(store: AgentStore(), onSend: {})
    }
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
