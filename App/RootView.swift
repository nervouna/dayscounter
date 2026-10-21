import DaysCounterKit
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if model.authorization == .fullAccess {
                MainView()
            } else {
                AccessView()
            }
        }
        .onOpenURL { model.open($0) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
    }
}

private struct MainView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.section) {
            Tab("倒数", systemImage: "hourglass", value: AppModel.Section.upcoming) {
                UpcomingView()
            }
            Tab("追溯", systemImage: "clock.arrow.circlepath", value: AppModel.Section.since) {
                SinceView()
            }
            #if os(iOS)
            Tab("设置", systemImage: "gearshape", value: AppModel.Section.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
            #endif
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

private struct AccessView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        ContentUnavailableView {
            Label("需要访问日历", systemImage: "calendar.badge.exclamationmark")
        } description: {
            if model.authorization == .notDetermined {
                Text("DaysCounter 只读取日历中的全天日程来计算天数，不会修改任何内容。")
            } else {
                Text("日历访问未开启。请在系统设置中允许 DaysCounter 完全访问日历。")
            }
        } actions: {
            if model.authorization == .notDetermined {
                Button("允许访问日历") {
                    Task { await model.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("打开系统设置") {
                    openURL(Self.settingsURL)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private static var settingsURL: URL {
        #if os(iOS)
        URL(string: UIApplication.openSettingsURLString)!
        #else
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!
        #endif
    }
}
