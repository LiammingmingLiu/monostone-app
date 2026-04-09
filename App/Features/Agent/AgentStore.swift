import Foundation
import Observation

/// Agent 聊天的 @Observable store.
///
/// 对应 prototype `window.AGENT_CONVERSATION` (data/mock.js).
/// 真实实现走 `GET /v1/agent/conversation` + `POST /v1/agent/messages` + WS stream.
@Observable
@MainActor
final class AgentStore {
    private(set) var conversation: AgentConversation

    /// 用户正在输入的文本（用于 ChatInputBar）
    var draftMessage: String = ""

    /// 当前是否正在显示 typing indicator
    var isAgentTyping: Bool {
        conversation.messages.last.map {
            if case .typing = $0.kind { return true }
            return false
        } ?? false
    }

    init(conversation: AgentConversation = AgentStore.mockConversation) {
        self.conversation = conversation
    }

    // MARK: - Actions

    /// 用户发送一条消息 (demo 行为: 直接 append + 模拟 agent 开始 typing)
    func sendDraftMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 插入用户消息
        let userMessage = AgentMessage(
            role: .user,
            kind: .text(markdown: trimmed)
        )

        // 移除旧的 typing indicator（如果有）
        conversation.messages.removeAll { if case .typing = $0.kind { return true }; return false }
        conversation.messages.append(userMessage)

        // 清空 draft
        draftMessage = ""

        // 模拟 agent 开始回复: 500ms 后显示 typing
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            let typing = AgentMessage(role: .agent, kind: .typing)
            conversation.messages.append(typing)
        }
    }
}

// MARK: - Mock Data
//
// 直接从 prototype data/mock.js 的 window.AGENT_CONVERSATION 翻译而来.
// HTML `<br>` 在 Swift 里用真换行 \n 代替, `<b>...</b>` → `**...**` 让 markdown 生效.

extension AgentStore {
    static let mockConversation = AgentConversation(
        id: "conv-2026-04-09",
        agentModel: "Claude Opus 4.6",
        contextDaysLoaded: 42,
        messages: [
            .init(role: .date, kind: .text(markdown: "今天 · 14:30")),
            .init(role: .system, kind: .text(
                markdown: "我是你的 Agent · 已加载今天全部会议纪要和 memory · 有问题直接问, 或按住录音键说话"
            )),
            .init(role: .user, kind: .text(
                markdown: "今天上午敦敏那个会的核心结论是什么?"
            )),
            .init(role: .agent, kind: .text(markdown: """
            三个核心结论:
            1. **定位已对齐** — 按 closed-loop 消费硬件估值, 但承认 Infra 叙事的想象空间
            2. **竞争排序** — OpenAI 最大威胁, Apple 反而最低
            3. **品类风险 > 对手风险** — 用双麦 15 dB + 高频交互对冲

            马俊额外建议把技术语言改成 "freestyle recording" 场景叙事.
            """)),
            .init(role: .user, kind: .text(
                markdown: "帮我起草给 Marshall 的 follow-up 邮件, 基于今早这个会"
            )),
            .init(role: .agent, kind: .steps([
                .init(text: "调用 memory: 敦敏、Marshall、ODM、Series A", status: .done),
                .init(text: "检索今早 Series A 会议纪要 (42 分钟)", status: .done),
                .init(text: "分析 Marshall 的历史沟通偏好 (45 条记忆)", status: .done),
                .init(text: "参考上周四 ODM 讨论的措辞风格", status: .done)
            ])),
            .init(role: .agent, kind: .text(
                markdown: "基于今早 Series A 会议 + Marshall 的沟通偏好, 起草了一版:"
            )),
            .init(role: .agent, kind: .attachment(.init(
                icon: "envelope",
                title: "Re: ODM 合作节奏对齐",
                subtitle: "收件人: marshall@monostone.com · 3 段 · 语气: 专业+友好",
                attachmentType: .email
            ))),
            .init(role: .agent, kind: .actions([
                .init(label: "查看全文",         toastMessage: "打开邮件全文"),
                .init(label: "改得正式一点",     toastMessage: "Agent 正在重写, 调整为更正式的语气..."),
                .init(label: "直接发送",         toastMessage: "已通过 Gmail 发送 · 同步到 Linear")
            ])),
            .init(role: .user, kind: .text(
                markdown: "改得正式一点, 然后把双麦 SNR 数据加进去"
            )),
            .init(role: .agent, kind: .typing)
        ]
    )
}
