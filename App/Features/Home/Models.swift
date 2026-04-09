import Foundation

// MARK: - Card

/// 首页 feed 里的一张卡片。对应 prototype `data-models.md §3 Card`.
///
/// 4 种子类型通过 `type` 判别：
/// - `.longRec` 长录音（会议、深度讨论）
/// - `.command` 指令（让 Agent 做事）
/// - `.idea`    灵感（短 capture）
/// - `.todo`    待办（日程 / 提醒）
struct Card: Identifiable, Hashable, Codable {
    let id: String
    let type: CardType
    let title: String
    let timeRelative: String
    let status: CardStatus

    /// 时间分组, "今天" / "昨天" / "本周" 等, view 层做 section grouping 用.
    /// 对应 prototype 首页的 `.time-sep`.
    let group: String

    /// 仅 `.longRec` 有意义：录音时长
    let durationSec: Int?
    /// 仅 `.longRec` 有意义：参与人数
    let participantsCount: Int?
    /// 仅 `.longRec` 有意义：待处理 action items 数
    let pendingActionCount: Int?

    /// 仅 `.command` / `.todo` 有意义
    let owner: String?
    let deadline: String?

    /// 所属项目名
    let project: String?

    /// 处理中的描述文案（status == .processing 时显示）
    let processingMeta: String?

    /// 可选的自定义 meta 显示行 (例如指令卡"已完成 · 调取 4 项上下文",
    /// 灵感卡"走路时 · Monostone 后端 · 关联 3 条过往").
    /// 如果为 nil, view 层会用默认的 `metaLine` 派生逻辑.
    let customMetaLine: String?

    var tint: Tint { type.tint }

    enum CardType: String, Hashable, Codable {
        case longRec
        case command
        case idea
        case todo

        var label: String {
            switch self {
            case .longRec: "长录音"
            case .command: "指令"
            case .idea:    "灵感"
            case .todo:    "待办"
            }
        }

        var tint: Tint { .init(kind: self) }
    }

    enum CardStatus: String, Hashable, Codable {
        case done
        case processing
        case failed
    }

    /// 卡片类型对应的前景色 (不进 JSON, 只是 view 侧的派生)
    struct Tint: Hashable {
        let kind: CardType
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, title, timeRelative, status, group,
             durationSec, participantsCount, pendingActionCount,
             owner, deadline, project, processingMeta, customMetaLine
    }
}

extension Card.CardType: CaseIterable {}

// MARK: - FilterType

/// 首页顶部 filter chips 的筛选类型.
/// `.all` 表示不筛选；其余对应 `Card.CardType`.
enum FilterType: String, Hashable, CaseIterable, Identifiable {
    case all
    case longRec
    case command
    case idea
    case todo

    var id: Self { self }

    var label: String {
        switch self {
        case .all:     "全部"
        case .longRec: "长录音"
        case .command: "指令"
        case .idea:    "灵感"
        case .todo:    "待办"
        }
    }

    /// 判断一张卡片是否属于此筛选
    func matches(_ card: Card) -> Bool {
        switch self {
        case .all:     true
        case .longRec: card.type == .longRec
        case .command: card.type == .command
        case .idea:    card.type == .idea
        case .todo:    card.type == .todo
        }
    }
}

// MARK: - ActionItem

/// 一条长录音卡片衍生出的待办项.
///
/// 对应 prototype `data-models.md §6 ActionItem`.
/// Step 7 会加左滑删除手势, 这里先只放数据模型.
struct ActionItem: Identifiable, Hashable, Codable {
    let id: String
    let cardId: String
    let text: String
    let owner: String
    let deadline: String
    /// 来自会议的原话引用
    let sourceQuote: String
    /// 来源卡片标题（冗余字段）
    let sourceCard: String
    /// 时间戳 e.g. "14:32"
    let sourceTime: String
    /// 3 条 context-aware 的 Agent prompt 建议
    let agentSuggestions: [String]
    var status: Status = .pending

    enum Status: String, Hashable, Codable {
        case pending
        case done
        case rejected
    }
}

// MARK: - DailySummary

/// 今日速览数据，显示在 home feed 顶部.
/// 对应 prototype `data-models.md §10 DailySummary`.
struct DailySummary: Hashable, Codable {
    let greeting: String
    let dayCount: Int
    let ringConnected: Bool
    let interactionsToday: Int
    let timeSavedMinutes: Int
    let interactionBreakdown: InteractionBreakdown

    struct InteractionBreakdown: Hashable, Codable {
        let walking: Int
        let postMeeting: Int
        let atDesk: Int
    }
}
