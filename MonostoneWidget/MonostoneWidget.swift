import WidgetKit
import SwiftUI

/// Widget bundle 入口. 一个 bundle 支持多个 widget,
/// 但 Monostone 目前只有一个 Widget struct 支持 4 种 family.
@main
struct MonostoneWidgets: WidgetBundle {
    var body: some Widget {
        MonostoneCardWidget()
        CardProcessingLiveActivity()
    }
}

/// 主 widget — 同时支持锁屏 (accessory*) 和桌面 (system*) 的 4 种尺寸.
struct MonostoneCardWidget: Widget {
    let kind = "MonostoneCardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MonostoneTimelineProvider()
        ) { entry in
            MonostoneWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monostone")
        .description("查看最新的录音、指令和灵感")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .systemSmall,
            .systemMedium
        ])
    }
}
