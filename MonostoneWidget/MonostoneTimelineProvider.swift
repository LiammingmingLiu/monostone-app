import WidgetKit
import SwiftUI

/// Widget timeline entry — Widget 渲染的数据快照.
struct MonostoneWidgetEntry: TimelineEntry {
    let date: Date
    /// 从 App Group UserDefaults 读到的数据. 冷启动时可能为 nil.
    let data: SharedWidgetData?
}

/// Timeline provider — Widget 的数据源.
///
/// 读取 `SharedDataWriter.read()` 获取主 App 最近一次写入的 cards + summary.
/// 主 App 每次 cards 变化时调 `WidgetCenter.shared.reloadAllTimelines()` 触发刷新.
struct MonostoneTimelineProvider: TimelineProvider {
    typealias Entry = MonostoneWidgetEntry

    func placeholder(in context: Context) -> MonostoneWidgetEntry {
        MonostoneWidgetEntry(date: .now, data: Self.placeholderData)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (MonostoneWidgetEntry) -> Void
    ) {
        let data = SharedDataWriter.read() ?? Self.placeholderData
        completion(MonostoneWidgetEntry(date: .now, data: data))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<MonostoneWidgetEntry>) -> Void
    ) {
        let data = SharedDataWriter.read()
        let entry = MonostoneWidgetEntry(date: .now, data: data)
        // 15 分钟后过期 (兜底), 但主要靠 App 端 reloadAllTimelines() 主动刷新
        let nextRefresh = Calendar.current.date(
            byAdding: .minute, value: 15, to: .now
        ) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - Placeholder

    /// Xcode Canvas / 冷启动用的占位数据
    private static let placeholderData = SharedWidgetData(
        cards: [
            SharedCard(
                id: "placeholder-1",
                typeRaw: "longRec",
                title: "和团队的周会",
                statusRaw: "done",
                timeRelative: "2 小时前",
                metaLine: "42:18 · 4 人 · Series A"
            ),
            SharedCard(
                id: "placeholder-2",
                typeRaw: "idea",
                title: "Memory 加入 confidence decay",
                statusRaw: "done",
                timeRelative: "45 分钟前",
                metaLine: "走路时 · Monostone 后端"
            ),
            SharedCard(
                id: "placeholder-3",
                typeRaw: "command",
                title: "\"帮我起草 follow-up 邮件\"",
                statusRaw: "done",
                timeRelative: "1 小时前",
                metaLine: "已完成 · 调取 4 项上下文"
            )
        ],
        dayCount: 12,
        interactionsToday: 8,
        ringConnected: true,
        updatedAt: .now
    )
}
