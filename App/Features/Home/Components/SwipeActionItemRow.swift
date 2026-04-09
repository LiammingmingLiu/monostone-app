import SwiftUI

/// 一个可"左滑删除"的 row 包装器, 专门给 Action Items 用.
///
/// 对应 prototype `pages-and-interactions.md §A1 左滑删除`:
///
/// 交互阶段：
/// 1. 手指按下 + 开始移动 → 检测是否 **水平主导** (abs(dx) > abs(dy) 且 dx < 0),
///    只在水平主导时才开始跟随手指 (offset = dx)。否则把事件让给父 ScrollView 滚动。
/// 2. 松手时判断 `dx < deleteThreshold (-100)` 是否触发删除。
/// 3. 触发删除 → 滑出 (transform translateX -420px, 220ms) →
///    180ms 后启动行塌陷 (frame height → 0 + opacity → 0, 350ms) →
///    总计 ~550ms 后调用 `onDelete` 让 parent 从 store 里移除 item.
/// 4. 否则弹回原位 (spring 0.28s).
///
/// 为什么不用 `List.swipeActions`:
/// - Action Items 是嵌在 ScrollView 里的一个 section, 父视图不是 `List`
/// - prototype 有**section 级联塌陷** (最后一条删完后整个 section 消失), `List` 不支持
///
/// 为什么用 `.simultaneousGesture` 而不是 `.gesture`:
/// - `.gesture` 会独占触摸事件, 阻塞父 ScrollView 的垂直滚动
/// - `.simultaneousGesture` 让 drag 和 scroll 共存, 我们在 onChanged 里做方向判定
///
/// 使用方式:
/// ```swift
/// SwipeActionItemRow(onDelete: { store.delete(...) }) {
///     Button { ... } label: { ActionItemRowContent() }
///         .buttonStyle(.plain)
/// }
/// ```
struct SwipeActionItemRow<Content: View>: View {
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var isCollapsing = false

    /// 松手后需要跨过这个阈值才触发删除 (prototype: -100px)
    private let deleteThreshold: CGFloat = -100
    /// 触发删除后 row 滑出屏幕到这个距离 (prototype: -420px)
    private let slideOutDistance: CGFloat = -420
    /// 滑出动画时长
    private let slideDuration: Double = 0.22
    /// 滑出开始后过多久启动行塌陷
    private let collapseDelayMs: Int = 180
    /// 行塌陷动画时长
    private let collapseDuration: Double = 0.35

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 红色 "delete" 背景, 左滑时才露出来
            deleteBackdrop
                .opacity(isDragging || offset < 0 ? 1 : 0)

            // 实际 row 内容, 跟随手指 offset
            content
                .background(Theme.panel)
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
        }
        .frame(height: isCollapsing ? 0 : nil)
        .opacity(isCollapsing ? 0 : 1)
        .clipped()
        .animation(.easeOut(duration: collapseDuration), value: isCollapsing)
    }

    // MARK: - Delete backdrop

    private var deleteBackdrop: some View {
        HStack {
            Spacer()
            Image(systemName: "trash.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.red.opacity(0.85))
    }

    // MARK: - Drag gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                // 方向判定: 只在水平主导且向左时才接管
                // (abs(dx) > abs(dy) 保证不和 ScrollView 垂直滚动冲突)
                guard dx < 0, abs(dx) > abs(dy) else {
                    return
                }

                isDragging = true
                // 允许一点过冲, 但不要滑到屏幕外之外
                offset = max(dx, slideOutDistance)
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false

                if value.translation.width < deleteThreshold {
                    performDelete()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        offset = 0
                    }
                }
            }
    }

    // MARK: - Delete pipeline

    private func performDelete() {
        // 阶段 1: 滑出屏幕
        withAnimation(.easeOut(duration: slideDuration)) {
            offset = slideOutDistance
        }

        Task { @MainActor in
            // 阶段 2: 180ms 后启动行塌陷
            try? await Task.sleep(for: .milliseconds(collapseDelayMs))
            isCollapsing = true

            // 阶段 3: 塌陷动画完成后才从 store 移除
            try? await Task.sleep(for: .milliseconds(Int(collapseDuration * 1000)))
            onDelete()
        }
    }
}

#Preview {
    VStack(spacing: 1) {
        ForEach(0..<3, id: \.self) { idx in
            SwipeActionItemRow(onDelete: { print("delete \(idx)") }) {
                HStack {
                    Text("Action Item \(idx + 1)")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textDimmer)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
        }
    }
    .background(Theme.panel)
    .clipShape(.rect(cornerRadius: 12))
    .padding(16)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
