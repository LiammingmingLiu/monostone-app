import ActivityKit
import SwiftUI
import WidgetKit

// `Activity` 没有标记 Sendable, 但它内部是线程安全的 (Apple 的 ActivityKit
// 在所有平台上都从任意线程调用 update/end). Swift 6 strict concurrency 要求
// 我们显式声明, 否则跨 Task 传递就会报 "sending risks data races".
extension Activity: @retroactive @unchecked Sendable {}

/// 首页 Feed（对应 prototype s2）
///
/// 构成：
/// - `header` · greeting + 状态行
/// - `TodayGlance` · 今日速览卡片
/// - `FilterChipBar` · 5 个 filter chips
/// - `LazyVStack` · 卡片列表（store.filteredCards）
/// - **FAB** 右下角浮动录音按钮 (Step 8, 通过 overlay)
///   - 快速点 → fullScreenCover 进 LongRecordingView
///   - 按住 300ms+ → 短捕捉, 松手时首页显示 toast
struct HomeView: View {
    /// Deep link 传入的卡片 ID. 收到后查找 card → push 到详情页 → 清零.
    @Binding var deepLinkCardId: String?

    @State private var store = HomeStore()
    @State private var summaryStore = FullSummaryStore()
    @State private var recordingStore = RecordingStore()
    @State private var shortCaptureToastMessage: String?
    /// 显式导航路径, 让 deep link 和通知能 programmatic push.
    @State private var navigationPath = NavigationPath()
    /// 全局唯一的 Live Activity 实例. 多个任务都堆在这一个里面.
    @State private var liveActivity: Activity<CardProcessingAttributes>?
    /// Live Activity 当前的 task 列表 (和 ContentState.tasks 同步)
    @State private var liveActivityTasks: [TaskItem] = []
    @Environment(RingCoordinator.self) private var ringCoordinator

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    header
                    TodayDigestText(summary: store.summary)
                        .padding(.horizontal, 16)

                    FilterChipBar(store: store)
                        .padding(.top, 2)

                    cardList

