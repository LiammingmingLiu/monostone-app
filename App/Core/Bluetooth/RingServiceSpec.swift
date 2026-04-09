@preconcurrency import CoreBluetooth

/// Monostone 戒指的 GATT 服务/特征 UUID 常量.
///
/// 对应 prototype `docs/events-protocol.md §1.1 GATT 服务结构`.
/// **UUID 为 placeholder**, 实际 firmware 里的值会在硬件固化时替换.
///
/// 所有常量集中在这里, 避免在 BluetoothRingConnection 里散落 UUID 字符串.
enum RingServiceSpec {
    /// Primary service
    static let primaryService = CBUUID(string: "A001")

    // MARK: - Characteristics

    /// `[R]` 设备信息 — 固件版本 / 电量 / 序列号
    static let deviceInfo = CBUUID(string: "A002")

    /// `[W]` 控制指令 — 开始/停止录音、固件升级 (JSON body, write_without_response)
    static let controlCommand = CBUUID(string: "A003")

    /// `[N]` 戒指事件推送 — 手势识别 / 电量 / 充电状态 (JSON RingEvent)
    static let ringEvent = CBUUID(string: "A004")

    /// `[N]` 音频 Opus 流 — 2-byte header + opus frame
    static let audioStream = CBUUID(string: "A005")

    /// `[N]` 传感器数据 — accelerometer / battery tick
    static let sensorData = CBUUID(string: "A006")

    /// 全部 notify characteristic 的合集, 用于一次性 discover + subscribe.
    static let notifyCharacteristics: [CBUUID] = [
        ringEvent, audioStream, sensorData
    ]

    /// 所有 characteristic 的合集, 用于 discoverCharacteristics 调用.
    static let allCharacteristics: [CBUUID] = [
        deviceInfo, controlCommand, ringEvent, audioStream, sensorData
    ]

    /// 扫描时用来过滤广播包 (advertising data) 里的设备名前缀.
    static let advertisingNamePrefix = "Monostone"
}
