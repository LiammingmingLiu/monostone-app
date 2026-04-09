import SwiftUI

/// 长录音进行中的全屏 overlay (对应 prototype s7 `record_long`).
///
/// 通过 HomeView 的 `.fullScreenCover` 呈现. 展示:
/// - 顶部: 取消按钮 + "正在聆听" 副标题
/// - 中间: 大号 mm:ss 计时器 + 中央 WaveformView 律动波形
/// - context chips: "已加载上下文 · Series A" 示意
/// - 底部: 巨大的红色停止按钮
///
/// 真正的音频采集 (AVAudioRecorder / BLE 上传) 是 Step 9-10 的事, 这里只管 UI.
struct LongRecordingView: View {
    let store: RecordingStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 36) {
                topBar
                listeningHeader
                WaveformView(barCount: 12, minHeight: 20, maxHeight: 92)
                    .frame(height: 100)
                contextChips
                Spacer()
                stopButton
                    .padding(.bottom, 36)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .statusBarHidden(false)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                store.cancelLongRecording()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 34, height: 34)
                    .background(Theme.panel)
                    .overlay { Circle().stroke(Theme.border, lineWidth: 0.5) }
                    .clipShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("取消录音")
            Spacer()
        }
    }

    // MARK: - Listening header

    private var listeningHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.red.opacity(0.6), radius: 4)
                Text("正在聆听")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textDim)
                    .tracking(0.5)
            }

            Text(store.elapsedDisplay)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
                .monospacedDigit()
                .padding(.top, 2)
        }
    }

    // MARK: - Context chips

    private var contextChips: some View {
        VStack(spacing: 8) {
            Text("已加载上下文")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textDimmer)
                .tracking(1.2)

            HStack(spacing: 6) {
                chip("Series A", systemImage: "briefcase")
                chip("敦敏 · Linear", systemImage: "person")
                chip("4/9 10:30", systemImage: "clock")
            }
        }
    }

    private func chip(_ label: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.accent.opacity(0.12))
        .overlay { Capsule().stroke(Theme.accent.opacity(0.4), lineWidth: 0.5) }
        .clipShape(.capsule)
    }

    // MARK: - Stop button

    private var stopButton: some View {
        Button {
            store.stopLongRecording()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.16))
                    .frame(width: 96, height: 96)
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 96, height: 96)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red)
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.red.opacity(0.6), radius: 10)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("停止录音")
    }
}

#Preview {
    LongRecordingView(store: {
        let s = RecordingStore()
        s.handleTouchDown()
        s.handleTouchUp()
        return s
    }())
    .preferredColorScheme(.dark)
}
