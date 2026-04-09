# Monostone iOS Native App

> Native SwiftUI implementation of the Monostone AI memory ring iOS app.
>
> The HTML prototype lives at [`monostone-ios-prototype`](https://github.com/LiammingmingLiu/monostone-ios-prototype) — **all product specs, data models, API contracts, and interaction design are authored there in `docs/`**. This repo is the Swift implementation.

---

## Stack

| Layer | Choice |
|---|---|
| Language | Swift 6.0 (strict concurrency) |
| UI | SwiftUI |
| Deployment target | iOS 26.0 |
| Xcode | 26.2+ |
| Project generator | [XcodeGen](https://github.com/yonaskolb/XcodeGen) via `project.yml` |
| Testing | [Swift Testing](https://developer.apple.com/documentation/testing) framework |
| AI coding assistant | Claude Code + [SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) (installed at project level) |

---

## Quick start

```bash
# 1. Install XcodeGen if not already
brew install xcodegen

# 2. Generate the .xcodeproj from project.yml
xcodegen generate

# 3. Open in Xcode
xed MonostoneApp.xcodeproj

# 4. Or build from CLI
xcodebuild -scheme MonostoneApp \
  -destination 'generic/platform=iOS Simulator' build
```

**Note**: `MonostoneApp.xcodeproj` is NOT committed — it's fully derivable from `project.yml`. Always run `xcodegen generate` after pulling.

---

## Project structure

```
monostone-app/
├── project.yml              ← XcodeGen single source of truth
├── App/
│   ├── MonostoneApp.swift   ← @main App entry
│   ├── RootView.swift       ← 4-tab TabView
│   ├── Core/Theme.swift     ← Design tokens (colors from HTML prototype)
│   ├── Features/
│   │   ├── Home/
│   │   ├── Memory/
│   │   ├── Agent/
│   │   └── Profile/
│   └── Assets.xcassets/
├── AppTests/
├── .claude/                 ← Project-level Claude Code config
│   ├── settings.json
│   └── skills/swiftui-expert-skill/
├── CLAUDE.md                ← AI assistant context
└── README.md
```

---

## Design authority

All product decisions live in the HTML prototype repo:

```
monostone-ios-prototype/docs/
├── README.md                     ← start here
├── architecture.md
├── data-flow.md
├── pages-and-interactions.md     ← ⭐️ primary iOS reference
├── data-models.md                ← entity → Swift struct mapping
├── api-contract.md               ← networking layer reference
├── oauth-flows.md
├── events-protocol.md
├── semantic-map.md
└── sharing-spec.md
```

Keep this repo in sync with those docs. If a design change is needed, update the docs first, then implement here.

---

## Roadmap

See `CLAUDE.md` → "第一阶段路线图" for the implementation order:

1. Theme + TabView skeleton ✅
2. HomeView (cards + filters)
3. MemoryView (Memory Tree + entities)
4. ProfileView (settings)
5. AgentView (IM chat — most complex)
6. Modals (Full Summary / Action Item / Share)
7. Action Items swipe-to-delete gesture
8. FAB recording button state machine
9. Data layer (@Observable stores)
10. Ring BLE integration (CoreBluetooth)

---

## License

Private repository. All rights reserved.
