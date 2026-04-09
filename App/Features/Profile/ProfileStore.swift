import Foundation
import Observation

/// 个人中心的 @Observable store.
///
/// 集中放所有 settings 子页需要的 mock state, 方便后续接入 `GET /v1/me` +
/// `PATCH /v1/*` 接口时集中改一处. 每个子页都通过 `@Bindable` 读写.
@Observable
@MainActor
final class ProfileStore {
    // MARK: - Top-level

    private(set) var user: UserProfile
    private(set) var ring: RingConnectionStatus
    private(set) var lastLoadError: Error?

    // MARK: - Delivery targets (s11)

    var deliveryTargets: [DeliveryTargetConnection]

    // MARK: - API Keys (s12)

    var apiKeys: [APIKeyConfig]
    var availableModels: [ModelChoice]
    var defaultModelId: String

    // MARK: - Calendar (s13)

    var calendarConnections: [CalendarConnection]
    var reminderPolicy: ReminderPolicy

    // MARK: - Privacy (s14)

    var audioStorage: AudioStorageMode
    var retentionPeriod: RetentionPeriod
    var permissions: [PermissionStatusEntry]

    // MARK: - Export (s15)

    var exportOptions: [ExportOption]

    // MARK: - Advanced (s16)

    var classificationPolicy: ClassificationPolicy
    var hardwareSettings: HardwareSettingsConfig
    var devSettings: DevSettingsConfig

    // MARK: - Dependencies

    private let repository: any ProfileRepository

    // MARK: - Init

    init(repository: any ProfileRepository = InMemoryProfileRepository()) {
        self.repository = repository
        self.user = UserProfile(
            id: "u-mingming",
            name: "明明",
            avatarChar: "明",
            subscription: .max,
            dayCount: 12
        )
        self.ring = RingConnectionStatus(
            connected: true,
            batteryPct: 87,
            firmwareVersion: "1.2.4"
        )
        self.deliveryTargets = [
            .init(id: "dt-1", platform: .appleCalendar, status: .connected,
                  metadataLine: "mingming@icloud.com"),
            .init(id: "dt-2", platform: .linear, status: .connected,
                  metadataLine: "team: Monostone · project: Hardware"),
            .init(id: "dt-3", platform: .notion, status: .connected,
                  metadataLine: "Workspace: Monostone HQ"),
            .init(id: "dt-4", platform: .gmail, status: .notConnected,
                  metadataLine: "连接后可直接发送邮件"),
            .init(id: "dt-5", platform: .obsidian, status: .notConnected,
                  metadataLine: "写入本地 vault + iCloud 同步"),
            .init(id: "dt-6", platform: .googleCalendar, status: .notConnected,
                  metadataLine: "与 Apple Calendar 二选一")
        ]
        self.apiKeys = [
            .init(provider: .anthropic,
                  maskedKey: "sk-ant-****fh7Q",
                  monthlyTokenCount: 2_400_000),
            .init(provider: .openai,
                  maskedKey: "sk-****Kp2n",
                  monthlyTokenCount: 860_000)
        ]
        self.availableModels = [
            .init(model: "claude-opus-4-6",   useCase: "长录音结构化 · 指令执行默认"),
            .init(model: "claude-sonnet-4-6", useCase: "短指令 · 延迟优先"),
            .init(model: "gpt-4o",            useCase: "备选 · 可 fallback"),
            .init(model: "claude-haiku-4-5",  useCase: "实时转写 · 最低成本")
        ]
        self.defaultModelId = "claude-opus-4-6"
        self.calendarConnections = [
            .init(platform: .appleCalendar, connected: true,
                  metadataLine: "主日历 · 通过 EventKit"),
            .init(platform: .googleCalendar, connected: false,
                  metadataLine: "需要授权"),
            .init(platform: .outlook, connected: false,
                  metadataLine: "需要授权")
        ]
        self.reminderPolicy = ReminderPolicy(
            autoRemind: true,
            meetingAdvanceMin: 10,
            taskAdvanceMin: 60,
            commuteCorrection: true
        )
        self.audioStorage = .deviceOnly
        self.retentionPeriod = .days90
        self.permissions = [
            .init(permission: .microphone, status: .authorized,
                  usage: "手动录音 + 短捕捉按钮"),
            .init(permission: .bluetooth,  status: .authorized,
                  usage: "连接 Monostone 戒指"),
            .init(permission: .location,   status: .notDetermined,
                  usage: "捕捉上下文的地点 tag（可选）"),
            .init(permission: .calendar,   status: .authorized,
                  usage: "读取日程 + 写入提醒")
        ]
        self.exportOptions = [
            .init(scope: .full,        format: .markdown, approxSizeMB: 1_228, includeAudio: true),
            .init(scope: .full,        format: .json,     approxSizeMB: 480,   includeAudio: false),
            .init(scope: .longRecOnly, format: .markdown, approxSizeMB: 820,   includeAudio: true),
            .init(scope: .cmdOnly,     format: .markdown, approxSizeMB: 48,    includeAudio: false),
            .init(scope: .ideaOnly,    format: .markdown, approxSizeMB: 12,    includeAudio: false)
        ]
        self.classificationPolicy = ClassificationPolicy(
            autoClassify: true,
            confirmLowConfidence: true,
            confidenceThresholdPct: 70
        )
        self.hardwareSettings = HardwareSettingsConfig(
            hapticFeedback: true,
            holdConfirmDurationMs: 300
        )
        self.devSettings = DevSettingsConfig(
            debugLogging: false,
            mockRing: false,
            localCacheSizeMB: 480
        )
    }

    // MARK: - Async loading

    /// 从 repository 拉取全部 profile + settings 数据, 覆盖当前 state.
    func refresh() async {
        do {
            let snap = try await repository.loadSnapshot()
            self.user = snap.user
            self.ring = snap.ring
            self.deliveryTargets = snap.deliveryTargets
            self.apiKeys = snap.apiKeys
            self.availableModels = snap.availableModels
            self.defaultModelId = snap.defaultModelId
            self.calendarConnections = snap.calendarConnections
            self.reminderPolicy = snap.reminderPolicy
            self.audioStorage = snap.audioStorage
            self.retentionPeriod = snap.retentionPeriod
            self.permissions = snap.permissions
            self.exportOptions = snap.exportOptions
            self.classificationPolicy = snap.classificationPolicy
            self.hardwareSettings = snap.hardwareSettings
            self.devSettings = snap.devSettings
            self.lastLoadError = nil
        } catch {
            self.lastLoadError = error
        }
    }
}
