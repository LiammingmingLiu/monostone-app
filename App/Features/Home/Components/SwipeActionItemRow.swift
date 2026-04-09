import SwiftUI

/// 一个可"左滑拒绝"的 row 包装器, 专门给 Action Items 用.
///
/// ## 产品语义
/// 对应 prototype `rejectActionItemBySwipe`:
/// - 左滑 = "用户认为这条 AI 推断不对 / 不想做"
/// - 所以 toast 是 "已删除 · Agent 会学习这个判断", 而不是纯粹的 "已删除"
/// - 视觉上也要体现"学习"而不是"销毁", 所以背景用 sparkles 图标 + 副标题
///   "学到了", 颜色是柔和的 rose 渐变而不是扁平的红色
///
/// ## 交互阶段
/// 1. 手指按下 + 开始移动 → 检测是否 **水平主导** (abs(dx) > abs(dy) 且 dx < 0),
///    只在水平主导时才开始跟随手指 (offset = dx)。否则把事件让给父 ScrollView 滚动。
/// 2. 松手时判断 `dx < deleteThreshold (-100)` 是否触发删除。
/// 3. 触发删除 → 滑出 (transform translateX -420px, 220ms) →
///    180ms 后启动行塌陷 (frame height → 0 + opacity → 0, 350ms) →
///    总计 ~550ms 后调用 `onDelete` 让 parent 从 store 里移除 item.
/// 4. 否则弹回原位 (spring 0.28s).
///
/// ## Tap 和 Drag 怎么不冲突
/// **由 SwipeActionItemRow 同时持有 tap 和 drag**, 不再让 parent 用 Button 包内容.
/// 对应 prototype "水平位移 > 8px 时, 抑制当前 tap, 不触发 openActionItem":
/// - 拖动距离超过 `tapSuppressionDistance` (8pt) 后, `dragDidMove = true`
/// - tapGesture 的 action 在触发前 guard 掉 `dragDidMove` 的情况
/// - 弹回动画结束后 250ms 把 `dragDidMove` 重置回 false, 下一次 tap 才能正常响应
///
/// 这解决了之前用 `Button { } label: { SwipeActionItemRow { ... } }` 时的 bug:
/// 左滑到一半松手后, SwiftUI 的 button tap gesture 依然会 fire, 误触发 modal.
///
/// 为什么不用 `List.swipeActions`:
/// - Action Items 是嵌在 ScrollView 里的一个 section, 父视图不是 `List`
/// - prototype 有**section 级联塌陷** (最后一条删完后整个 section 消失), `List` 不支持
///
/// 使用方式:
/// ```swift
/// SwipeActionItemRow(
///     onTap:    { presentedSheet = .actionItem(item) },
///     onDelete: { store.delete(...) }
/// ) {
///     ActionItemRowContent()   // 纯 view, 不要再套 Button
/// }
/// ```
struct SwipeActionItemRow<Content: View>: View {
    let onTap: () -> Void
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var isCollapsing = false
    /// 本次 drag 是否已经越过 `tapSuppressionDistance` — 一旦 true, 松手时
    /// 的 tap 被抑制, 防止左滑误触发 modal.
    @State private var dragDidMove = false

    /// 水平位移超过这个阈值, 本次 tap 被认为是 swipe 的一部分, 不 fire.
    private let tapSuppressionDistance: CGFloat = 8
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

    init(
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onTap = onTap
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 软一点的 "Agent 学到了" 背景, 左滑时才露出来
            learnedBackdrop
                .opacity(backdropOpacity)

            // 实际 row 内容, 跟随手指 offset
            content
                .background(Theme.panel)
                .contentShape(Rectangle())
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
                .onTapGesture { handleTap() }
        }
        .frame(height: isCollapsing ? 0 : nil)
        .opacity(isCollapsing ? 0 : 1)
        .clipped()
        .animation(.easeOut(duration: collapseDuration), value: isCollapsing)
    }

    // MARK: - Tap handling

    private func handleTap() {
        // 如果本次交互是 swipe (dragDidMove) 或者 offset 还没归零,
        // 都不触发 tap — 避免左滑到一半松手误开 modal.
        guard !dragDidMove, offset == 0, !isCollapsing else { return }
        onTap()
    }

    // MARK: - Learn backdrop

    /// 左滑拖动幅度越大, 背景越实 — 从完全透明渐进到 opacity 1.
    private var backdropOpacity: Double {
        if isCollapsing { return 0 }
        let distance = min(abs(offset), 120)
        return Double(distance / 120)
    }

    /// 替换 prototype 里那种"扁平饱和红色 + 垃圾桶"的反馈.
    /// 现在用:
    /// - sparkles 图标 + "学到了" 副标题 (强调"Agent 学习", 不是破坏性删除)
    /// - rose → 透明的水平渐变, 右边重左边轻, 视觉更柔和
    /// - 图标 + 文字合成一个 column, 整体视觉像一个"行动标签"
    private var learnedBackdrop: some View {
        HStack(spacing: 0) {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
                Text("学到了")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .tracking(0.6)
            }
            .padding(.trailing, 22)
            .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.38, blue: 0.42).opacity(0.0),
                    Color(red: 0.82, green: 0.38, blue: 0.42).opacity(0.35),
                    Color(red: 0.82, green: 0.38, blue: 0.42).opacity(0.72)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Drag gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                // 方向判定: 只在水平主导且向左时才接管
                guard dx < 0, abs(dx) > abs(dy) else { return }

                isDragging = true
                if abs(dx) > tapSuppressionDistance {
                    dragDidMove = true
                }
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
                    // 弹回后给 onTapGesture 一个短窗口清掉 drag 标记,
                    // 否则 tapGesture 的 action 会和 drag 的 onEnded 在
                    // 同一帧触发, guard 检查到 dragDidMove=true 就误吃掉这次 tap.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(260))
                        dragDidMove = false
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
            SwipeActionItemRow(
                onTap: { print("tap \(idx)") },
                onDelete: { print("delete \(idx)") }
            ) {
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
