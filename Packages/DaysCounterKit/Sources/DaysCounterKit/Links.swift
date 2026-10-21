import Foundation

/// Widget kinds, shared so the app can reload a specific widget.
public enum WidgetKind {
    public static let countdown = "io.damao.DaysCounter.Countdown"
    public static let since = "io.damao.DaysCounter.Since"
}

/// URLs a widget opens to show one event in the app.
public enum DeepLink: Hashable, Sendable {
    case upcoming(eventID: String)
    case since(eventID: String)

    public static let scheme = "dayscounter"

    public var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        switch self {
        case .upcoming(let id):
            components.host = "upcoming"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        case .since(let id):
            components.host = "since"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        }
        return components.url!
    }

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == Self.scheme,
              let id = components.queryItems?.first(where: { $0.name == "id" })?.value
        else { return nil }
        switch components.host {
        case "upcoming": self = .upcoming(eventID: id)
        case "since": self = .since(eventID: id)
        default: return nil
        }
    }
}
