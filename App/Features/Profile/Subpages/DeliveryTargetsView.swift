import SwiftUI

/// s11 · 投递目标.
/// 展示所有已连接/可连接的第三方平台 (日历 / Linear / Notion / Gmail / ...)
/// 真实实现时走 `POST /v1/integrations/delivery-targets/{platform}/connect`.
struct DeliveryTargetsView: View {
    @Bindable var store: ProfileStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("已连接", items: connected)
                section("可添加", items: notConnected)
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("投递目标")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var connected: [DeliveryTargetConnection] {
        store.deliveryTargets.filter { $0.status == .connected }
    }

    private var notConnected: [DeliveryTargetConnection] {
        store.deliveryTargets.filter { $0.status == .notConnected }
    }

    @ViewBuilder
    private func section(_ title: String, items: [DeliveryTargetConnection]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title)
                MenuGroup {
                    ForEach(items) { target in
                        row(target)
                        if target.id != items.last?.id {
                            Divider().background(Theme.border).padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    private func row(_ target: DeliveryTargetConnection) -> some View {
        HStack(spacing: 12) {
            Image(systemName: target.platform.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(target.status == .connected ? Theme.accent : Theme.textDim)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(target.platform.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text(target.metadataLine)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(1)
            }
            Spacer()
            Button(target.status == .connected ? "断开" : "连接") {
                toggle(target)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(target.status == .connected ? .red : Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func toggle(_ target: DeliveryTargetConnection) {
        guard let idx = store.deliveryTargets.firstIndex(where: { $0.id == target.id }) else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            store.deliveryTargets[idx].status =
                store.deliveryTargets[idx].status == .connected ? .notConnected : .connected
        }
    }
}

#Preview {
    NavigationStack {
        DeliveryTargetsView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
