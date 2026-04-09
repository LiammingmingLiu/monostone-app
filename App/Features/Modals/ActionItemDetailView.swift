import SwiftUI

/// 单条 Action Item 的详情 modal (对应 prototype `modal_action_item`).
///
/// 结构:
/// - 标题（action item 的 text）
/// - meta: 负责人 + 截止
/// - 原话 quote block (来自会议纪要)
/// - 3 条 Agent 建议 prompt, 点击后 dismiss + 触发 agent dispatch
///
/// 使用 `.sheet(item:)` 驱动. Sheet 内通过 `@Environment(\.dismiss)` 自己处理关闭
/// (sheet-navigation-patterns.md §"Sheets Own Their Actions" 规则).
struct ActionItemDetailView: View {
    let item: ActionItem
    let onSuggestionTap: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    /// 默认开到 `.large`. SwiftUI 不管 `presentationDetents` 数组顺序, 默认永远选
    /// 最小的那个, 必须通过 `selection:` binding 才能强制打开时是 `.large`.
    @State private var detent: PresentationDetent = .large

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    metaBlock
                    sourceQuoteBlock
                    voicePromptBlock    // 新增: "告诉 Agent 下一步" 语音 CTA
                    suggestionsBlock
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Action Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .tint(Theme.accent)
                }
            }
        }
        .presentationDragIndicator(.visible)
        // 默认 `.large` 直接拉满到顶, 避免只露出半屏看不到 source quote + agent
        // suggestions. 用户仍然可以手动拖到 `.medium` 缩小.
        .presentationDetents([.large, .medium], selection: $detent)
    }

    // MARK: - Subviews

    private var titleBlock: some View {
        Text(item.text)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Theme.text)
            .lineSpacing(2)
    }

    private var metaBlock: some View {
        HStack(spacing: 12) {
            metaChip(icon: "person", label: item.owner)
            metaChip(icon: "clock", label: item.deadline)
        }
    }

    private func metaChip(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.panel)
        .overlay {
            Capsule().stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.capsule)
    }

    private var sourceQuoteBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("从会议中摘取")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.2)
            VStack(alignment: .leading, spacing: 6) {
                Text("\"\(item.sourceQuote)\"")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(Theme.text)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text("— \(item.sourceCard) · \(item.sourceTime)")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textDim)
            }
            .padding(14)
            .background(Theme.accent.opacity(0.06))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 2)
            }
            .clipShape(.rect(cornerRadius: 8))
        }
    }

    /// "告诉 Agent 下一步" 语音 CTA 提醒. 对应 prototype `.voice-prompt` 区块:
    /// 解释性文字 + 麦克风按钮. 核心设计意图是让用户意识到"可以语音直接告诉
    /// Agent 要做什么", 而不只是从下面的 suggestions 里挑一个.
    private var voicePromptBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("告诉 Agent 下一步")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.2)

            VStack(alignment: .leading, spacing: 12) {
                Text("想让 Agent 帮你推进这条？直接用语音告诉它要做什么 —— 起草邮件、查资料、关联历史、生成分析都可以。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.text)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    onSuggestionTap("语音输入占位 · 按住戒指或首页 FAB")
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                            .shadow(color: Theme.accent.opacity(0.6), radius: 4)
                        Text("告诉 Agent 下一步")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Theme.accent.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.accent.opacity(0.4), lineWidth: 0.5)
                    }
                    .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: item.id)
            }
            .padding(14)
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 10))
        }
    }

    private var suggestionsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("常用的后续动作")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.2)
            VStack(spacing: 8) {
                ForEach(Array(item.agentSuggestions.enumerated()), id: \.offset) { _, suggestion in
                    Button {
                        onSuggestionTap(suggestion)
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\u{201C}")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.accent)
                                .offset(y: 2)
                            Text(suggestion)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
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
        }
    }
}

#Preview {
    ActionItemDetailView(
        item: HomeStore.mockActionItems["rec-1"]!.first!,
        onSuggestionTap: { _ in }
    )
    .preferredColorScheme(.dark)
}
