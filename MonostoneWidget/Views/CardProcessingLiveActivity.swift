import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity 的 UI — 锁屏上的**任务队列**卡片.
///
/// 全局只有一个 Live Activity, 里面渲染一个 task list.
/// 新任务在最上面, 每条任务有 processing / done 两种状态.
///
/// 锁屏 banner 最多显示 3 条任务 (空间有限).
/// Dynamic Island expanded 显示最新 1 条 + 队列数.
struct CardProcessingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CardProcessingAttributes.self) { context in
            // ===== 锁屏 banner =====
            lockScreenView(tasks: context.state.tasks)
                .activityBackgroundTint(Color.black.opacity(0.75))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Monostone")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    dynamicIslandTrailing(context.state.tasks)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    dynamicIslandBottom(context.state.tasks)
                }
            } compactLeading: {
                Circle()
                    .fill(typeColor(context.state.tasks.first?.typeRaw ?? ""))
                    .frame(width: 10, height: 10)
            } compactTrailing: {
                dynamicIslandCompactTrailing(context.state.tasks)
            } minimal: {
                dynamicIslandCompactTrailing(context.state.tasks)
            }
        }
    }

    // MARK: - Lock screen banner (task list)

    private func lockScreenView(tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 最多显示 3 条
            let visibleTasks = Array(tasks.prefix(3))

            ForEach(Array(visibleTasks.enumerated()), id: \.element.id) { idx, task in
                // deep link: 点击某一行跳到对应卡片
                Link(destination: URL(string: "monostone://card/\(task.id)")!) {
                    taskRow(task)
                }

                if idx < visibleTasks.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 20)
                }
            }

            // 如果还有更多, 显示 "+N"
            if tasks.count > 3 {
                Text("还有 \(tasks.count - 3) 个任务")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Single task row

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 10) {
            // 类型色圆点
            Circle()
                .fill(typeColor(task.typeRaw))
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                // 类型标签 + 状态
                HStack(spacing: 6) {
                    Text(task.typeLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    statusBadge(task)
                }

                // 标题
                Text(task.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // 详情 — done 态显示更多行, 用户看锁屏就够了不用进 App
                Text(task.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(task.isDone ? 3 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Status badge

    private func statusBadge(_ task: TaskItem) -> some View {
        HStack(spacing: 3) {
            if task.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
            }
            Text(task.isProcessing ? "处理中…" : "完成")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(task.isProcessing ? Color.secondary : Color.green)
        }
    }

    // MARK: - Dynamic Island helpers

    @ViewBuilder
    private func dynamicIslandTrailing(_ tasks: [TaskItem]) -> some View {
        let processingCount = tasks.filter(\.isProcessing).count
        if processingCount > 0 {
            Text("\(processingCount) 处理中")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
                Text("完成")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.green)
            }
        }
    }

    @ViewBuilder
    private func dynamicIslandBottom(_ tasks: [TaskItem]) -> some View {
        if let latest = tasks.first {
            taskRow(latest)
            if tasks.count > 1 {
                Text("还有 \(tasks.count - 1) 个任务")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private func dynamicIslandCompactTrailing(_ tasks: [TaskItem]) -> some View {
        let processingCount = tasks.filter(\.isProcessing).count
        if processingCount > 0 {
            Text("\(processingCount)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.green)
        }
    }

    // MARK: - Colors

    private func typeColor(_ typeRaw: String) -> Color {
        switch typeRaw {
        case "longRec": Color(red: 0.435, green: 0.765, blue: 0.816)
        case "command": Color(red: 0.635, green: 0.584, blue: 0.816)
        case "idea":    Color(red: 0.831, green: 0.659, blue: 0.408)
        case "todo":    Color(red: 0.498, green: 0.753, blue: 0.565)
        default:        Color.gray
        }
    }
}
