import SwiftUI

/// 渲染单个 `SummaryBlock` 的 view.
///
/// 对应 prototype `.full-summary` 样式:
/// - H3 加粗小标题
/// - paragraph: 13pt 行距 1.8, markdown 解析
/// - blockquote: 左侧青绿竖条, 斜体, 引用下方的作者小字
/// - bulleted / ordered list: 标准缩进 + 类型色 marker
/// - table: 圆角容器 + 半透明 header row + 细分割线
struct SummaryBlockView: View {
    let block: SummaryBlock

    var body: some View {
        switch block {
        case .subheading(let text):
            subheadingView(text)
        case .paragraph(let markdown):
            paragraphView(markdown)
        case .quote(let text, let author):
            quoteView(text: text, author: author)
        case .bulletedList(let items):
            listView(items, ordered: false)
        case .orderedList(let items):
            listView(items, ordered: true)
        case .table(let headers, let rows):
            tableView(headers: headers, rows: rows)
        }
    }

    // MARK: - Markdown

    private func attributed(_ markdown: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return (try? AttributedString(markdown: markdown, options: options))
            ?? AttributedString(markdown)
    }

    // MARK: - Block renderers

    private func subheadingView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Theme.text)
            .padding(.top, 6)
    }

    private func paragraphView(_ markdown: String) -> some View {
        Text(attributed(markdown))
            .font(.system(size: 13.5))
            .foregroundStyle(Theme.text)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func quoteView(text: String, author: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(attributed(text))
                .font(.system(size: 13, weight: .regular))
                .italic()
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(author)")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textDim)
                .tracking(0.2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.accent.opacity(0.06))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 2)
        }
        .clipShape(.rect(cornerRadius: 6))
    }

    private func listView(_ items: [String], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(marker(index: index, ordered: ordered))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 18, alignment: .leading)
                    Text(attributed(item))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.text)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func marker(index: Int, ordered: Bool) -> String {
        ordered ? "\(index + 1)." : "•"
    }

    private func tableView(headers: [String], rows: [[String]]) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textDim)
                        .tracking(0.4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                }
            }
            .background(Color.white.opacity(0.03))
            // Data rows
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                Divider().background(Theme.border)
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        Text(attributed(cell))
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                    }
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 8))
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            SummaryBlockView(block: .subheading("Subheading 示例"))
            SummaryBlockView(block: .paragraph("这是一段 **加粗** 的段落, 含 Monostone 关键词."))
            SummaryBlockView(block: .quote(
                text: "这就是引用的内容, 会用 **markdown** 加粗.",
                author: "敦敏, 10:31"
            ))
            SummaryBlockView(block: .orderedList([
                "**第一项** 加粗",
                "第二项",
                "第三项"
            ]))
            SummaryBlockView(block: .bulletedList([
                "项目 A",
                "项目 B · 带说明"
            ]))
            SummaryBlockView(block: .table(
                headers: ["排名", "玩家", "威胁"],
                rows: [
                    ["1", "**OpenAI**", "最大"],
                    ["2", "Samsung", "中"]
                ]
            ))
        }
        .padding()
    }
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
