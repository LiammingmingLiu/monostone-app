import SwiftUI

/// 个人中心 Tab（对应 prototype s10）
///
/// TODO（按 prototype 的 pages-and-interactions.md §8 profile 实现）:
/// - [ ] 用户头像 + 名字 + 订阅 badge
/// - [ ] 戒指连接卡片（电量 + 连接天数）
/// - [ ] 菜单 list groups 跳转各个 settings 子页
/// - [ ] 退出登录 / 重新开始引导
struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    userHeader
                    ringCard
                    placeholder
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.background)
            .navigationBarHidden(true)
        }
    }

    private var userHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Theme.panel)
                .overlay { Circle().stroke(Theme.borderStrong, lineWidth: 0.5) }
                .overlay {
                    Text("明")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.text)
                }
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 3) {
                Text("明明")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text("Max 订阅")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var ringCard: some View {
        HStack(spacing: 16) {
            Circle()
                .stroke(Theme.accent, lineWidth: 1)
                .shadow(color: Theme.accent.opacity(0.2), radius: 6)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Monostone 戒指")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text("已连接 · 第 12 天")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Text("87%")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.text)
        }
        .padding(16)
        .background(Theme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置菜单尚未实现")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            Text("参考 monostone-ios-prototype/docs/pages-and-interactions.md §8 profile 以及 §9-§14 各 settings 子页")
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
    ProfileView()
        .preferredColorScheme(.dark)
}
