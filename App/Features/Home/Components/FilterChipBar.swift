import SwiftUI

/// 首页的 filter chip 横排.
///
/// - 显示 5 个 chip：全部 / 长录音 / 指令 / 灵感 / 待办
/// - 选中的 chip 背景高亮，使用类型色 (Theme.typeLongRec / typeCommand / ...)
/// - `.all` 使用通用 accent 色
/// - 每个 chip 带角标数字
///
/// 使用 `@Bindable` 接收外部 store，直接写回 `selectedFilter`。
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
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textDimmer)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(foreground)
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

    private var tintColor: Color {
        switch filter {
        case .all:     Theme.accent
        case .longRec: Theme.typeLongRec
        case .command: Theme.typeCommand
        case .idea:    Theme.typeIdea
        case .todo:    Theme.typeTodo
        }
    }

    private var foreground: Color {
        isSelected ? Theme.text : Theme.textDim
    }

    private var background: Color {
        isSelected ? tintColor.opacity(0.16) : .clear
    }

    private var borderColor: Color {
        isSelected ? tintColor.opacity(0.6) : Theme.border
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
