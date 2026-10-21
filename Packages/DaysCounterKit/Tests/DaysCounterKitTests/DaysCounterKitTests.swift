import Foundation
import Testing
@testable import DaysCounterKit

private func calendar(_ timeZone: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: timeZone)!
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, in calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

private func event(_ title: String, on day: Date) -> DayEvent {
    DayEvent(id: "\(title)@\(day.timeIntervalSince1970)", title: title, date: day, calendarTitle: "Home", color: .gray)
}

@Suite struct DayMathTests {
    let shanghai = calendar("Asia/Shanghai")
    let newYork = calendar("America/New_York")

    @Test func countsWholeCalendarDays() {
        let now = date(2026, 10, 22, 23, 59, in: shanghai)
        #expect(DayMath.days(from: now, to: date(2026, 10, 22, in: shanghai), calendar: shanghai) == 0)
        #expect(DayMath.days(from: now, to: date(2026, 10, 23, in: shanghai), calendar: shanghai) == 1)
        #expect(DayMath.days(from: now, to: date(2027, 1, 1, in: shanghai), calendar: shanghai) == 71)
        #expect(DayMath.days(from: now, to: date(2025, 10, 22, in: shanghai), calendar: shanghai) == -365)
    }

    @Test func ignoresDaylightSavingTransitions() {
        // US clocks spring forward on 2026-03-08 and fall back on 2026-11-01.
        let before = date(2026, 3, 7, 12, in: newYork)
        #expect(DayMath.days(from: before, to: date(2026, 3, 9, in: newYork), calendar: newYork) == 2)
        let autumn = date(2026, 10, 31, 23, in: newYork)
        #expect(DayMath.days(from: autumn, to: date(2026, 11, 2, in: newYork), calendar: newYork) == 2)
    }

    @Test func upcomingKeepsTodayDropsPastAndSorts() {
        let now = date(2026, 10, 22, 15, in: shanghai)
        let events = [
            event("Later", on: date(2026, 12, 1, in: shanghai)),
            event("Yesterday", on: date(2026, 10, 21, in: shanghai)),
            event("Today B", on: date(2026, 10, 22, in: shanghai)),
            event("Today A", on: date(2026, 10, 22, in: shanghai)),
        ]
        let titles = DayMath.upcoming(events, from: now, calendar: shanghai).map(\.title)
        #expect(titles == ["Today A", "Today B", "Later"])
    }

    @Test func midnightsFollowReference() {
        let now = date(2026, 10, 22, 15, in: shanghai)
        let midnights = DayMath.midnights(after: now, count: 3, calendar: shanghai)
        #expect(midnights == [
            date(2026, 10, 23, in: shanghai),
            date(2026, 10, 24, in: shanghai),
            date(2026, 10, 25, in: shanghai),
        ])
    }
}

@Suite struct CalendarSelectionTests {
    let home = CalendarInfo(id: "home", title: "Home", sourceTitle: "iCloud", color: .gray, isSubscription: false)
    let holidays = CalendarInfo(id: "holidays", title: "Holidays", sourceTitle: "Other", color: .gray, isSubscription: true)

    @Test func automaticSkipsSubscriptions() {
        #expect(CalendarSelection.automatic.includes(home))
        #expect(!CalendarSelection.automatic.includes(holidays))
    }

    @Test func firstChangeMaterializesTheDefault() {
        let selection = CalendarSelection.automatic.setting(holidays, included: true, among: [home, holidays])
        #expect(selection.includedIDs == ["home", "holidays"])
        let narrowed = selection.setting(home, included: false, among: [home, holidays])
        #expect(narrowed.includedIDs == ["holidays"])
        #expect(!narrowed.includes(home))
    }
}

@Suite struct SharedStoreTests {
    @Test func roundTripsSettingsAndPins() throws {
        let suite = "DaysCounterKitTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SharedStore(defaults: defaults)

        #expect(store.calendarSelection == .automatic)
        #expect(store.pinnedEvents.isEmpty)

        let pinned = event("Moved in", on: Date(timeIntervalSince1970: 1_700_000_000))
        store.calendarSelection = CalendarSelection(includedIDs: ["home"])
        store.pinnedEvents = [pinned]

        #expect(store.calendarSelection.includedIDs == ["home"])
        #expect(store.pinnedEvents == [pinned])
    }
}

@Suite struct DeepLinkTests {
    @Test(arguments: [
        DeepLink.upcoming(eventID: "ABC-123@1761062400"),
        DeepLink.since(eventID: "id with spaces/&?"),
    ])
    func roundTrips(link: DeepLink) {
        #expect(DeepLink(url: link.url) == link)
    }

    @Test func rejectsForeignURLs() {
        #expect(DeepLink(url: URL(string: "https://example.com/upcoming?id=1")!) == nil)
        #expect(DeepLink(url: URL(string: "dayscounter://unknown?id=1")!) == nil)
    }
}
