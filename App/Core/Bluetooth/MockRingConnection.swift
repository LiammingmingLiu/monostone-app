import Foundation

/// Mock 戒指连接, 不依赖 CoreBluetooth 或真实硬件.
///
/// 适用场景:
/// - 模拟器 demo 演示
/// - 单元测试 RingCoordinator / view 层对 ring state 的响应
/// - 硬件还没到手时团队先做 UI 开发
///
/// 行为:
/// - `start()` 500ms 后状态切到 `.connected`, 电量 87%
/// - 之后每 60 秒模拟电量 -1% 衰减 (加速 demo 可以调参数)
/// - `send(.requestBattery)` 立即 echo 一个 battery 事件
/// - `send(.setHaptic)` / `.stopRecording` 不做实际动作, 静默 ack
///
/// **Actor 隔离**: 整个 class 标 `@MainActor`, 所有 mutable state 都在 main actor
/// 上保护. 之前用 `@unchecked Sendable` 跨 actor 访问 `isConnected` / `batteryPct`
/// 会导致 Swift 6 严格并发下 data race → `EXC_BAD_ACCESS`. `@MainActor` 提供
/// 自动串行化, 消除这类 crash.
///
/// `RingConnection` 协议要求 `Sendable`, `@MainActor` 类型隐式满足 Sendable.
@MainActor
final class MockRingConnection: RingConnection {
    // MARK: - AsyncStream plumbing

    nonisolated let events: AsyncStream<RingEvent>
    nonisolated let stateUpdates: AsyncStream<RingConnectionState>

    private let eventContinuation: AsyncStream<RingEvent>.Continuation
    private let stateContinuation: AsyncStream<RingConnectionState>.Continuation

    // MARK: - Mock state (all mutations on @MainActor)

    private var isConnected = false
    private var batteryPct = 87
    private var batteryDrainTask: Task<Void, Never>?

    /// Demo 模式下电量衰减间隔. 生产场景应该是 60 秒, demo 里调成 10 秒更有感觉.
    private let batteryDrainIntervalSec: Int

    // MARK: - Init

    init(batteryDrainIntervalSec: Int = 60) {
        self.batteryDrainIntervalSec = batteryDrainIntervalSec

        var eventCont: AsyncStream<RingEvent>.Continuation!
        self.events = AsyncStream { eventCont = $0 }
        self.eventContinuation = eventCont

        var stateCont: AsyncStream<RingConnectionState>.Continuation!
        self.stateUpdates = AsyncStream { stateCont = $0 }
        self.stateContinuation = stateCont
    }

    // 注: 不实现 `deinit` 显式 finish. Swift 6 严格并发下 deinit 不能访问
    // @MainActor 属性. AsyncStream continuation 在 Stream 被 dealloc 时会
    // 自动 finish, 不会泄漏.

    // MARK: - RingConnection

    func start() async {
        stateContinuation.yield(.scanning)
        try? await Task.sleep(for: .milliseconds(300))
        stateContinuation.yield(.connecting)
        try? await Task.sleep(for: .milliseconds(500))

        isConnected = true
        let info = RingDeviceInfo(
            serialNumber: "MOCK-0001-2026",
            firmwareVersion: "0.3.2",
            batteryPct: batteryPct
        )
        stateContinuation.yield(.connected(info: info))
        startBatteryDrain()
    }

    func stop() async {
        batteryDrainTask?.cancel()
        batteryDrainTask = nil
        isConnected = false
        stateContinuation.yield(.idle)
    }

    func send(_ command: RingCommand) async throws {
        guard isConnected else {
            throw RingConnectionError.notConnected
        }
        switch command {
        case .requestBattery:
            // 回送一个 event, 让上层能看到电量被更新
            let event: RingEvent = batteryPct <= 5
                ? .batteryCritical(pct: batteryPct)
                : batteryPct <= 15
                    ? .batteryLow(pct: batteryPct)
                    : .hapticAck  // 高电量时用 hapticAck 作为 ack 占位
            eventContinuation.yield(event)
        case .startRecording(let mode):
            // 模拟戒指收到指令后立即回传 recording_started 事件
            let payload = RecordingStartedPayload(
                sessionId: UUID().uuidString,
                mode: mode,
                trigger: .doubleTap,
                startedAt: Int(Date().timeIntervalSince1970 * 1000),
                ringBattery: batteryPct
            )
            eventContinuation.yield(.recordingStarted(payload))
        case .stopRecording(let sessionId):
            let payload = RecordingStoppedPayload(
                sessionId: sessionId,
                stoppedAt: Int(Date().timeIntervalSince1970 * 1000),
                stopReason: .forced
            )
            eventContinuation.yield(.recordingStopped(payload))
        case .setHaptic:
            eventContinuation.yield(.hapticAck)
        case .otaBegin:
            // Mock 不模拟 OTA
            break
        }
    }

    // MARK: - Battery drain simulation

    private func startBatteryDrain() {
        batteryDrainTask?.cancel()
        // Task { @MainActor ... } 和外层 @MainActor 一致, self 访问无需 hop,
        // 保持所有 mutable state 访问都在 main actor 上.
        batteryDrainTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let interval = self.batteryDrainIntervalSec
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, self.isConnected else { return }
                self.batteryPct = max(0, self.batteryPct - 1)
                if self.batteryPct <= 5 {
                    self.eventContinuation.yield(.batteryCritical(pct: self.batteryPct))
                } else if self.batteryPct <= 15 {
                    self.eventContinuation.yield(.batteryLow(pct: self.batteryPct))
                }
                // Push refreshed info through state channel too
                let info = RingDeviceInfo(
                    serialNumber: "MOCK-0001-2026",
                    firmwareVersion: "0.3.2",
                    batteryPct: self.batteryPct
                )
                self.stateContinuation.yield(.connected(info: info))
            }
        }
    }
}
