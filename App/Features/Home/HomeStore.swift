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
    /// 按 cardId 索引的 action items; 只有 `type == .longRec` 的卡片会有
    var actionItemsByCard: [String: [ActionItem]]

    // MARK: - Init

    init(cards: [Card] = HomeStore.mockCards,
         summary: DailySummary = HomeStore.mockSummary,
         actionItemsByCard: [String: [ActionItem]] = HomeStore.mockActionItems) {
        self.cards = cards
        self.summary = summary
        self.filteredCards = cards
        self.actionItemsByCard = actionItemsByCard
    }

    // MARK: - Action item helpers

    func actionItems(for cardId: String) -> [ActionItem] {
        actionItemsByCard[cardId] ?? []
    }

    func actionItem(cardId: String, itemId: String) -> ActionItem? {
        actionItemsByCard[cardId]?.first { $0.id == itemId }
    }

    /// 删除一条 Action Item.
    ///
    /// 实际 prototype 语义是 **软删除** (`rejected = true`), 但当前 UI 层只关心"从列表
    /// 里移除". Step 9 (数据层抽象) 时会把这个改成 PATCH + optimistic update.
    ///
    /// **副作用说明 (对应 prototype `rejectActionItemBySwipe` 的注释)**:
    /// - 从结构化摘要里 "N 项待办" 计数 -1
    /// - 反馈给分类器: "这条 AI 推断是错的"
    /// - Memory: **不记录** 任何 commitment (用户主动拒绝, 不是承诺)
    func deleteActionItem(cardId: String, itemId: String) {
        guard var list = actionItemsByCard[cardId] else { return }
        list.removeAll { $0.id == itemId }
        if list.isEmpty {
            actionItemsByCard.removeValue(forKey: cardId)
        } else {
            actionItemsByCard[cardId] = list
        }
    }

    /// 重置一张卡片的 action items 回到初始 mock 状态 (demo 用的 reset 按钮).
    func restoreActionItems(for cardId: String) {
        if let initial = HomeStore.mockActionItems[cardId] {
            actionItemsByCard[cardId] = initial
        }
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

    static let mockActionItems: [String: [ActionItem]] = [
        "rec-1": [
            ActionItem(
                id: "ai-1",
                cardId: "rec-1",
                text: "Marshall 锁定 ODM 合作方",
                owner: "Marshall",
                deadline: "4 月底",
                sourceQuote: "Marshall 你周五前要把 ODM 供应商的事情定下来, 不然影响后面的节奏. 我们不能再拖了, 下轮融资前必须要有一个明确的交付节奏.",
                sourceCard: "和敦敏的 Series A 跟进会",
                sourceTime: "14:32",
                agentSuggestions: [
                    "帮我起草一封 follow-up 邮件给 Marshall, 语气温和但要给明确节奏",
                    "查一下我们目前评估过的 ODM 候选有哪些, 各自的优劣",
                    "关联一下上次的硬件 roadmap 讨论, 看看 ODM 选型会影响到哪些节点"
                ]
            ),
            ActionItem(
                id: "ai-2",
                cardId: "rec-1",
                text: "把双麦 SNR 数据整理成 marketing 故事",
                owner: "石慧",
                deadline: "本周",
                sourceQuote: "石慧你帮我把双麦 15dB 的数据提炼一下, 不要用技术语言 —— 改成 freestyle recording 的场景故事, 走路、开车、户外都能清晰录音.",
                sourceCard: "和敦敏的 Series A 跟进会",
                sourceTime: "27:18",
                agentSuggestions: [
                    "帮我拉一下最近三次户外录音测试的 SNR 数据, 整理成表格",
                    "写一版 \"freestyle recording\" 的场景故事草稿, 三段就好",
                    "查一下竞品 Sandbar、Humane 他们是怎么讲录音清晰度的"
                ]
            ),
            ActionItem(
                id: "ai-3",
                cardId: "rec-1",
                text: "研究 EO 14117 美国数据法规",
                owner: "明明",
                deadline: "下周前",
                sourceQuote: "明明你抽空看一下 EO 14117, 这是美国对涉及敏感个人数据的外国控制技术的限制, 可能影响 Monostone 进入美国市场的策略. 下周前给我一份简短的分析.",
                sourceCard: "和敦敏的 Series A 跟进会",
                sourceTime: "38:45",
                agentSuggestions: [
                    "帮我查 EO 14117 最近 3 个月的执行动态",
                    "找一下做 AI 硬件的中国公司是怎么应对这个法规的",
                    "生成一份 1 页纸分析给 Linear 的合规团队"
                ]
            )
        ],
        "rec-2": [
            ActionItem(
                id: "ai-4",
                cardId: "rec-2",
                text: "上线 A/B 动态切换逻辑",
                owner: "林啸",
                deadline: "周五前",
                sourceQuote: "那我本周把动态切换逻辑 ship 出去. 短会话走 baseline, 长会话走 A 组, 这样 latency 和准确率都不损失.",
                sourceCard: "林啸 Memory A/B 对比测试评审",
                sourceTime: "18:22",
                agentSuggestions: [
                    "帮我看一下当前动态切换的代码 diff 和测试覆盖",
                    "起草一份上线公告给团队, 说清楚为什么要动态切换",
                    "设定一个周四的提醒, 跟进林啸的上线进度"
                ]
            ),
            ActionItem(
                id: "ai-5",
                cardId: "rec-2",
                text: "集成 confidence decay 机制",
                owner: "王浩",
                deadline: "下周",
                sourceQuote: "王浩你把 confidence decay 的 v1 做出来, 先用指数衰减, 参数粗调. 记得预留受保护 memory 的锁定机制.",
                sourceCard: "林啸 Memory A/B 对比测试评审",
                sourceTime: "21:10",
                agentSuggestions: [
                    "帮我找关于 SM-2 算法和 Ebbinghaus 遗忘曲线的权威资料",
                    "列一个 v1 confidence decay 的 task breakdown, 按优先级",
                    "关联到之前明明走路时的那条灵感录音"
                ]
            )
        ]
    ]

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
