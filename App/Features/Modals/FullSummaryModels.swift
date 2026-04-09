import Foundation

// MARK: - FullSummary

/// 长录音的完整会议纪要.
///
/// 对应 prototype `data-models.md §5 FullSummary`:
/// - 1 个 H1 标题 (总标题, 永远唯一)
/// - 1 张 meta 信息表 (会议时间/时长/参会人员/项目/形式)
/// - 多个 H2 section, 每个 section 有若干 block
///
/// prototype 里 section.paragraphs 是 HTML 字符串数组; 这里改成结构化的
/// `Block` enum, 让 SwiftUI 渲染更干净, 并且类型安全.
struct FullSummary: Identifiable, Hashable, Codable {
    var id: String { cardId }
    let cardId: String
    let title: String
    let meta: [MetaEntry]
    let sections: [SummarySection]
}

/// 有序 key-value, 用数组而不是 Dictionary 以保持渲染顺序.
struct MetaEntry: Identifiable, Hashable, Codable {
    var id: String { key }
    let key: String
    let value: String
}

struct SummarySection: Identifiable, Hashable, Codable {
    /// view 内渲染用的本地 id, 不进 JSON
    var id: UUID { _id }
    private let _id: UUID

    /// H2 标题
    let heading: String
    /// 章节内按顺序排列的 block
    let blocks: [SummaryBlock]

    init(heading: String, blocks: [SummaryBlock]) {
        self._id = UUID()
        self.heading = heading
        self.blocks = blocks
    }

    private enum CodingKeys: String, CodingKey {
        case heading, blocks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = UUID()
        self.heading = try container.decode(String.self, forKey: .heading)
        self.blocks = try container.decode([SummaryBlock].self, forKey: .blocks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(heading, forKey: .heading)
        try container.encode(blocks, forKey: .blocks)
    }
}

// MARK: - SummaryBlock

/// 会议纪要里可能出现的内容 block 类型.
///
/// 覆盖 prototype `modal_full_summary` 里所有用到的 HTML 标签:
/// - `<h3>` → `.subheading`
/// - `<p>` → `.paragraph`  (markdown 字符串)
/// - `<blockquote>` → `.quote`
/// - `<ul>` → `.bulletedList`
/// - `<ol>` → `.orderedList`
/// - `<table>` → `.table`
enum SummaryBlock: Hashable {
    case subheading(String)
    case paragraph(String)              // markdown (**bold** / *italic*)
    case quote(text: String, author: String)
    case bulletedList([String])         // 每项也是 markdown
    case orderedList([String])
    case table(headers: [String], rows: [[String]])
}

// MARK: - SummaryBlock Codable (discriminator-based)
//
// 带关联值的 enum 没有 Codable 自动合成, 手写一个基于 `type` 字段的 discriminator.
// JSON 形状示例:
// ```json
// { "type": "paragraph", "text": "这是一段..." }
// { "type": "quote", "text": "...", "author": "敦敏, 10:31" }
// { "type": "table", "headers": [...], "rows": [[...]] }
// ```
extension SummaryBlock: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, text, author, items, headers, rows
    }

    private enum BlockType: String, Codable {
        case subheading, paragraph, quote, bulletedList, orderedList, table
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .subheading(let text):
            try container.encode(BlockType.subheading, forKey: .type)
            try container.encode(text, forKey: .text)
        case .paragraph(let markdown):
            try container.encode(BlockType.paragraph, forKey: .type)
            try container.encode(markdown, forKey: .text)
        case .quote(let text, let author):
            try container.encode(BlockType.quote, forKey: .type)
            try container.encode(text, forKey: .text)
            try container.encode(author, forKey: .author)
        case .bulletedList(let items):
            try container.encode(BlockType.bulletedList, forKey: .type)
            try container.encode(items, forKey: .items)
        case .orderedList(let items):
            try container.encode(BlockType.orderedList, forKey: .type)
            try container.encode(items, forKey: .items)
        case .table(let headers, let rows):
            try container.encode(BlockType.table, forKey: .type)
            try container.encode(headers, forKey: .headers)
            try container.encode(rows, forKey: .rows)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BlockType.self, forKey: .type)
        switch type {
        case .subheading:
            let text = try container.decode(String.self, forKey: .text)
            self = .subheading(text)
        case .paragraph:
            let text = try container.decode(String.self, forKey: .text)
            self = .paragraph(text)
        case .quote:
            let text = try container.decode(String.self, forKey: .text)
            let author = try container.decode(String.self, forKey: .author)
            self = .quote(text: text, author: author)
        case .bulletedList:
            let items = try container.decode([String].self, forKey: .items)
            self = .bulletedList(items)
        case .orderedList:
            let items = try container.decode([String].self, forKey: .items)
            self = .orderedList(items)
        case .table:
            let headers = try container.decode([String].self, forKey: .headers)
            let rows = try container.decode([[String]].self, forKey: .rows)
            self = .table(headers: headers, rows: rows)
        }
    }
}
