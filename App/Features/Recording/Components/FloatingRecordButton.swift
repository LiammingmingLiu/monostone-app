import SwiftUI

/// 浮在首页右下角的录音 FAB.
///
/// 对应 prototype `.fab` + `@keyframes fab-pulse-red`:
/// - 60×60 圆形（空闲 / 长录音态）
/// - 18px 圆角方形（短捕捉态, 对应 prototype `.fab.recording-short`）
/// - 按下时 scale 0.9
/// - 进入长录音态时开启青绿外圈脉动（TimelineView 驱动）
///
/// 使用 `RoundedRectangle(cornerRadius:)` 作为主形状, 通过动画改变
/// cornerRadius 实现圆 ↔ 圆角方的 morph. 不用 `Circle` 因为跨类型
/// 切换没法流畅动画.
///
/// 手势: `DragGesture(minimumDistance: 0)` 跟踪 touch-down/up.
/// Store 侧管理 300ms 阈值判定, view 只转发 touch 事件.
struct FloatingRecordButton: View {
    let store: RecordingStore

    /// `@State` local only for gesture phase tracking.
    /// 真正的 phase 在 store 里.
    @State private var hasStartedTouch = false

    /// `sensoryFeedback` 触发器 (每次 phase 变化震一下)
    @State private var feedbackToken = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let size: CGFloat = 60
    private let circleRadius: CGFloat = 30    // 半径 = 直径 / 2 ⇒ 圆形
    private let squareRadius: CGFloat = 18    // 圆角方形

    var body: some View {
        ZStack {
            // Outer pulsing ring · 只在长录音态显示
            if store.phase == .recordingLong && !reduceMotion {
                pulsingOuterRing
            }

            // Main button
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1.5)
                }
                .overlay { innerShape }
                .frame(width: size, height: size)
                .scaleEffect(scaleFactor)
                .shadow(color: shadowColor, radius: 12, x: 0, y: 4)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: store.phase)
        .simultaneousGesture(touchGesture)
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackToken)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("快速点 开始长录音, 按住 短捕捉")
    }

    // MARK: - Gesture

    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !hasStartedTouch else { return }
                hasStartedTouch = true
                store.handleTouchDown()
                feedbackToken += 1
            }
            .onEnded { _ in
                hasStartedTouch = false
                store.handleTouchUp()
                feedbackToken += 1
            }
    }

    // MARK: - Visual computed values

    private var cornerRadius: CGFloat {
        store.phase == .capturingShort ? squareRadius : circleRadius
    }

    private var fillColor: Color {
        switch store.phase {
        case .idle, .pressed:
            return Theme.accent.opacity(0.14)
        case .recordingLong:
            return Color.red.opacity(0.18)
        case .capturingShort:
            return Theme.typeCommand.opacity(0.22) // 紫色, 对应 prototype
        }
    }

    private var borderColor: Color {
        switch store.phase {
        case .idle, .pressed:
            return Theme.accent
        case .recordingLong:
            return .red
        case .capturingShort:
            return Theme.typeCommand
        }
    }

    private var shadowColor: Color {
        switch store.phase {
        case .recordingLong:
            return Color.red.opacity(0.45)
        case .capturingShort:
            return Theme.typeCommand.opacity(0.45)
        default:
            return Theme.accent.opacity(0.35)
        }
    }

    private var scaleFactor: CGFloat {
        switch store.phase {
        case .idle: return 1.0
        case .pressed, .capturingShort: return 0.9
        case .recordingLong: return 1.0
        }
    }

    // MARK: - Inner shape (dot / square / fill)

    @ViewBuilder
    private var innerShape: some View {
        switch store.phase {
        case .idle, .pressed:
            Circle()
                .fill(Theme.accent)
                .frame(width: 22, height: 22)
                .shadow(color: Theme.accent.opacity(0.6), radius: 6)
        case .recordingLong:
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red)
                .frame(width: 20, height: 20)
                .shadow(color: Color.red.opacity(0.6), radius: 6)
        case .capturingShort:
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.typeCommand)
                .frame(width: 22, height: 22)
                .shadow(color: Theme.typeCommand.opacity(0.6), radius: 6)
        }
    }

    // MARK: - Pulsing ring (long recording only)

    private var pulsingOuterRing: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = (t.truncatingRemainder(dividingBy: 1.4)) / 1.4
            RoundedRectangle(cornerRadius: circleRadius)
                .stroke(Color.red, lineWidth: 1.5)
                .frame(width: size, height: size)
                .scaleEffect(1.0 + phase * 0.6)
                .opacity(1.0 - phase)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabelText: String {
        switch store.phase {
        case .idle, .pressed: "录音按钮"
        case .recordingLong:  "停止长录音"
        case .capturingShort: "捕捉中"
        }
    }
}

#Preview("Idle") {
    FloatingRecordButton(store: RecordingStore())
        .padding(40)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
