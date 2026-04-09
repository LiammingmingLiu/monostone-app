# CLAUDE.md — monostone-app 项目上下文

> 这个文件是给 Claude Code 读的项目指令。任何在这个仓库里开 session 的 AI 都会自动看到它。

---

## 这是什么项目

**Monostone iOS native app**——从 0 开始的 SwiftUI 原生应用，对标同组织的 `monostone-ios-prototype` HTML 原型。

- **仓库**：`LiammingmingLiu/monostone-app`（Private）
- **参考 prototype**：`LiammingmingLiu/monostone-ios-prototype`（Public，有完整 docs/）
- **最低部署**：iOS 26.0
- **语言**：Swift 6.0（strict concurrency 开启）
- **脚手架**：XcodeGen（`project.yml` → `xcodegen generate` → `MonostoneApp.xcodeproj`）
- **不进 git**：`MonostoneApp.xcodeproj/`、`DerivedData/`、`.build/`、用户级 workspace state

---

## 权威设计源

**所有产品 / UI / 数据 / 接口的权威定义都在 `monostone-ios-prototype` 仓库的 `docs/` 里**。优先级：

1. **`docs/pages-and-interactions.md`** — 17 个页面的 UI 区块、数据依赖、导航关系，以及所有非平凡交互的 iOS 实现复杂度估计。**新增任何 SwiftUI view 之前必读相关小节**
2. **`docs/data-models.md`** — 25+ 核心实体的 TypeScript 类型定义，直接映射到 Swift `struct` / `enum`
3. **`docs/api-contract.md`** — 50+ HTTP / WebSocket 接口契约。实现网络层时对照字段名
4. **`docs/data-flow.md`** — Memory Tree L0-L4 层级、Capture → Memory → Agent 全链路
5. **`docs/architecture.md`** — 5 层系统架构（硬件、iOS、云、外部）
6. **`docs/README.md`** — 文档索引 + 按任务的快速导航

如果 prototype 的 HTML `index.html` 和这里的 Swift 代码有分歧，**以 docs 为准**。如果 docs 和 HTML 也分歧，**以 docs 为准**，然后回头修 HTML。

**本地路径**：
```
/Users/mingmingliu/.openclaw/workspace/monostone-ios-prototype/docs/
```

---

## 目录结构

```
monostone-app/
├── project.yml                    ← XcodeGen 唯一事实来源
├── App/
│   ├── MonostoneApp.swift         ← @main App entry
│   ├── RootView.swift             ← TabView 4 root tabs
│   ├── Core/
│   │   └── Theme.swift            ← 设计令牌 (colors 来自 prototype CSS)
│   ├── Features/
│   │   ├── Home/     HomeView.swift
│   │   ├── Memory/   MemoryView.swift
│   │   ├── Agent/    AgentView.swift
│   │   └── Profile/  ProfileView.swift
│   └── Assets.xcassets/
├── AppTests/                      ← Swift Testing framework
├── .claude/
│   ├── settings.json              ← 启用项目级 skills
│   └── skills/
│       └── swiftui-expert-skill/  ← AvdLee/SwiftUI-Agent-Skill (v1, 4573a25)
├── CLAUDE.md                      ← 本文件
└── README.md
```

---

## 常用命令

```bash
# 每次修改 project.yml 后
xcodegen generate

# 构建 (模拟器, iOS 26)
xcodebuild -scheme MonostoneApp -destination 'generic/platform=iOS Simulator' build

# 跑测试
xcodebuild test -scheme MonostoneApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 打开 Xcode
xed MonostoneApp.xcodeproj
```

---

## 规则与约定

### SwiftUI 风格

- **始终使用 swiftui-expert-skill** 来做 SwiftUI 相关的 review 和重构。这个 skill 已装在 `.claude/skills/swiftui-expert-skill/`
- **优先 native SwiftUI**，避免 UIKit bridging，除非必须
- **使用 `@Observable`**（iOS 17+）而不是 `ObservableObject` + `@Published`
- **使用 `@State` / `@Bindable` / `@Environment`** 作为主要状态机制
- **Swift 6 strict concurrency**：所有跨 isolation 的调用都要明确 `Sendable` / `@MainActor` 标注
- **iOS 26+ Liquid Glass**：只在 prototype 或这个 CLAUDE.md 明确要求时启用（当前默认不开，因为第一版要先把功能对齐）
- **颜色使用 `Theme.*`**，不允许在 view 里 hardcode hex

### 命名与组织

- 一个 view 对应一个文件，命名 `XxxView.swift`
- Feature 目录下放对应的 store、model、subviews
- 所有 public API 加三行以内 doc comment

### 测试

- 用 Swift Testing framework（`import Testing`），不用 XCTest（除非 mock 老框架时）
- 测试文件命名 `XxxTests.swift`
- 业务逻辑和 view 分离，便于测试

### Git 规则

- **本仓库 Private**。不要 push 任何 secret / API key / personal info
- 每次 PR 之前跑一次 `xcodegen generate` 确保 `project.yml` 是 canonical
- Commit message 风格参考 prototype 仓库（简短主题 + 空行 + 详细 body）
- 从 memory 继承的规则：**改完代码不要问"要不要 commit / push"，直接干**

---

## 第一阶段路线图（MVP）

按复杂度从低到高：

1. **Theme + 空 TabView 骨架**（已完成 ✓）
2. **HomeView** — 卡片列表 + Filter chips（静态 mock 数据）
3. **MemoryView** — Memory Tree stats + entities 列表（静态 mock）
4. **ProfileView** — 菜单列表 + settings 子页（纯 UI）
5. **AgentView** — IM 聊天界面（最复杂，消息 5 类型 + 动画）
6. **Modals** — Full Summary + Action Item detail + Share sheet
7. **Action Items 左滑删除手势** — `UIPanGestureRecognizer` 级别的复杂交互
8. **FAB 录音按钮** — 长按 / 快点状态机
9. **数据层抽象** — `@Observable` stores 从 mock JSON 加载，未来切 URLSession
10. **戒指 BLE 层** — `CoreBluetooth` 对接 events-protocol.md

每完成一个阶段，同步更新 prototype 仓库的 docs/ 里对应的"已实现"标注。

---

## 已知注意点

- `project.yml` 里的 `DEVELOPMENT_TEAM` 是空的——真正跑真机之前需要在 Xcode 里手动签名，或者在 project.yml 里填入 Apple Developer Team ID
- `.claude/skills/swiftui-expert-skill` 是从 `AvdLee/SwiftUI-Agent-Skill@4573a25` 复制过来的快照，不是 git submodule。要升级时重新下载覆盖
- Prototype 的 `data/mock.js` 里的 `FULL_SUMMARIES` / `ACTION_ITEMS` / `MEMORY_OVERVIEW` / `AGENT_CONVERSATION` 四个对象是 iOS 版 mock 数据的源头——建议写一个简单的 Python 或 Swift script 把它们转成 Swift 字面量
