import SwiftUI

/// 记忆页高频实体列表的单行.
///
/// 对应 prototype `.entity-row`:
/// - 左侧圆形头像 (36x36, 青绿半透明背景)
/// - 中间 name + subtitle
/// - 右侧 kind badge (人 / 项目 / 组织 / 概念 / 事件)
/// - 最右 chevron
struct EntityRow: View {
    let entity: MemoryEntity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                avatar
                info
                kindBadge
                chevron
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text("\(entity.name)，\(entity.kind.rawValue)，\(entity.memoryCount) 条记忆")
        )
    }

    // MARK: - Subviews

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.1))
                .overlay { Circle().stroke(Theme.borderStrong, lineWidth: 0.5) }
            Text(entity.avatar)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(4)
        }
        .frame(width: 36, height: 36)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entity.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Text(entity.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDim)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kindBadge: some View {
        Text(entity.kind.rawValue)
            .font(.system(size: 10))
            .foregroundStyle(Theme.textDimmer)
            .tracking(0.4)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.border, lineWidth: 0.5)
            }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.textDimmer)
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(MemoryStore.mockEntities) { entity in
            EntityRow(entity: entity) { }
            if entity.id != MemoryStore.mockEntities.last?.id {
                Divider().background(Theme.border).padding(.leading, 64)
            }
        }
    }
    .background(Theme.panel)
    .clipShape(.rect(cornerRadius: 14))
    .padding(16)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
