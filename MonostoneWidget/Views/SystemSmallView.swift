import SwiftUI
import WidgetKit

/// 桌面 2×2 小组件 — 环状态 + 第 N 天 + 今日交互数.
///
/// 深色背景, 和 App 的 dark theme 保持一致.
struct SystemSmallView: View {
    let entry: MonostoneWidgetEntry

    private var data: SharedWidgetData? { entry.data }

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            // 环连接指示
            HStack(spacing: 6) {
                Circle()
                    .fill(data?.ringConnected == true ? Color.teal : Color.gray)
                    .frame(width: 7, height: 7)
                Text(data?.ringConnected == true ? "戒指已连接" : "戒指未连接")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // 第 N 天
            Text("第 \(data?.dayCount ?? 0) 天")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // 今日交互
            Text("今日 \(data?.interactionsToday ?? 0) 次交互")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "monostone://home"))
    }
}
