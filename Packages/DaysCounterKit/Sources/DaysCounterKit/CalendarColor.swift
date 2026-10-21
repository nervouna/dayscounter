import CoreGraphics
import SwiftUI

/// A calendar color in sRGB, small enough to store alongside pinned events.
public struct CalendarColor: Hashable, Codable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(cgColor: CGColor?) {
        guard let cgColor,
              let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil),
              let components = converted.components, components.count >= 3
        else {
            self = .gray
            return
        }
        self.init(red: Double(components[0]), green: Double(components[1]), blue: Double(components[2]))
    }

    public static let gray = CalendarColor(red: 0.557, green: 0.557, blue: 0.576)

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }
}
