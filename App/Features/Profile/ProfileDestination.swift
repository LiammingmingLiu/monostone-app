import Foundation

/// NavigationStack 的 value-based 目的地枚举.
///
/// 用 `.navigationDestination(for: ProfileDestination.self) { ... }` 统一 dispatch,
/// 避免在 ProfileView 里写一堆 `NavigationLink` destination 字面量.
/// (latest-apis.md 规则: iOS 16+ 使用 value-based navigation)
enum ProfileDestination: Hashable {
    case deliveryTargets
    case apiKeys
    case calendarSettings
    case privacyData
    case exportData
    case advancedSettings
}
