import DaysCounterKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let sources = model.calendars.map(\.sourceTitle).reduce(into: [String]()) { result, source in
            if !result.contains(source) { result.append(source) }
        }
        Form {
            ForEach(sources, id: \.self) { source in
                Section {
                    ForEach(model.calendars.filter { $0.sourceTitle == source }) { calendar in
                        Toggle(isOn: Binding(
                            get: { model.isIncluded(calendar) },
                            set: { model.setIncluded(calendar, $0) }
                        )) {
                            Label {
                                Text(calendar.title)
                            } icon: {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(calendar.color.color)
                                    .imageScale(.small)
                            }
                        }
                    }
                } header: {
                    Text(source)
                } footer: {
                    if source == sources.last {
                        Text("只计入所选日历中的全天日程。订阅日历（例如节假日）默认不计入。")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .overlay {
            if model.calendars.isEmpty {
                ContentUnavailableView("没有可用的日历", systemImage: "calendar", description: Text("允许 DaysCounter 访问日历后，可以在这里选择要计入的日历。"))
            }
        }
        .navigationTitle("重要日历")
    }
}
