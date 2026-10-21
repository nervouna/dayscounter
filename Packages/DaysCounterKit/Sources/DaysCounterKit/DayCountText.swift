import SwiftUI

/// "12 天", or "今天" when the count is zero.
public struct DayCountText: View {
    private let days: Int
    private let size: CGFloat

    /// `days` is shown as an absolute value; `size` is the point size of the number.
    public init(days: Int, size: CGFloat) {
        self.days = abs(days)
        self.size = size
    }

    public var body: some View {
        if days == 0 {
            Text("今天")
                .font(.system(size: size * 0.8, weight: .bold, design: .rounded))
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(days, format: .number)
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("天")
                    .font(.system(size: max(size * 0.38, 11), weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
