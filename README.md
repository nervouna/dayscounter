# DaysCounter

An iOS + macOS app with WidgetKit widgets that count down to the next all-day calendar event, and count up from past events you pin.

- **倒数日 widget**: the next all-day event from the selected calendars (small, medium; on iOS also lock screen circular, rectangular, inline).
- **追溯 widget**: days since a past event pinned in the app (small; on iOS also lock screen).
- Read-only EventKit access. Only all-day events count; subscribed calendars (e.g. public holidays) are excluded by default.

Requires iOS 26 / macOS 26 and Xcode 27.

## Layout

| Path | Contents |
| --- | --- |
| `project.yml` | XcodeGen spec; `DaysCounter.xcodeproj` is generated from it and not checked in |
| `App/` | SwiftUI app (shared by iOS and macOS) |
| `Widget/` | WidgetKit extension |
| `Packages/DaysCounterKit/` | Shared logic: day math, EventKit queries, App Group store, deep links |

The app and widget share settings and pinned events through the App Group `group.io.damao.DaysCounter`. The widget reads EventKit itself using the app's calendar permission.

## Build

```bash
brew install xcodegen
xcodegen generate
open DaysCounter.xcodeproj
```

Command line:

```bash
xcodebuild -project DaysCounter.xcodeproj -scheme DaysCounter -destination 'platform=macOS' -allowProvisioningUpdates build
```

Tests (logic only, run on macOS):

```bash
cd Packages/DaysCounterKit && swift test
```

## Simulator demo data

Debug builds on the simulator accept `-seedDemoEvents`, which creates a "示例" calendar with sample all-day events when calendar access is already granted:

```bash
xcrun simctl privacy booted grant calendar io.damao.DaysCounter
xcrun simctl launch booted io.damao.DaysCounter -seedDemoEvents
```

## License

MIT. See [LICENSE](LICENSE).
