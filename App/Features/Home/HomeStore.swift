import Foundation
import Observation
import WidgetKit

/// 首页的 @Observable store
///
/// - 初始化时立即用 Swift 字面量 mock 数据 seed, 保证**冷启动零等待**
/// - `.task { await store.refresh() }` 从 repository 异步刷新,
///   Step 9 的 `BundleHomeRepository` 读的是 bundle 里的 `home.json`,
///   未来切到 `URLHomeRepository` 只换 init 的参数, 业务逻辑零改动
/// - `filteredCards` 是派生视图, store 内部缓存, 避免在 view 里 inline `.filter()`
///   (list-patterns.md 规则: 不允许在 ForEach 上直接 filter)
@Observable
@MainActor
final class HomeStore {
    // MARK: - Public state

    var selectedFilter: FilterType = .all {
        didSet { recomputeFiltered() }
    }
    private(set) var cards: [Card]
    private(set) var filteredCards: [Card]
    private(set) var summary: DailySummary
    /// 按 cardId 索引的 action items; 只有 `type == .longRec` 的卡片会有
    var actionItemsByCard: [String: [ActionItem]]

    /// 最近一次 `refresh()` 的错误, view 层可选展示
    private(set) var lastLoadError: Error?

    // MARK: - Dependencies

    private let repository: any HomeRepository

    // MARK: - Init

    /// 初始化 store. `cards` / `summary` / `actionItemsByCard` 的默认值是 Swift
    /// 字面量 mock, 保证 view 构造时立即有数据可以渲染; 之后调 `refresh()` 从
    /// repository 覆盖掉.
    init(
        repository: any HomeRepository = BundleHomeRepository(),
        cards: [Card] = HomeStore.mockCards,
        summary: DailySummary = HomeStore.mockSummary,
        actionItemsByCard: [String: [ActionItem]] = HomeStore.mockActionItems
    ) {
        self.repository = repository
        self.cards = cards
        self.summary = summary
        self.filteredCards = cards
        self.actionItemsByCard = actionItemsByCard
    }

    // MARK: - Async loading

