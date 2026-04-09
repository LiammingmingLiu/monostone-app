import SwiftUI

/// 完整会议纪要 modal (对应 prototype `modal_full_summary`).
///
/// 层级契约 (prototype 里的渲染约定):
/// - 1 个 H1 (标题, 渲染为 `.largeTitle` 或手工大号字)
/// - 1 个 meta 表格
/// - 多个 H2 (section.heading)
/// - section 内含 H3 / paragraph / quote / list / table
///
/// 使用 `.sheet(item:)` 驱动, 入参是 `FullSummary`.
struct FullSummaryView: View {
    let summary: FullSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    metaTable
                    ForEach(summary.sections) { section in
                        sectionView(section)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("完整总结")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .tint(Theme.accent)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Title (H1)

    private var titleBlock: some View {
        Text(summary.title)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Theme.text)
            .lineSpacing(4)
            .padding(.bottom, 4)
    }

    // MARK: - Meta table

    private var metaTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(summary.meta.enumerated()), id: \.offset) { index, entry in
                HStack(alignment: .top, spacing: 14) {
                    Text(entry.key)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textDim)
                        .frame(width: 64, alignment: .leading)
                    Text(entry.value)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 5)
                if index != summary.meta.count - 1 {
                    Divider().background(Theme.border)
                }
            }
        }
        .padding(14)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - Section (H2 + blocks)

    private func sectionView(_ section: SummarySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.heading)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.text)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.borderStrong)
                        .frame(height: 0.5)
                        .offset(y: 4)
                }

            ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                SummaryBlockView(block: block)
            }
        }
    }
}

#Preview {
    FullSummaryView(summary: FullSummaryStore.mockSummaries["rec-1"]!)
        .preferredColorScheme(.dark)
}
