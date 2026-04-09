import SwiftUI

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
    @State private var store = HomeStore()
    @State private var summaryStore = FullSummaryStore()
    @State private var recordingStore = RecordingStore()
    @State private var shortCaptureToastMessage: String?
    @Environment(RingCoordinator.self) private var ringCoordinator

    var body: some View {
        NavigationStack {
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
            .onChange(of: recordingStore.lastShortCaptureId) { _, _ in
                handleShortCaptureFinished()
            }
        }
    }

    // MARK: - Short capture toast

    private func handleShortCaptureFinished() {
        let seconds = Int(recordingStore.elapsedSeconds.rounded())
        withAnimation(.easeOut(duration: 0.2)) {
            shortCaptureToastMessage = "已捕捉 \(seconds) 秒 · Agent 会自动分类"
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeIn(duration: 0.2)) {
                shortCaptureToastMessage = nil
            }
        }
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
    HomeView()
        .preferredColorScheme(.dark)
}
