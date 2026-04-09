import SwiftUI

/// 长录音详情页（对应 prototype s3 recording_details 的最小版本）.
///
/// Step 6 focus: 把这里做成 3 个 modal 的触发入口:
/// - "查看完整总结" 按钮 → FullSummaryView
/// - "分享" 按钮 → ShareSheetView
/// - Action Items 列表里每一行 → ActionItemDetailView
///
/// 完整的波形动画、时间轴、结构化摘要等等留到后续 step (没在路线图里专门提到).
struct RecordingDetailView: View {
    let card: Card
    let store: HomeStore

    // 单一 state 驱动所有 3 个 modals (enum-based sheet pattern)
    @State private var presentedSheet: SheetDestination?
    @State private var toastMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                actions
                actionItemsSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(card.type.label)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .fullSummary(let summary):
                FullSummaryView(summary: summary)
            case .actionItem(let item):
                ActionItemDetailView(
                    item: item,
                    onSuggestionTap: { prompt in
                        showToast("已发给 Agent: \(prompt.prefix(20))…")
                    }
                )
            case .share:
                ShareSheetView(
                    cardTitle: card.title,
                    cardSubtitle: card.metaLine,
                    onShare: { format, target in
                        showToast("已用 \(format.label) 分享到 \(target.label)")
                    }
                )
            }
        }
        .overlay(alignment: .bottom) { toastOverlay }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(card.metaLine)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
            if let project = card.project {
                Text(project)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .tracking(0.4)
            }
        }
    }

    // MARK: - Action buttons

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                if let summary = FullSummaryStore.summary(for: card.id) {
                    presentedSheet = .fullSummary(summary)
                } else {
                    showToast("该卡片暂无完整纪要")
                }
            } label: {
                Label("查看完整总结", systemImage: "text.alignleft")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.14))
                    .foregroundStyle(Theme.accent)
                    .clipShape(.capsule)
            }
            .buttonStyle(.plain)

            Button {
                presentedSheet = .share
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .frame(width: 38, height: 38)
                    .background(Theme.panel)
                    .overlay { Circle().stroke(Theme.border, lineWidth: 0.5) }
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("分享")

            Spacer()
        }
    }

    // MARK: - Action items

    private var actionItemsSection: some View {
        let items = store.actionItems(for: card.id)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Action Items")
            if items.isEmpty {
                Text("没有提取到待办")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDimmer)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            presentedSheet = .actionItem(item)
                        } label: {
                            actionItemRow(item)
                        }
                        .buttonStyle(.plain)
                        if item.id != items.last?.id {
                            Divider().background(Theme.border).padding(.leading, 16)
                        }
                    }
                }
                .background(Theme.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.border, lineWidth: 0.5)
                }
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private func actionItemRow(_ item: ActionItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.typeTodo.opacity(0.6))
                .frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.text)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.leading)
                Text("\(item.owner) · \(item.deadline)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeIn(duration: 0.2)) { toastMessage = nil }
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toastMessage {
            Text(toastMessage)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.panel)
                .overlay { Capsule().stroke(Theme.border, lineWidth: 0.5) }
                .clipShape(.capsule)
                .padding(.bottom, 30)
                .transition(.opacity.combined(with: .offset(y: 10)))
        }
    }
}

// MARK: - Sheet destination (enum-based sheet)

/// sheet-navigation-patterns.md §"Enum-Based Sheet Management" 规则:
/// 多个不同的 sheet 用一个 Identifiable enum + 一个 .sheet(item:) 驱动.
enum SheetDestination: Identifiable {
    case fullSummary(FullSummary)
    case actionItem(ActionItem)
    case share

    var id: String {
        switch self {
        case .fullSummary(let s): "full-\(s.cardId)"
        case .actionItem(let i):  "item-\(i.id)"
        case .share:              "share"
        }
    }
}

#Preview {
    NavigationStack {
        RecordingDetailView(
            card: HomeStore.mockCards.first { $0.type == .longRec }!,
            store: HomeStore()
        )
    }
    .preferredColorScheme(.dark)
}
