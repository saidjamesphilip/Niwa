import WidgetKit
import SwiftUI

@main
struct NiwaWidgetBundle: WidgetBundle {
    var body: some Widget {
        NiwaWidget()
    }
}

struct NiwaWidget: Widget {
    let kind: String = "NiwaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NiwaTimelineProvider()) { entry in
            NiwaWidgetView(entry: entry)
        }
        .configurationDisplayName("Niwa")
        .description("Your productivity garden at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct NiwaWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NiwaWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
