import SwiftUI

/// s14 · 隐私与数据.
/// - 音频存储策略 (仅本地 / 云端加密) 二选一
/// - 数据保留期 (30 / 90 / 永久)
/// - iOS 系统权限状态列表
/// - 删除所有数据（危险操作）
struct PrivacyDataView: View {
    @Bindable var store: ProfileStore
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                audioStorageSection
                retentionSection
                permissionsSection
                dangerSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("隐私与数据")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "删除所有数据并重置账户？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("永久删除", role: .destructive) {
                // Demo only. 真实实现走 DELETE /v1/privacy/all-data
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("这个操作不可逆，所有录音、memory、action items、订阅记录都会被清空。")
        }
    }

    // MARK: - Audio storage

    private var audioStorageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("音频存储")
            MenuGroup {
                ForEach(AudioStorageMode.allCases) { mode in
                    radioRow(
                        title: mode.label,
                        description: mode.description,
                        isSelected: store.audioStorage == mode
                    ) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.audioStorage = mode
                        }
                    }
                    if mode != AudioStorageMode.allCases.last {
                        Divider().background(Theme.border).padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Retention

    private var retentionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("数据保留期")
            MenuGroup {
                ForEach(RetentionPeriod.allCases) { period in
                    radioRow(
                        title: period.label,
                        description: nil,
                        isSelected: store.retentionPeriod == period
                    ) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            store.retentionPeriod = period
                        }
                    }
                    if period != RetentionPeriod.allCases.last {
                        Divider().background(Theme.border).padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Permissions

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("系统权限")
            MenuGroup {
                ForEach(store.permissions) { entry in
                    permissionRow(entry)
                    if entry.id != store.permissions.last?.id {
                        Divider().background(Theme.border).padding(.leading, 52)
                    }
                }
            }
        }
    }

    private func permissionRow(_ entry: PermissionStatusEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.permission.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.permission.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text(entry.usage)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(1)
            }
            Spacer()
            statusBadge(entry.status)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func statusBadge(_ status: PermissionStatusEntry.Status) -> some View {
        let color: Color = {
            switch status {
            case .authorized:    Theme.typeTodo
            case .denied:        .red
            case .notDetermined: Theme.textDimmer
            }
        }()
        return Text(status.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(.rect(cornerRadius: 6))
    }

    // MARK: - Danger

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("危险操作")
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .frame(width: 24)
                    Text("删除所有数据并重置")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundStyle(Color.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Theme.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
                }
                .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func radioRow(title: String,
                          description: String?,
                          isSelected: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.text)
                    if let description {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textDim)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textDimmer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PrivacyDataView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
