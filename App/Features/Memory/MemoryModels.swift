import Foundation

// MARK: - MemoryTreeStats

/// Memory Tree L0-L4 层级计数.
///
/// 对应 prototype `data-models.md §19.b.1 MemoryTreeStats` 以及
/// `data-flow.md` 里的 Memory Tree 分层定义：
/// - L0 场景 → L1 项目 → L2 片段 → L3 描述 → L4 原始
struct MemoryTreeStats: Hashable {
    let l0Scenes: Int
    let l1Projects: Int
    let l2Episodes: Int
    let l3Descriptions: Int
    let l4Raw: Int
}

// MARK: - MemoryInsight

/// 今天学到的一条洞察.
///
/// - `body` 是 markdown 字符串, 用 `**word**` 标记加粗
///   （对应 prototype 的 HTML `<b>word</b>`）
/// - `source` 是来源描述, e.g. "和敦敏的 Series A 跟进会 · 10:34"
/// - `highlight` 标识视觉优先级 (新学到的 vs 已有的更新)
struct MemoryInsight: Identifiable, Hashable {
    let id: String
    let body: String
    let source: String
    let highlight: Highlight

    enum Highlight: Hashable {
        case new
        case updated
        case normal
    }
}

// MARK: - MemoryEntity

/// 高频实体（人 / 项目 / 组织 / 概念 / 事件）.
/// 一个 Entity 聚合了该实体相关的多条 Memory.
struct MemoryEntity: Identifiable, Hashable {
    let id: String
    let avatar: String
    let name: String
    let kind: Kind
    let memoryCount: Int
    let subtitle: String

    enum Kind: String, Hashable, CaseIterable {
        case person       = "人"
        case project      = "项目"
        case organization = "组织"
        case concept      = "概念"
        case event        = "事件"
    }
}

// MARK: - CorrectionRecord

/// 用户最近的 human correction 记录.
///
/// - `body` 也是 markdown 字符串
/// - `propagatedCount` 表示这次纠正级联传播到了多少条 memory
struct CorrectionRecord: Identifiable, Hashable {
    let id: String
    let body: String
    let source: String
    let propagatedCount: Int?
}
