import SwiftUI

/// 单条消息的渲染 dispatch 视图.
///
/// 根据 `message.role` 决定对齐和样式，根据 `message.kind` 决定内容：
/// - role=date    → 居中小字时间分隔符
/// - role=system  → 居中 pill 系统提示
/// - role=user    → 右对齐 accent 气泡（永远是 .text）
/// - role=agent   → 左对齐 panel 气泡，内容由 kind 决定（text / steps / attachment / actions / typing）
///
/// 统一 view 而不是每种 role 一个 view —— list-patterns.md 规则: 不要用 AnyView
/// 隐藏身份, 让同一个 view 内部分支。
struct MessageBubble: View {
    let message: AgentMessage
    let onActionTap: (AgentQuickAction) -> Void
    let onAttachmentTap: (AgentAttachment) -> Void

    var body: some View {
        HStack(spacing: 0) {
            switch message.role {
            case .date:
                dateSeparator
            case .system:
                systemBanner
            case .user:
                Spacer(minLength: 40)
                userBubble
            case .agent:
                agentContent
                Spacer(minLength: 40)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity
        ))
    }

    // MARK: - Date separator

    private var dateSeparator: some View {
        HStack {
            Spacer()
            if case .text(let markdown) = message.kind {
                Text(markdown)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textDimmer)
                    .tracking(0.8)
                    .padding(.vertical, 6)
            }
            Spacer()
        }
    }

    // MARK: - System banner

    private var systemBanner: some View {
        HStack {
            Spacer()
            if case .text(let markdown) = message.kind {
                Text(markdown)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.accent.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.border, lineWidth: 0.5)
                    }
                    .clipShape(.rect(cornerRadius: 12))
                    .frame(maxWidth: 280)
            }
            Spacer()
        }
    }

    // MARK: - User bubble (right aligned)

    private var userBubble: some View {
        Group {
            if case .text(let markdown) = message.kind {
                Text(attributed(markdown))
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: 5,
                            topTrailingRadius: 18
                        )
                    )
            }
        }
    }

    // MARK: - Agent content (left aligned)

    @ViewBuilder
    private var agentContent: some View {
        switch message.kind {
        case .text(let markdown):
            agentTextBubble(markdown: markdown)
        case .steps(let steps):
            agentStepsBubble(steps: steps)
        case .attachment(let att):
            // Attachment 不包在气泡里, 直接裸显示（prototype 里也是）
            AttachmentCard(attachment: att) { onAttachmentTap(att) }
        case .actions(let actions):
            QuickActionsRow(actions: actions, onTap: onActionTap)
        case .typing:
            TypingIndicator()
        }
    }

    private func agentTextBubble(markdown: String) -> some View {
        Text(attributed(markdown))
            .font(.system(size: 13.5))
            .foregroundStyle(Theme.text)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.panel)
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
                .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
            )
    }

    private func agentStepsBubble(steps: [AgentThinkingStep]) -> some View {
        ThinkingStepsBlock(steps: steps)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(Theme.panel)
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
                .stroke(Theme.border, lineWidth: 0.5)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
            )
    }

    // MARK: - Helpers

    private func attributed(_ markdown: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return (try? AttributedString(markdown: markdown, options: options))
            ?? AttributedString(markdown)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        MessageBubble(
            message: .init(role: .user, kind: .text(markdown: "今天敦敏那个会的核心结论是什么?")),
            onActionTap: { _ in },
            onAttachmentTap: { _ in }
        )
        MessageBubble(
            message: .init(role: .agent, kind: .text(markdown: "三个核心结论:\n1. **定位对齐**\n2. **竞争排序**\n3. **品类风险**")),
            onActionTap: { _ in },
            onAttachmentTap: { _ in }
        )
        MessageBubble(
            message: .init(role: .agent, kind: .typing),
            onActionTap: { _ in },
            onAttachmentTap: { _ in }
        )
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
