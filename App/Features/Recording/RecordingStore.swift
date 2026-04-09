import Foundation
import Observation

/// 录音 session 的 `@Observable` 状态机.
///
/// 对应 prototype `pages-and-interactions.md §F1 F2 FAB 录音按钮`:
///
/// 状态流转:
/// ```
///      idle
///        │ (touch down)
///        ↓
///     pressed ──────────┐
///        │              │ (300ms timer fires 时用户还在按)
///        │              ↓
///        │         capturingShort
///        │              │ (touch up)
///        │              ↓
///        │           idle + toast
///        │
///        │ (touch up 在 300ms 之前)
///        ↓
///   recordingLong (fullScreenCover presents)
///        │ (用户点停止 / 取消)
///        ↓
///      idle
/// ```
///
/// 所有状态切换 / timer 调度都集中在这里, FAB 和 fullScreenCover 只读这个
/// `phase` + 调对应方法, 避免状态分散在多处 view 里.
@Observable
@MainActor
final class RecordingStore {
    enum Phase: Hashable {
        case idle
        /// 用户按下但还不到 300ms, 方向未定
        case pressed
        /// 全屏录音中 (对应 prototype s7)
        case recordingLong
        /// 按住捕捉短录音 (不跳屏, FAB 本身变形)
        case capturingShort
    }

    // MARK: - Public observable state

    private(set) var phase: Phase = .idle
    /// 当前 session 已录制秒数 (用于 timer 显示)
    private(set) var elapsedSeconds: Double = 0

    /// 每次短录音完成会换一个新 token, HomeView 用它触发"插入新卡片 + toast".
    /// 用 UUID 而不是 Bool 避免"多次短录音连续触发时 toast 不刷新".
    private(set) var lastShortCaptureId: UUID?

    /// 每次**长录音**停止会换一个新 token, HomeView 用它在 feed 顶部插入一张
    /// 新的长录音卡片. `cancelLongRecording` 不会更新这个 token, 只有 stop
    /// 才会 —— 对应"取消不产生卡片, 停止产生卡片"的产品语义.
    private(set) var lastLongRecordingId: UUID?

    /// 上一次录音/捕捉的最终时长 (秒). 因为 `startTimer()` 会把 `elapsedSeconds`
    /// 归零, 而新卡片需要读到停止那一刻的时长, 所以在 stop 的时候先快照到这里,
    /// 再让 HomeView 通过 onChange 读.
    private(set) var lastCaptureDurationSec: Int = 0

    // MARK: - Private

    private var pressTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    /// 按住超过这个时长判定为"短录音捕捉", 否则是"快速点 → 长录音"
    private let shortHoldThresholdMs: Int = 300

    // MARK: - Touch handlers (from FloatingRecordButton)

    /// FAB touch-down 时调用.
    ///
    /// - 如果当前在 `.recordingLong`: 这次 touch 是"再次点击以停止录音"(prototype
    ///   `fabDown` 的第一条分支, 见 events-protocol.md §F1). 直接调 stop, 后续的
    ///   touchUp 看到 .idle 状态会 no-op.
    /// - 如果当前在 `.idle`: 进入 .pressed, 300ms 阈值决定 short vs long.
    /// - 如果当前在 .capturingShort: 已经在按住态不应该再次触发 down.
    func handleTouchDown() {
        if phase == .recordingLong {
            stopLongRecording()
            return
        }
        guard phase == .idle else { return }
        phase = .pressed
        pressTask?.cancel()
        pressTask = Task { @MainActor [weak self] in
            // 睡 300ms, 如果醒来时仍在 .pressed 就转到 .capturingShort
            try? await Task.sleep(for: .milliseconds(self?.shortHoldThresholdMs ?? 300))
            guard let self, !Task.isCancelled, self.phase == .pressed else { return }
            self.phase = .capturingShort
            self.startTimer()
        }
    }

    /// FAB touch-up 时调用.
    func handleTouchUp() {
        pressTask?.cancel()
        switch phase {
        case .pressed:
            // 快速点 → 留在首页进入长录音态, FAB 变红
            phase = .recordingLong
            startTimer()
        case .capturingShort:
            // 按住录完松手 → 回到 idle, 通知 HomeView 弹 toast + 插卡
            lastCaptureDurationSec = Int(elapsedSeconds.rounded())
            stopTimer()
            phase = .idle
            lastShortCaptureId = UUID()
        case .idle, .recordingLong:
            break
        }
    }

    /// 长录音停止 (FAB 再次点击触发, 通过 `handleTouchDown` 里的提前分支).
    /// 会快照 duration + 更新 `lastLongRecordingId`, HomeView 监听后往 feed
    /// 插入一张新的 `.longRec` 卡片.
    func stopLongRecording() {
        lastCaptureDurationSec = Int(elapsedSeconds.rounded())
        stopTimer()
        phase = .idle
        lastLongRecordingId = UUID()
    }

    /// LongRecordingView 里点"取消"调用 (**不** 更新 lastLongRecordingId,
    /// 所以不会插卡).
    func cancelLongRecording() {
        stopTimer()
        phase = .idle
    }

    // MARK: - Timer

    private func startTimer() {
        elapsedSeconds = 0
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            let start = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                self?.elapsedSeconds = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Derived

    var elapsedDisplay: String {
        let totalSeconds = Int(elapsedSeconds)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
