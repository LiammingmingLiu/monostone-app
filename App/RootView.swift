import SwiftUI

/// 应用根视图：4 个 tab 的 TabView，对应 monostone-ios-prototype 里的 4 个 root screens
/// - Home  (s2 · 首页 feed)
/// - Memory (s8 · 记忆)
/// - Agent  (s9 · Agent 聊天)
/// - Profile (s10 · 我)
struct RootView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home, memory, agent, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "square.grid.2x2") }
                .tag(Tab.home)

            MemoryView()
                .tabItem { Label("记忆", systemImage: "brain") }
                .tag(Tab.memory)

            AgentView()
                .tabItem { Label("Agent", systemImage: "bubble.left.and.bubble.right") }
                .tag(Tab.agent)

            ProfileView()
                .tabItem { Label("我", systemImage: "person.circle") }
                .tag(Tab.profile)
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
