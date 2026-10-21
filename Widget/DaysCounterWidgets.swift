import SwiftUI
import WidgetKit

@main
struct DaysCounterWidgets: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        SinceWidget()
    }
}
