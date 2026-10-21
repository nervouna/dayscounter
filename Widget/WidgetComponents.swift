import DaysCounterKit
import SwiftUI
import WidgetKit

extension DayEvent {
    static func placeholder(_ title: String, days: Int, calendarTitle: String, color: CalendarColor) -> DayEvent {
        let today = Calendar.current.startOfDay(for: .now)
        let date = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        return DayEvent(id: "placeholder-\(title)", title: title, date: date, calendarTitle: calendarTitle, color: color)
    }
}

/// Calendar color dot followed by a short caption.
struct CaptionTag: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
    }
}

/// The small-widget layout shared by the countdown and since widgets.
struct EventSummaryView: View {
    let event: DayEvent
    /// Signed day count; shown as an absolute value.
    let days: Int
    /// "还有" or "已过", hidden on the day itself.
    let label: String
    let tag: String
    let dateFormat: Date.FormatStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CaptionTag(color: event.color.color, text: tag)
            Text(event.title)
                .font(.headline)
                .lineLimit(2)
                .padding(.top, 2)
            Spacer(minLength: 0)
            if days != 0 {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            DayCountText(days: days, size: 40)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .widgetAccentable()
            Text(event.date, format: dateFormat)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Day count for the circular lock screen widget.
struct CircularCountView: View {
    let days: Int

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if days == 0 {
                Text("今天")
                    .font(.system(.headline, design: .rounded).weight(.bold))
            } else {
                VStack(spacing: -2) {
                    Text(abs(days), format: .number)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("天")
                        .font(.caption2)
                }
                .padding(.horizontal, 4)
            }
        }
        .widgetAccentable()
    }
}

/// Shown when a widget has nothing to display.
struct WidgetMessageView: View {
    @Environment(\.widgetFamily) private var family
    let systemImage: String
    let message: String

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: systemImage)
                    .font(.title3)
            }
        case .accessoryInline:
            Label(message, systemImage: systemImage)
        case .accessoryRectangular:
            Label(message, systemImage: systemImage)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension FormatStyle where Self == Date.FormatStyle {
    static var monthDayWeekday: Self { .dateTime.month().day().weekday() }
    static var yearMonthDay: Self { .dateTime.year().month().day() }
}
