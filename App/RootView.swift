import SwiftUI

/// 应用根视图：4 个 tab 的 TabView，对应 monostone-ios-prototype 里的 4 个 root screens
/// - Home    (s2 · 首页 feed)
/// - Memory  (s8 · 记忆)
/// - Agent   (s9 · Agent 聊天)
/// - Profile (s10 · 我)
///
/// 使用 iOS 18+ 的 `Tab` API (替代已 deprecated 的 `.tabItem(_:)`), 兼容 iOS 26 Liquid Glass
/// tab bar minimize behavior 保持默认, 等确定要开 Liquid Glass 时再加 `.tabBarMinimizeBehavior`
struct RootView: View {
    var body: some View {
        TabView {
            Tab("首页", systemImage: "square.grid.2x2") {
                HomeView()
            }
            Tab("记忆", systemImage: "brain") {
                MemoryView()
            }
            Tab("Agent", systemImage: "bubble.left.and.bubble.right") {
                AgentView()
            }
            Tab("我", systemImage: "person.circle") {
                ProfileView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
