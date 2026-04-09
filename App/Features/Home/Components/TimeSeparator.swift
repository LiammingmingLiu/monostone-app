import SwiftUI

/// 首页卡片列表里的时间分隔. 对应 prototype `.time-sep`:
/// 一个左右各有一条细线 + 中间小号灰色文字, 显示 "今天" / "昨天" / "本周".
struct TimeSeparator: View {
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            lineRule
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.4)
            lineRule
        }
        .padding(.vertical, 4)
    }

    private var lineRule: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(height: 0.5)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 14) {
        TimeSeparator(label: "今天")
        TimeSeparator(label: "昨天")
        TimeSeparator(label: "本周")
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
