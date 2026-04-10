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
    /// Deep link 目标卡片 ID. 从 MonostoneApp 传入, HomeView 消费后清零.
    @Binding var deepLinkCardId: String?

    /// 当前选中的 tab. deep link 到来时自动切到 .home.
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("首页", systemImage: "square.grid.2x2", value: .home) {
                HomeView(deepLinkCardId: $deepLinkCardId)
            }
            Tab("记忆", systemImage: "brain", value: .memory) {
                MemoryView()
            }
            Tab("Agent", systemImage: "bubble.left.and.bubble.right", value: .agent) {
                AgentView()
            }
            Tab("我", systemImage: "person.circle", value: .profile) {
                ProfileView()
            }
        }
        .tint(Theme.accent)
        // Deep link 到来时, 确保先切到首页 tab
        .onChange(of: deepLinkCardId) { _, newValue in
            if newValue != nil {
                selectedTab = .home
            }
        }
    }
}

/// TabView 的 selection 枚举. 用在 `Tab(..., value:)` 和 `TabView(selection:)`.
enum AppTab: Hashable {
    case home, memory, agent, profile
}

#Preview {
    RootView(deepLinkCardId: .constant(nil))
        .preferredColorScheme(.dark)
}
