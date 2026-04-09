import Foundation

// MARK: - UserProfile

/// 对应 prototype `data-models.md §1 User`.
struct UserProfile: Hashable {
    let id: String
    let name: String
    let avatarChar: String
    let subscription: Subscription
    let dayCount: Int

    enum Subscription: String, Hashable {
        case free
        case pro
        case max

        var label: String {
            switch self {
            case .free: "免费版"
            case .pro:  "Pro 订阅"
            case .max:  "Max 订阅"
            }
        }
    }
}

// MARK: - RingConnectionStatus

struct RingConnectionStatus: Hashable {
    let connected: Bool
    let batteryPct: Int
    let firmwareVersion: String
}

// MARK: - Delivery Targets (s11)

struct DeliveryTargetConnection: Identifiable, Hashable {
    let id: String
    let platform: Platform
    var status: ConnectionStatus
    let metadataLine: String

    enum Platform: String, Hashable {
        case appleCalendar, linear, notion, gmail, obsidian, googleCalendar

        var label: String {
            switch self {
            case .appleCalendar:  "Apple Calendar"
            case .linear:         "Linear"
            case .notion:         "Notion"
            case .gmail:          "Gmail"
            case .obsidian:       "Obsidian"
            case .googleCalendar: "Google Calendar"
            }
        }

        var systemImage: String {
            switch self {
            case .appleCalendar, .googleCalendar: "calendar"
            case .linear:     "rectangle.3.group"
            case .notion:     "doc.text"
            case .gmail:      "envelope"
            case .obsidian:   "square.stack.3d.up"
            }
        }
    }

    enum ConnectionStatus: Hashable {
        case connected
        case notConnected
    }
}

// MARK: - API Keys (s12)

struct APIKeyConfig: Identifiable, Hashable {
    var id: Provider { provider }
    let provider: Provider
    let maskedKey: String
    let monthlyTokenCount: Int

    enum Provider: String, Hashable {
        case anthropic, openai, gemini

        var label: String {
            switch self {
            case .anthropic: "Anthropic"
            case .openai:    "OpenAI"
            case .gemini:    "Google Gemini"
            }
        }
    }

    var monthlyUsageDisplay: String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        let tokens = formatter.string(from: NSNumber(value: monthlyTokenCount)) ?? "\(monthlyTokenCount)"
        return "\(tokens) tokens · 本月"
    }
}

struct ModelChoice: Identifiable, Hashable {
    var id: String { model }
    let model: String
    let useCase: String
}

// MARK: - Calendar & Reminders (s13)

struct CalendarConnection: Identifiable, Hashable {
    var id: Platform { platform }
    let platform: Platform
    var connected: Bool
    let metadataLine: String

    enum Platform: String, Hashable {
        case appleCalendar, googleCalendar, outlook

        var label: String {
            switch self {
            case .appleCalendar:  "Apple Calendar"
            case .googleCalendar: "Google Calendar"
            case .outlook:        "Outlook"
            }
        }

        var systemImage: String {
            switch self {
            case .appleCalendar:  "calendar"
            case .googleCalendar: "calendar.circle"
            case .outlook:        "envelope.open"
            }
        }
    }
}

/// 提醒策略（对应 prototype `data-models.md §15 ReminderPolicy`）
struct ReminderPolicy: Hashable {
    var autoRemind: Bool
    var meetingAdvanceMin: Int
    var taskAdvanceMin: Int
    var commuteCorrection: Bool
}

// MARK: - Privacy & Data (s14)

enum AudioStorageMode: String, Hashable, CaseIterable, Identifiable {
    case deviceOnly
    case cloudEncrypted

    var id: Self { self }

    var label: String {
        switch self {
        case .deviceOnly:     "仅本地存储"
        case .cloudEncrypted: "云端加密同步"
        }
    }

    var description: String {
        switch self {
        case .deviceOnly:     "录音和转写只留在设备上，离开设备即丢失"
        case .cloudEncrypted: "E2EE 加密上云，多设备可访问"
        }
    }
}

enum RetentionPeriod: Hashable, CaseIterable, Identifiable {
    case days30
    case days90
    case forever

    var id: Self { self }

    var label: String {
        switch self {
        case .days30:  "30 天"
        case .days90:  "90 天"
        case .forever: "永久保留"
        }
    }
}

struct PermissionStatusEntry: Identifiable, Hashable {
    var id: Permission { permission }
    let permission: Permission
    let status: Status
    let usage: String

    enum Permission: String, Hashable {
        case microphone, bluetooth, location, calendar

        var label: String {
            switch self {
            case .microphone: "麦克风"
            case .bluetooth:  "蓝牙"
            case .location:   "位置"
            case .calendar:   "日历"
            }
        }

        var systemImage: String {
            switch self {
            case .microphone: "mic"
            case .bluetooth:  "dot.radiowaves.left.and.right"
            case .location:   "location"
            case .calendar:   "calendar"
            }
        }
    }

    enum Status: Hashable {
        case authorized
        case denied
        case notDetermined

        var label: String {
            switch self {
            case .authorized:    "已授权"
            case .denied:        "已拒绝"
            case .notDetermined: "未询问"
            }
        }
    }
}

// MARK: - Export (s15)

struct ExportOption: Identifiable, Hashable {
    var id: Scope { scope }
    let scope: Scope
    let format: Format
    let approxSizeMB: Int
    let includeAudio: Bool

    enum Scope: String, Hashable {
        case full
        case longRecOnly
        case cmdOnly
        case ideaOnly

        var label: String {
            switch self {
            case .full:        "完整数据"
            case .longRecOnly: "仅长录音"
            case .cmdOnly:     "仅指令产出"
            case .ideaOnly:    "仅灵感"
            }
        }
    }

    enum Format: String, Hashable {
        case markdown, json

        var label: String {
            switch self {
            case .markdown: "Markdown"
            case .json:     "JSON"
            }
        }
    }

    var sizeDisplay: String {
        if approxSizeMB >= 1024 {
            return String(format: "约 %.1f GB", Double(approxSizeMB) / 1024)
        } else {
            return "约 \(approxSizeMB) MB"
        }
    }
}

// MARK: - Advanced (s16)

struct ClassificationPolicy: Hashable {
    var autoClassify: Bool
    var confirmLowConfidence: Bool
    var confidenceThresholdPct: Int
}

struct HardwareSettingsConfig: Hashable {
    var hapticFeedback: Bool
    var holdConfirmDurationMs: Int
}

struct DevSettingsConfig: Hashable {
    var debugLogging: Bool
    var mockRing: Bool
    var localCacheSizeMB: Int
}
