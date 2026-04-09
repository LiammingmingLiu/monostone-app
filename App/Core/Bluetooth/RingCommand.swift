import Foundation

// MARK: - RingCommand

/// 手机下发给戒指的指令.
///
/// 对应 prototype `docs/events-protocol.md §1.4`. 通过 GATT Write
/// characteristic `0000A003-...` 以 `write_without_response` 方式发送.
///
/// 同样用 **discriminator Codable**, JSON shape:
/// ```json
/// { "cmd": "stop_recording", "session_id": "..." }
/// { "cmd": "set_haptic", "enabled": true }
/// ```
enum RingCommand: Hashable, Sendable {
    case startRecording(mode: RecordingStartedPayload.RecordingMode)
    case stopRecording(sessionId: String)
    case setHaptic(enabled: Bool)
    case requestBattery
    case otaBegin(firmwareVersion: String, chunks: Int)
}

// MARK: - Codable

extension RingCommand: Codable {
    private enum CodingKeys: String, CodingKey {
        case cmd
        case mode
        case sessionId
        case enabled
        case firmwareVersion
        case chunks
    }

    private enum CommandTag: String, Codable {
        case startRecording = "start_recording"
        case stopRecording  = "stop_recording"
        case setHaptic      = "set_haptic"
        case requestBattery = "request_battery"
        case otaBegin       = "ota_begin"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(CommandTag.self, forKey: .cmd)
        switch tag {
        case .startRecording:
            let mode = try container.decode(
                RecordingStartedPayload.RecordingMode.self, forKey: .mode
            )
            self = .startRecording(mode: mode)
        case .stopRecording:
            let sid = try container.decode(String.self, forKey: .sessionId)
            self = .stopRecording(sessionId: sid)
        case .setHaptic:
            let enabled = try container.decode(Bool.self, forKey: .enabled)
            self = .setHaptic(enabled: enabled)
        case .requestBattery:
            self = .requestBattery
        case .otaBegin:
            let fw = try container.decode(String.self, forKey: .firmwareVersion)
            let chunks = try container.decode(Int.self, forKey: .chunks)
            self = .otaBegin(firmwareVersion: fw, chunks: chunks)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .startRecording(let mode):
            try container.encode(CommandTag.startRecording, forKey: .cmd)
            try container.encode(mode, forKey: .mode)
        case .stopRecording(let sid):
            try container.encode(CommandTag.stopRecording, forKey: .cmd)
            try container.encode(sid, forKey: .sessionId)
        case .setHaptic(let enabled):
            try container.encode(CommandTag.setHaptic, forKey: .cmd)
            try container.encode(enabled, forKey: .enabled)
        case .requestBattery:
            try container.encode(CommandTag.requestBattery, forKey: .cmd)
        case .otaBegin(let fw, let chunks):
            try container.encode(CommandTag.otaBegin, forKey: .cmd)
            try container.encode(fw, forKey: .firmwareVersion)
            try container.encode(chunks, forKey: .chunks)
        }
    }
}

// MARK: - JSON encoding helper

extension RingCommand {
    /// Encode 成 UTF-8 JSON Data, 方便直接写进 BLE characteristic.
    /// 使用 snake_case 以对齐 events-protocol.md 的约定.
    func encodeJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(self)
    }
}
