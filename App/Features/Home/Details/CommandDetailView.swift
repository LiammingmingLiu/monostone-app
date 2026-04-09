import SwiftUI

/// 指令卡片详情页 (对应 prototype s4).
///
/// 匹配 prototype `CARD_TEMPLATES['cmd-1']` 和 `'cmd-2']` 的结构:
/// - Detail head: 类型 / 标题 / "已完成 · 用时 1 分 42 秒 · 1 小时前"
/// - Reclass picker: 指令 / 灵感 / 待办 三选一切换分类
/// - 你说的原话 (quote-said)
/// - 调取的上下文 (ctx-row 列表)
/// - 执行步骤 (timeline, done/running/pending 三种状态)
/// - 产出 (邮件卡片) 或 "正在生成" loading 状态
/// - 继续和 Agent 沟通 (chat 预览)
///
/// **processing 态**: cmd-2 是执行中的卡片, 没有"产出"只有 loading 占位,
/// 底部按钮是"在后台继续 / 取消任务" 而不是"存草稿 / 发送".
struct CommandDetailView: View {
    let card: Card

    /// demo 用: 本地 state reflect 当前 reclass 选择, 真实实现写回 card type
    @State private var reclass: Card.CardType

    init(card: Card) {
        self.card = card
        self._reclass = State(initialValue: card.type)
    }

