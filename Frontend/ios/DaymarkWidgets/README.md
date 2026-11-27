# DaymarkWidgets (iOS WidgetKit extension)

The "Daymark Tasks" and "Next reminder" widgets (W-06). The Flutter side is
`lib/utils/services/home_widgets/`; the Android widgets are in
`android/app/src/main/kotlin/com/devquorix/daymark/widgets/`.

| File | What it is |
|---|---|
| `DaymarkWidgetsBundle.swift` | The extension's entry point: both widgets |
| `TasksWidget.swift` | "Daymark Tasks": systemMedium (3 rows), systemLarge (6 rows) |
| `NextReminderWidget.swift` | "Next reminder": systemSmall, systemMedium, lock screen (accessoryRectangular, accessoryInline) |
| `WidgetModels.swift` | Reads the snapshot the app writes; links and date formats |
| `WidgetStyle.swift` | Design tokens (light/dark), shared views, the iOS 17 / iOS 15–16 action button |
| `Assets.xcassets` | `ic_reminder`, `ic_repeat`, `ic_plus`, `ic_check` from `assets/icons/` as template vectors |
| `../Shared/DaymarkWidgetShared.swift` | App Group keys and helpers (Runner **and** extension) |
| `../Shared/DaymarkWidgetIntent.swift` | The interactive button intent (Runner **and** extension) |
| `../Runner/AddTaskIntent.swift` | "Add task in Daymark" for Siri, Shortcuts and the Action button (Runner only) |

## How it is wired

- **App Group** `group.com.devquorix.daymark` in `Runner/Runner.entitlements`
  and `DaymarkWidgets.entitlements`. The app writes the snapshot there with
  home_widget (`HomeWidget.setAppGroupId`).
- **Buttons (iOS 17+)**: `Button(intent: DaymarkWidgetIntent(url:))`. The intent
  records the tap in the App Group (the widget shows it at once, and the app
  applies it on its next start if nothing else did), then, in the app process,
  runs the Dart callback through `HomeWidgetBackgroundWorker`.
  `DAYMARK_APP` is a Swift compilation condition set on Runner only: the
  extension doesn't link Flutter or the plugins.
- **iOS 15–16**: the same buttons are links that open the app, which applies
  the action and shows the Workspace.
- **Roll-over**: the Next reminder timeline has an entry just after each
  upcoming reminder; the countdown is `Text(date, style: .relative)`.
- **Privacy**: task and reminder titles are `.privacySensitive()`.

## Adding the target to the Xcode project

The target was added with `ios/scripts/add_widget_extension.rb` (xcodeproj
gem). It is idempotent; run it again after pulling if the project file lost the
target:

```sh
gem install xcodeproj   # once
cd Frontend && ruby ios/scripts/add_widget_extension.rb
```

## Before running on a device (one-time, in Xcode)

`flutter build ios --no-codesign` builds without signing. To run on a phone:

1. Open `ios/Runner.xcworkspace`, select the **Runner** target → Signing &
   Capabilities, and check that **App Groups** lists
   `group.com.devquorix.daymark` (tick it; Xcode registers it with your team).
2. Do the same for the **DaymarkWidgets** target (same team, automatic
   signing, same App Group). Its bundle id is
   `com.devquorix.daymark.DaymarkWidgets`.
3. Run from Xcode or `flutter run` as usual.
