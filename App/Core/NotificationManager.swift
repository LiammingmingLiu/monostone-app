import Foundation
import UserNotifications
import Observation

/// 本地通知管理器.
///
/// 职责:
/// 1. 请求通知权限
/// 2. 调度延迟本地通知 (模拟 Agent 异步完成)
/// 3. 处理通知点击 → 提取 cardId → 传给 deep link 路由
///
/// 遵循项目 store 模式: `@Observable @MainActor`.
/// 注入方式: `MonostoneApp.swift` 里 `.environment(notificationManager)`.
@Observable
@MainActor
final class NotificationManager {
    private(set) var isAuthorized = false
    private let center = UNUserNotificationCenter.current()
    private let delegate: NotificationDelegate

    /// 通知点击后要跳转的 cardId. MonostoneApp 监听这个值写到 deepLinkCardId.
    var pendingDeepLinkCardId: String?

    init() {
        delegate = NotificationDelegate()
        center.delegate = delegate
        // delegate 回调 → 写到 self.pendingDeepLinkCardId
        delegate.onNotificationTap = { [weak self] cardId in
            Task { @MainActor [weak self] in
                self?.pendingDeepLinkCardId = cardId
            }
        }
    }

    // MARK: - Permission

    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Schedule

    /// 调度一条延迟本地通知, 模拟 "Agent 处理完成" 的推送.
    ///
    /// - Parameters:
    ///   - cardId: 通知携带的卡片 ID, 点击后通过 deep link 跳转
    ///   - title: 通知标题, e.g. "长录音 · 处理完成"
    ///   - body: 通知正文, e.g. "与设计团队的周会"
    ///   - delay: 延迟秒数 (UNTimeIntervalNotificationTrigger)
    func scheduleCardCompleted(
        cardId: String,
        title: String,
        body: String,
        delay: TimeInterval
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["cardId": cardId]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(delay, 1),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "card-\(cardId)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}

// MARK: - Notification Delegate

/// UNUserNotificationCenterDelegate 的实现.
///
/// 这个 class 不能是 @MainActor (delegate 方法在任意线程回调),
/// 所以用 `@Sendable` 闭包桥接回 NotificationManager.
private final class NotificationDelegate: NSObject,
    UNUserNotificationCenterDelegate, @unchecked Sendable
{
    /// 通知被点击时调用, 传入 cardId
    var onNotificationTap: (@Sendable (String) -> Void)?

    /// App 在前台时, 通知仍然以 banner 展示 (不被静默吞掉)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// 用户点击通知 → 提取 cardId → 通过闭包传给 NotificationManager
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let cardId = userInfo["cardId"] as? String {
            onNotificationTap?(cardId)
        }
    }
}
