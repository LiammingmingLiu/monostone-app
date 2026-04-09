import SwiftUI

/// Agent 聊天 Tab（对应 prototype s9 agent_tab）.
///
/// 结构：
/// - 自定义 `AgentNavBar` (脉动头像 + 在线状态)
/// - 聊天滚动区 `ScrollViewReader + LazyVStack<MessageBubble>`
///   - 新消息追加时自动滚到底
///   - 气泡入场用 `.transition` + `withAnimation`
/// - 底部 `ChatInputBar`
///   - 输入框 focus 时 SwiftUI 会自动处理键盘 avoidance
///
/// 导航栏被完全隐藏, 改用自定义 `AgentNavBar` 以匹配 prototype 的视觉.
struct AgentView: View {
    @State private var store = AgentStore()
    @State private var toastMessage: String?
    @State private var toastId = UUID()

    private let bottomAnchorID = "chat-bottom"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AgentNavBar(
                    agentModel: store.conversation.agentModel,
                    contextDaysLoaded: store.conversation.contextDaysLoaded
                )
                Divider().background(Theme.border)

                chatScroll

                ChatInputBar(store: store, onSend: handleSend)
            }
            .background(Theme.background)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) { toastOverlay }
            .task { await store.refresh() }
        }
    }

    // MARK: - Chat scroll

    private var chatScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(store.conversation.messages) { message in
                        MessageBubble(
                            message: message,
                            onActionTap: handleAction,
                            onAttachmentTap: handleAttachment
                        )
                        .id(message.id)
                    }
                    // 底部锚点用于自动滚动
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .onAppear {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
            .onChange(of: store.conversation.messages.count) { _, _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8),
                   value: store.conversation.messages.count)
    }

    // MARK: - Actions

    private func handleSend() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            store.sendDraftMessage()
        }
    }

    private func handleAction(_ action: AgentQuickAction) {
        showToast(action.toastMessage)
    }

    private func handleAttachment(_ attachment: AgentAttachment) {
        showToast("打开附件: \(attachment.title)")
    }

    private func showToast(_ message: String) {
        toastMessage = message
        toastId = UUID()
        let currentId = toastId
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if currentId == toastId {
                withAnimation(.easeIn(duration: 0.2)) { toastMessage = nil }
            }
        }
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if let toastMessage {
            Text(toastMessage)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.panel)
                .overlay { Capsule().stroke(Theme.border, lineWidth: 0.5) }
                .clipShape(.capsule)
                .padding(.bottom, 90)
                .transition(.opacity.combined(with: .offset(y: 10)))
                .animation(.easeOut(duration: 0.2), value: self.toastMessage)
        }
    }
}

#Preview {
    AgentView()
        .preferredColorScheme(.dark)
}
