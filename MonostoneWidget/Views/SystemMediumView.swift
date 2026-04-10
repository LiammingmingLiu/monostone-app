import SwiftUI
import WidgetKit

/// 桌面 4×2 小组件 — 最新 3 张卡片列表, 每行可点击跳转到详情页.
///
/// 这是信息密度最高的 widget: 用户扫一眼就能看到最近录了什么、哪些处理完了.
struct SystemMediumView: View {
    let entry: MonostoneWidgetEntry

    /// 最多显示 3 张卡片
    private var topCards: [SharedCard] {
        Array((entry.data?.cards ?? []).prefix(3))
    }

    var body: some View {
        if topCards.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(topCards.enumerated()), id: \.element.id) { idx, card in
                    cardRow(card)
                    if idx < topCards.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 22)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Card row

    private func cardRow(_ card: SharedCard) -> some View {
        Link(destination: URL(string: "monostone://card/\(card.id)")!) {
            HStack(spacing: 10) {
                // 类型色圆点
                Circle()
                    .fill(typeColor(card.typeRaw))
                    .frame(width: 7, height: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(card.isProcessing ? "处理中…" : card.metaLine)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(card.timeRelative)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "waveform")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text("打开 Monostone 开始录音")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "monostone://home"))
    }

    // MARK: - Helpers

    /// 卡片类型色. Widget 进程没有 Theme.swift, 这里 inline 定义.
    /// 值从 `App/Core/Theme.swift` 里的 type* 颜色复制过来.
    private func typeColor(_ typeRaw: String) -> Color {
        switch typeRaw {
        case "longRec": Color(red: 0.435, green: 0.765, blue: 0.816) // 6FC3D0
        case "command": Color(red: 0.635, green: 0.584, blue: 0.816) // A295D0
        case "idea":    Color(red: 0.831, green: 0.659, blue: 0.408) // D4A868
        case "todo":    Color(red: 0.498, green: 0.753, blue: 0.565) // 7FC090
        default:        Color.gray
        }
    }
}
