import SwiftUI

/// 日程 / 待办卡片详情页 (对应 prototype s6).
///
/// 匹配 prototype `CARD_TEMPLATES['todo-1']` / `'todo-2']`:
/// - Detail head: 类型 / 标题 / "30 分钟前捕捉 · 0:03"
/// - Reclass picker
/// - 你说的原话 (quote-said, 绿色左条)
/// - 解析结果 (parse-grid: 标题 / 时间 / 地点 / 提醒 ...)
/// - 已写入 (目标平台卡片: Apple 日历 / Linear)
/// - 冲突检测
struct TodoDetailView: View {
    let card: Card
    @State private var reclass: Card.CardType
    @State private var toastMessage: String?

    init(card: Card) {
        self.card = card
        self._reclass = State(initialValue: card.type)
    }

    private var isEvent: Bool { card.id == "todo-1" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                head
                reclassPicker
                quoteSaid
                parseResultSection
                writtenToSection
                conflictSection
                // Inline bottom actions: 日程和待办的"主动作"都贴在内容底下,
                // 不再浮在 tab bar 上方的 safeAreaInset, 避免和 tab bar 挤.
                inlineActions
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(isEvent ? "日程" : "待办")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) { toastOverlay }
    }

    // MARK: - Head

    private var head: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isEvent ? "日程" : "待办")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.typeTodo)
                .tracking(1.0)
            Text(card.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(headMeta)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
        }
    }

    private var headMeta: String {
        if isEvent {
            "30 分钟前捕捉 · 0:03"
        } else {
            "昨天 11:20 捕捉 · 0:05"
        }
    }

    // MARK: - Reclass picker

    private var reclassPicker: some View {
        HStack(spacing: 8) {
            Text("类型")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.0)
            ForEach([Card.CardType.command, .idea, .todo], id: \.self) { t in
                reclassChip(t)
            }
            Spacer()
        }
    }

    private func reclassChip(_ t: Card.CardType) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { reclass = t }
        } label: {
            Text(t.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(reclass == t ? Theme.text : Theme.textDim)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(reclass == t ? tint(for: t).opacity(0.14) : Color.clear)
                .overlay {
                    Capsule()
                        .stroke(reclass == t ? tint(for: t).opacity(0.6) : Theme.border,
                                lineWidth: 0.5)
                }
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func tint(for t: Card.CardType) -> Color {
        switch t {
        case .longRec: Theme.typeLongRec
        case .command: Theme.typeCommand
        case .idea:    Theme.typeIdea
        case .todo:    Theme.typeTodo
        }
    }

    // MARK: - Quote said

    private var quoteSaid: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("你说的原话")
            Text("\"" + userQuote + "\"")
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(Theme.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.typeTodo)
                        .frame(width: 2)
                }
                .background(Theme.typeTodo.opacity(0.06))
                .clipShape(.rect(cornerRadius: 8))
        }
    }

    private var userQuote: String {
        if isEvent {
            "提醒我周四下午 3 点去看牙医, 在人民医院口腔科."
        } else {
            "周五之前提醒 Marshall 把 ODM 供应商的事情定下来, 不然要影响后面的节奏."
        }
    }

    // MARK: - Parse result

    private var parseResultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("解析结果")
            MenuGroup {
                ForEach(parseEntries.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 14) {
                        Text(parseEntries[i].0)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textDim)
                            .tracking(0.4)
                            .frame(width: 52, alignment: .leading)
                        Text(parseEntries[i].1)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    if i != parseEntries.count - 1 {
                        Divider().background(Theme.border).padding(.leading, 14)
                    }
                }
            }
        }
    }

    private var parseEntries: [(String, String)] {
        if isEvent {
            return [
                ("标题", "看牙医"),
                ("时间", "4 月 11 日 (周四) 15:00 – 16:00"),
                ("地点", "人民医院 · 口腔科"),
                ("提醒", "提前 1 小时 · 提前 10 分钟"),
                ("重复", "不重复")
            ]
        }
        return [
            ("标题", "锁定 ODM 供应商"),
            ("负责人", "Marshall"),
            ("截止日期", "4 月 12 日 (周五)"),
            ("项目", "Series A · 硬件"),
            ("优先级", "P0")
        ]
    }

    // MARK: - Written to

    private var writtenToSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("已写入")
            HStack(spacing: 12) {
                calendarIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEvent ? "Apple 日历" : "Linear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.text)
                    Text(isEvent
                         ? "同步至 iCloud · 已推送到 Mac"
                         : "team:Monostone · project:Hardware")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textDim)
                }
                Spacer()
                Button("打开") {}
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Theme.typeTodo)
            }
            .padding(14)
            .background(Theme.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var calendarIcon: some View {
        if isEvent {
            VStack(spacing: 0) {
                Text("四月")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(Color.red)
                Text("11")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .padding(.vertical, 3)
            }
            .frame(width: 42)
            .background(Theme.background)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.borderStrong, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 6))
        } else {
            VStack(spacing: 0) {
                Text("LINEAR")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(Theme.typeCommand)
                Text("P0")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .padding(.vertical, 5)
            }
            .frame(width: 42)
            .background(Theme.background)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.borderStrong, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 6))
        }
    }

    // MARK: - Conflict detection

    private var conflictSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("冲突检测")
            Text(conflictText)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.border, lineWidth: 0.5)
                }
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var conflictText: String {
        if isEvent {
            "那天下午没有其他安排 · 无冲突"
        } else {
            "Marshall 本周还有 4 个 P0 任务 · 建议同步沟通优先级"
        }
    }

    // MARK: - Inline actions (type-aware)

    /// 日程和待办的"主动作". 原来只是三个无意义的 修改 / 取消 / 完成 —— 点了
    /// 没有任何反馈. 现在按 `isEvent` 分支:
    ///
    /// **日程** (todo-1 硬件供应商视频会议):
    /// - 主: 加入会议 (去点击 Zoom / Meet 链接)
    /// - 副: 重新安排 (改时间 — 真实实现打开 reschedule modal)
    /// - 危险: 取消会议 (从日历里删掉)
    ///
    /// **待办** (todo-2):
    /// - 主: 标记完成 (同步到 Apple 提醒事项 + Memory)
    /// - 副: 改截止时间
    /// - 危险: 删除
    ///
    /// 每个按钮点击都会触发 toast 反馈 (demo 用), 真实实现换成对应的
    /// store mutation / deep link.
    @ViewBuilder
    private var inlineActions: some View {
        if isEvent {
            HStack(spacing: 10) {
                DetailActionButton(title: "取消会议", kind: .destructive) {
                    showToast("会议已取消 · 已从 Apple 日历移除")
                }
                DetailActionButton(title: "重新安排", kind: .secondary) {
                    showToast("重新安排 · 打开时间选择 (demo)")
                }
                DetailActionButton(title: "加入会议", kind: .primary) {
                    showToast("已打开会议链接 (demo)")
                }
            }
            .padding(.top, 2)
        } else {
            HStack(spacing: 10) {
                DetailActionButton(title: "删除", kind: .destructive) {
                    showToast("已删除 · 从提醒事项移除")
                }
                DetailActionButton(title: "改截止时间", kind: .secondary) {
                    showToast("改截止时间 · 打开日期选择 (demo)")
                }
                DetailActionButton(title: "标记完成", kind: .primary) {
                    showToast("已完成 · 同步到 Apple 提醒事项")
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeIn(duration: 0.2)) { toastMessage = nil }
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toastMessage {
            Text(toastMessage)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.panel)
                .overlay { Capsule().stroke(Theme.border, lineWidth: 0.5) }
                .clipShape(.capsule)
                .padding(.bottom, 30)
                .transition(.opacity.combined(with: .offset(y: 10)))
        }
    }
}

#Preview("日程") {
    NavigationStack {
        TodoDetailView(card: HomeStore.mockCards.first { $0.id == "todo-1" }!)
    }
    .preferredColorScheme(.dark)
}

#Preview("待办") {
    NavigationStack {
        TodoDetailView(card: HomeStore.mockCards.first { $0.id == "todo-2" }!)
    }
    .preferredColorScheme(.dark)
}
