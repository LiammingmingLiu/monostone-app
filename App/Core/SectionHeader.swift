import SwiftUI

/// 跨页面共享的"小节标题"样式.
///
/// 对应 prototype CSS `.settings-sec-title`:
/// 10px 字号 / text-dimmer / 0.14em letter-spacing / 700 weight / upper-tracking
///
/// 用法: `SectionHeader("今天学到的")` → 显示为
/// 全大写、灰色、字距拉开的小标题, 主要用在 Memory/Profile/Agent 等 tab root 里分组.
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.textDimmer)
            .tracking(1.4)
            .padding(.horizontal, 4)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        SectionHeader("今天学到的")
        SectionHeader("高频实体")
        SectionHeader("最近纠正")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
