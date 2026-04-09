import SwiftUI

/// 个人中心的菜单列表行.
///
/// 对应 prototype `.list-row` 样式:
/// 标题 (14pt text) + 右侧 chevron, 点击走 NavigationLink(value:).
/// 可选 subtitle (作为 secondary info, 12pt text-dim).
struct MenuRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textDim)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

/// 一组菜单行的容器, 负责提供 panel 背景和分隔线.
struct MenuGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 14))
    }
}

#Preview {
    VStack(spacing: 14) {
        MenuGroup {
            MenuRow("日历与提醒", systemImage: "calendar")
            Divider().background(Theme.border).padding(.leading, 52)
            MenuRow("投递目标", subtitle: "6 个平台已接入", systemImage: "arrow.up.right.square")
        }
        MenuGroup {
            MenuRow("隐私与数据", systemImage: "lock")
        }
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
