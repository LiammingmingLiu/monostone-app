import SwiftUI

/// 首页"今日速览"**文字版**段落.
///
/// 对应 prototype `.digest .body`:
/// ```
/// 你今天和 AI 交互了 8 次
/// 其中 3 次走路时、2 次会后、3 次电脑前
/// Monostone 为你省下 47 分钟整理时间
/// ```
///
/// 这是和已有的 `TodayGlance` (大数字卡片) 互补的: prototype 里两者都有,
/// 本组件放在 filter chips 上方, 作为文字版的摘要.
struct TodayDigestText: View {
    let summary: DailySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            labelHeader
            line1
            line2
            line3
        }
        .padding(16)
        // 填满父宽度, 否则 VStack(alignment:.leading) 只会取最长一行的宽度,
        // 卡片缩在左边和下面的 filter chips / cards 对不齐
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 14))
    }

    private var labelHeader: some View {
        Text("今日速览")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.textDimmer)
            .tracking(1.4)
            .padding(.bottom, 3)
    }

    // iOS 26 弃用 `Text + Text` 拼接, 改用 AttributedString + markdown 语法.
    // `**` 包围的部分自动加粗并用 tintColor 上色.

    private var line1: some View {
        Text(line1Attributed)
            .font(.system(size: 13))
    }

    private var line2: some View {
        Text(line2Attributed)
            .font(.system(size: 13))
    }

    private var line3: some View {
        Text(line3Attributed)
            .font(.system(size: 13))
            .padding(.top, 4)
    }

    // MARK: - Attributed strings

    private var line1Attributed: AttributedString {
        let raw = "你今天和 AI 交互了 **\(summary.interactionsToday) 次**"
        return attributed(raw, boldColor: Theme.text)
    }

    private var line2Attributed: AttributedString {
        let b = summary.interactionBreakdown
        let raw = "其中 **\(b.walking) 次**走路时、**\(b.postMeeting) 次**会后、**\(b.atDesk) 次**电脑前"
        return attributed(raw, boldColor: Theme.text)
    }

    private var line3Attributed: AttributedString {
        let raw = "Monostone 为你省下 **\(summary.timeSavedMinutes) 分钟**整理时间"
        return attributed(raw, boldColor: Theme.accent)
    }

    /// 从 markdown 字符串构造 AttributedString,
    /// 对普通部分用 textDim 灰色, 对加粗部分用传入的 boldColor.
    private func attributed(_ markdown: String, boldColor: Color) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        var attr = (try? AttributedString(markdown: markdown, options: options))
            ?? AttributedString(markdown)
        // 设置默认颜色为灰色, 粗体 run 覆盖为 boldColor
        attr.foregroundColor = Theme.textDim
        for run in attr.runs where run.inlinePresentationIntent == .stronglyEmphasized {
            attr[run.range].foregroundColor = boldColor
        }
        return attr
    }
}

#Preview {
    TodayDigestText(summary: HomeStore.mockSummary)
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
