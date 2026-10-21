#if DEBUG && targetEnvironment(simulator)
import DaysCounterKit
import EventKit

/// Fills an empty simulator calendar with sample events when launched with `-seedDemoEvents`.
enum DemoSeeder {
    private static let calendarTitle = "示例"
    private static let allDay: [(days: Int, title: String)] = [
        (0, "交房租"),
        (3, "年假出发"),
        (12, "妈妈生日"),
        (45, "结婚纪念日"),
        (200, "护照到期"),
        (-30, "入职新公司"),
        (-400, "搬进新家"),
        (-1000, "第一次见面"),
    ]

    static func seedIfRequested(into store: EKEventStore) {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemoEvents"),
              EventSource.hasAccess,
              !store.calendars(for: .event).contains(where: { $0.title == calendarTitle }),
              let source = store.sources.first(where: { $0.sourceType == .local }) ?? store.defaultCalendarForNewEvents?.source
        else { return }

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = calendarTitle
        calendar.source = source
        calendar.cgColor = CGColor(srgbRed: 1, green: 0.58, blue: 0, alpha: 1)
        let today = Calendar.current.startOfDay(for: .now)
        do {
            try store.saveCalendar(calendar, commit: false)
            for sample in allDay {
                let date = Calendar.current.date(byAdding: .day, value: sample.days, to: today)!
                try store.save(event(sample.title, calendar: calendar, store: store, start: date, allDay: true), span: .thisEvent, commit: false)
            }
            // A timed event, which the app should ignore.
            let meeting = Calendar.current.date(byAdding: .hour, value: 34, to: today)!
            try store.save(event("周会", calendar: calendar, store: store, start: meeting, allDay: false), span: .thisEvent, commit: false)
            try store.commit()
        } catch {
            print("DemoSeeder failed: \(error)")
        }
    }

    private static func event(_ title: String, calendar: EKCalendar, store: EKEventStore, start: Date, allDay: Bool) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = title
        event.isAllDay = allDay
        event.startDate = start
        event.endDate = allDay ? start : start.addingTimeInterval(3600)
        return event
    }
}
#endif
