import SwiftUI

/// 首页 Feed（对应 prototype s2）
///
/// 构成：
/// - `header` · greeting + 状态行
/// - `TodayGlance` · 今日速览卡片
/// - `FilterChipBar` · 5 个 filter chips
/// - `LazyVStack` · 卡片列表（store.filteredCards）
///
/// 未实现（后续步骤）：
/// - FAB 浮动录音按钮（Step 8）
/// - Action Items 嵌入 + 左滑删除（Step 7）
/// - 打开 card 详情页（Step 6 modals + navigation）
struct HomeView: View {
    @State private var store = HomeStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    TodayGlance(summary: store.summary)
                        .padding(.horizontal, 16)

                    FilterChipBar(store: store)
                        .padding(.top, 2)

                    cardList
                }
                .padding(.vertical, 8)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Card.self) { card in
                RecordingDetailView(card: card, store: store)
            }
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
                    .fill(store.summary.ringConnected ? Theme.accent : Theme.textDimmer)
                    .frame(width: 6, height: 6)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 4)
                Text(statusLine)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .padding(.horizontal, 16)
    }

    private var statusLine: String {
        let ringText = store.summary.ringConnected ? "戒指已连接" : "戒指未连接"
        return "第 \(store.summary.dayCount) 天 · \(ringText) · 今日第 \(store.summary.interactionsToday) 次交互"
    }

    private var cardList: some View {
        LazyVStack(spacing: 12) {
            if store.filteredCards.isEmpty {
                emptyState
            } else {
                ForEach(store.filteredCards) { card in
                    // 长录音卡片可点击进入详情页; 其他类型暂时不可点
                    // (step 7 会把 Action Items 直接展示在 home feed 里)
                    Group {
                        if card.type == .longRec {
                            NavigationLink(value: card) {
                                CardRow(card: card)
                            }
                            .buttonStyle(.plain)
                        } else {
                            CardRow(card: card)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity
                    ))
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
