import Foundation
import Observation

/// 记忆页的 @Observable store.
///
/// 对应 prototype 的 `window.MEMORY_OVERVIEW` 对象 (data/mock.js).
/// 后续接真实后端时换成 `GET /v1/memory/overview`.
@Observable
@MainActor
final class MemoryStore {
    // MARK: - Public state

    private(set) var stats: MemoryTreeStats
    private(set) var insights: [MemoryInsight]
    private(set) var entities: [MemoryEntity]
    private(set) var corrections: [CorrectionRecord]

    // MARK: - Derived

    /// 大标题下的副标题. 由底层数据派生, view 层直接读.
    var summaryLine: String {
        let totalEntities = entities.count
        let totalSedimented = stats.l3Descriptions
        let newToday = insights.filter { $0.highlight == .new }.count
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        let sedimentedText = formatter.string(from: NSNumber(value: totalSedimented)) ?? "\(totalSedimented)"
        return "\(totalEntities) 个实体 · \(sedimentedText) 条沉淀 · 今天新增 \(newToday) 条"
    }

    // MARK: - Init

    init(stats: MemoryTreeStats = MemoryStore.mockStats,
         insights: [MemoryInsight] = MemoryStore.mockInsights,
         entities: [MemoryEntity] = MemoryStore.mockEntities,
         corrections: [CorrectionRecord] = MemoryStore.mockCorrections) {
        self.stats = stats
        self.insights = insights
        self.entities = entities
        self.corrections = corrections
    }
}

// MARK: - Mock Data
//
// 直接从 prototype 的 data/mock.js 里 window.MEMORY_OVERVIEW 字面量翻译过来.
// `<b>...</b>` → `**...**` 以便 SwiftUI Text 自动识别 markdown 加粗.

extension MemoryStore {
    static let mock = MemoryStore()

    static let mockStats = MemoryTreeStats(
        l0Scenes: 18,
        l1Projects: 12,
        l2Episodes: 234,
        l3Descriptions: 1842,
        l4Raw: 12453
    )

    static let mockInsights: [MemoryInsight] = [
        .init(
            id: "mi-1",
            body: "**敦敏** 是 Linear Capital 合伙人, 偏好 closed-loop 定位的消费硬件项目, 对 Infra 叙事持保留态度",
            source: "和敦敏的 Series A 跟进会 · 10:34",
            highlight: .new
        ),
        .init(
            id: "mi-2",
            body: "Linear Capital 本轮带上了 **投资总监郑灿** 和合伙人 **马俊**, 阵容罕见加码, 内部对项目重视程度已拉满",
            source: "和敦敏的 Series A 跟进会 · 10:38",
            highlight: .new
        ),
        .init(
            id: "mi-3",
            body: "\"freestyle recording\" 是 **马俊** 建议的 marketing 主叙事, 用于替代晦涩的 \"15 dB SNR\" 技术语言",
            source: "和敦敏的 Series A 跟进会 · 10:58",
            highlight: .new
        ),
        .init(
            id: "mi-4",
            body: "**林啸** Memory A/B 测试: A 组检索准确率 **85%** vs baseline **71%**, 但 p95 latency 从 320ms 涨到 500ms",
            source: "林啸 Memory A/B 对比测试评审 · 16:48",
            highlight: .new
        )
    ]

    static let mockEntities: [MemoryEntity] = [
        .init(id: "e-1", avatar: "敦", name: "敦敏",
              kind: .person, memoryCount: 12,
              subtitle: "Linear Capital 合伙人 · 最近出现于 Series A 跟进会"),
        .init(id: "e-2", avatar: "M", name: "Monostone",
              kind: .project, memoryCount: 142,
              subtitle: "AI 记忆戒指项目 · 贯穿全部长录音"),
        .init(id: "e-3", avatar: "Ma", name: "Marshall",
              kind: .person, memoryCount: 45,
              subtitle: "硬件联创 · 前 OPPO / Harman"),
        .init(id: "e-4", avatar: "林", name: "林啸",
              kind: .person, memoryCount: 38,
              subtitle: "软件联创 / CTO · Memory 架构负责"),
        .init(id: "e-5", avatar: "S", name: "Series A",
              kind: .event, memoryCount: 23,
              subtitle: "融资轮次 · 跨 4 次会议"),
        .init(id: "e-6", avatar: "双", name: "双麦 15 dB SNR",
              kind: .concept, memoryCount: 18,
              subtitle: "产品核心差异化 · freestyle recording 叙事"),
        .init(id: "e-7", avatar: "L", name: "Linear Capital",
              kind: .organization, memoryCount: 8,
              subtitle: "领投方 · 上海办公室")
    ]

    static let mockCorrections: [CorrectionRecord] = [
        .init(id: "c-1",
              body: "你纠正: **敦敏** 不是\"投资总监\", 是\"合伙人\" · 已更新相关 7 条记忆",
              source: "2 小时前 · Agent 已学习",
              propagatedCount: 7),
        .init(id: "c-2",
              body: "你纠正: 马俊是 **合伙人** 不是普通 MD · 已更新 3 条记忆",
              source: "昨天 · Agent 已学习",
              propagatedCount: 3)
    ]
}