    private var isProcessing: Bool { card.status == .processing }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                head
                reclassPicker
                quoteSaid
                contextsSection
                timelineSection
                outputSection
                chatSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(isProcessing ? "指令 · 执行中" : "指令")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomActions }
    }

    // MARK: - Head

    private var head: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isProcessing ? "指令 · 执行中" : "指令")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.typeCommand)
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
        if isProcessing {
            return "正在执行 · 已用时 1 分 12 秒 · 预计还需 3 分钟"
        } else {
            return "已完成 · 用时 1 分 42 秒 · \(card.timeRelative)"
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
                        .fill(Theme.typeCommand)
                        .frame(width: 2)
                }
                .background(Theme.typeCommand.opacity(0.06))
                .clipShape(.rect(cornerRadius: 8))
        }
    }

    private var userQuote: String {
        if isProcessing {
            "帮我做个 Sandbar 最新融资情况的 research, 重点是 Round 金额、估值、领投方, 以及产品方向的变化."
        } else {
            "帮我写封 follow-up 邮件给敦敏, 基于今天早上的会议, 重点回应他对估值和 GTM 的疑问. 语气参考我平时给投资人的风格."
        }
    }

    // MARK: - Contexts

    private var contextsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("调取的上下文")
            MenuGroup {
                ForEach(contexts, id: \.0) { ctx in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ctx.0)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.text)
                            Text(ctx.1)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textDim)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.typeTodo)
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)

                    if ctx.0 != contexts.last?.0 {
                        Divider().background(Theme.border).padding(.leading, 14)
                    }
                }
            }
        }
    }

    private var contexts: [(String, String)] {
        if isProcessing {
            return [
                ("Sandbar 历史 watching list", "Memory"),
                ("你上次对 Sandbar 的分析", "3 周前录音"),
                ("Crunchbase 竞品数据", "Integration")
            ]
        }
        return [
            ("今早 Series A 跟进会", "42 分钟录音"),
            ("敦敏的投资人档案", "Memory"),
            ("你的邮件语气和风格", "自动学习"),
            ("Series A 邮件线程", "8 封历史")
        ]
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("执行步骤")
            MenuGroup {
                ForEach(steps, id: \.title) { step in
                    HStack(alignment: .top, spacing: 12) {
                        stepDot(step.status)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.text)
                            Text(step.desc)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textDim)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    if step.title != steps.last?.title {
                        Divider().background(Theme.border).padding(.leading, 38)
                    }
                }
            }
        }
    }

    private func stepDot(_ status: StepStatus) -> some View {
        Circle()
            .fill(status == .done ? Theme.typeTodo : (status == .running ? Theme.typeCommand : Theme.textDimmer))
            .frame(width: 8, height: 8)
            .shadow(
                color: status == .running ? Theme.typeCommand.opacity(0.5) : .clear,
                radius: 4
            )
    }

    enum StepStatus { case done, running, pending }

    private var steps: [(title: String, desc: String, status: StepStatus)] {
        if isProcessing {
            return [
                ("解析指令意图", "识别为竞品研究任务 · 0.4s", .done),
                ("从 Memory 检索相关上下文", "调取 3 项相关记忆 · 1.8s", .done),
                ("联网搜索最新信息", "并发调用 4 个数据源 · 已跑 68s…", .running),
                ("生成研究报告", "等待中", .pending),
                ("自我校验 + 推送", "等待中", .pending)
            ]
        }
        return [
            ("解析指令意图", "识别为邮件起草任务 · 0.3s", .done),
            ("从 Memory 检索相关上下文", "调取 4 项相关记忆 · 2.1s", .done),
            ("分析敦敏的关注点", "估值、GTM、moat 三个主题 · 4.8s", .done),
            ("生成草稿 (模仿你的语气)", "正式但不端着 · 18.2s", .done),
            ("自我校验 + 推送", "通过事实核对 · 76.6s", .done)
        ]
    }

    // MARK: - Output

    @ViewBuilder
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("产出")
            if isProcessing {
                loadingOutput
            } else {
                emailOutput
            }
        }
    }

    private var loadingOutput: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Text("正在生成研究报告")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textDim)
                ForEach(0..<3, id: \.self) { _ in
                    Text("·")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textDim)
                }
            }
            Text("报告完成后会自动推送到首页 Timeline")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDimmer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 12))
    }

    private var emailOutput: some View {
        VStack(alignment: .leading, spacing: 10) {
            emailField("收件人", "cai@linearcap.com")
            emailField("主题", "Re: Series A 讨论跟进")
            Divider().background(Theme.border)
            Text("""
            敦敏，

            谢谢今早的深度交流。针对估值和 GTM，我这边补充几点：

            **估值** — 我们的逻辑基于 Context 复利带来的切换成本。Day 30 的用户迁移成本是 Day 1 的 10 倍以上，这是数据独立性之外的第二条护城河。

            **GTM** — 我们认同企业场景优先级更高。我们的核心用户是每天和 AI 交互 10+ 次的高频用户，团队协作场景的 Context 共享需求远大于家庭场景。下周拉出初版 B2B roadmap 给你看。

            另外 EO 14117 的角度我这边会查一下，有结论同步。

            再聊，
            明明
            """)
            .font(.system(size: 12))
            .foregroundStyle(Theme.text)
            .lineSpacing(4)
        }
        .padding(14)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 12))
    }

    private func emailField(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(key)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDim)
                .tracking(0.6)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Chat preview

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("继续和 Agent 沟通")
            VStack(alignment: .leading, spacing: 8) {
                chatBubble(role: .agent, text: "草稿写好了。想改哪里都可以告诉我 —— 语气、长度、结构都行。")
                chatBubble(role: .user,  text: "GTM 那段太简略了, 展开一下, 重点说我们为什么选企业优先")
                chatBubble(role: .agent, text: "好, 我把 GTM 段扩展成三句, 锚点用\"10+ 交互/天的高频用户\". 新版已经更新到上面.")
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

    private enum BubbleRole { case user, agent }

    private func chatBubble(role: BubbleRole, text: String) -> some View {
        HStack {
            if role == .user { Spacer(minLength: 32) }
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(role == .user ? Color.black : Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(role == .user ? Theme.accent : Theme.background)
                .overlay {
                    if role == .agent {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.border, lineWidth: 0.5)
                    }
                }
                .clipShape(.rect(cornerRadius: 12))
            if role == .agent { Spacer(minLength: 32) }
        }
    }

    // MARK: - Bottom actions

    @ViewBuilder
    private var bottomActions: some View {
        HStack(spacing: 10) {
            if isProcessing {
                Button("在后台继续") {}
                    .buttonStyle(.bordered)
                    .tint(Theme.textDim)
                Button("取消任务") {}
                    .buttonStyle(.bordered)
                    .tint(.red)
            } else {
                Button("存为草稿") {}
                    .buttonStyle(.bordered)
                    .tint(Theme.textDim)
                Button("发送") {}
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.typeCommand)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

#Preview("Done") {
    NavigationStack {
        CommandDetailView(card: HomeStore.mockCards.first { $0.id == "cmd-1" }!)
    }
    .preferredColorScheme(.dark)
}

#Preview("Processing") {
    NavigationStack {
        CommandDetailView(card: HomeStore.mockCards.first { $0.id == "cmd-2" }!)
    }
    .preferredColorScheme(.dark)
}
