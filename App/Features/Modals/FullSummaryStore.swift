import Foundation
import Observation

/// 完整会议纪要的 @Observable store.
///
/// Step 9 refactor: 从 `enum` 静态 lookup 改成 instance-based store, 这样可以:
/// - 通过 `repository` 抽象 mock / JSON / 未来的网络实现
/// - 把加载错误 (`lastLoadError`) 暴露给 view
/// - 和其他 store 保持一致的生命周期 (owned by view via @State)
///
/// 初始化时立即用 `seedSummaries` (Swift literal) 填充, 保证冷启动零等待;
/// `.task { await refresh() }` 从 bundle JSON 刷新.
@Observable
@MainActor
final class FullSummaryStore {
    // MARK: - State

    private(set) var summaries: [String: FullSummary]
    private(set) var lastLoadError: Error?

    // MARK: - Dependencies

    private let repository: any FullSummaryRepository

    // MARK: - Init

    init(
        repository: any FullSummaryRepository = BundleFullSummaryRepository(),
        seed: [String: FullSummary] = FullSummaryStore.seedSummaries
    ) {
        self.repository = repository
        self.summaries = seed
    }

    // MARK: - Lookup

    func summary(for cardId: String) -> FullSummary? {
        summaries[cardId]
    }

    // MARK: - Async loading

    func refresh() async {
        do {
            let loaded = try await repository.loadAll()
            self.summaries = loaded
            self.lastLoadError = nil
        } catch {
            self.lastLoadError = error
        }
    }
}

// MARK: - Seed data (fallback for cold start)

extension FullSummaryStore {
    /// 最小 seed 数据, 防止 Bundle 加载失败时没东西可显示.
    /// 真正的展示数据在 `Resources/MockData/full_summaries.json` 里, 内容更丰富.
    static let seedSummaries: [String: FullSummary] = [
        "rec-1": FullSummary(
            cardId: "rec-1",
            title: "和敦敏的 Series A 跟进会 · 会议纪要",
            meta: [
                .init(key: "会议时间", value: "2026 年 4 月 9 日（周三）10:30 – 11:12"),
                .init(key: "会议时长", value: "42 分 18 秒"),
                .init(key: "参会人员", value: "敦敏、明明、郑灿、马俊"),
                .init(key: "会议项目", value: "Series A 融资 · D-Day"),
                .init(key: "会议形式", value: "线下会议 · Linear Capital 上海办公室")
            ],
            sections: [
                SummarySection(heading: "会议背景", blocks: [
                    .paragraph("加载中…")
                ])
            ]
        )
    ]
}
