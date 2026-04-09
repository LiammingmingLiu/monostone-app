import SwiftUI

/// 浮在首页右下角的录音 FAB.
///
/// 对应 prototype `.fab` + `.fab-label`:
/// - 60×60 按钮, 空闲 = 青绿圆形, 长录音 = 红色圆形 + 脉动外环, 短捕捉 = 紫色圆角方形
/// - 按钮**上方** 浮一个 label, 显示 "录音中 m:ss" / "捕捉中 m:ss"
/// - label 只在录音 / 捕捉态出现, 用 `.transition` 进出动画
///
/// 行为 (prototype `fabDown` / `fabUp` 行为 1:1 复刻):
/// - 空闲 + 快速点 (< 300ms 松手) → 进入长录音态, **留在首页**, FAB 变红 + 显示 timer
/// - 空闲 + 按住 ≥ 300ms → 进入短捕捉态, FAB 变紫 + 显示 timer, 松手停止
/// - 长录音态 + 再次点 → **停止** 长录音, FAB 回到空闲
///
/// Store 里的 `handleTouchDown` / `handleTouchUp` 实现了上面的状态机.
struct FloatingRecordButton: View {
    let store: RecordingStore

    @State private var hasStartedTouch = false
    @State private var feedbackToken = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let size: CGFloat = 60
    private let circleRadius: CGFloat = 30
    private let squareRadius: CGFloat = 18

    var body: some View {
        VStack(spacing: 10) {
            // Timer label 浮在 FAB 上方, 只在录音/捕捉态显示.
            if isActivelyRecording {
                timerLabel
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity)
                            .combined(with: .offset(y: 8)),
                        removal: .opacity.combined(with: .offset(y: 8))
                    ))
            }

            // 主按钮
            buttonBody
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: store.phase)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isActivelyRecording)
    }

    // MARK: - Timer label

    private var isActivelyRecording: Bool {
        switch store.phase {
        case .recordingLong, .capturingShort: true
        default: false
        }
    }

    private var timerLabel: some View {
        VStack(spacing: 2) {
            Text(store.phase == .capturingShort ? "捕捉中" : "录音中")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(store.phase == .capturingShort ? Theme.typeCommand : .red)
                .tracking(0.6)
            Text(store.elapsedDisplay)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    // MARK: - Button body

    private var buttonBody: some View {
        ZStack {
            // Outer pulsing ring · 仅长录音态显示
            if store.phase == .recordingLong && !reduceMotion {
                pulsingOuterRing
            }

            // 主按钮
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
        .simultaneousGesture(touchGesture)
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackToken)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("快速点 开始长录音, 按住 短捕捉, 再次点 停止长录音")
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
            return Theme.typeCommand.opacity(0.22)
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

    // MARK: - Inner shape

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
