import SwiftUI
import WidgetKit

/// 锁屏矩形小组件 — 最新卡片的 at-a-glance 预览.
///
/// 这是用户在锁屏上最主要的"结果检查"入口.
/// 显示: 类型标签 (灵感 / 长录音 / ...) + 标题 (1 行) + 状态或 meta.
/// 点击: deep link 到该卡片的详情页 (`monostone://card/{id}`).
struct AccessoryRectangularView: View {
    let entry: MonostoneWidgetEntry

    private var latestCard: SharedCard? {
        entry.data?.cards.first
    }

    var body: some View {
        if let card = latestCard {
            VStack(alignment: .leading, spacing: 2) {
                // 类型标签 + 时间
                HStack(spacing: 4) {
                    // 类型色圆点 (锁屏上颜色有限, 用文字代替)
                    Text(card.typeLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(card.timeRelative)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                // 卡片标题
                Text(card.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                // 状态 / meta
                Text(card.isProcessing ? "处理中…" : card.metaLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .widgetURL(URL(string: "monostone://card/\(card.id)"))
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Monostone")
                .font(.system(size: 13, weight: .semibold))
            Text("打开 App 开始录音")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "monostone://home"))
    }
}
