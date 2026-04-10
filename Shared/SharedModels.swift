import Foundation

// MARK: - 跨进程共享的数据类型
//
// 这些 DTO 被 **主 App** 和 **Widget Extension** 两个 target 同时编译.
// 设计原则:
// - 只包含 Widget 渲染必需的字段, 不引入 SwiftUI / Theme / 任何 view 层依赖
// - 全部 Codable + Sendable, 通过 App Group UserDefaults 序列化传递
// - 不直接复用 App 内的 `Card` struct (它依赖 Theme.Tint, metaLine computed
//   property 等 app-only 代码, 拖进来会让 widget target 膨胀)

/// Widget 用的卡片投影. 只保留渲染一行列表项需要的字段.
struct SharedCard: Codable, Sendable, Identifiable, Hashable {
    let id: String
    /// `Card.CardType.rawValue` (longRec / command / idea / todo)
    let typeRaw: String
    let title: String
    /// `Card.CardStatus.rawValue` (done / processing / failed)
    let statusRaw: String
    let timeRelative: String
    /// 已经算好的 meta 行文本, widget 直接显示, 不再自己派生
    let metaLine: String

    /// 类型的中文标签, 用于 widget 显示 "长录音" / "指令" / "灵感" / "待办"
    var typeLabel: String {
        switch typeRaw {
        case "longRec": "长录音"
        case "command": "指令"
        case "idea":    "灵感"
        case "todo":    "待办"
        default:        typeRaw
        }
    }

    var isProcessing: Bool { statusRaw == "processing" }
}

/// Widget TimelineProvider 从 App Group 读到的完整数据包.
/// 主 App 每次 cards / summary 变化时都重新序列化写一遍.
struct SharedWidgetData: Codable, Sendable {
    /// 最新的卡片 (已经按时间排序, 最新在前). Widget 按需取前 N 条.
    let cards: [SharedCard]

    /// 今日速览数据 (来自 DailySummary)
    let dayCount: Int
    let interactionsToday: Int
    let ringConnected: Bool

    /// 写入时间戳, Widget 可以判断数据新鲜度
    let updatedAt: Date
}
