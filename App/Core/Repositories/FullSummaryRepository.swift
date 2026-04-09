import Foundation

// MARK: - FullSummaryIndex

/// 按 `cardId` 索引的完整会议纪要. 后端对应 `GET /v1/full-summaries` (预留).
struct FullSummaryIndex: Codable, Hashable {
    let summaries: [String: FullSummary]
}

// MARK: - FullSummaryRepository

protocol FullSummaryRepository: Sendable {
    func loadAll() async throws -> [String: FullSummary]
}

// MARK: - BundleFullSummaryRepository

struct BundleFullSummaryRepository: FullSummaryRepository {
    func loadAll() async throws -> [String: FullSummary] {
        let index = try await JSONBundleLoader.load("full_summaries", as: FullSummaryIndex.self)
        return index.summaries
    }
}
