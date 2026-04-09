import SwiftUI

/// Memory Tree L0-L4 的 5 列统计条, 显示在记忆页顶部.
///
/// 对应 prototype `.mem-stats` 样式:
/// 五列等宽 · 青绿大数字 · 下方小号大写层级名
struct MemoryStatsBar: View {
    let stats: MemoryTreeStats

    private var entries: [(number: Int, label: String)] {
        [
            (stats.l0Scenes,       "L0 场景"),
            (stats.l1Projects,     "L1 项目"),
            (stats.l2Episodes,     "L2 片段"),
            (stats.l3Descriptions, "L3 描述"),
            (stats.l4Raw,          "L4 原始")
        ]
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                StatCell(number: entry.number, label: entry.label)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memory Tree 共 \(stats.l0Scenes + stats.l1Projects + stats.l2Episodes + stats.l3Descriptions + stats.l4Raw) 条")
    }
}

// MARK: - StatCell

private struct StatCell: View {
    let number: Int
    let label: String

    private var displayNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(displayNumber)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(0.6)
                .lineLimit(1)
        }
    }
}

#Preview {
    MemoryStatsBar(stats: MemoryStore.mockStats)
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
