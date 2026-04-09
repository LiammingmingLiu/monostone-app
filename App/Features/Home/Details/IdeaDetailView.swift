import SwiftUI

/// 灵感卡片详情页 (对应 prototype s5).
///
/// 匹配 prototype `CARD_TEMPLATES['idea-1']` / `'idea-2']` 的结构:
/// - Detail head: 类型 / 标题 / "走路时捕捉 · 45 分钟前 · 0:08"
/// - Reclass picker
/// - 原声 (play button + 波形预览 + 时长)
/// - 转写文本 (transcript box)
/// - 自动归属 (project badge + confidence)
/// - 相关的过往灵感 (3 条 related cards)
/// - 和 Agent 一起发散 (chat preview)
struct IdeaDetailView: View {
    let card: Card
    @State private var reclass: Card.CardType

    init(card: Card) {
        self.card = card
        self._reclass = State(initialValue: card.type)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                head
                reclassPicker
                audioPlayer
                transcriptSection
                autoCategorySection
                relatedSection
                chatSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("灵感")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomActions }
    }

    // MARK: - Head

    private var head: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("灵感")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.typeIdea)
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
        let context = card.id == "idea-1" ? "走路时捕捉" : "开车时捕捉"
        let dur = card.durationDisplay ?? "0:08"
        return "\(context) · \(card.timeRelative) · \(dur)"
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

    // MARK: - Audio player

    private var audioPlayer: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("原声")
            HStack(spacing: 14) {
                // Play button
                Button { } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.typeIdea.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.typeIdea)
                            .offset(x: 1)
                    }
                }
                .buttonStyle(.plain)

                // Mini waveform (static, 30 bars)
                HStack(spacing: 2) {
                    ForEach(waveformHeights.indices, id: \.self) { i in
                        Capsule()
                            .fill(Theme.typeIdea.opacity(0.6))
                            .frame(width: 2.5, height: waveformHeights[i])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(card.durationDisplay ?? "0:08")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
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

    private var waveformHeights: [CGFloat] {
        // 固定的 30 条高度, 视觉上像波形但不动
        [10, 20, 28, 16, 24, 32, 20, 12, 26, 18,
         30, 14, 22, 28, 18, 16, 24, 12, 20, 18,
         14, 18, 28, 16, 10, 22, 18, 12, 24, 20]
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("转写文本")
            Text(transcriptText)
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .background(Theme.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.border, lineWidth: 0.5)
                }
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var transcriptText: String {
        if card.id == "idea-2" {
            "戒指 onboarding 可以加一步 LinkedIn 导入, 让 Day 1 用户的 first prompt 就有 context. 现在 Day 1 体验太冷了, 和 Day 30 差距太大. 如果能从 LinkedIn 拉出来用户的 role、company、network, Day 1 就能把 baseline confidence 从 60 分拉到 75 分左右."
        } else {
            "Memory 的 L2 到 L3 的 promotion 机制可以加一个 confidence decay, 如果一条 memory 在 7 天内没被引用或确认, confidence 要自动往下掉, 这样才不会让错误的早期推断一直被当成事实."
        }
    }

    // MARK: - Auto category

    private var autoCategorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("自动归属")
            HStack(spacing: 10) {
                Image(systemName: "folder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.typeIdea)
                Text(card.project ?? "未分类")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("\(autoCategoryConfidence)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.typeTodo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.typeTodo.opacity(0.14))
                    .clipShape(.capsule)
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

    private var autoCategoryConfidence: Int {
        card.id == "idea-2" ? 91 : 94
    }

    // MARK: - Related

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("相关的过往灵感")
            VStack(spacing: 8) {
                ForEach(relatedIdeas, id: \.title) { r in
                    relatedCard(r)
                }
            }
        }
    }

    private func relatedCard(_ r: (type: String, similarity: Int, title: String)) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(r.type)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textDimmer)
                    .tracking(0.4)
                Spacer()
                Text("\(r.similarity)%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.typeIdea)
            }
            Text(r.title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 10))
    }

    private var relatedIdeas: [(type: String, similarity: Int, title: String)] {
        if card.id == "idea-2" {
            return [
                ("长录音 · 4/8", 83, "Linear 指出 Day 1 和 Day 30 的体验差距是最大的流失风险, 早期用户撑不过来..."),
                ("灵感 · 上周二", 74, "其实可以在开箱前让用户扫码进 Pre-Ring App, 提前导入 Calendar 和 Contacts..."),
                ("指令 · 3 天前", 65, "我之前让 Agent 做了个 Day 1 vs Day 30 的 context 差距分析, 结论是差 35 分...")
            ]
        }
        return [
            ("灵感 · 3 天前", 87, "L2 consolidation 的触发条件现在太激进了, 应该加一个\"稳定窗口\"的概念..."),
            ("长录音 · 上周三", 72, "林啸提到 memory conflict resolution 需要人工 loop, 这是 Linear 也指出的问题..."),
            ("灵感 · 上周", 68, "其实可以参考 spaced repetition 的遗忘曲线来设计 memory 的 decay...")
        ]
    }

    // MARK: - Chat

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("和 Agent 一起发散")
            VStack(alignment: .leading, spacing: 8) {
                chatBubble(role: .agent, text: "这个想法我记下来了。想让我帮你展开、还是和已有的想法做关联？")
                chatBubble(role: .user, text: "和 spaced repetition 的遗忘曲线怎么结合")
                chatBubble(role: .agent, text: "可以借 SM-2 的思路: memory 每次被引用就 refresh confidence, 没被引用按 Ebbinghaus 曲线衰减. 这样 memory 的\"重要性\"随使用自然分层.")
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

    private var bottomActions: some View {
        HStack(spacing: 10) {
            Button("归档") {}
                .buttonStyle(.bordered)
                .tint(Theme.textDim)
            Button("加入项目") {}
                .buttonStyle(.borderedProminent)
                .tint(Theme.typeIdea)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationStack {
        IdeaDetailView(card: HomeStore.mockCards.first { $0.id == "idea-1" }!)
    }
    .preferredColorScheme(.dark)
}
