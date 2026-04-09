import SwiftUI

/// s13 · 日历与提醒.
/// 日历连接开关 + 提醒策略（会议 / 待办提前多少分钟、通勤修正）.
struct CalendarSettingsView: View {
    @Bindable var store: ProfileStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                connectionsSection
                reminderSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("日历与提醒")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Connections

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("已连接的日历")
            MenuGroup {
                ForEach($store.calendarConnections) { $connection in
                    HStack(spacing: 12) {
                        Image(systemName: connection.platform.systemImage)
                            .font(.system(size: 16))
                            .foregroundStyle(connection.connected ? Theme.accent : Theme.textDim)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(connection.platform.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.text)
                            Text(connection.metadataLine)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textDim)
                                .lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: $connection.connected)
                            .labelsHidden()
                            .tint(Theme.accent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if connection.id != store.calendarConnections.last?.id {
                        Divider().background(Theme.border).padding(.leading, 52)
                    }
                }
            }
        }
    }

    // MARK: - Reminder policy

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("提醒策略")
            MenuGroup {
                autoRemindRow
                Divider().background(Theme.border).padding(.leading, 16)
                advanceMinRow("会议提前", value: $store.reminderPolicy.meetingAdvanceMin,
                              options: [5, 10, 15, 30])
                Divider().background(Theme.border).padding(.leading, 16)
                advanceMinRow("待办提前", value: $store.reminderPolicy.taskAdvanceMin,
                              options: [15, 30, 60, 120])
                Divider().background(Theme.border).padding(.leading, 16)
                commuteRow
            }
        }
    }

    private var autoRemindRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("自动提前提醒")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.text)
                Text("关闭后不会主动推送日程和待办提醒")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Toggle("", isOn: $store.reminderPolicy.autoRemind)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func advanceMinRow(_ label: String,
                               value: Binding<Int>,
                               options: [Int]) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)
            Spacer()
            Picker("", selection: value) {
                ForEach(options, id: \.self) { minutes in
                    Text("\(minutes) 分钟").tag(minutes)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var commuteRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("通勤时间修正")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.text)
                Text("结合实时位置和路况动态调整提醒时间")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Toggle("", isOn: $store.reminderPolicy.commuteCorrection)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        CalendarSettingsView(store: ProfileStore())
    }
    .preferredColorScheme(.dark)
}
