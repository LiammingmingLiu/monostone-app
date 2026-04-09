import SwiftUI

/// s12 · 自带 API Key (BYOK).
/// 显示已配置的 API key 列表 + 本月用量, 以及默认模型的单选切换.
/// 真实实现走 `GET /v1/integrations/api-keys` + `PATCH /v1/integrations/default-model`.
struct APIKeysView: View {
    @Bindable var store: ProfileStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                configuredSection
                modelPickerSection
                footerHint
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("自带 API Key")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Configured keys

    private var configuredSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("已配置")
            MenuGroup {
                ForEach(store.apiKeys) { key in
                    keyRow(key)
                    if key.id != store.apiKeys.last?.id {
                        Divider().background(Theme.border).padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func keyRow(_ key: APIKeyConfig) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key.provider.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text(key.maskedKey)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
                Text(key.monthlyUsageDisplay)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textDimmer)
            }
            Spacer()
            Button("管理") { /* 真实实现跳到 key 管理子页 */ }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Model picker

    private var modelPickerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("默认模型")
            MenuGroup {
                ForEach(store.availableModels) { model in
                    modelRow(model)
                    if model.id != store.availableModels.last?.id {
                        Divider().background(Theme.border).padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func modelRow(_ model: ModelChoice) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                store.defaultModelId = model.id
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.model)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.text)
                    Text(model.useCase)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: store.defaultModelId == model.id ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(store.defaultModelId == model.id ? Theme.accent : Theme.textDimmer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: store.defaultModelId)
    }

    // MARK: - Footer

    private var footerHint: some View {
        Text("""
        BYOK 只对付费用户开放。免费计划默认使用 Monostone 提供的共享 quota，\
        想用自己的 key 需至少 $20/月 的订阅档位。
        """)
        .font(.system(size: 11))
        .foregroundStyle(Theme.textDim)
        .padding(.horizontal, 4)
    }
}

#Preview {
    NavigationStack {
        APIKeysView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
