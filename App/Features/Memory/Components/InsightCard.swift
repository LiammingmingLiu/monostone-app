import SwiftUI

/// 一条 insight 或 correction 的卡片内容行.
///
/// 对应 prototype `.insight-card` 样式:
/// - 左侧 6px 发光圆点（颜色区分：青绿 = insight / 金色 = correction）
/// - 右侧: markdown body（Text 自动解析 `**bold**`）+ 小号灰色 source
///
/// 可复用给 insights section 和 corrections section 两处.
struct InsightCard: View {
    let markdownBody: String
    let source: String
    let accent: Color

    /// 把 markdown 字符串安全转成 AttributedString.
    /// `AttributedString(markdown:)` 支持 `**bold**` / `*italic*` 等基础语法.
    private var attributedBody: AttributedString {
        (try? AttributedString(markdown: markdownBody)) ?? AttributedString(markdownBody)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
                .shadow(color: accent.opacity(0.6), radius: 4)
            VStack(alignment: .leading, spacing: 5) {
                Text(attributedBody)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(source)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textDimmer)
                    .tracking(0.2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        InsightCard(
            markdownBody: "**敦敏** 是 Linear Capital 合伙人, 偏好 closed-loop 定位",
            source: "和敦敏的 Series A 跟进会 · 10:34",
            accent: Theme.accent
        )
        Divider().background(Theme.border)
        InsightCard(
            markdownBody: "你纠正: **敦敏** 不是\"投资总监\", 是\"合伙人\" · 已更新相关 7 条记忆",
            source: "2 小时前 · Agent 已学习",
            accent: Theme.typeIdea
        )
    }
    .background(Theme.panel)
    .clipShape(.rect(cornerRadius: 14))
    .padding(16)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
