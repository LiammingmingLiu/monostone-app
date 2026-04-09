import SwiftUI

/// Agent 聊天 Tab（对应 prototype s9，IM 风格）
///
/// TODO（按 prototype 的 pages-and-interactions.md §7.6 agent_tab 实现）:
/// - [ ] 自定义导航栏：脉动头像 + "Agent" + 在线状态点 + 模型说明
/// - [ ] 消息列表 ScrollView + ScrollViewReader，支持 5 种消息类型:
///       text / steps / attachment / actions / typing
/// - [ ] 气泡入场动画（bubble-in keyframes → SwiftUI .transition）
/// - [ ] Typing indicator（3 点波浪跳动）
/// - [ ] 底部输入栏 + 麦克风 + 发送按钮（处理键盘 avoidance）
/// - [ ] 数据从 `GET /v1/agent/conversation` 拉取（当前只读 mock.js 的 AGENT_CONVERSATION）
/// - [ ] 发送消息走 `POST /v1/agent/messages` + WebSocket stream
struct AgentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    placeholder
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.accent.opacity(0.12))
                .overlay { Circle().stroke(Theme.accent, lineWidth: 0.5) }
                .frame(width: 34, height: 34)
                .shadow(color: Theme.accent.opacity(0.2), radius: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text("Agent")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 5) {
                    Circle()
                        .fill(Theme.typeTodo)
                        .frame(width: 5, height: 5)
                        .shadow(color: Theme.typeTodo.opacity(0.6), radius: 3)
                    Text("在线 · Claude Opus 4.6 · 已加载 42 天 context")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textDim)
                }
            }
            Spacer()
        }
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IM 聊天界面尚未实现")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            Text("参考 monostone-ios-prototype/docs/pages-and-interactions.md §7.6 agent_tab")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDimmer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    AgentView()
        .preferredColorScheme(.dark)
}
