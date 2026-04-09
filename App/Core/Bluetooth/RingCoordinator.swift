import Foundation
import Observation

/// 戒指连接的 `@Observable` 门面.
///
/// 职责:
/// - 持有一个 `RingConnection` (真实 BLE 或 mock)
/// - 从 connection 的 `AsyncStream<RingEvent>` + `AsyncStream<RingConnectionState>`
///   消费事件, 把它们映射到 observable 属性 (`connectionState` / `battery` /
///   `lastEvent`), 供 SwiftUI view 直接绑定
/// - 提供主动 API (`connect`, `disconnect`, `requestBattery`) 给 UI 调用
///
/// 生命周期: 在 `MonostoneApp` 里创建一个实例, 用 `.environment(ringCoordinator)`
/// 注入到整个 view 树. 所有 tab (HomeView / ProfileView 等) 通过 `@Environment` 读.
@Observable
@MainActor
final class RingCoordinator {
    // MARK: - Public observable state

    private(set) var connectionState: RingConnectionState = .idle
    private(set) var deviceInfo: RingDeviceInfo?
    private(set) var lastEvent: RingEvent?
    private(set) var connectedSince: Date?

    /// 便捷派生属性, 给 view 直接用 (`store.isConnected`).
    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    /// 当前电量, 没连时为 nil
    var batteryPct: Int? {
        deviceInfo?.batteryPct
    }

    /// 距离连接已经过去多少天 (demo 用的 "第 N 天" 指示)
    var dayCount: Int {
        guard let connectedSince else { return 0 }
        let seconds = Date().timeIntervalSince(connectedSince)
        return max(1, Int(seconds / 86400) + 1)
    }

    // MARK: - Dependencies

    private let connection: any RingConnection
    private var eventTask: Task<Void, Never>?
    private var stateTask: Task<Void, Never>?

    // MARK: - Init

    init(connection: any RingConnection = MockRingConnection()) {
        self.connection = connection
        // 启动时假装已经连了 12 天, 让 demo 显示 "第 12 天"
        // 真实实现里 connectedSince 应该从第一次连上戒指的时间戳持久化读取
        self.connectedSince = Calendar.current.date(byAdding: .day, value: -11, to: Date())
        startConsuming()
    }

    // 注: 不实现 `deinit` 显式 cancel. Swift 6 严格并发下 deinit 不能访问
    // @MainActor 属性. Tasks 都用了 `[weak self]`, self 销毁后 `guard let self`
    // 短路, for-await 循环自动退出, 不会泄漏.

    // MARK: - Public API

    /// 开始扫描 + 自动连接戒指.
    func connect() async {
        await connection.start()
    }

    /// 主动断开.
    func disconnect() async {
        await connection.stop()
    }

    /// 发一条指令给戒指 (静默失败, 错误记录到 lastError).
    @discardableResult
    func send(_ command: RingCommand) async -> Bool {
        do {
            try await connection.send(command)
            return true
        } catch {
            print("[RingCoordinator] send \(command) failed: \(error)")
            return false
        }
    }

    // MARK: - Stream consumers

    private func startConsuming() {
        eventTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await event in self.connection.events {
                self.handle(event: event)
            }
        }
        stateTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await state in self.connection.stateUpdates {
                self.handle(state: state)
            }
        }
    }

    private func handle(event: RingEvent) {
        self.lastEvent = event
        // 把 event 里包含的电量信息同步到 deviceInfo
        switch event {
        case .batteryLow(let pct), .batteryCritical(let pct):
            if var info = deviceInfo {
                info = RingDeviceInfo(
                    serialNumber: info.serialNumber,
                    firmwareVersion: info.firmwareVersion,
                    batteryPct: pct
                )
                self.deviceInfo = info
            }
        case .recordingStarted(let payload):
            // 让 deviceInfo 里的电量也跟着 ring_battery 字段同步
            if var info = deviceInfo {
                info = RingDeviceInfo(
                    serialNumber: info.serialNumber,
                    firmwareVersion: info.firmwareVersion,
                    batteryPct: payload.ringBattery
                )
                self.deviceInfo = info
            }
        default:
            break
        }
    }

    private func handle(state: RingConnectionState) {
        self.connectionState = state
        if case .connected(let info) = state {
            self.deviceInfo = info
        }
    }
}
