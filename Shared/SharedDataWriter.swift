import Foundation

/// App Group UserDefaults 读写工具.
///
/// 主 App 调 `write(_:)`, Widget Extension 调 `read()`.
///
/// 为什么用 UserDefaults 而不是文件 / Core Data:
/// - 数据量很小 (< 30 条 SharedCard, JSON < 50 KB), 远低于 UserDefaults 的安全上限
/// - UserDefaults 是线程安全的, Widget 和 App 不用做 file coordination
/// - App Group UserDefaults 是 Apple 官方推荐的 Widget ↔ App 数据共享方式
///
/// 用法:
/// ```swift
/// // App 侧 (写)
/// SharedDataWriter.write(widgetData)
///
/// // Widget 侧 (读)
/// if let data = SharedDataWriter.read() {
///     // 渲染 widget
/// }
/// ```
enum SharedDataWriter {
    /// App Group identifier — 在 `.entitlements` 文件里声明的同一个 group id.
    /// 如果改了这个值, 两个 entitlements 文件也要同步改.
    static let appGroupId = "group.com.monostone.app"

    /// UserDefaults key
    private static let key = "widget_data"

    /// 把 `SharedWidgetData` 序列化写入 App Group UserDefaults.
    /// 由主 App 在 `@MainActor` 上调用 (HomeStore.writeToAppGroup).
    static func write(_ data: SharedWidgetData) {
        guard let suite = UserDefaults(suiteName: appGroupId) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        guard let jsonData = try? encoder.encode(data) else { return }
        suite.set(jsonData, forKey: key)
    }

    /// 从 App Group UserDefaults 读取 `SharedWidgetData`.
    /// 由 Widget 的 TimelineProvider 在非 MainActor 线程调用.
    /// 如果还没写过 (冷启动) 或解码失败, 返回 nil.
    static func read() -> SharedWidgetData? {
        guard let suite = UserDefaults(suiteName: appGroupId),
              let jsonData = suite.data(forKey: key)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SharedWidgetData.self, from: jsonData)
    }
}
