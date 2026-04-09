import Foundation

/// 完整会议纪要的 mock 数据源.
///
/// 对应 prototype `data/mock.js` 里的 `window.FULL_SUMMARIES`.
/// 这里只翻译了 rec-1 (敦敏 Series A) 的前 3 个 section, 已经覆盖所有 block 类型
/// (subheading / paragraph / quote / bullet / ordered / table), 够展示渲染能力.
enum FullSummaryStore {
    /// 按 cardId 查找
    static func summary(for cardId: String) -> FullSummary? {
        mockSummaries[cardId]
    }

    static let mockSummaries: [String: FullSummary] = [
        "rec-1": rec1,
        "rec-2": rec2
    ]

    // MARK: - rec-1

    private static let rec1 = FullSummary(
        cardId: "rec-1",
        title: "和敦敏的 Series A 跟进会 · 会议纪要",
        meta: [
            .init(key: "会议时间", value: "2026 年 4 月 9 日（周三）10:30 – 11:12"),
            .init(key: "会议时长", value: "42 分 18 秒"),
            .init(key: "参会人员", value: "敦敏（Linear Capital 合伙人）、明明（Monostone CEO）、郑灿（Linear Capital 投资总监）、马俊（Linear Capital 合伙人）"),
            .init(key: "会议项目", value: "Series A 融资 · D-Day"),
            .init(key: "会议形式", value: "线下会议 · Linear Capital 上海办公室")
        ],
        sections: [
            SummarySection(heading: "会议背景", blocks: [
                .paragraph("本次会议是 **Monostone** 与 **Linear Capital** 的 **Series A D-Day** 深度对接会议, 也是双方进入正式融资流程前的最后一次关键访谈."),
                .subheading("D-Day 前的三周铺垫"),
                .paragraph("在过去 **三周** 内, Monostone 团队与 Linear Capital 完成了 **4 轮** 前期沟通, 双方已在三件事上达成共识: 产品形态 (单硬件 + 端到端软件)、技术可行性 (双麦 + 低功耗方案验证通过)、团队背景 (硬件 / 软件 / GTM 三角齐备). 今天的 D-Day 会议目的明确 —— 做最后一轮关键投资判断."),
                .subheading("Pitch 材料的重新梳理"),
                .paragraph("明明在会议开始前一天 (**2026-04-08**) 专门重新梳理了 pitch 材料, 重点针对敦敏此前提出的 **三个疑问** 做专项回应:"),
                .orderedList([
                    "**产品定位**: Monostone 是 AI Infrastructure 项目, 还是 Closed-Loop 消费级硬件?",
                    "**竞争壁垒**: 面对 Apple / OpenAI 级别玩家时, 护城河究竟在哪?",
                    "**GTM 节奏**: 为什么跳过 Kickstarter 直接独立站 DTC?"
                ])
            ]),
            SummarySection(heading: "议题一 · Infrastructure vs Closed-Loop 产品定位", blocks: [
                .subheading("敦敏的开场直球"),
                .paragraph("会议 **10:30** 准时开始. 敦敏没有寒暄, 直接把心里盘旋多日的疑问摊在桌面上:"),
                .quote(
                    text: "Monostone 到底是一个 AI infrastructure 项目, 还是一个 closed-loop 的消费级产品? 这两个叙事我们内部几个合伙人吵了一周, 没吵出结果.",
                    author: "敦敏, 10:31"
                ),
                .subheading("明明的回答: 闭环为本, 生态为翼"),
                .paragraph("明明没有回避这个问题, 直接亮出他已经想清楚的答案:"),
                .quote(
                    text: "戒指 + App + Agent 是闭环产品, 插件生态是长期的开放性叙事. 两者不矛盾 —— 主心骨是闭环, 外延是生态.",
                    author: "刘明明, 10:34"
                ),
                .paragraph("他进一步解释: Agent 层保留开放接口 (**CLI** / **API** / **Skills**) 是为了让高阶用户和开发者能接入, 但 **这不是产品的主要价值主张**, 主要价值仍然在闭环的端到端体验上.")
            ]),
            SummarySection(heading: "议题二 · 竞争格局重估", blocks: [
                .subheading("明明的反驳: Apple 被自己的隐私框架锁死"),
                .paragraph("明明对郑灿的 \"Apple 威胁论\" 给出了完全不同的解读. 他分析说, **Apple 在 AI 穿戴领域反而是最慢的玩家**, 原因有两层:"),
                .bulletedList([
                    "**隐私框架锁死**: Apple 的品牌根基是 \"隐私\", 这让它在结构上无法做激进的 \"always listening\" 类产品.",
                    "**内部协作历史糟糕**: Apple 的 AI 团队 (**Siri**) 和硬件团队 (**Vision Pro**) 之间的协作历史上就是出名的糟糕."
                ]),
                .subheading("大厂威胁排序 (明明给出的最终版)"),
                .table(
                    headers: ["排名", "玩家", "威胁等级", "核心判断"],
                    rows: [
                        ["1", "OpenAI",   "最大",   "硬件团队 + 模型垄断 + Altman 亲自下场"],
                        ["2", "Samsung",  "中",     "已有 Galaxy Ring, 短期再做一款概率极低"],
                        ["3", "Google",   "低",     "生态封闭、跨 AI/硬件协作差"],
                        ["4", "Apple",    "最低",   "隐私框架锁死 + Siri/Vision Pro 协作差"]
                    ]
                )
            ])
        ]
    )

    // MARK: - rec-2

    private static let rec2 = FullSummary(
        cardId: "rec-2",
        title: "林啸 Memory A/B 对比测试评审 · 会议纪要",
        meta: [
            .init(key: "会议时间", value: "2026 年 4 月 8 日（周二）16:40 – 17:08"),
            .init(key: "会议时长", value: "28 分 04 秒"),
            .init(key: "参会人员", value: "林啸（Memory 模块负责人）、明明（Monostone CEO）、王浩（后端工程师）"),
            .init(key: "会议项目", value: "Monostone 后端 · Memory 模块"),
            .init(key: "会议形式", value: "线上会议 · 飞书视频")
        ],
        sections: [
            SummarySection(heading: "会议背景", blocks: [
                .paragraph("过去两周 Monostone 后端团队在 Memory 模块上运行了一个 A/B 对比实验, 评估一版新的 consolidation 策略是否值得全量上线. A 组使用林啸开发的新 branch, B 组维持原 baseline. 今天的目的是基于数据做出全量切换决策.")
            ]),
            SummarySection(heading: "关键数据", blocks: [
                .subheading("两周对比数据"),
                .table(
                    headers: ["指标", "A 组", "baseline"],
                    rows: [
                        ["Retrieval 准确率", "**85%**", "71%"],
                        ["p95 latency",    "500 ms",  "320 ms"],
                        ["Token 消耗",      "+18%",   "基准"]
                    ]
                ),
                .paragraph("A 组的优势主要在长会话场景, 短会话上 A 组和 baseline 几乎没有差异."),
                .subheading("最终决策"),
                .orderedList([
                    "短会话走 **baseline** (成熟稳定, latency 低)",
                    "长会话走 **A 组** (准确率明显更好)",
                    "林啸周五前 ship 动态切换逻辑"
                ])
            ])
        ]
    )
}
