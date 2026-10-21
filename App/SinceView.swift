import DaysCounterKit
import SwiftUI

struct SinceView: View {
    @Environment(AppModel.self) private var model
    @State private var isPicking = false

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.sincePath) {
            List {
                ForEach(model.pinned) { event in
                    NavigationLink(value: event) {
                        EventRow(event: event, days: event.days(from: model.today), showsYear: true)
                    }
                    .contextMenu {
                        Button("取消追溯", systemImage: "pin.slash", role: .destructive) {
                            model.unpin(event)
                        }
                    }
                }
                .onDelete { model.unpin(at: $0) }
            }
            .overlay {
                if model.pinned.isEmpty {
                    ContentUnavailableView {
                        Label("还没有追溯的日程", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("从过去的全天日程中选一个，看看已经过去了多少天。")
                    } actions: {
                        Button("选择日程") { isPicking = true }
                    }
                }
            }
            .navigationTitle("追溯")
            .navigationDestination(for: DayEvent.self) { event in
                EventDetailView(event: event, mode: .since)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("添加", systemImage: "plus") { isPicking = true }
                }
            }
            .sheet(isPresented: $isPicking) {
                PastEventPicker()
            }
        }
    }
}

private struct PastEventPicker: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var events: [DayEvent]?
    @State private var query = ""

    var body: some View {
        NavigationStack {
            Group {
                if let events {
                    list(of: events)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .searchable(text: $query, prompt: "搜索日程")
            .navigationTitle("选择过去的日程")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .task { events = await model.pastEvents() }
        }
        #if os(macOS)
        // Sheets size to their ideal frame; keep it shorter than the main window's default height.
        .frame(minWidth: 400, idealWidth: 460, minHeight: 320, idealHeight: 440)
        #endif
    }

    private func list(of events: [DayEvent]) -> some View {
        let years = groupedByYear(matching(events))
        return List {
            ForEach(years, id: \.year) { group in
                Section {
                    ForEach(group.events) { event in
                        Button {
                            model.pin(event)
                            dismiss()
                        } label: {
                            HStack {
                                EventRow(event: event, days: event.days(from: model.today), showsYear: true)
                                if model.isPinned(event) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isPinned(event))
                    }
                } header: {
                    Text(group.events[0].date, format: .dateTime.year())
                }
            }
        }
        .overlay {
            if years.isEmpty {
                if query.isEmpty {
                    ContentUnavailableView(
                        "没有过去的全天日程",
                        systemImage: "calendar",
                        description: Text("所选日历在过去十年内没有全天日程。")
                    )
                } else {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
    }

    private func matching(_ events: [DayEvent]) -> [DayEvent] {
        guard !query.isEmpty else { return events }
        return events.filter {
            $0.title.localizedStandardContains(query) || $0.calendarTitle.localizedStandardContains(query)
        }
    }

    /// Most recent year first; `events` is already sorted most recent first.
    private func groupedByYear(_ events: [DayEvent]) -> [(year: Int, events: [DayEvent])] {
        let calendar = Calendar.current
        var groups: [(year: Int, events: [DayEvent])] = []
        for event in events {
            let year = calendar.component(.year, from: event.date)
            if groups.last?.year == year {
                groups[groups.count - 1].events.append(event)
            } else {
                groups.append((year, [event]))
            }
        }
        return groups
    }
}
