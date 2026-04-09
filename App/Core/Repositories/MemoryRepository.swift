import Foundation

// MARK: - MemoryOverview

/// 记忆 Tab 一次加载就拿到的全部数据. 后端对应 `GET /v1/memory/overview`.
struct MemoryOverview: Hashable {
    let stats: MemoryTreeStats
    let insights: [MemoryInsight]
    let entities: [MemoryEntity]
    let corrections: [CorrectionRecord]
}

// MARK: - MemoryRepository

protocol MemoryRepository: Sendable {
    func loadOverview() async throws -> MemoryOverview
}

// MARK: - InMemoryMemoryRepository

/// 用 Swift 字面量作为 mock 数据源. 没 JSON 化, 因为 Memory 类型暂不需要 Codable.
/// 未来把 Memory 类型加 Codable + JSON 后可以无缝换成 `BundleMemoryRepository`.
///
/// 标 `@MainActor` 因为访问的 `MemoryStore.mockStats` 等 static property 都是
/// main-actor-isolated. 调用方 MemoryStore 也是 @MainActor, 不会有 actor hop.
@MainActor
struct InMemoryMemoryRepository: MemoryRepository {
    func loadOverview() async throws -> MemoryOverview {
        MemoryOverview(
            stats: MemoryStore.mockStats,
            insights: MemoryStore.mockInsights,
            entities: MemoryStore.mockEntities,
            corrections: MemoryStore.mockCorrections
        )
    }
}
