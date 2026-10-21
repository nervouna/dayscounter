import DaysCounterKit
import SwiftUI
import WidgetKit

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.countdown, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("倒数日")
        .description("显示下一个全天日程还有几天。")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }
}

struct CountdownEntry: TimelineEntry {
    enum Content {
        case events([DayEvent])
        case noAccess
    }

    var date: Date
    var content: Content

    /// Events still upcoming at this entry's date, soonest first.
    var upcoming: [DayEvent] {
        guard case .events(let events) = content else { return [] }
        return DayMath.upcoming(events, from: date)
    }

    static let placeholder = CountdownEntry(date: .now, content: .events([
        .placeholder("妈妈生日", days: 12, calendarTitle: "家庭", color: CalendarColor(red: 1, green: 0.23, blue: 0.19)),
        .placeholder("年假出发", days: 30, calendarTitle: "个人", color: CalendarColor(red: 0, green: 0.48, blue: 1)),
        .placeholder("结婚纪念日", days: 45, calendarTitle: "家庭", color: CalendarColor(red: 1, green: 0.23, blue: 0.19)),
        .placeholder("护照到期", days: 200, calendarTitle: "个人", color: CalendarColor(red: 0, green: 0.48, blue: 1)),
    ]))
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let entry = load(at: .now)
        // The widget gallery should show something even before access is granted.
        completion(context.isPreview && entry.upcoming.isEmpty ? .placeholder : entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now = Date.now
        let current = load(at: now)
        // Counts change at midnight, so each coming midnight gets its own entry.
        let entries = [current] + DayMath.midnights(after: now, count: 7).map {
            CountdownEntry(date: $0, content: current.content)
        }
        // Calendar edits made in other apps don't reach the widget, so re-read periodically.
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
    }

    private func load(at date: Date) -> CountdownEntry {
        guard EventSource.hasAccess else { return CountdownEntry(date: date, content: .noAccess) }
        let events = EventSource().upcomingEvents(from: date, selection: SharedStore.shared.calendarSelection)
        return CountdownEntry(date: date, content: .events(Array(events.prefix(20))))
    }
}

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        content
            .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        let events = entry.upcoming
        if case .noAccess = entry.content {
            WidgetMessageView(systemImage: "calendar.badge.exclamationmark", message: "打开 DaysCounter 允许访问日历")
        } else if let next = events.first {
            let days = next.days(from: entry.date)
            Group {
                switch family {
                case .systemMedium:
                    MediumCountdownView(next: next, rest: Array(events.dropFirst().prefix(3)), now: entry.date)
                case .accessoryCircular:
                    CircularCountView(days: days)
                case .accessoryRectangular:
                    VStack(alignment: .leading, spacing: 0) {
                        Text(next.title)
                            .font(.headline)
                            .widgetAccentable()
                        Text(days == 0 ? "今天" : "还有 \(days) 天")
                        Text(next.date, format: .monthDayWeekday)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                case .accessoryInline:
                    Text(days == 0 ? "\(next.title) · 今天" : "\(next.title) · \(days) 天")
                default:
                    EventSummaryView(event: next, days: days, label: "还有", tag: next.calendarTitle, dateFormat: .monthDayWeekday)
                }
            }
            .widgetURL(DeepLink.upcoming(eventID: next.id).url)
        } else {
            WidgetMessageView(systemImage: "calendar", message: "未来一年没有全天日程")
        }
    }
}

private struct MediumCountdownView: View {
    let next: DayEvent
    let rest: [DayEvent]
    let now: Date

    var body: some View {
        HStack(spacing: 16) {
            EventSummaryView(event: next, days: next.days(from: now), label: "还有", tag: next.calendarTitle, dateFormat: .monthDayWeekday)
            VStack(alignment: .leading, spacing: 8) {
                Text("接下来")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                if rest.isEmpty {
                    Text("没有更多日程")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                ForEach(rest) { event in
                    Link(destination: DeepLink.upcoming(eventID: event.id).url) {
                        row(event)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func row(_ event: DayEvent) -> some View {
        let days = event.days(from: now)
        return HStack(spacing: 6) {
            Capsule()
                .fill(event.color.color)
                .frame(width: 3, height: 14)
            Text(event.title)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(days == 0 ? "今天" : "\(days) 天")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
