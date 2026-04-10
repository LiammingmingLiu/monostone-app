import SwiftUI
import WidgetKit

/// 锁屏圆形小组件 — 显示今日交互次数.
///
/// 视觉: 圆形 Gauge 进度环 + 中间数字 "8次".
/// 数据: `SharedWidgetData.interactionsToday`.
struct AccessoryCircularView: View {
    let entry: MonostoneWidgetEntry

    private var count: Int {
        entry.data?.interactionsToday ?? 0
    }

    var body: some View {
        Gauge(value: Double(min(count, 20)), in: 0...20) {
            // Gauge label (accessibility)
            Text("交互")
        } currentValueLabel: {
            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("次")
                    .font(.system(size: 8, weight: .medium))
            }
        }
        .gaugeStyle(.accessoryCircular)
        .widgetURL(URL(string: "monostone://home"))
    }
}
