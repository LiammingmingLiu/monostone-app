import Foundation

// MARK: - RingConnectionState

/// 戒指连接状态机.
enum RingConnectionState: Hashable, Sendable {
    case idle                                   // 尚未开始扫描
    case bluetoothOff                           // 系统蓝牙关闭
    case unauthorized                           // 用户拒绝 bluetooth 权限
    case scanning                               // 正在扫描广播包
    case connecting                             // 已发现 peripheral, 正在握手
    case connected(info: RingDeviceInfo)        // 已连接, 拿到了固件 / 电量
    case reconnecting                           // 中断后自动重连中
    case failed(reason: String)                 // 终态失败
}

// MARK: - RingDeviceInfo

/// 戒指的基本信息, 对应 `deviceInfo` characteristic 读出来的内容.
struct RingDeviceInfo: Hashable, Sendable, Codable {
    let serialNumber: String
    let firmwareVersion: String
    let batteryPct: Int
}

// MARK: - RingConnection protocol

/// 戒指连接的抽象层. 真实实现走 CoreBluetooth, mock 实现走 AsyncStream 模拟.
///
/// 把 CBCentralManagerDelegate 这种老式 callback API 包装成 Swift Concurrency
/// 原语 (`AsyncStream`), 让上层 RingCoordinator 可以直接 `for await event in events`,
/// 不需要和 delegate 模式打交道.
///
/// 为什么用 `AsyncStream` 而不是 `AsyncThrowingStream`:
/// - 连接失败 / 错误通过 `stateUpdates` 里的 `.failed(reason:)` 状态告知, 不抛异常
/// - 保证 `events` 不会因为单次 decode 错误而提前终止 stream
protocol RingConnection: Sendable {
    /// Ring → phone 事件流. 上层 for-await 消费.
    var events: AsyncStream<RingEvent> { get }

    /// 连接状态变化流.
    var stateUpdates: AsyncStream<RingConnectionState> { get }

    /// 开始扫描并自动连接第一个符合条件的戒指.
    func start() async

    /// 主动断开连接 (清理扫描 / 停止 notify).
    func stop() async

    /// Phone → ring 指令下发. 未连接时抛错.
    func send(_ command: RingCommand) async throws
}

// MARK: - RingConnectionError

enum RingConnectionError: Error, LocalizedError {
    case notConnected
    case bluetoothUnavailable
    case encodingFailed(Error)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            "戒指未连接, 无法发送指令"
        case .bluetoothUnavailable:
            "iOS 蓝牙不可用 (关闭 / 权限被拒)"
        case .encodingFailed(let err):
            "指令编码失败: \(err.localizedDescription)"
        case .writeFailed(let err):
            "GATT write 失败: \(err.localizedDescription)"
        }
    }
}
