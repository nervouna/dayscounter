import DaysCounterKit
import SwiftUI

struct UpcomingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.upcomingPath) {
            List(model.upcoming) { event in
                NavigationLink(value: event) {
                    EventRow(event: event, days: event.days(from: model.today))
                }
            }
            .overlay {
                if model.upcoming.isEmpty {
                    ContentUnavailableView(
                        "没有即将到来的日程",
                        systemImage: "calendar",
                        description: Text("所选日历在未来一年内没有全天日程。")
                    )
                }
            }
            .navigationTitle("倒数")
            .navigationDestination(for: DayEvent.self) { event in
                EventDetailView(event: event, mode: .countdown)
            }
            .refreshable { model.refresh() }
        }
    }
}
