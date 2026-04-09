import Foundation
import Observation

/// 首页的 @Observable store
///
/// - 持有 mock 数据, 未来替换成 URLSession / async fetch
/// - `filteredCards` 是派生视图, store 内部缓存, 避免在 view 里 inline `.filter()`
///   （list-patterns.md 规则: 不允许在 ForEach 上直接 filter）
@Observable
@MainActor
final class HomeStore {
    // MARK: - Public state

    var selectedFilter: FilterType = .all {
        didSet { recomputeFiltered() }
    }
    private(set) var cards: [Card]
    private(set) var filteredCards: [Card]
    let summary: DailySummary

    // MARK: - Init

    init(cards: [Card] = HomeStore.mockCards,
         summary: DailySummary = HomeStore.mockSummary) {
        self.cards = cards
        self.summary = summary
        self.filteredCards = cards
    }

    // MARK: - Derived state

    private func recomputeFiltered() {
        filteredCards = cards.filter { selectedFilter.matches($0) }
    }

    /// 计算每种类型的卡片数（供 filter chip 角标显示）
    func count(for filter: FilterType) -> Int {
        switch filter {
        case .all: cards.count
        default:   cards.filter { filter.matches($0) }.count
        }
    }
}

// MARK: - Mock Data
//
// 直接映射 prototype `data/mock.js` 里 4 种卡片的字段。
// 实现 step 9（数据层）时会把这里换成从 JSON 加载或走 API.

extension HomeStore {
    static let mockSummary = DailySummary(
        greeting: "早上好，明明",
        dayCount: 12,
        ringConnected: true,
        interactionsToday: 8,
        timeSavedMinutes: 47,
        interactionBreakdown: .init(walking: 3, postMeeting: 3, atDesk: 2)
    )

    static let mockCards: [Card] = [
        Card(
            id: "rec-1",
            type: .longRec,
            title: "和敦敏的 Series A 跟进会",
            timeRelative: "2 小时前",
            status: .done,
            durationSec: 42 * 60 + 18,
            participantsCount: 4,
            pendingActionCount: 3,
            owner: nil,
            deadline: nil,
            project: "Series A",
            processingMeta: nil
        ),
        Card(
            id: "cmd-1",
            type: .command,
            title: "起草给敦敏的 follow-up 邮件",
            timeRelative: "1 小时前",
            status: .processing,
            durationSec: nil,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: "Agent",
            deadline: "今天",
            project: "Series A",
            processingMeta: "Step 3 / 5 · 生成邮件正文"
        ),
        Card(
            id: "idea-1",
            type: .idea,
            title: "\"Agent 记忆泄漏\" 的修复思路",
            timeRelative: "30 分钟前",
            status: .done,
            durationSec: 8,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: nil,
            deadline: nil,
            project: "Monostone 后端",
            processingMeta: nil
        ),
        Card(
            id: "todo-1",
            type: .todo,
            title: "周四下午 3 点去看牙医",
            timeRelative: "昨天",
            status: .done,
            durationSec: nil,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: "明明",
            deadline: "4/11 15:00",
            project: nil,
            processingMeta: nil
        ),
        Card(
            id: "rec-2",
            type: .longRec,
            title: "林啸 Memory A/B 对比测试评审",
            timeRelative: "昨天",
            status: .done,
            durationSec: 28 * 60 + 4,
            participantsCount: 3,
            pendingActionCount: 3,
            owner: nil,
            deadline: nil,
            project: "Monostone 后端 · Memory",
            processingMeta: nil
        )
    ]
}

// MARK: - Formatting helpers

extension Card {
    /// 将 `durationSec` 格式化成 "42:18" 或 "0:08"
    var durationDisplay: String? {
        guard let durationSec else { return nil }
        let minutes = durationSec / 60
        let seconds = durationSec % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 首页卡片下方的 meta 行内容，根据类型拼出 e.g.
    /// - longRec: "42:18 · 4 人 · 3 项待办"
    /// - command: "Agent · 今天"
    /// - idea:    "0:08 · Monostone 后端"
    /// - todo:    "明明 · 4/11 15:00"
    var metaLine: String {
        switch type {
        case .longRec:
            var parts: [String] = []
            if let d = durationDisplay { parts.append(d) }
            if let n = participantsCount { parts.append("\(n) 人") }
            if let p = pendingActionCount, p > 0 { parts.append("\(p) 项待办") }
            return parts.joined(separator: " · ")
        case .command:
            var parts: [String] = []
            if let owner { parts.append(owner) }
            if let deadline { parts.append(deadline) }
            return parts.joined(separator: " · ")
        case .idea:
            var parts: [String] = []
            if let d = durationDisplay { parts.append(d) }
            if let p = project { parts.append(p) }
            return parts.joined(separator: " · ")
        case .todo:
            var parts: [String] = []
            if let owner { parts.append(owner) }
            if let deadline { parts.append(deadline) }
            return parts.joined(separator: " · ")
        }
    }
}
