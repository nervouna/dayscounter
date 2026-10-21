import Foundation

/// A calendar the user can include or exclude.
public struct CalendarInfo: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var sourceTitle: String
    public var color: CalendarColor
    /// Subscribed calendars, such as public holidays.
    public var isSubscription: Bool

    public init(id: String, title: String, sourceTitle: String, color: CalendarColor, isSubscription: Bool) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
        self.color = color
        self.isSubscription = isSubscription
    }
}

/// Which calendars count as important.
public struct CalendarSelection: Codable, Hashable, Sendable {
    /// `nil` until the user changes anything, which means every calendar except subscriptions.
    /// After the first change every included calendar is listed explicitly.
    public var includedIDs: Set<String>?

    public init(includedIDs: Set<String>? = nil) {
        self.includedIDs = includedIDs
    }

    public static let automatic = CalendarSelection()

    public func includes(_ calendar: CalendarInfo) -> Bool {
        includedIDs?.contains(calendar.id) ?? !calendar.isSubscription
    }

    public func setting(_ calendar: CalendarInfo, included: Bool, among all: [CalendarInfo]) -> CalendarSelection {
        var ids = includedIDs ?? Set(all.filter(includes).map(\.id))
        if included {
            ids.insert(calendar.id)
        } else {
            ids.remove(calendar.id)
        }
        return CalendarSelection(includedIDs: ids)
    }
}
