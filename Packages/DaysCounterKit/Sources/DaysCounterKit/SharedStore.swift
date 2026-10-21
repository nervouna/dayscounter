import Foundation

/// Settings and pinned events, stored in the App Group so the widget extension sees them too.
public struct SharedStore: @unchecked Sendable {
    public static let appGroupID = "group.io.damao.DaysCounter"
    public static let shared = SharedStore(defaults: UserDefaults(suiteName: appGroupID) ?? .standard)

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public var calendarSelection: CalendarSelection {
        get { decode(CalendarSelection.self, forKey: Key.calendarSelection) ?? .automatic }
        nonmutating set { encode(newValue, forKey: Key.calendarSelection) }
    }

    /// Past events the user chose to count up from.
    public var pinnedEvents: [DayEvent] {
        get { decode([DayEvent].self, forKey: Key.pinnedEvents) ?? [] }
        nonmutating set { encode(newValue, forKey: Key.pinnedEvents) }
    }

    private enum Key {
        static let calendarSelection = "calendarSelection"
        static let pinnedEvents = "pinnedEvents"
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