    /// 从 repository 异步拉取最新的 HomeFeed, 整体替换当前 state.
    /// 失败时保留现有 state, 只把 error 记到 `lastLoadError`.
    func refresh() async {
        do {
            let feed = try await repository.loadFeed()
            self.cards = feed.cards
            self.summary = feed.summary
            self.actionItemsByCard = feed.actionItemsByCard
            recomputeFiltered()
            lastLoadError = nil
        } catch {
            lastLoadError = error
        }
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

    /// 切换一条 action item 的 done 状态.
    ///
    /// 对应 prototype `toggleActionItem` 的语义:
    /// - status 在 `.pending` ↔ `.done` 之间来回切
    /// - done 态真实实现应同步到 Apple 提醒事项 + Linear + Memory, 这里只本地切
    func toggleActionItemDone(cardId: String, itemId: String) {
        guard var list = actionItemsByCard[cardId],
              let idx = list.firstIndex(where: { $0.id == itemId })
        else { return }
        list[idx].status = list[idx].status == .done ? .pending : .done
        actionItemsByCard[cardId] = list
    }

    // MARK: - Insert new captured card

    /// 在 feed 顶部插入一张刚捕捉的新卡片.
    ///
    /// 触发路径:
    /// - **快速点 FAB** → 长录音停止 → `RecordingStore.lastLongRecordingId`
    ///   change → HomeView 调本方法, `type = .longRec`
    /// - **按住 FAB** → 短捕捉松手 → `lastShortCaptureId` change → HomeView
    ///   本地做一次 mock 分类 (cmd/idea/todo), 然后调本方法
    ///
    /// 新卡片被设为 `.processing` 状态 + 对应的 `processingMeta` 文案,
    /// 模拟"Agent 正在后台结构化 / 匹配上下文" 的状态.
    func insertNewCapturedCard(type: Card.CardType, durationSec: Int) {
        let newCard = Self.makeCapturedCard(type: type, durationSec: durationSec)
        cards.insert(newCard, at: 0)
        recomputeFiltered()
    }

    /// 构造一张"刚捕捉"的卡片. 每种类型有专属的占位标题 + processingMeta,
    /// 让用户一眼看出"这张卡是刚刚录的, Agent 还在处理".
    private static func makeCapturedCard(
        type: Card.CardType,
        durationSec: Int
    ) -> Card {
        // 用 UUID 前 8 位做 id, 避免和 mock 数据里的固定 id (rec-1 等) 冲突
        let shortId = UUID().uuidString.prefix(8).lowercased()
        let id = "\(type.rawValue)-\(shortId)"

        switch type {
        case .longRec:
            return Card(
                id: id,
                type: .longRec,
                title: "刚录制的长录音",
                timeRelative: "刚刚",
                status: .processing,
                group: "今天",
                durationSec: durationSec,
                participantsCount: nil,
                pendingActionCount: nil,
                owner: nil,
                deadline: nil,
                project: nil,
                processingMeta: "正在结构化 · 提取参与人、要点、action items…",
                customMetaLine: nil
            )
        case .command:
            return Card(
                id: id,
                type: .command,
                title: "\"刚捕捉的指令\"",
                timeRelative: "刚刚",
                status: .processing,
                group: "今天",
                durationSec: nil,
                participantsCount: nil,
                pendingActionCount: nil,
                owner: nil,
                deadline: nil,
                project: nil,
                processingMeta: "Agent 判断中 · 匹配上下文…",
                customMetaLine: nil
            )
        case .idea:
            return Card(
                id: id,
                type: .idea,
                title: "刚捕捉的灵感",
                timeRelative: "刚刚",
                status: .processing,
                group: "今天",
                durationSec: durationSec,
                participantsCount: nil,
                pendingActionCount: nil,
                owner: nil,
                deadline: nil,
                project: nil,
                processingMeta: "关联相似灵感中…",
                customMetaLine: nil
            )
        case .todo:
            return Card(
                id: id,
                type: .todo,
                title: "刚捕捉的待办",
                timeRelative: "刚刚",
                status: .processing,
                group: "今天",
                durationSec: nil,
                participantsCount: nil,
                pendingActionCount: nil,
                owner: nil,
                deadline: nil,
                project: nil,
                processingMeta: "解析时间和地点中…",
                customMetaLine: nil
            )
        }
    }

    // MARK: - Processing simulation

    /// 把一张 `.processing` 卡片转成 `.done`, 换上"完成后"的 mock 标题和 meta.
    /// HomeView 在延迟 Task 里调用, 模拟 Agent 异步处理完成.
    func simulateProcessingComplete(cardId: String) {
        guard let idx = cards.firstIndex(where: { $0.id == cardId }),
              cards[idx].status == .processing
        else { return }
        cards[idx].status = .done
        cards[idx].processingMeta = nil
        cards[idx].title = Self.completedTitle(for: cards[idx].type)
        cards[idx].customMetaLine = Self.completedMetaLine(for: cards[idx].type)
        recomputeFiltered()
    }

    /// 把所有还在 processing 的卡片强制完成.
    /// 在 App 回到前台时调用 (防止 Task 被系统 suspend 后卡片永远停在 processing).
    func completeAllProcessingCards() {
        let processingIds = cards
            .filter { $0.status == .processing }
            .map { $0.id }
        guard !processingIds.isEmpty else { return }
        for id in processingIds {
            simulateProcessingComplete(cardId: id)
        }
        writeToAppGroup()
    }

    /// 完成后的 mock 标题. 每种类型有几个候选, 随机挑一个让 demo 不单调.
    static func completedTitle(for type: Card.CardType) -> String {
        switch type {
        case .longRec:
            ["与设计团队的产品评审", "和供应商的硬件对接会", "团队周会 · 技术方向讨论"]
                .randomElement()!
        case .command:
            ["\"帮我写一封跟进邮件\"", "\"做一份竞品分析 research\"", "\"整理今天的会议要点\""]
                .randomElement()!
        case .idea:
            ["Memory 可以加入 time-decay 机制", "onboarding 加 LinkedIn 导入试试", "Agent Skill 市场的变现思路"]
                .randomElement()!
        case .todo:
            ["周五下午 3 点团建", "提醒发给投资人的 deck", "下周一前完成原型测试"]
                .randomElement()!
        }
    }

    /// 完成后的 mock meta 行.
    static func completedMetaLine(for type: Card.CardType) -> String {
        switch type {
        case .longRec: "刚刚 · 已结构化 · 3 项待办"
        case .command: "已完成 · 调取 3 项上下文"
        case .idea:    "刚刚捕捉 · 已关联 2 条过往"
        case .todo:    "已写入 Apple 日历"
        }
    }

    /// Live Activity 完成态的详细摘要. 比 `completedMetaLine` 更长,
    /// 目标是让用户看一眼锁屏就不用再点进去.
    static func completedSummary(for type: Card.CardType) -> String {
        switch type {
        case .longRec:
            [
                "42:18 · 4 人 · 提取 3 项 Action Items · 2 条关键决策\n要点: 产品定位确认闭环路线, 企业场景优先级提升",
                "28:04 · 3 人 · A/B 测试数据对比完成\n结论: 长会话走新策略, 短会话维持 baseline",
                "35:12 · 2 人 · 硬件 roadmap 更新\n下一步: ODM 供应商本周锁定, Marshall 跟进"
            ].randomElement()!
        case .command:
            [
                "已调取 4 项上下文 · 邮件草稿已生成\n收件人: cai@linearcap.com · 主题: Re: Series A 讨论跟进",
                "已调取 3 项上下文 · 竞品 research 完成\nSandbar: Series B $40M · 产品方向转 enterprise",
                "已调取 2 项上下文 · 会议要点整理完成\n生成 5 条要点 + 3 个后续 action"
            ].randomElement()!
        case .idea:
            [
                "已关联 2 条过往灵感 · 归属: Monostone 后端 94%\n相似: \"L2 consolidation 加稳定窗口\" (87%)",
                "已关联 1 条过往 · 归属: Monostone iOS 91%\n可结合: spaced repetition 遗忘曲线做 decay",
                "新灵感已归档 · 归属: Growth 88%\nAgent 建议: 可以展开成 RFC 草稿"
            ].randomElement()!
        case .todo:
            [
                "已写入 Apple 日历 + 提醒事项\n4/11 15:00 · 已设提前 30 分钟提醒",
                "已同步到 Linear · 分配给 Marshall\n截止: 本周五 · 优先级: 高",
                "已写入提醒事项\n明天 10:00 · 已设提前 1 小时提醒"
            ].randomElement()!
        }
    }

    // MARK: - App Group sync

    /// 把当前 cards + summary 序列化写到 App Group UserDefaults,
    /// 然后通知 WidgetKit 刷新 timeline. Widget 的 TimelineProvider
    /// 调 `SharedDataWriter.read()` 就能拿到最新数据.
    func writeToAppGroup() {
        let sharedCards = cards.prefix(10).map { card in
            SharedCard(
                id: card.id,
                typeRaw: card.type.rawValue,
                title: card.title,
                statusRaw: card.status.rawValue,
                timeRelative: card.timeRelative,
                metaLine: card.metaLine
            )
        }
        let data = SharedWidgetData(
            cards: Array(sharedCards),
            dayCount: summary.dayCount,
            interactionsToday: summary.interactionsToday,
            ringConnected: summary.ringConnected,
            updatedAt: .now
        )
        SharedDataWriter.write(data)
        WidgetCenter.shared.reloadAllTimelines()
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

    // 直接映射 prototype index.html 里的 9 张卡片 (5 今天 + 4 昨天).
    // 顺序很重要, view 层按 group 分组时保持 append 顺序.
    static let mockCards: [Card] = [
        // ===== 今天 =====
        Card(
            id: "rec-1",
            type: .longRec,
            title: "和敦敏的 Series A 跟进会",
            timeRelative: "2 小时前",
            status: .done,
            group: "今天",
            durationSec: 42 * 60 + 18,
            participantsCount: 4,
            pendingActionCount: 3,
            owner: nil,
            deadline: nil,
            project: "Series A",
            processingMeta: nil,
            customMetaLine: nil
        ),
        Card(
            id: "cmd-1",
            type: .command,
            title: "\"帮我起草给敦敏的 follow-up 邮件\"",
            timeRelative: "1 小时前",
            status: .done,
            group: "今天",
            durationSec: nil,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: nil,
            deadline: nil,
            project: "Series A",
            processingMeta: nil,
            customMetaLine: "已完成 · 调取 4 项上下文"
        ),
        Card(
            id: "idea-1",
            type: .idea,
            title: "Memory 的 L2→L3 promotion 可以加 confidence decay",
            timeRelative: "45 分钟前",
            status: .done,
            group: "今天",
            durationSec: 8,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: nil,
            deadline: nil,
            project: "Monostone 后端",
            processingMeta: nil,
            customMetaLine: "走路时 · Monostone 后端 · 关联 3 条过往"
        ),
        Card(
            id: "cmd-2",
            type: .command,
            title: "\"帮我做 Sandbar 最新融资情况的 research\"",
            timeRelative: "刚刚",
            status: .processing,
            group: "今天",
            durationSec: nil,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: nil,
            deadline: nil,
            project: nil,
            processingMeta: "执行中 · 联网搜索中 · 还剩约 3 分钟",
            customMetaLine: nil
        ),
        Card(
            id: "todo-1",
            type: .todo,
            title: "周四下午 3 点去看牙医",
            timeRelative: "30 分钟前",
            status: .done,
            group: "今天",
            durationSec: nil,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: nil,
            deadline: "4/11 15:00",
            project: nil,
            processingMeta: nil,
            customMetaLine: "4/11 15:00 · 已写入 Apple 日历"
        ),
        // ===== 昨天 =====
        Card(
            id: "idea-2",
            type: .idea,
            title: "戒指 onboarding 可以加一步 LinkedIn 导入, 让 Day 1 就有 context",
            timeRelative: "22:14",
            status: .done,
            group: "昨天",
            durationSec: 11,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: nil,
            deadline: nil,
            project: "Monostone iOS",
            processingMeta: nil,
            customMetaLine: "开车时 · Monostone iOS"
        ),
        Card(
            id: "rec-2",
            type: .longRec,
            title: "林啸 Memory A/B 对比测试评审",
            timeRelative: "16:40",
            status: .done,
            group: "昨天",
            durationSec: 28 * 60 + 4,
            participantsCount: 3,
            pendingActionCount: 3,
            owner: nil,
            deadline: nil,
            project: "Monostone 后端",
            processingMeta: nil,
            customMetaLine: nil
        ),
        Card(
            id: "todo-2",
            type: .todo,
            title: "提醒 Marshall 周五之前锁定 ODM 供应商",
            timeRelative: "11:20",
            status: .done,
            group: "昨天",
            durationSec: nil,
            participantsCount: nil,
            pendingActionCount: nil,
            owner: "Marshall",
            deadline: "4/12 之前",
            project: "Series A · 硬件",
            processingMeta: nil,
            customMetaLine: "4/12 之前 · 已写入 Linear"
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

    /// 首页卡片下方的 meta 行内容. 优先用 `customMetaLine`, 否则按类型派生.
    /// - longRec 派生: "42:18 · 4 人 · Series A · 3 项待办"
    /// - command 派生: "Agent · 今天"
    /// - idea 派生:    "0:08 · Monostone 后端"
    /// - todo 派生:    "明明 · 4/11 15:00"
    var metaLine: String {
        if let custom = customMetaLine, !custom.isEmpty {
            return custom
        }
        switch type {
        case .longRec:
            var parts: [String] = []
            if let d = durationDisplay { parts.append(d) }
            if let n = participantsCount { parts.append("\(n) 人") }
            if let p = project { parts.append(p) }
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
