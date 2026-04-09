import Foundation

// MARK: - RingEvent

/// 戒指推送给手机的事件.
///
/// 对应 prototype `docs/events-protocol.md §1.2`. 戒指通过 GATT Notify
/// characteristic `0000A004-...` 发送 JSON payload, 手机侧 decode 成这个枚举.
///
/// 使用 **关联值枚举 + discriminator Codable**:
/// ```json
/// { "event": "recording_started", "session_id": "...", "mode": "long", ... }
/// ```
enum RingEvent: Hashable, Sendable {
    case recordingStarted(RecordingStartedPayload)
    case recordingStopped(RecordingStoppedPayload)
    case pressCancelled
    case hapticAck
    case batteryLow(pct: Int)
    case batteryCritical(pct: Int)
    case chargingStarted
    case chargingCompleted
    case disconnectWarning(rssi: Int)
}

// MARK: - Payloads

/// `recording_started` 事件的详细 payload.
struct RecordingStartedPayload: Codable, Hashable, Sendable {
    let sessionId: String
    let mode: RecordingMode
    let trigger: Trigger
    let startedAt: Int          // unix ms
    let ringBattery: Int

    enum RecordingMode: String, Codable, Hashable, Sendable {
        case long, short
    }
    enum Trigger: String, Codable, Hashable, Sendable {
        case doubleTap = "double_tap"
        case pressHold = "press_hold"
    }
}

/// `recording_stopped` 事件的详细 payload.
struct RecordingStoppedPayload: Codable, Hashable, Sendable {
    let sessionId: String
    let stoppedAt: Int
    let stopReason: StopReason

    enum StopReason: String, Codable, Hashable, Sendable {
        case userDoubleTap    = "user_double_tap"
        case userRelease      = "user_release"
        case timeout          = "timeout"
        case forced           = "forced"
    }
}

// MARK: - Codable (discriminator "event" field)

extension RingEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case event
        // Payload 字段直接同级展开 (和 prototype spec 一致)
        case sessionId, mode, trigger, startedAt, ringBattery
        case stoppedAt, stopReason
        case battery
        case rssi
    }

    private enum EventTag: String, Codable {
        case recordingStarted  = "recording_started"
        case recordingStopped  = "recording_stopped"
        case pressCancelled    = "press_cancelled"
        case hapticAck         = "haptic_ack"
        case batteryLow        = "battery_low"
        case batteryCritical   = "battery_critical"
        case chargingStarted   = "charging_started"
        case chargingCompleted = "charging_completed"
        case disconnectWarning = "disconnect_warning"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(EventTag.self, forKey: .event)

        switch tag {
        case .recordingStarted:
            self = .recordingStarted(try RecordingStartedPayload(from: decoder))
        case .recordingStopped:
            self = .recordingStopped(try RecordingStoppedPayload(from: decoder))
        case .pressCancelled:
            self = .pressCancelled
        case .hapticAck:
            self = .hapticAck
        case .batteryLow:
            let pct = try container.decode(Int.self, forKey: .battery)
            self = .batteryLow(pct: pct)
        case .batteryCritical:
            let pct = try container.decode(Int.self, forKey: .battery)
            self = .batteryCritical(pct: pct)
        case .chargingStarted:
            self = .chargingStarted
        case .chargingCompleted:
            self = .chargingCompleted
        case .disconnectWarning:
            let rssi = try container.decode(Int.self, forKey: .rssi)
            self = .disconnectWarning(rssi: rssi)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .recordingStarted(let payload):
            try container.encode(EventTag.recordingStarted, forKey: .event)
            try payload.encode(to: encoder)
        case .recordingStopped(let payload):
            try container.encode(EventTag.recordingStopped, forKey: .event)
            try payload.encode(to: encoder)
        case .pressCancelled:
            try container.encode(EventTag.pressCancelled, forKey: .event)
        case .hapticAck:
            try container.encode(EventTag.hapticAck, forKey: .event)
        case .batteryLow(let pct):
            try container.encode(EventTag.batteryLow, forKey: .event)
            try container.encode(pct, forKey: .battery)
        case .batteryCritical(let pct):
            try container.encode(EventTag.batteryCritical, forKey: .event)
            try container.encode(pct, forKey: .battery)
        case .chargingStarted:
            try container.encode(EventTag.chargingStarted, forKey: .event)
        case .chargingCompleted:
            try container.encode(EventTag.chargingCompleted, forKey: .event)
        case .disconnectWarning(let rssi):
            try container.encode(EventTag.disconnectWarning, forKey: .event)
            try container.encode(rssi, forKey: .rssi)
        }
    }
}

// MARK: - Human-readable descriptions

extension RingEvent {
    /// 给 UI 显示用的一句话描述 (debug / toast).
    var displayLabel: String {
        switch self {
        case .recordingStarted(let p):
            "开始 \(p.mode == .long ? "长录音" : "短捕捉") (\(p.trigger == .doubleTap ? "双击" : "按住"))"
        case .recordingStopped(let p):
            "停止录音 · \(p.stopReason.rawValue)"
        case .pressCancelled:
            "按下取消 (< 300ms)"
        case .hapticAck:
            "振动反馈确认"
        case .batteryLow(let pct):
            "电量低 · \(pct)%"
        case .batteryCritical(let pct):
            "电量极低 · \(pct)%"
        case .chargingStarted:
            "开始充电"
        case .chargingCompleted:
            "充电完成"
        case .disconnectWarning(let rssi):
            "信号弱 · RSSI \(rssi)"
        }
    }
}
