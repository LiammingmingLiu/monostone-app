import Foundation

// MARK: - AgentConversation

/// 对应 prototype `data-models.md §19.c AgentConversation`.
/// 每天自动开一个新 conversation, id 格式 `conv-YYYY-MM-DD`.
struct AgentConversation: Hashable {
    let id: String
    let agentModel: String
    let contextDaysLoaded: Int
    var messages: [AgentMessage]
}

// MARK: - AgentMessage

/// IM 聊天消息. 5 种 `kind` 对应 prototype `data-models.md §19.d`.
struct AgentMessage: Identifiable, Hashable {
    let id: UUID
    let role: Role
    let kind: Kind

    init(id: UUID = UUID(), role: Role, kind: Kind) {
        self.id = id
        self.role = role
        self.kind = kind
    }

    enum Role: Hashable {
        case date        // 日期分隔符，居中小字
        case system      // 系统提示，居中 pill
        case user        // 用户气泡，右对齐，accent 背景
        case agent       // agent 气泡，左对齐，panel 背景
    }

    /// 消息的实际内容类型. 用户消息只会有 `.text`;
    /// agent 消息可能是 text / steps / attachment / actions / typing 之一.
    enum Kind: Hashable {
        case text(markdown: String)
        case steps([AgentThinkingStep])
        case attachment(AgentAttachment)
        case actions([AgentQuickAction])
        case typing
    }
}

// MARK: - AgentThinkingStep

/// 对应 prototype `data-models.md §19.d.1 AgentThinkingStep`.
struct AgentThinkingStep: Hashable {
    let text: String
    let status: Status

    enum Status: Hashable {
        case pending
        case running
        case done
        case failed
    }
}

// MARK: - AgentAttachment

/// 对应 prototype `data-models.md §19.d.2 AgentAttachment`.
struct AgentAttachment: Hashable {
    let icon: String        // SF Symbol name
    let title: String
    let subtitle: String
    let attachmentType: AttachmentType

    enum AttachmentType: Hashable {
        case email
        case deck
        case report
        case doc
        case link
    }
}

// MARK: - AgentQuickAction

/// 对应 prototype `data-models.md §19.d.3 AgentQuickAction`.
struct AgentQuickAction: Identifiable, Hashable {
    let id: UUID
    let label: String
    let toastMessage: String

    init(id: UUID = UUID(), label: String, toastMessage: String) {
        self.id = id
        self.label = label
        self.toastMessage = toastMessage
    }
}
