import Foundation

// MARK: - AgentRepository

/// Agent 聊天数据源抽象.
/// 真实实现: `GET /v1/agent/conversation?date=<today>` + `POST /v1/agent/messages` +
/// WebSocket stream. 这里只抽象了"拉取当前 conversation"这一个读操作,
/// 发消息 / 订阅 stream 留到后续.
protocol AgentRepository: Sendable {
    func loadCurrentConversation() async throws -> AgentConversation
}

// MARK: - InMemoryAgentRepository

/// 用 Swift 字面量作为 mock. AgentMessage.Kind 有关联值枚举, JSON 化需要自定义
/// Codable 实现; Step 9 先用 InMemory, 未来有时间再 JSON 化.
///
/// 标 `@MainActor` 因为 `AgentStore.mockConversation` 是 main-actor-isolated
/// static property. 调用方 AgentStore 也是 @MainActor, 不会有额外 actor hop.
@MainActor
struct InMemoryAgentRepository: AgentRepository {
    func loadCurrentConversation() async throws -> AgentConversation {
        AgentStore.mockConversation
    }
}
