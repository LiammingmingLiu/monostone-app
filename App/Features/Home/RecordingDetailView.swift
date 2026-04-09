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
    let summaryStore: FullSummaryStore

    // 单一 state 驱动所有 3 个 modals (enum-based sheet pattern)
    @State private var presentedSheet: SheetDestination?
    @State private var toastMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                actions
                participantsSection
                structuredSummarySection
                actionItemsSection
                decisionsSection
                memoryLearnedSection
                transcriptSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(card.type.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Demo-only 重置按钮: 左滑删掉的 action items 可以一键还原
            if store.actionItems(for: card.id).count < (HomeStore.mockActionItems[card.id]?.count ?? 0) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            store.restoreActionItems(for: card.id)
                        }
                        showToast("已重置 Action Items")
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(Theme.accent)
                    .accessibilityLabel("重置 Action Items")
                }
            }
        }
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
                if let summary = summaryStore.summary(for: card.id) {
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

    // MARK: - Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("参与人")
            HStack(spacing: 16) {
                ForEach(participants, id: \.self) { name in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Theme.panel)
                            .overlay { Circle().stroke(Theme.borderStrong, lineWidth: 0.5) }
                            .overlay {
                                Text(String(name.prefix(1)))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.text)
                            }
                            .frame(width: 42, height: 42)
                        Text(name)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textDim)
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var participants: [String] {
        if card.id == "rec-2" {
            return ["林啸", "明明", "王浩"]
        }
        return ["敦敏", "明明", "郑灿", "马俊"]
    }

    // MARK: - Structured summary

    private var structuredSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("结构化摘要")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(summaryBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Theme.typeLongRec)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(bullet)
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.text)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 7)
                    if bullet != summaryBullets.last {
                        Divider().background(Theme.border)
                    }
                }
                // 查看完整总结 link
                Button {
                    if let summary = summaryStore.summary(for: card.id) {
                        presentedSheet = .fullSummary(summary)
                    } else {
                        showToast("该卡片暂无完整纪要")
                    }
                } label: {
                    HStack {
                        Text("查看完整总结")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.typeLongRec)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.typeLongRec)
                    }
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var summaryBullets: [String] {
        if card.id == "rec-2" {
            return [
                "A 组 (新 branch) 的 memory retrieval 准确率相比 baseline 提升 14%, 但 p95 latency 增加了 180ms.",
                "B 组 (baseline) 在少样本场景更稳定, 但多会话场景下会出现 L2 记忆泄漏到其他 session.",
                "最终决定: A/B 同时在线, 按 session 长度动态选择策略, 短会话走 baseline, 长会话走新 branch.",
                "下一步集成 confidence decay 机制, 验证长尾 memory 的稳定性."
            ]
        }
        return [
            "Linear 对产品定义提出关键质疑: 是 infra 还是 closed-loop? 明明确认 Agent 层是闭环, 仅插件生态开放.",
            "最大风险不是巨头入局, 而是戒指品类本身两年后没起来. 巨头入局反而是品类验证.",
            "Linear 认为 OpenAI 是头号威胁, Apple 反而排很后.",
            "双麦 15dB SNR 的优势要包装成 \"freestyle recording\" 营销故事."
        ]
    }

    // MARK: - Decisions

    private var decisionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("关键决策")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(decisions, id: \.text) { d in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(d.text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(d.who)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textDim)
                    }
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if d.text != decisions.last?.text {
                        Divider().background(Theme.border)
                    }
                }
            }
            .padding(14)
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var decisions: [(text: String, who: String)] {
        if card.id == "rec-2" {
            return [
                (text: "A/B 策略不做 hard switch, 按 session 特征动态选",
                 who: "林啸主张, 明明认可"),
                (text: "Memory promotion 加 confidence decay 作为正式 feature",
                 who: "团队共识")
            ]
        }
        return [
            (text: "不做 Kickstarter, 坚持独立站 DTC",
             who: "明明主张, Linear 支持"),
            (text: "企业场景优先级高于家庭场景, 作为 B2B 扩展路径",
             who: "Linear 建议, 待评估")
        ]
    }

    // MARK: - Memory learned

    private var memoryLearnedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("本次会议学到了什么")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(memoryLearned, id: \.self) { md in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "brain")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .padding(.top, 3)
                        Text(attributedMarkdown(md))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.text)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                    if md != memoryLearned.last {
                        Divider().background(Theme.border)
                    }
                }
            }
            .padding(14)
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var memoryLearned: [String] {
        if card.id == "rec-2" {
            return [
                "**Memory A/B** 新 branch 在准确率上领先 14%",
                "**王浩** 开始负责 Memory 模块的 confidence decay 实现",
                "**Monostone 后端** 新增 \"长尾 memory 稳定性\" 作为关键指标"
            ]
        }
        return [
            "**敦敏** 是 Linear Capital 合伙人, 偏好 closed-loop 定位",
            "你谈 vision 时喜欢用 **Polanyi tacit knowledge** 框架",
            "**Marshall** 在 Linear 眼中硬件可信度很高",
            "**Series A** 新增关键风险: 品类形成而非巨头入局"
        ]
    }

    private func attributedMarkdown(_ markdown: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return (try? AttributedString(markdown: markdown, options: options))
            ?? AttributedString(markdown)
    }

    // MARK: - Transcript toggle

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("完整转录")
            Button { showToast("展开转录 (demo)") } label: {
                HStack {
                    Text(card.id == "rec-2" ? "展开 2,814 字" : "展开 4,281 字")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textDimmer)
                }
                .padding(14)
                .background(Theme.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.border, lineWidth: 0.5)
                }
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Action items (with swipe-to-delete)

    @ViewBuilder
    private var actionItemsSection: some View {
        let items = store.actionItems(for: card.id)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("Action Items")
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        SwipeActionItemRow(
                            onDelete: {
                                // 用 spring 动画让 section 自己走 .transition
                                // (section 级联塌陷 = 父视图的 !items.isEmpty 切换)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    store.deleteActionItem(cardId: card.id, itemId: item.id)
                                }
                            }
                        ) {
                            Button {
                                presentedSheet = .actionItem(item)
                            } label: {
                                actionItemRow(item)
                            }
                            .buttonStyle(.plain)
                        }

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
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
            ))
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
            store: HomeStore(),
            summaryStore: FullSummaryStore()
        )
    }
    .preferredColorScheme(.dark)
}
