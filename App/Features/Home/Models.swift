import Foundation

// MARK: - Card

/// 首页 feed 里的一张卡片。对应 prototype `data-models.md §3 Card`.
///
/// 4 种子类型通过 `type` 判别：
/// - `.longRec` 长录音（会议、深度讨论）
/// - `.command` 指令（让 Agent 做事）
/// - `.idea`    灵感（短 capture）
/// - `.todo`    待办（日程 / 提醒）
struct Card: Identifiable, Hashable {
    let id: String
    let type: CardType
    let title: String
    let timeRelative: String
    let status: CardStatus

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

    var tint: Tint { type.tint }

    enum CardType: String, Hashable {
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

    enum CardStatus: Hashable {
        case done
        case processing
        case failed
    }

    /// 卡片类型对应的前景色
    struct Tint: Hashable {
        let kind: CardType
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

// MARK: - DailySummary

/// 今日速览数据，显示在 home feed 顶部.
/// 对应 prototype `data-models.md §10 DailySummary`.
struct DailySummary: Hashable {
    let greeting: String
    let dayCount: Int
    let ringConnected: Bool
    let interactionsToday: Int
    let timeSavedMinutes: Int
    let interactionBreakdown: InteractionBreakdown

    struct InteractionBreakdown: Hashable {
        let walking: Int
        let postMeeting: Int
        let atDesk: Int
    }
}
