import SwiftUI

@main
struct MonostoneApp: App {
    /// 全局单例. Step 10 默认用 `MockRingConnection` (模拟器 + demo 用),
    /// 切换到真实硬件时换成:
    /// ```swift
    /// @State private var ringCoordinator = RingCoordinator(
    ///     connection: BluetoothRingConnection()
    /// )
    /// ```
    @State private var ringCoordinator = RingCoordinator()
    @State private var notificationManager = NotificationManager()

    /// Deep link 目标卡片 ID. 通知 / Widget 点击写入, RootView → HomeView 读取后导航.
    @State private var deepLinkCardId: String?

    var body: some Scene {
        WindowGroup {
            RootView(deepLinkCardId: $deepLinkCardId)
                .preferredColorScheme(.dark)
                .environment(ringCoordinator)
                .environment(notificationManager)
                .task {
                    // 冷启动立即开始扫描 / 模拟连接
                    await ringCoordinator.connect()
                }
                .onOpenURL { url in
                    // 处理 monostone://card/{cardId} 和 monostone://home
                    handleDeepLink(url)
                }
                // 通知点击 → NotificationManager.pendingDeepLinkCardId → deepLinkCardId
                .onChange(of: notificationManager.pendingDeepLinkCardId) { _, newCardId in
                    if let newCardId {
                        deepLinkCardId = newCardId
                        notificationManager.pendingDeepLinkCardId = nil
                    }
                }
        }
    }

    // MARK: - Deep link parsing

    /// URL 格式:
    /// - `monostone://card/{cardId}` → 跳转到特定卡片详情
    /// - `monostone://home` → 只切到首页 tab (不推详情)
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "monostone" else { return }
        switch url.host {
        case "card":
            // path = "/{cardId}", pathComponents = ["/", "cardId"]
            let components = url.pathComponents
            if components.count >= 2 {
                deepLinkCardId = components[1]
            }
        case "home":
            deepLinkCardId = nil  // 只切 tab, 不推详情 (RootView 会处理)
        default:
            break
        }
    }
}
