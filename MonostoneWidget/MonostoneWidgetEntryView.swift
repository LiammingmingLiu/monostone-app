import SwiftUI
import WidgetKit

/// 按 WidgetFamily 分发到具体的 widget view.
struct MonostoneWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MonostoneWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .systemSmall:
            SystemSmallView(entry: entry)
        case .systemMedium:
            SystemMediumView(entry: entry)
        default:
            // systemLarge, systemExtraLarge 等暂不支持
            Text("Monostone")
        }
    }
}
