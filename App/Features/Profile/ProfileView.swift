import SwiftUI

/// 个人中心 Tab（对应 prototype s10）
///
/// 结构：
/// - 用户头像 + 名字 + 订阅 badge
/// - 戒指连接卡片（电量 + 连接天数）
/// - 3 组菜单 list groups, 通过 value-based NavigationLink 跳到各 settings 子页
/// - 使用 `.navigationDestination(for: ProfileDestination.self)` 统一路由
struct ProfileView: View {
    @State private var store = ProfileStore()
    @Environment(RingCoordinator.self) private var ringCoordinator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    userHeader
                    ringCard
                    menuGroups
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .task { await store.refresh() }
            .navigationDestination(for: ProfileDestination.self) { dest in
                destinationView(for: dest)
            }
        }
    }

    // MARK: - Header

    private var userHeader: some View {
        HStack(spacing: 14) {
            avatar
            VStack(alignment: .leading, spacing: 3) {
                Text(store.user.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text(store.user.subscription.label)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var avatar: some View {
        Circle()
            .fill(Theme.panel)
            .overlay { Circle().stroke(Theme.borderStrong, lineWidth: 0.5) }
            .overlay {
                Text(store.user.avatarChar)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.text)
            }
            .frame(width: 60, height: 60)
    }

    // MARK: - Ring card

    private var ringCard: some View {
        HStack(spacing: 16) {
            Circle()
                .stroke(ringCoordinator.isConnected ? Theme.accent : Theme.textDimmer, lineWidth: 1)
                .shadow(color: Theme.accent.opacity(ringCoordinator.isConnected ? 0.2 : 0), radius: 6)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Monostone 戒指")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text(ringStatusLine)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim)
                    .contentTransition(.opacity)
            }
            Spacer()
            if let battery = ringCoordinator.batteryPct {
                Text("\(battery)%")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 14))
    }

    /// 实时从 `RingCoordinator` 拼装状态文案. 连接中 / 已连接 / 断开 / 未授权
    /// 都会自动刷新; AsyncStream 事件直接驱动 UI.
    private var ringStatusLine: String {
        let connState: String = {
            switch ringCoordinator.connectionState {
            case .connected: "已连接"
            case .connecting, .scanning: "正在连接"
            case .reconnecting: "重连中"
            case .bluetoothOff: "蓝牙关闭"
            case .unauthorized: "未授权"
            case .failed(let reason): "失败: \(reason)"
            case .idle: "未连接"
            }
        }()
        let firmware = ringCoordinator.deviceInfo?.firmwareVersion ?? store.ring.firmwareVersion
        return "\(connState) · 第 \(ringCoordinator.dayCount) 天 · 固件 \(firmware)"
    }

    // MARK: - Menu groups

    private var menuGroups: some View {
        VStack(spacing: 14) {
            MenuGroup {
                navRow("日历与提醒",
                       systemImage: "calendar",
                       destination: .calendarSettings)
                divider
                navRow("投递目标",
                       subtitle: "\(connectedTargetsCount) / \(store.deliveryTargets.count) 已连接",
                       systemImage: "arrow.up.right.square",
                       destination: .deliveryTargets)
                divider
                navRow("自带 API Key",
                       subtitle: "默认: \(store.defaultModelId)",
                       systemImage: "key",
                       destination: .apiKeys)
            }
            MenuGroup {
                navRow("隐私与数据",
                       systemImage: "lock.shield",
                       destination: .privacyData)
                divider
                navRow("导出所有数据",
                       systemImage: "square.and.arrow.up",
                       destination: .exportData)
                divider
                navRow("高级设置",
                       systemImage: "gearshape.2",
                       destination: .advancedSettings)
            }
        }
    }

    private var connectedTargetsCount: Int {
        store.deliveryTargets.filter { $0.status == .connected }.count
    }

    private var divider: some View {
        Divider().background(Theme.border).padding(.leading, 52)
    }

    private func navRow(_ title: String,
                        subtitle: String? = nil,
                        systemImage: String,
                        destination: ProfileDestination) -> some View {
        NavigationLink(value: destination) {
            MenuRow(title, subtitle: subtitle, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Destination dispatch

    @ViewBuilder
    private func destinationView(for dest: ProfileDestination) -> some View {
        switch dest {
        case .deliveryTargets:  DeliveryTargetsView(store: store)
        case .apiKeys:          APIKeysView(store: store)
        case .calendarSettings: CalendarSettingsView(store: store)
        case .privacyData:      PrivacyDataView(store: store)
        case .exportData:       ExportDataView(store: store)
        case .advancedSettings: AdvancedSettingsView(store: store)
        }
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
