import EventKit

/// Read-only access to the system calendar, used by both the app and the widget extension.
public final class EventSource: @unchecked Sendable {
    public let store = EKEventStore()

    public init() {}

    public static var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    public static var hasAccess: Bool {
        authorizationStatus == .fullAccess
    }

    @discardableResult
    public func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    public func calendars() -> [CalendarInfo] {
        store.calendars(for: .event)
            .map(Self.info(for:))
            .sorted { ($0.sourceTitle, $0.title) < ($1.sourceTitle, $1.title) }
    }

    /// All-day events starting today or later, soonest first.
    public func upcomingEvents(
        from reference: Date,
        selection: CalendarSelection,
        days: Int = 366,
        calendar: Calendar = .current
    ) -> [DayEvent] {
        let start = calendar.startOfDay(for: reference)
        guard let end = calendar.date(byAdding: .day, value: days, to: start) else { return [] }
        return DayMath.upcoming(events(from: start, to: end, selection: selection, calendar: calendar), from: reference, calendar: calendar)
    }

    /// All-day events that started today or earlier, most recent first.
    public func pastEvents(
        before reference: Date,
        selection: CalendarSelection,
        years: Int = 10,
        calendar: Calendar = .current
    ) -> [DayEvent] {
        let today = calendar.startOfDay(for: reference)
        guard var end = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }
        var result: [DayEvent] = []
        // EventKit only searches up to four years per predicate, so walk back one year at a time.
        for _ in 0..<years {
            guard let start = calendar.date(byAdding: .year, value: -1, to: end) else { break }
            result += events(from: start, to: end, selection: selection, calendar: calendar)
            end = start
        }
        return result.sorted { ($0.date, $0.title) > ($1.date, $1.title) }
    }

    /// All-day events that start within `start..<end`.
    private func events(from start: Date, to end: Date, selection: CalendarSelection, calendar: Calendar) -> [DayEvent] {
        let calendars = store.calendars(for: .event).filter { selection.includes(Self.info(for: $0)) }
        // An empty list would mean "all calendars" to EventKit.
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate)
            .filter { $0.isAllDay && $0.startDate >= start && $0.startDate < end }
            .map { Self.dayEvent(from: $0, calendar: calendar) }
    }

    private static func info(for calendar: EKCalendar) -> CalendarInfo {
        CalendarInfo(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            sourceTitle: calendar.source?.title ?? "",
            color: CalendarColor(cgColor: calendar.cgColor),
            isSubscription: calendar.type == .subscription
        )
    }

    private static func dayEvent(from event: EKEvent, calendar: Calendar) -> DayEvent {
        let day = calendar.startOfDay(for: event.startDate)
        let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return DayEvent(
            id: "\(event.calendarItemIdentifier)@\(Int(day.timeIntervalSince1970))",
            title: title.isEmpty ? "无标题" : title,
            date: day,
            calendarTitle: event.calendar?.title ?? "",
            color: CalendarColor(cgColor: event.calendar?.cgColor)
        )
    }
}
