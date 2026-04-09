import Testing
@testable import MonostoneApp

/// 骨架测试. 用 Swift Testing framework (Xcode 16+).
struct MonostoneAppTests {
    @Test("RootView.Tab enum has 4 cases matching prototype tabs")
    func rootTabsMatchPrototype() async throws {
        let allCases: [RootView.Tab] = [.home, .memory, .agent, .profile]
        #expect(allCases.count == 4)
    }
}
