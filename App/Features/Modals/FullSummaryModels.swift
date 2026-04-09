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
struct FullSummary: Identifiable, Hashable {
    var id: String { cardId }
    let cardId: String
    let title: String
    let meta: [MetaEntry]
    let sections: [SummarySection]
}

/// 有序 key-value, 用数组而不是 Dictionary 以保持渲染顺序.
struct MetaEntry: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let value: String
}

struct SummarySection: Identifiable, Hashable {
    let id = UUID()
    /// H2 标题
    let heading: String
    /// 章节内按顺序排列的 block
    let blocks: [SummaryBlock]
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
