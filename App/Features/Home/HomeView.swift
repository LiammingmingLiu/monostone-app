import SwiftUI

/// 首页 Feed（对应 prototype s2）
///
/// TODO（按 prototype 的 pages-and-interactions.md §2 home_feed 实现）:
/// - [ ] 顶部 greeting + 今日速览（DailySummary）
/// - [ ] Filter chips（全部 / 长录音 / 指令 / 灵感 / 待办）
/// - [ ] 卡片列表 LazyVStack，支持 `processing` 状态的 shimmer
/// - [ ] 嵌入 Action Items 左滑删除（最复杂的手势交互，参考 prototype §A1）
/// - [ ] FAB 浮动录音按钮（长按 / 快点两态，参考 prototype §F1 F2）
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    placeholderContent
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
            Text("早上好，明明")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.text)
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 6, height: 6)
                Text("第 12 天 · 戒指已连接 · 今日第 8 次交互")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim)
            }
        }
    }

    private var placeholderContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("首页 Feed 尚未实现")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            Text("参考 monostone-ios-prototype/docs/pages-and-interactions.md §2 home_feed")
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
    HomeView()
        .preferredColorScheme(.dark)
}
