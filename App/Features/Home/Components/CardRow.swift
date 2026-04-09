import SwiftUI

/// 首页 feed 里单条卡片的展示视图.
///
/// 4 种卡片类型使用同一个 `CardRow` view（`list-patterns.md` 规则: 不要用 AnyView,
/// 让同一个 row view 根据 type 内部分支）。
/// processing 状态叠加 shimmer + 显示 processingMeta 文案.
struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            title
            if let meta = footerText {
                meta
            }
            if card.status == .processing, let processingMeta = card.processingMeta {
                processingLine(processingMeta)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 14))
        .shimmering(isActive: card.status == .processing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 8) {
            Text(card.type.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tintColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tintColor.opacity(0.14))
                .clipShape(.rect(cornerRadius: 6))
            if let project = card.project {
                Text(project)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(card.timeRelative)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDimmer)
        }
    }

    private var title: some View {
        Text(card.title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.text)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var footerText: Text? {
        let line = card.metaLine
        line.isEmpty ? nil : Text(line)
            .font(.system(size: 12))
            .foregroundStyle(Theme.textDim)
    }

    @ViewBuilder
    private func processingLine(_ meta: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tintColor)
                .frame(width: 5, height: 5)
            Text(meta)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Theme.textDim)
        }
    }

    // MARK: - Styling helpers

    private var tintColor: Color {
        switch card.type {
        case .longRec: Theme.typeLongRec
        case .command: Theme.typeCommand
        case .idea:    Theme.typeIdea
        case .todo:    Theme.typeTodo
        }
    }

    private var borderColor: Color {
        card.status == .processing ? tintColor.opacity(0.35) : Theme.border
    }

    private var accessibilityDescription: String {
        var parts: [String] = [card.type.label, card.title]
        if !card.metaLine.isEmpty { parts.append(card.metaLine) }
        parts.append(card.timeRelative)
        return parts.joined(separator: "，")
    }
}

#Preview("All types") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(HomeStore.mockCards) { card in
                CardRow(card: card)
            }
        }
        .padding(16)
    }
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
