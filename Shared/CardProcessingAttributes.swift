import ActivityKit
import Foundation

/// Live Activity 的数据定义 — 锁屏上的实时处理状态卡片.
///
/// 对应产品流程:
/// 1. 用户录音/捕捉 → App 创建 Live Activity (processing 态)
/// 2. Agent 处理完成 → App 更新 ContentState (done 态, 带标题 + 摘要)
/// 3. 延迟后 → App 结束 Activity, 锁屏卡片淡出
///
/// `ActivityAttributes` 放在 `Shared/` 是因为 App (请求/更新/结束)
/// 和 Widget Extension (渲染 UI) 两个 target 都需要编译它.
struct CardProcessingAttributes: ActivityAttributes {
    // MARK: - Static attributes (创建时设定, 之后不变)

    /// 关联的 feed 卡片 ID, 用于 deep link: `monostone://card/{cardId}`
    let cardId: String

    /// `Card.CardType.rawValue` — "longRec" / "command" / "idea" / "todo"
    let cardTypeRaw: String

    // MARK: - Dynamic content state (可以随时 update)

    /// 锁屏上的动态展示内容. 从 "处理中…" 变成 "完成 ✓" 的过程
    /// 就是通过 `activity.update(ActivityContent(state: newState, ...))` 实现的.
    struct ContentState: Codable, Hashable {
        /// "processing" or "done"
        let status: String

        /// 处理中: "正在结构化…" / 完成: "与设计团队的产品评审"
        let title: String

        /// 处理中: "提取参与人、要点、action items…" / 完成: "42:18 · 3 项待办"
        let detail: String
    }
}

// MARK: - Helpers

extension CardProcessingAttributes {
    /// 类型的中文标签, 和 `SharedCard.typeLabel` 保持一致
    var typeLabel: String {
        switch cardTypeRaw {
        case "longRec": "长录音"
        case "command": "指令"
        case "idea":    "灵感"
        case "todo":    "待办"
        default:        cardTypeRaw
        }
    }

    var isProcessing: Bool { false } // unused at attributes level
}

extension CardProcessingAttributes.ContentState {
    var isProcessing: Bool { status == "processing" }
    var isDone: Bool { status == "done" }
}
