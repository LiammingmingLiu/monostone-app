import SwiftUI

/// s15 · 导出所有数据.
/// 列出所有导出选项, 点击后 toast 提示 (真实实现走 `POST /v1/export/request`).
struct ExportDataView: View {
    @Bindable var store: ProfileStore
    @State private var lastRequestedScope: ExportOption.Scope?
    @State private var showToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hintSection
                optionsSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("导出所有数据")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) { toastOverlay }
    }

    // MARK: - Subviews

    private var hintSection: some View {
        Text("""
        所有导出任务由后端异步生成, 完成后推送下载链接到你登录的 iCloud Drive。\
        大数据集（> 1 GB）可能需要几分钟。
        """)
        .font(.system(size: 12))
        .foregroundStyle(Theme.textDim)
        .padding(.horizontal, 4)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("可导出")
            MenuGroup {
                ForEach(store.exportOptions) { option in
                    optionRow(option)
                    if option.id != store.exportOptions.last?.id {
                        Divider().background(Theme.border).padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func optionRow(_ option: ExportOption) -> some View {
        Button {
            lastRequestedScope = option.scope
            withAnimation(.easeOut(duration: 0.2)) { showToast = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeIn(duration: 0.2)) { showToast = false }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(option.scope.label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.text)
                        Text(option.format.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.14))
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    HStack(spacing: 6) {
                        Text(option.sizeDisplay)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.textDim)
                        if option.includeAudio {
                            Text("· 含原音频")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textDimmer)
                        }
                    }
                }
                Spacer()
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if showToast, let scope = lastRequestedScope {
            Text("已提交导出任务：\(scope.label)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.panel)
                .overlay {
                    Capsule().stroke(Theme.border, lineWidth: 0.5)
                }
                .clipShape(.capsule)
                .padding(.bottom, 30)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

#Preview {
    NavigationStack {
        ExportDataView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
