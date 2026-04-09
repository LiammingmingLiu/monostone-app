import SwiftUI

/// s16 · 高级设置.
/// - 短录音分类策略 (自动分类 / 低置信度时询问)
/// - 硬件反馈 (触觉 / 按住确认时长)
/// - 开发者选项 (debug logging / mock ring / 本地缓存清理)
struct AdvancedSettingsView: View {
    @Bindable var store: ProfileStore
    @State private var cacheCleared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                classificationSection
                hardwareSection
                devSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("高级设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Classification

    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("短录音分类")
            MenuGroup {
                toggleRow(
                    title: "自动分类",
                    description: "让 Agent 判断短录音是指令 / 灵感 / 待办",
                    isOn: $store.classificationPolicy.autoClassify
                )
                Divider().background(Theme.border).padding(.leading, 16)
                toggleRow(
                    title: "低置信度时询问",
                    description: "置信度低于阈值时弹出确认",
                    isOn: $store.classificationPolicy.confirmLowConfidence
                )
                if store.classificationPolicy.confirmLowConfidence {
                    Divider().background(Theme.border).padding(.leading, 16)
                    thresholdRow
                }
            }
        }
    }

    private var thresholdRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("置信度阈值")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.text)
                Text("低于 \(store.classificationPolicy.confidenceThresholdPct)% 时询问")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Stepper(
                "",
                value: $store.classificationPolicy.confidenceThresholdPct,
                in: 50...95,
                step: 5
            )
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Hardware

    private var hardwareSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("硬件反馈")
            MenuGroup {
                toggleRow(
                    title: "触觉反馈",
                    description: "录音开始 / 结束 / 手势识别时震动戒指",
                    isOn: $store.hardwareSettings.hapticFeedback
                )
                Divider().background(Theme.border).padding(.leading, 16)
                hapticDurationRow
            }
        }
    }

    private var hapticDurationRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("按住确认时长")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.text)
                Text("\(store.hardwareSettings.holdConfirmDurationMs) 毫秒")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Stepper(
                "",
                value: $store.hardwareSettings.holdConfirmDurationMs,
                in: 100...1000,
                step: 50
            )
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Dev

    private var devSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("开发者")
            MenuGroup {
                toggleRow(
                    title: "Debug logging",
                    description: "BLE / API / WebSocket 详细日志",
                    isOn: $store.devSettings.debugLogging
                )
                Divider().background(Theme.border).padding(.leading, 16)
                toggleRow(
                    title: "Mock 戒指连接",
                    description: "没有真戒指时模拟 BLE 事件",
                    isOn: $store.devSettings.mockRing
                )
                Divider().background(Theme.border).padding(.leading, 16)
                clearCacheRow
            }
        }
    }

    private var clearCacheRow: some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                store.devSettings.localCacheSizeMB = 0
                cacheCleared = true
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("清除本地缓存")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.text)
                    Text(cacheCleared ? "已清除" : "当前占用 \(store.devSettings.localCacheSizeMB) MB")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textDim)
                }
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func toggleRow(title: String,
                           description: String,
                           isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.text)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        AdvancedSettingsView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
