import Foundation

// MARK: - HomeFeed

/// 首页一次加载就拿到的全部数据. 等同于后端 `GET /v1/home/feed` 的响应.
///
/// 之所以把 3 份数据打包成一个 struct, 是为了:
/// 1. 首页一次 request / 一次 Bundle 读取就能渲染, 避免多个 loading state
/// 2. Codable 层级清晰, JSON 文件也一个就够了
struct HomeFeed: Codable, Hashable {
    let cards: [Card]
    let actionItemsByCard: [String: [ActionItem]]
    let summary: DailySummary
}

// MARK: - HomeRepository

/// 首页数据源抽象.
/// 真实实现应该打 `GET /v1/home/feed`; 当前 Step 9 用的是 Bundle JSON.
protocol HomeRepository: Sendable {
    func loadFeed() async throws -> HomeFeed
}

// MARK: - BundleHomeRepository

/// 从 app bundle 里的 `home.json` 加载首页数据.
struct BundleHomeRepository: HomeRepository {
    func loadFeed() async throws -> HomeFeed {
        try await JSONBundleLoader.load("home", as: HomeFeed.self)
    }
}
