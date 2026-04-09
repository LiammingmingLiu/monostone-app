import SwiftUI

/// 分享 modal (对应 prototype `modal_share`).
///
/// 结构:
/// - 顶部预览: 被分享的卡片标题 + 副信息
/// - 格式选择器: Markdown / PDF / 纯文本 (三选一)
/// - 分享目标 grid: 8 个平台图标
/// - 点击目标后触发 toast (demo 行为)
struct ShareSheetView: View {
    let cardTitle: String
    let cardSubtitle: String
    let onShare: (ShareFormat, ShareTarget) -> Void

    @State private var selectedFormat: ShareFormat = .markdown
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    previewCard
                    formatSection
                    targetsSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("分享")
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

    // MARK: - Preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cardTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Text(cardSubtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Format picker

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("格式")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.2)
            HStack(spacing: 8) {
                ForEach(ShareFormat.allCases) { format in
                    formatChip(format)
                }
            }
        }
    }

    private func formatChip(_ format: ShareFormat) -> some View {
        let isSelected = selectedFormat == format
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedFormat = format
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: format.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(format.label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? Theme.text : Theme.textDim)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.accent.opacity(0.16) : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Theme.accent.opacity(0.6) : Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Targets grid

    private var targetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分享到")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.2)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 16
            ) {
                ForEach(ShareTarget.allCases) { target in
                    targetButton(target)
                }
            }
        }
    }

    private func targetButton(_ target: ShareTarget) -> some View {
        Button {
            onShare(selectedFormat, target)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(target.tint.opacity(0.14))
                    .overlay { Circle().stroke(target.tint.opacity(0.4), lineWidth: 0.5) }
                    .overlay {
                        Image(systemName: target.systemImage)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(target.tint)
                    }
                    .frame(width: 52, height: 52)
                Text(target.label)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ShareSheetView(
        cardTitle: "和敦敏的 Series A 跟进会",
        cardSubtitle: "42:18 · 4 人 · 3 项待办",
        onShare: { _, _ in }
    )
    .preferredColorScheme(.dark)
}
