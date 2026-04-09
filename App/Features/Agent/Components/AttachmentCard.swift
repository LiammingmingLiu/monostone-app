import SwiftUI

/// Agent 消息里的附件卡片（邮件 / deck / 报告 / 文档 / 链接预览）.
///
/// 对应 prototype `.chat-row .attach`:
/// 28px icon 方块 + 标题 + 小号副标题, 整条可点打开详情.
struct AttachmentCard: View {
    let attachment: AgentAttachment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: attachment.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28, height: 28)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(.rect(cornerRadius: 7))
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text(attachment.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textDimmer)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.04))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.borderStrong, lineWidth: 0.5)
            }
            .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AttachmentCard(
        attachment: .init(
            icon: "envelope",
            title: "Re: ODM 合作节奏对齐",
            subtitle: "收件人: marshall@monostone.com · 3 段",
            attachmentType: .email
        ),
        onTap: {}
    )
    .padding()
    .background(Theme.panel)
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
