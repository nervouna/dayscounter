import DaysCounterKit
import SwiftUI

enum CountMode {
    case countdown, since
}

struct EventRow: View {
    let event: DayEvent
    /// Signed day count from today.
    let days: Int
    var showsYear = false

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(event.color.color)
                .frame(width: 4, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .lineLimit(1)
                Text("\(event.date, format: showsYear ? .dateTime.year().month().day().weekday() : .dateTime.month().day().weekday()) · \(event.calendarTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            DayCountText(days: days, size: 22)
        }
        .padding(.vertical, 2)
    }
}

struct EventDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let event: DayEvent
    let mode: CountMode

    var body: some View {
        let days = event.days(from: model.today)
        Form {
            Section {
                VStack(spacing: 6) {
                    if days != 0 {
                        Text(mode == .countdown ? "还有" : "已经过去")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    DayCountText(days: days, size: 64)
                        .foregroundStyle(event.color.color)
                    Text(event.title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section {
                LabeledContent("日期") {
                    Text(event.date, format: .dateTime.year().month().day().weekday(.wide))
                }
                LabeledContent("日历") {
                    Label {
                        Text(event.calendarTitle)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(event.color.color)
                            .imageScale(.small)
                    }
                }
            }

            #if os(iOS)
            Section {
                Button("在日历中查看", systemImage: "calendar") {
                    openURL(URL(string: "calshow:\(Int(event.date.timeIntervalSinceReferenceDate))")!)
                }
            }
            #endif

            if mode == .since {
                Section {
                    Button("取消追溯", systemImage: "pin.slash", role: .destructive) {
                        model.unpin(event)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(event.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
