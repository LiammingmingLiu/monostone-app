import Foundation

// MARK: - ProfileSnapshot

/// Profile Tab 一次加载就拿到的全部 settings state.
/// 后端对应 `GET /v1/me` + `/v1/integrations/*` + `/v1/settings/*` 的组合.
struct ProfileSnapshot: Hashable {
    var user: UserProfile
    var ring: RingConnectionStatus
    var deliveryTargets: [DeliveryTargetConnection]
    var apiKeys: [APIKeyConfig]
    var availableModels: [ModelChoice]
    var defaultModelId: String
    var calendarConnections: [CalendarConnection]
    var reminderPolicy: ReminderPolicy
    var audioStorage: AudioStorageMode
    var retentionPeriod: RetentionPeriod
    var permissions: [PermissionStatusEntry]
    /// 对应 prototype s15 第一 section "完整导出" 的两张大卡片
    var fullExportCards: [FullExportCard]
    /// 对应 prototype s15 第二 section "按类型导出" 的三行 list
    var typedExportRows: [TypedExportRow]
    var classificationPolicy: ClassificationPolicy
    var hardwareSettings: HardwareSettingsConfig
    var devSettings: DevSettingsConfig
}

// MARK: - ProfileRepository

protocol ProfileRepository: Sendable {
    func loadSnapshot() async throws -> ProfileSnapshot
}

// MARK: - InMemoryProfileRepository

/// Swift 字面量作为 mock. 大部分 Profile 类型都是 `Hashable` 简单 struct,
/// 将来 JSON 化比较容易, 但因为 Profile 子页很多, Step 9 先用 InMemory.
struct InMemoryProfileRepository: ProfileRepository {
    func loadSnapshot() async throws -> ProfileSnapshot {
        ProfileSnapshot(
            user: UserProfile(
                id: "u-mingming",
                name: "明明",
                avatarChar: "明",
                subscription: .max,
                dayCount: 12
            ),
            ring: RingConnectionStatus(
                connected: true,
                batteryPct: 87,
                firmwareVersion: "1.2.4"
            ),
            deliveryTargets: [
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
            ],
            apiKeys: [
                .init(provider: .anthropic, maskedKey: "sk-ant-****fh7Q",
                      monthlyTokenCount: 2_400_000),
                .init(provider: .openai, maskedKey: "sk-****Kp2n",
                      monthlyTokenCount: 860_000)
            ],
            availableModels: [
                .init(model: "claude-opus-4-6",   useCase: "长录音结构化 · 指令执行默认"),
                .init(model: "claude-sonnet-4-6", useCase: "短指令 · 延迟优先"),
                .init(model: "gpt-4o",            useCase: "备选 · 可 fallback"),
                .init(model: "claude-haiku-4-5",  useCase: "实时转写 · 最低成本")
            ],
            defaultModelId: "claude-opus-4-6",
            calendarConnections: [
                .init(platform: .appleCalendar, connected: true,
                      metadataLine: "主日历 · 通过 EventKit"),
                .init(platform: .googleCalendar, connected: false,
                      metadataLine: "需要授权"),
                .init(platform: .outlook, connected: false,
                      metadataLine: "需要授权")
            ],
            reminderPolicy: ReminderPolicy(
                autoRemind: true,
                meetingAdvanceMin: 10,
                taskAdvanceMin: 60,
                commuteCorrection: true
            ),
            audioStorage: .deviceOnly,
            retentionPeriod: .days90,
            permissions: [
                .init(permission: .microphone, status: .authorized,
                      usage: "手动录音 + 短捕捉按钮"),
                .init(permission: .bluetooth, status: .authorized,
                      usage: "连接 Monostone 戒指"),
                .init(permission: .location, status: .notDetermined,
                      usage: "捕捉上下文的地点 tag (可选)"),
                .init(permission: .calendar, status: .authorized,
                      usage: "读取日程 + 写入提醒")
            ],
            fullExportCards: [
                .init(
                    title: "Markdown 归档",
                    description: "所有长录音、指令、灵感、待办以 Markdown 文件形式导出, 按日期分文件夹. 可以直接导入 Obsidian / Logseq.",
                    format: .markdownZip
                ),
                .init(
                    title: "JSON 原始数据",
                    description: "完整的 card + memory + chat 结构化数据, 包含原始 transcript 和 metadata. 适合自建后端或迁移.",
                    format: .json
                )
            ],
            typedExportRows: [
                .init(scope: .longRecOnly, approxSizeMB: 1_228, includeAudio: true),
                .init(scope: .cmdOnly,     approxSizeMB: 8,     includeAudio: false),
                .init(scope: .ideaOnly,    approxSizeMB: 320,   includeAudio: true)
            ],
            classificationPolicy: ClassificationPolicy(
                autoClassify: true,
                confirmLowConfidence: true,
                confidenceThresholdPct: 70
            ),
            hardwareSettings: HardwareSettingsConfig(
                hapticFeedback: true,
                holdConfirmDurationMs: 300
            ),
            devSettings: DevSettingsConfig(
                debugLogging: false,
                mockRing: false,
                localCacheSizeMB: 480
            )
        )
    }
}
