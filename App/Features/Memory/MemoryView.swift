import SwiftUI

/// 记忆 Tab（对应 prototype s8 memory_tab）.
///
/// 结构：
/// - `header` · 大标题 "记忆" + 实体/沉淀/今日新增 副标题
/// - `MemoryStatsBar` · L0-L4 5 列统计
/// - "今天学到的" section · insights list
/// - "高频实体" section · entities list
/// - "最近纠正" section · corrections list (金色 bullet 区别 insights)
///
/// 未实现（预留）：
/// - 点击 entity 跳转 entity 详情页 (预留 `onTap` 但目前只 toast-style)
/// - 搜索框顶部（prototype 里还没画）
struct MemoryView: View {
    @State private var store = MemoryStore()
    @State private var tappedEntity: MemoryEntity?
    @State private var showEntityAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    header
                    MemoryStatsBar(stats: store.stats)
                        .padding(.horizontal, 16)

                    insightsSection
                    entitiesSection
                    correctionsSection

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .task { await store.refresh() }
            .alert(
                tappedEntity?.name ?? "",
                isPresented: $showEntityAlert,
                presenting: tappedEntity
            ) { _ in
                Button("好", role: .cancel) { }
            } message: { entity in
                Text("\(entity.memoryCount) 条记忆\n\n\(entity.subtitle)\n\nEntity 详情页待后续 step 实现")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("记忆")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.text)
            Text(store.summaryLine)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Sections

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("今天学到的")
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                ForEach(store.insights) { insight in
                    InsightCard(
                        markdownBody: insight.body,
                        source: insight.source,
                        accent: Theme.accent
                    )
                    if insight.id != store.insights.last?.id {
                        Divider().background(Theme.border).padding(.leading, 34)
                    }
                }
            }
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private var entitiesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("高频实体")
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                ForEach(store.entities) { entity in
                    EntityRow(entity: entity) {
                        tappedEntity = entity
                        showEntityAlert = true
                    }
                    if entity.id != store.entities.last?.id {
                        Divider().background(Theme.border).padding(.leading, 64)
                    }
                }
            }
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private var correctionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("最近纠正")
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                ForEach(store.corrections) { correction in
                    InsightCard(
                        markdownBody: correction.body,
                        source: correction.source,
                        accent: Theme.typeIdea
                    )
                    if correction.id != store.corrections.last?.id {
                        Divider().background(Theme.border).padding(.leading, 34)
                    }
                }
            }
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    MemoryView()
        .preferredColorScheme(.dark)
}
