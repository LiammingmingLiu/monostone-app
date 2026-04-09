import SwiftUI

/// 首页的 filter chip 横排.
///
/// - 显示 5 个 chip：全部 / 长录音 / 指令 / 灵感 / 待办
/// - **每个 chip 始终显示自己的类型色** (不管选中与否), 对应 prototype CSS:
///   `.filter-chip[data-type="rec"] { color: var(--t-rec); }` 等
/// - 选中时额外加半透明背景 + 粗边框 + count 数字变色
/// - 未选中时文字用类型色, 背景透明, 边框灰
///
/// 使用 `@Bindable` 接收外部 store, 直接写回 `selectedFilter`.
struct FilterChipBar: View {
    @Bindable var store: HomeStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterType.allCases) { filter in
                    ChipButton(
                        filter: filter,
                        count: store.count(for: filter),
                        isSelected: store.selectedFilter == filter
                    ) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .sensoryFeedback(.selection, trigger: store.selectedFilter)
    }
}

// MARK: - ChipButton

private struct ChipButton: View {
    let filter: FilterType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(filter.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(labelColor)
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(countColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(filter.label) · \(count) 条"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Styling

    /// 每个 filter 的类型色. `.all` 用通用 accent, 其他用对应的 type 色.
    private var tintColor: Color {
        switch filter {
        case .all:     Theme.accent
        case .longRec: Theme.typeLongRec
        case .command: Theme.typeCommand
        case .idea:    Theme.typeIdea
        case .todo:    Theme.typeTodo
        }
    }

    /// Label 永远是类型色. 选中时略微加亮 (100% 不透明), 未选中时稍暗一点.
    private var labelColor: Color {
        isSelected ? tintColor : tintColor.opacity(0.75)
    }

    /// count 数字选中时用 label 同色, 未选中时灰色.
    private var countColor: Color {
        isSelected ? tintColor : Theme.textDimmer
    }

    /// 背景只在选中态有半透明色块.
    private var background: Color {
        isSelected ? tintColor.opacity(0.16) : .clear
    }

    /// 边框: 未选中时用类型色的极浅描边 (25%), 选中时加深 (60%).
    /// 这样即使未选中也能看到色带, 对齐 prototype 的视觉.
    private var borderColor: Color {
        isSelected ? tintColor.opacity(0.6) : tintColor.opacity(0.25)
    }
}

#Preview {
    @Previewable @State var store = HomeStore()
    return VStack(spacing: 20) {
        FilterChipBar(store: store)
        Text("selected: \(store.selectedFilter.label)")
            .font(.caption)
            .foregroundStyle(Theme.textDim)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
