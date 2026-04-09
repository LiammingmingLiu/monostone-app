import SwiftUI

/// 设计令牌 (Design Tokens)
/// ------------------------------------------------------------------
/// 这些颜色从 monostone-ios-prototype/index.html 的 CSS 变量反推而来。
/// 任何新的 SwiftUI 组件都应该引用这里的令牌，而不是硬编码 hex。
///
/// CSS → SwiftUI 对照:
///   --bg              → Theme.background
///   --panel  #141416  → Theme.panel
///   --text            → Theme.text
///   --text-dim  #8E8E93 → Theme.textDim
///   --text-dimmer #48484A → Theme.textDimmer
///   --border  rgba(255,255,255,0.08) → Theme.border
///   --border-strong rgba(255,255,255,0.12) → Theme.borderStrong
///   --accent  #6FD4E0 → Theme.accent
///   --t-rec   #6FC3D0 → Theme.typeLongRec
///   --t-cmd   #A295D0 → Theme.typeCommand
///   --t-idea  #D4A868 → Theme.typeIdea
///   --t-todo  #7FC090 → Theme.typeTodo
enum Theme {
    static let background = Color(hex: 0x0A0A0A)
    static let panel      = Color(hex: 0x141416)

    static let text       = Color.white
    static let textDim    = Color(hex: 0x8E8E93)
    static let textDimmer = Color(hex: 0x48484A)

    static let border        = Color.white.opacity(0.08)
    static let borderStrong  = Color.white.opacity(0.12)

    static let accent     = Color(hex: 0x6FD4E0)

    /// 卡片类型颜色（对应 Card.type 的 4 种值）
    static let typeLongRec = Color(hex: 0x6FC3D0)  // 长录音
    static let typeCommand = Color(hex: 0xA295D0)  // 指令
    static let typeIdea    = Color(hex: 0xD4A868)  // 灵感
    static let typeTodo    = Color(hex: 0x7FC090)  // 待办
}

// MARK: - Color(hex:) 扩展

extension Color {
    /// 从 0xRRGGBB 整数构造 Color
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double((hex >>  0) & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
