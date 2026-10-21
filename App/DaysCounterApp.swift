import SwiftUI

@main
struct DaysCounterApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        #if os(macOS)
        .defaultSize(width: 760, height: 560)
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(model)
                .frame(width: 420, height: 480)
        }
        #endif
    }
}