                    // 给 FAB 留出滚动底部空间, 避免被最后一张卡挡住
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 8)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .task {
                // Step 9: 从 repository 异步刷新. 默认 BundleHomeRepository
                // 读 `home.json`, BundleFullSummaryRepository 读 `full_summaries.json`.
                await store.refresh()
                await summaryStore.refresh()
            }
            .navigationDestination(for: Card.self) { card in
                // 按卡片 type dispatch 到对应详情页. 所有 4 种类型都有专属详情 view.
                switch card.type {
                case .longRec:
                    RecordingDetailView(
                        card: card,
                        store: store,
                        summaryStore: summaryStore
                    )
                case .command:
                    CommandDetailView(card: card)
                case .idea:
                    IdeaDetailView(card: card)
                case .todo:
                    TodoDetailView(card: card)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // FAB + timer label 作为整体浮在右下角
                // 长录音 + 短捕捉 全部留在首页, 不再 fullScreenCover 到独立页面
                // (prototype `fabDown` / `fabUp` 行为: 快速点 FAB = 进长录音态留在首页,
                //  按住 = 短捕捉, 再次点 = 停止)
                FloatingRecordButton(store: recordingStore)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .overlay(alignment: .bottom) { shortCaptureToast }
            // 短捕捉结束 → Agent mock 分类 → 插入新卡 + toast
            .onChange(of: recordingStore.lastShortCaptureId) { _, newValue in
                guard newValue != nil else { return }
                handleShortCaptureFinished()
            }
            // 长录音停止 → 插入一张新的 .longRec 卡片到 feed 顶部
            .onChange(of: recordingStore.lastLongRecordingId) { _, newValue in
                guard newValue != nil else { return }
                handleLongRecordingFinished()
            }
            // Deep link: 通知 / Widget 点击 → 跳转到指定卡片详情页
            .onChange(of: deepLinkCardId) { _, newCardId in
                handleDeepLink(cardId: newCardId)
            }
        }
    }

    // MARK: - Deep link

    private func handleDeepLink(cardId: String?) {
        guard let cardId else { return }
        // 找到卡片 → 推到 NavigationStack
        if let card = store.cards.first(where: { $0.id == cardId }) {
            // 如果卡片还在 processing, 强制完成 (防止 Task 被系统 suspend)
            if card.status == .processing {
                store.simulateProcessingComplete(cardId: cardId)
            }
            // 清掉 path 里的旧页面, 再 push 新的
            navigationPath = NavigationPath()
            // 微延迟让 NavigationStack 重置后再 push, 避免动画冲突
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                navigationPath.append(card)
            }
        }
        // 消费完毕, 清零
        deepLinkCardId = nil
    }

    // MARK: - Recording finished handlers

    /// 快速点 FAB → 长录音开始 → 再次点 FAB 停止 → 本方法被调用,
    /// 在 feed 顶部插入一张 `.longRec` 卡片.
    private func handleLongRecordingFinished() {
        let seconds = recordingStore.lastCaptureDurationSec
        guard seconds >= 2 else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            store.insertNewCapturedCard(type: .longRec, durationSec: seconds)
        }

        let timeText = formatDuration(seconds)
        showToastBriefly("新增长录音 \(timeText) · 正在结构化")

        // 异步处理模拟: 4-6 秒后 card → done + 通知 + widget 刷新
        scheduleProcessingSimulation(type: .longRec)
    }

    /// 按住 FAB 做短捕捉, 松手后走这里.
    private func handleShortCaptureFinished() {
        let seconds = recordingStore.lastCaptureDurationSec
        guard seconds >= 1 else { return }

        let classified: Card.CardType = [.command, .idea, .todo]
            .randomElement() ?? .idea

        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            store.insertNewCapturedCard(type: classified, durationSec: seconds)
        }

        showToastBriefly("已捕捉 \(seconds) 秒 · Agent 判断为\(classified.label)")
        scheduleProcessingSimulation(type: classified)
    }

    // MARK: - Processing simulation

    /// 模拟 Agent 异步处理: 延迟后把 processing 卡片转成 done,
    /// 更新 Live Activity (单个共享实例) + 刷新 Widget.
    private func scheduleProcessingSimulation(type: Card.CardType) {
        store.writeToAppGroup()

        guard let card = store.cards.first, card.status == .processing else { return }

        let delay = Double.random(in: 4...6)
        let completedTitle = HomeStore.completedTitle(for: type)
        let completedSummary = HomeStore.completedSummary(for: type)
        let processingDetail = card.processingMeta ?? "处理中…"

        // ① 往 Live Activity 里插入新的 processing 任务 (新的在最上面)
        let newTask = TaskItem(
            id: card.id,
            typeRaw: type.rawValue,
            status: "processing",
            title: "正在处理…",
            detail: processingDetail
        )
        addTaskToLiveActivity(newTask)

        // ② 延迟后: card → done + 更新 Live Activity + 刷新 widget
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.3)) {
                store.simulateProcessingComplete(cardId: card.id)
            }
            store.writeToAppGroup()

            // 更新这条 task 的状态为 done (带详细摘要)
            updateTaskInLiveActivity(
                cardId: card.id,
                status: "done",
                title: completedTitle,
                detail: completedSummary
            )

            // 检查是否所有 task 都完成了 — 是的话 15 秒后结束 Activity
            if liveActivityTasks.allSatisfy(\.isDone) {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                // 再次确认 (期间可能有新任务加入)
                if liveActivityTasks.allSatisfy(\.isDone) {
                    await endLiveActivity()
                }
            }
        }
    }

    // MARK: - Live Activity management (single shared instance)

    /// 往 Live Activity 的 task list 前面插入一条新任务.
    /// 如果还没有 Activity, 创建一个; 如果已有, update 它.
    private func addTaskToLiveActivity(_ task: TaskItem) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // 插入到最前面, 最多保留 4 条
        liveActivityTasks.insert(task, at: 0)
        if liveActivityTasks.count > 4 {
            liveActivityTasks = Array(liveActivityTasks.prefix(4))
        }

        let state = CardProcessingAttributes.ContentState(tasks: liveActivityTasks)
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity = liveActivity {
            // 已有 Activity — 直接 update
            Task {
                await activity.update(content)
            }
        } else {
            // 第一次 — 创建新的 Activity
            do {
                liveActivity = try Activity.request(
                    attributes: CardProcessingAttributes(),
                    content: content,
                    pushType: nil
                )
            } catch {
                print("[LiveActivity] request failed: \(error)")
            }
        }
    }

    /// 更新某条 task 的状态 (processing → done).
    private func updateTaskInLiveActivity(
        cardId: String,
        status: String,
        title: String,
        detail: String
    ) {
        guard let idx = liveActivityTasks.firstIndex(where: { $0.id == cardId }) else { return }
        liveActivityTasks[idx] = TaskItem(
            id: cardId,
            typeRaw: liveActivityTasks[idx].typeRaw,
            status: status,
            title: title,
            detail: detail
        )

        let state = CardProcessingAttributes.ContentState(tasks: liveActivityTasks)
        let content = ActivityContent(state: state, staleDate: nil)

        let activity = liveActivity
        Task { await activity?.update(content) }
    }

    /// 结束 Live Activity, 清理本地状态.
    private func endLiveActivity() async {
        let activity = liveActivity
        await activity?.end(nil, dismissalPolicy: .default)
        liveActivity = nil
        liveActivityTasks = []
    }

    private func showToastBriefly(_ message: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            shortCaptureToastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeIn(duration: 0.2)) {
                shortCaptureToastMessage = nil
            }
        }
    }

    /// 把秒数格式化成 "m:ss" 或 "X 秒" —— 短的用"秒"直观, 长的用 mm:ss.
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) 秒"
        }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    @ViewBuilder
    private var shortCaptureToast: some View {
        if let shortCaptureToastMessage {
            Text(shortCaptureToastMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.panel)
                .overlay { Capsule().stroke(Theme.accent.opacity(0.4), lineWidth: 0.5) }
                .clipShape(.capsule)
                .padding(.bottom, 100)
                .transition(.opacity.combined(with: .offset(y: 10)))
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.summary.greeting)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.text)
                .contentTransition(.opacity)

            HStack(spacing: 6) {
                Circle()
                    .fill(ringCoordinator.isConnected ? Theme.accent : Theme.textDimmer)
                    .frame(width: 6, height: 6)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 4)
                Text(statusLine)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim)
                    .contentTransition(.opacity)
            }
        }
        .padding(.horizontal, 16)
    }

    /// 实时从 `RingCoordinator` 读连接状态 + 电量 / 天数.
    /// 戒指事件通过 AsyncStream → @Observable → SwiftUI 自动刷新.
    private var statusLine: String {
        let ringText: String = {
            switch ringCoordinator.connectionState {
            case .idle, .scanning, .connecting: "正在连接戒指"
            case .connected: "戒指已连接"
            case .reconnecting: "戒指重连中"
            case .bluetoothOff: "蓝牙未开启"
            case .unauthorized: "蓝牙未授权"
            case .failed: "戒指连接失败"
            }
        }()
        let dayCount = ringCoordinator.isConnected ? ringCoordinator.dayCount : store.summary.dayCount
        return "第 \(dayCount) 天 · \(ringText) · 今日第 \(store.summary.interactionsToday) 次交互"
    }

    /// 按 `Card.group` 把 filteredCards 分组, 每组前面插一个 `TimeSeparator`.
    /// 保持 HomeStore.mockCards 里 append 的顺序 (今天→昨天), 不做字典序排序.
    private var groupedCards: [(group: String, cards: [Card])] {
        var seenGroups: [String] = []
        var grouped: [String: [Card]] = [:]
        for card in store.filteredCards {
            if grouped[card.group] == nil {
                seenGroups.append(card.group)
                grouped[card.group] = []
            }
            grouped[card.group]?.append(card)
        }
        return seenGroups.map { ($0, grouped[$0] ?? []) }
    }

    private var cardList: some View {
        LazyVStack(spacing: 12) {
            if store.filteredCards.isEmpty {
                emptyState
            } else {
                ForEach(Array(groupedCards.enumerated()), id: \.element.group) { _, bucket in
                    // 时间分隔符
                    TimeSeparator(label: bucket.group)
                        .padding(.top, 6)

                    ForEach(bucket.cards) { card in
                        // 所有 4 种卡片类型都可点, navigationDestination 内按 type 分发到
                        // 对应的 Detail view.
                        NavigationLink(value: card) {
                            CardRow(card: card)
                        }
                        .buttonStyle(.plain)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity
                        ))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeOut(duration: 0.2), value: store.filteredCards)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("没有匹配的卡片", systemImage: "tray")
                .foregroundStyle(Theme.textDim)
        } description: {
            Text("切换其他筛选，或下拉刷新")
                .foregroundStyle(Theme.textDimmer)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    HomeView(deepLinkCardId: .constant(nil))
        // NotificationManager 已移除
        .preferredColorScheme(.dark)
}
