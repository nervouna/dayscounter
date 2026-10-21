import DaysCounterKit
import EventKit
import Observation
import SwiftUI
import WidgetKit

@MainActor
@Observable
final class AppModel {
    enum Section: Hashable {
        case upcoming, since, settings
    }

    var section: Section = .upcoming
    var upcomingPath: [DayEvent] = []
    var sincePath: [DayEvent] = []

    private(set) var authorization = EventSource.authorizationStatus
    private(set) var calendars: [CalendarInfo] = []
    private(set) var upcoming: [DayEvent] = []
    private(set) var pinned: [DayEvent]
    private(set) var selection: CalendarSelection
    /// Reference date for every day count on screen; refreshed whenever the day may have changed.
    private(set) var today = Date.now

    @ObservationIgnored private let source = EventSource()
    @ObservationIgnored private let store = SharedStore.shared
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    init() {
        pinned = store.pinnedEvents
        selection = store.calendarSelection
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: .EKEventStoreChanged, object: source.store, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.calendarDidChange() }
            },
            center.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.calendarDidChange() }
            },
        ]
        #if DEBUG && targetEnvironment(simulator)
        DemoSeeder.seedIfRequested(into: source.store)
        #endif
        refresh()
    }

    func refresh() {
        authorization = EventSource.authorizationStatus
        today = .now
        guard authorization == .fullAccess else {
            calendars = []
            upcoming = []
            return
        }
        calendars = source.calendars()
        upcoming = source.upcomingEvents(from: today, selection: selection)
    }

    func requestAccess() async {
        _ = try? await source.requestAccess()
        calendarDidChange()
    }

    private func calendarDidChange() {
        refresh()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Calendars

    func isIncluded(_ calendar: CalendarInfo) -> Bool {
        selection.includes(calendar)
    }

    func setIncluded(_ calendar: CalendarInfo, _ included: Bool) {
        selection = selection.setting(calendar, included: included, among: calendars)
        store.calendarSelection = selection
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.countdown)
    }

    // MARK: Pinned events

    func pastEvents() async -> [DayEvent] {
        let source = source
        let selection = selection
        let today = today
        return await Task.detached {
            source.pastEvents(before: today, selection: selection)
        }.value
    }

    func isPinned(_ event: DayEvent) -> Bool {
        pinned.contains { $0.id == event.id }
    }

    func pin(_ event: DayEvent) {
        guard !isPinned(event) else { return }
        pinned.append(event)
        pinned.sort { $0.date > $1.date }
        savePinned()
    }

    func unpin(_ event: DayEvent) {
        pinned.removeAll { $0.id == event.id }
        sincePath.removeAll { $0.id == event.id }
        savePinned()
    }

    func unpin(at offsets: IndexSet) {
        offsets.map { pinned[$0] }.forEach(unpin)
    }

    private func savePinned() {
        store.pinnedEvents = pinned
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.since)
    }

    // MARK: Deep links

    func open(_ url: URL) {
        switch DeepLink(url: url) {
        case .upcoming(let id):
            refresh()
            section = .upcoming
            upcomingPath = upcoming.first { $0.id == id }.map { [$0] } ?? []
        case .since(let id):
            section = .since
            sincePath = pinned.first { $0.id == id }.map { [$0] } ?? []
        case nil:
            break
        }
    }
}
