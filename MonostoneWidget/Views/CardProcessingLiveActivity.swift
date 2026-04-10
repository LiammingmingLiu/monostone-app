import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity 的 UI 配置 — 锁屏上的实时处理状态卡片.
///
/// 渲染两个场景:
/// 1. **锁屏 banner** — 最重要的展示位, 用户解锁前就能看到
/// 2. **Dynamic Island** — compact (pill) + expanded (大卡片)
///
/// 状态转换:
/// - `processing`: 类型标签 + 动态进度条 + 处理步骤文案
/// - `done`: 类型标签 + ✓ 完成 + 最终标题 + meta line
struct CardProcessingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CardProcessingAttributes.self) { context in
            // ===== 锁屏 banner =====
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .widgetURL(URL(string: "monostone://card/\(context.attributes.cardId)"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    typeBadge(context.attributes.typeLabel)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    statusBadge(context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Text(context.state.detail)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                // Dynamic Island compact 左边: 类型色圆点
                Circle()
                    .fill(typeColor(context.attributes.cardTypeRaw))
                    .frame(width: 10, height: 10)
            } compactTrailing: {
                // Dynamic Island compact 右边: 状态文字
                Text(context.state.isProcessing ? "处理中" : "完成")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(context.state.isProcessing ? .secondary : .primary)
            } minimal: {
                // Dynamic Island minimal (多个 activity 时)
                Circle()
                    .fill(typeColor(context.attributes.cardTypeRaw))
                    .frame(width: 10, height: 10)
            }
            .widgetURL(URL(string: "monostone://card/\(context.attributes.cardId)"))
        }
    }

    // MARK: - Lock screen banner

    private func lockScreenView(
        context: ActivityViewContext<CardProcessingAttributes>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶行: 类型标签 + 状态
            HStack {
                typeBadge(context.attributes.typeLabel)
                Spacer()
                statusBadge(context.state)
            }

            // 处理中: 进度条动画
            if context.state.isProcessing {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(typeColor(context.attributes.cardTypeRaw))
            }

            // 标题
            Text(context.state.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // 详情
            Text(context.state.detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(16)
    }

    // MARK: - Components

    private func typeBadge(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.4)
    }

    private func statusBadge(_ state: CardProcessingAttributes.ContentState) -> some View {
        HStack(spacing: 4) {
            if state.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.green)
            }
            Text(state.isProcessing ? "处理中…" : "完成")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(state.isProcessing ? Color.secondary : Color.green)
        }
    }

    // MARK: - Colors

    /// 类型色 — 从 Theme.swift 复制, Widget 进程无法 import Theme
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
