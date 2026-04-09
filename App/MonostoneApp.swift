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

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environment(ringCoordinator)
                .task {
                    // 冷启动立即开始扫描 / 模拟连接
                    await ringCoordinator.connect()
                }
        }
    }
}
