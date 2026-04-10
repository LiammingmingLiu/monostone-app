import ActivityKit
import Foundation

/// Live Activity 的数据定义 — 锁屏上的**任务队列**卡片.
///
/// 核心设计: **全局只有一个 Live Activity**, 里面装一个 `[TaskItem]` 列表.
/// 每次录音/捕捉不会新建 Activity, 而是往已有 Activity 的 tasks 数组前面
/// 插入一条新的 TaskItem, 然后 `activity.update()`.
///
/// 这样锁屏上只有一张卡片, 但能看到多个任务的实时状态, 新的在最上面.
///
/// 生命周期:
/// 1. 第一次录音 → `Activity.request()` 创建, tasks = [processing]
/// 2. 再次录音 → `activity.update()` 往 tasks 前面插新的
/// 3. 某个任务处理完 → `activity.update()` 把那条的 status 改成 done
/// 4. 所有任务都 done 且过了 15 秒 → `activity.end()`
struct CardProcessingAttributes: ActivityAttributes {
    // 不需要 per-card 的静态属性 — 这是一个共享的"任务队列" Activity

    struct ContentState: Codable, Hashable {
        /// 当前所有活跃的任务, 最新的在 index 0. 最多保留 4 条.
        let tasks: [TaskItem]
    }
}

/// 一条任务的快照 — Live Activity 渲染列表里的一行.
struct TaskItem: Codable, Hashable, Identifiable {
    let id: String         // card id, 也用于 deep link
    let typeRaw: String    // Card.CardType.rawValue
    let status: String     // "processing" / "done"
    let title: String      // 处理中: "正在处理…" / 完成: 真实标题
    let detail: String     // 处理中: processingMeta / 完成: meta line

    var typeLabel: String {
        switch typeRaw {
        case "longRec": "长录音"
        case "command": "指令"
        case "idea":    "灵感"
        case "todo":    "待办"
        default:        typeRaw
        }
    }

    var isProcessing: Bool { status == "processing" }
    var isDone: Bool { status == "done" }
}
