import Foundation

/// Day arithmetic shared by the app and the widgets. Everything counts whole calendar days,
/// so a count only changes at midnight, never in the middle of a day.
public enum DayMath {
    /// Calendar days from the day of `start` to the day of `end`; negative when `end` is earlier.
    public static func days(from start: Date, to end: Date, calendar: Calendar = .current) -> Int {
        let from = calendar.startOfDay(for: start)
        let to = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// Events on or after the day of `reference`, soonest first.
    public static func upcoming(_ events: [DayEvent], from reference: Date, calendar: Calendar = .current) -> [DayEvent] {
        events
            .filter { $0.days(from: reference, calendar: calendar) >= 0 }
            .sorted { ($0.date, $0.title) < ($1.date, $1.title) }
    }

    /// The next `count` midnights strictly after `reference`.
    public static func midnights(after reference: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: reference)
        for _ in 0..<count {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            result.append(next)
            day = next
        }
        return result
    }
}
