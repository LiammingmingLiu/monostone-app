import SwiftUI

/// 首页顶部的"今日速览"卡片.
///
/// 对应 prototype `home_feed` 的 glance panel:
/// - 左边大数字：今日节省时间（分钟）
/// - 右边三个小条：按来源拆分（走路 / 会后 / 电脑前）
struct TodayGlance: View {
    let summary: DailySummary

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            savingsColumn
            Divider()
                .background(Theme.border)
                .frame(height: 52)
            breakdownColumn
        }
        .padding(16)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: - Subviews

    private var savingsColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日节省")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textDimmer)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(summary.timeSavedMinutes)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                Text("分钟")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim)
            }

            Text("今日 \(summary.interactionsToday) 次交互")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var breakdownColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            breakdownRow(label: "走路时",  count: summary.interactionBreakdown.walking)
            breakdownRow(label: "会后",    count: summary.interactionBreakdown.postMeeting)
            breakdownRow(label: "电脑前",  count: summary.interactionBreakdown.atDesk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func breakdownRow(label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDim)
                .frame(width: 44, alignment: .leading)
            // 长度随 count 变化的迷你进度条
            Capsule()
                .fill(Theme.accent.opacity(0.3))
                .frame(width: CGFloat(max(count, 1)) * 14, height: 3)
            Text("\(count)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.text)
        }
    }
}

#Preview {
    TodayGlance(summary: HomeStore.mockSummary)
        .padding(16)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
