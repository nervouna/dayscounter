import AppIntents
import DaysCounterKit
import SwiftUI
import WidgetKit

struct SinceWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKind.since, intent: SinceWidgetIntent.self, provider: SinceProvider()) { entry in
            SinceWidgetView(entry: entry)
        }
        .configurationDisplayName("追溯")
        .description("显示某个过去的日程已经过了多少天。在 App 的“追溯”里添加日程。")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #else
        [.systemSmall]
        #endif
    }
}

// MARK: - Configuration

struct SinceWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "追溯日程"
    static let description = IntentDescription("选择要追溯的日程。")

    @Parameter(title: "日程")
    var event: PinnedEventEntity?

    init() {}
}

/// A past event pinned in the app, offered as a widget configuration choice.
struct PinnedEventEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "追溯日程"
    static let defaultQuery = PinnedEventQuery()

    let id: String
    let title: String
    let date: Date

    init(_ event: DayEvent) {
        id = event.id
        title = event.title
        date = event.date
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(date.formatted(.yearMonthDay))")
    }
}

struct PinnedEventQuery: EntityQuery {
    func entities(for identifiers: [PinnedEventEntity.ID]) async throws -> [PinnedEventEntity] {
        SharedStore.shared.pinnedEvents.filter { identifiers.contains($0.id) }.map(PinnedEventEntity.init)
    }

    func suggestedEntities() async throws -> [PinnedEventEntity] {
        SharedStore.shared.pinnedEvents.map(PinnedEventEntity.init)
    }

    func defaultResult() async -> PinnedEventEntity? {
        SharedStore.shared.pinnedEvents.first.map(PinnedEventEntity.init)
    }
}

// MARK: - Timeline

struct SinceEntry: TimelineEntry {
    var date: Date
    var event: DayEvent?

    static let placeholder = SinceEntry(
        date: .now,
        event: .placeholder("搬进新家", days: -400, calendarTitle: "家庭", color: CalendarColor(red: 1, green: 0.58, blue: 0))
    )
}

struct SinceProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SinceEntry {
        .placeholder
    }

    func snapshot(for configuration: SinceWidgetIntent, in context: Context) async -> SinceEntry {
        let entry = SinceEntry(date: .now, event: event(for: configuration))
        return context.isPreview && entry.event == nil ? .placeholder : entry
    }

    func timeline(for configuration: SinceWidgetIntent, in context: Context) async -> Timeline<SinceEntry> {
        let now = Date.now
        let event = event(for: configuration)
        // Pinned events only change from the app, which reloads this widget, so midnights are enough.
        let entries = [SinceEntry(date: now, event: event)] + DayMath.midnights(after: now, count: 7).map {
            SinceEntry(date: $0, event: event)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    /// The configured event, or the first pinned one when none is chosen or it was unpinned.
    private func event(for configuration: SinceWidgetIntent) -> DayEvent? {
        let pinned = SharedStore.shared.pinnedEvents
        return pinned.first { $0.id == configuration.event?.id } ?? pinned.first
    }
}

// MARK: - Views

struct SinceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SinceEntry

    var body: some View {
        content
            .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        if let event = entry.event {
            let days = -event.days(from: entry.date)
            Group {
                switch family {
                case .accessoryCircular:
                    CircularCountView(days: days)
                case .accessoryRectangular:
                    VStack(alignment: .leading, spacing: 0) {
                        Text(event.title)
                            .font(.headline)
                            .widgetAccentable()
                        Text(days == 0 ? "今天" : "已过 \(days) 天")
                        Text(event.date, format: .yearMonthDay)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                case .accessoryInline:
                    Text(days == 0 ? "\(event.title) · 今天" : "\(event.title) · 已过 \(days) 天")
                default:
                    EventSummaryView(event: event, days: days, label: "已过", tag: "追溯", dateFormat: .yearMonthDay)
                }
            }
            .widgetURL(DeepLink.since(eventID: event.id).url)
        } else {
            WidgetMessageView(systemImage: "clock.arrow.circlepath", message: "在 DaysCounter 的“追溯”中添加日程")
        }
    }
}
