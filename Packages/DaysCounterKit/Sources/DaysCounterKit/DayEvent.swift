import Foundation

/// One occurrence of an all-day calendar event, reduced to what the app and widgets display.
public struct DayEvent: Identifiable, Hashable, Codable, Sendable {
    /// Unique per occurrence, so every instance of a recurring event is distinct.
    public var id: String
    public var title: String
    /// Midnight at the start of the occurrence's first day.
    public var date: Date
    public var calendarTitle: String
    public var color: CalendarColor

    public init(id: String, title: String, date: Date, calendarTitle: String, color: CalendarColor) {
        self.id = id
        self.title = title
        self.date = date
        self.calendarTitle = calendarTitle
        self.color = color
    }

    /// Calendar days from `reference` to this event; negative once the event is in the past.
    public func days(from reference: Date, calendar: Calendar = .current) -> Int {
        DayMath.days(from: reference, to: date, calendar: calendar)
    }
}
