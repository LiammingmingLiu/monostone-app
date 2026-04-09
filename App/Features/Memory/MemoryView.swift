import SwiftUI

/// 记忆 Tab（对应 prototype s8）
///
/// TODO（按 prototype 的 pages-and-interactions.md §7.5 memory_tab 实现）:
/// - [ ] Memory Tree 5 列 stats（L0-L4）
/// - [ ] 今天学到的 insights section（青绿圆点 + HTML 片段渲染）
/// - [ ] 高频实体 entities section（头像 + kind badge + chevron）
/// - [ ] 最近纠正 corrections section（金色圆点变体）
/// - [ ] 数据从 `GET /v1/memory/overview` 拉取（当前只读 mock.js 的 MEMORY_OVERVIEW）
struct MemoryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    placeholder
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("记忆")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.text)
            Text("47 个实体 · 1,842 条沉淀 · 今天新增 4 条")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
        }
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Tree + Entities 尚未实现")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            Text("参考 monostone-ios-prototype/docs/pages-and-interactions.md §7.5")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDimmer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    MemoryView()
        .preferredColorScheme(.dark)
}
