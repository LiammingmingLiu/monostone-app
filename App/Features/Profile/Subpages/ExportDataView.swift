import SwiftUI

/// s15 · 导出所有数据.
///
/// 对齐 prototype `index.html` 里 `<div class="screen" id="s15">`:
/// - 顶部 hint 文案
/// - **完整导出** section: 2 张大卡片 (Markdown 归档 / JSON 原始数据),
///   每张卡片有 title + 段落描述 + 全宽导出按钮
/// - **按类型导出** section: 3 行 list row (只导出长录音 / 指令产出 / 灵感),
///   每行左边 title + subtitle, 右边一个小的"导出"按钮
///
/// 之前的实现把所有东西塞进一个 `可导出` list 并且把"完整数据"拆成两行
/// (Markdown + JSON) 导致出现两条看起来一样的"完整数据 Markdown", 这次
/// 拆分成两个独立 model 类型 (`FullExportCard` / `TypedExportRow`) 分开渲染.
struct ExportDataView: View {
    @Bindable var store: ProfileStore
    @State private var toastText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hintSection
                fullExportSection
                typedExportSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("导出所有数据")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) { toastOverlay }
    }

    // MARK: - Hint

    private var hintSection: some View {
        Text("你的 Context 是可移植资产. 任何时候都可以完整导出, 换其他工具也不会丢失.")
            .font(.system(size: 12))
            .foregroundStyle(Theme.textDim)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    // MARK: - 完整导出 (2 big cards)

    private var fullExportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("完整导出")
            VStack(spacing: 10) {
                ForEach(store.fullExportCards) { card in
                    fullExportCard(card)
                }
            }
        }
    }

    private func fullExportCard(_ card: FullExportCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)

            Text(card.description)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showToast("已提交: \(card.title)")
            } label: {
                Text(card.format.cta)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Theme.background)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.borderStrong, lineWidth: 0.5)
                    }
                    .clipShape(.rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - 按类型导出 (list rows)

    private var typedExportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("按类型导出")
            MenuGroup {
                ForEach(store.typedExportRows) { row in
                    typedExportRow(row)
                    if row.id != store.typedExportRows.last?.id {
                        Divider().background(Theme.border).padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func typedExportRow(_ row: TypedExportRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.scope.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text(row.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Button {
                showToast("已提交: \(row.scope.label)")
            } label: {
                Text("导出")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .overlay {
                        Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 0.5)
                    }
                    .clipShape(.capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Toast

    private func showToast(_ text: String) {
        withAnimation(.easeOut(duration: 0.2)) { toastText = text }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeIn(duration: 0.2)) { toastText = nil }
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toastText {
            Text(toastText)
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

#Preview {
    NavigationStack {
        ExportDataView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
