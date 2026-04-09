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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    metaBlock
                    sourceQuoteBlock
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
        .presentationDetents([.medium, .large])
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
            Text("来自会议的原话")
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

    private var suggestionsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Agent 建议的快捷 Prompt")
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
