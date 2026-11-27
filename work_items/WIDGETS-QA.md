# WIDGETS-QA — Home-screen widgets: device checklist

**Type:** QA · **Depends on:** W-01 … W-06

Automated tests cover the snapshot, the widget actions, the quick-add sheet and the inbox. They can't cover launchers, WidgetKit timelines, background engines or reboots, so run this on real devices. Fill in each row: date, device / OS, build, ✅ / ❌, notes (and a screenshot for anything visual).

## Before you start
- [ ] iOS: in Xcode, the **App Groups** capability with `group.com.devquorix.daymark` is ticked for **Runner** and **DaymarkWidgets** (see `Frontend/ios/DaymarkWidgets/README.md`).
- [ ] Signed in, with: 2 tasks due today (one at a time that has passed), 1 overdue task from yesterday, 4 undated tasks, a one-off reminder in ~10 min, a DAILY reminder later today, and another reminder tomorrow.

Devices: _______________________ (Android) · _______________________ (iPhone, iOS 17+) · _______________________ (iOS 15/16 if available)

## 1. Add both widgets in light and dark, at every size
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 1.1 | Tasks 4x2 (Android) / Medium (iOS): header "Today" + count, + button, 3 rows, "+N more" | ✅ Pixel 8 emu, Android 17 | | |
| 1.2 | Tasks 2x2 (Android): still readable, rows fit, nothing clipped | | n/a | |
| 1.3 | Tasks 4x4 (Android) / Large (iOS): 6 rows | | | |
| 1.4 | Overdue times are red; others muted; titles one line | ✅ Pixel 8 emu, Android 17 | | |
| 1.5 | Next reminder 2x2 (Android) / Small (iOS): bell tile, title, time, "in N min", repeat label | | | |
| 1.6 | Next reminder 4x1 (Android) / Medium (iOS): Done button and the following reminder line | | | |
| 1.7 | Switch the phone to dark mode: both widgets switch colours without opening the app | | | |
| 1.8 | Widget picker shows the preview and description | | | |
| 1.9 | Empty states: no tasks → "All clear for today" + "Add task"; no reminders → "No upcoming reminders" + "New reminder" | ✅ Tasks (emu); reminder widget not tested | | |
| 1.10 | Tapping a task row opens the app on that task; a reminder opens that reminder; "+N more" opens the Workspace | ✅ task row + "+N more" (emu); reminder not tested | | |

## 2. Tick a task offline, check it syncs later
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 2.1 | Airplane mode, app closed. Tick a task: it fills green with a check and strikes through right away | | | |
| 2.2 | A few seconds later the row drops off and the count goes down | ✅ Pixel 8 emu, Android 17 (online) | | |
| 2.3 | Open the app: the task is completed there too | | | |
| 2.4 | Turn the network on: the task is completed on the server (check on the web/another device) | ✅ online only: PUT toggle-status 200 at once | | |
| 2.5 | Tap the same checkbox twice quickly: the task stays completed (not undone) | | | |
| 2.6 | iOS 15/16 only: tapping the circle opens the app, which completes the task | n/a | | |

## 3. Quick add
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 3.1 | Tasks widget **+**: Android shows the pop-up over the home screen; iOS opens the quick-add sheet over the Workspace | ✅ after FIX-02 (was "Something went wrong" in release builds) | | |
| 3.2 | Keyboard opens on the title; Today is selected; Tomorrow / No date / time work | ✅ keyboard + Today (FIX-02 fixed the keyboard when the app was running); Tomorrow / No date / time not tapped on device | | |
| 3.3 | "Add task" saves, closes, and the task appears on the widget | ✅ widget updates at once, POST create-task 201 at once | | |
| 3.4 | Android: tapping outside the pop-up closes it without saving; it isn't in Recents | | n/a | |
| 3.5 | Add a task offline, then go online: it syncs (no duplicate) | | | |
| 3.6 | iOS: "Hey Siri, add task in Daymark" → asks for the title → "Added …"; the widget shows it at once | n/a | | |
| 3.7 | iOS: the Shortcuts action and the Action button do the same | n/a | | |
| 3.8 | iOS: open the app afterwards: the Siri task is in the list once (not twice) and syncs | n/a | | |

## 4. Done on the reminder widget
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 4.1 | Done on a one-off reminder: the widget moves to the next reminder; the app shows it completed; its notification doesn't fire | | | |
| 4.2 | Done on a DAILY reminder: it moves to tomorrow; the app shows the next occurrence | | | |
| 4.3 | Done offline, app killed: applied on the device; synced after reconnecting | | | |
| 4.4 | Answer a reminder from its **notification** (Done / Snooze): the widget updates | | | |

## 5. Roll-over without opening the app
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 5.1 | Kill the app. Let the next reminder's time pass: within about a minute the widget shows the following one | | | |
| 5.2 | The countdown ("in N min") stays roughly right while the app is closed | | | |
| 5.3 | A task due at a time that passes turns red without opening the app | | | |
| 5.4 | After midnight, "today" moves on (yesterday's tasks show "Yesterday" in red) | | | |

## 6. Logout clears the widgets
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 6.1 | Log out: both widgets show "Sign in to Daymark", nothing of the old account | ✅ Tasks widget (emu) | | |
| 6.2 | Lock screen widget shows "Sign in to Daymark" too | n/a | | |
| 6.3 | Log in as another user: their data appears, not the previous user's | ✅ (emu; FIX-02 fixed Sign out staying on the Dashboard) | | |

## 7. Reboot
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 7.1 | Reboot with a reminder due in 10 min: both widgets show data after the reboot | | | |
| 7.2 | The reminder widget still rolls over when that reminder passes (app not opened) | | | |

## 8. iOS lock-screen widget
| # | Check | iOS | Notes |
|---|---|---|---|
| 8.1 | Add "Next reminder" as rectangular and inline on the lock screen | | |
| 8.2 | Shows time and title; tapping opens the app on the reminder | | |
| 8.3 | With Settings → Face ID & Passcode → "Allow access when locked: Lock Screen widget data" **off**, the title is hidden while locked | | |
| 8.4 | Rolls over when the reminder passes | | |

## FIX-02 results (2026-11-27)

Android only, on the Pixel 8 emulator (Android 17, API 37), against a local backend, with debug and release builds of `com.invospec.daymark`. iOS was not run.

**Bug:** tapping **+** on the Tasks widget showed "Something went wrong". This happened in release builds only.

**Root cause:** `PlatformException(invalid_icon, The resource ic_stat_daymark could not be found…)`, thrown by `flutter_local_notifications.initialize()` inside `BackgroundGraph.open()`. The plugin looks up the notification icon by name at runtime, and nothing else references it. Release builds shrink resources (`aapt2 dump resources` on the release APK listed 0 entries for `drawable/ic_stat_daymark`), so the drawable was removed.

The same `open()` serves widget ticks and notification actions, so those failed in release builds too. The app's own `NotificationService.init` failed the same way, but the app catches that error, so reminders were silently not scheduled. The `com.devquorix` → `com.invospec` rename was not the cause: no Android/Kotlin/Gradle/resource leftovers were found.

**Fixes:**
- `res/raw/keep.xml` keeps the icon.
- Quick add uses the light `TaskGraph` (preferences, database, task repo, sync and the time zone; no notifications or scheduler).
- Debug builds show the real error, and the error is logged with `debugPrint` so it reaches logcat in release builds.
- The keyboard is re-requested when the pop-up window gains focus.
- Sign out now reliably returns to the login screen.

**Verified on the emulator:**
- **Quick add:** works with the app running, with the app engine closed, and cold. The keyboard opens, the task saves, the widget count updates at once, and the task uploads at once (no duplicate).
- **Checkbox tick:** shows the tick at once, the row drops off after about 5 s, the count goes down, and the server gets the change.
- **Taps:** a row opens that task's edit sheet; "+N more" opens the Workspace.
- **App changes:** a tick in the app and a confirmed delete update the widget.
- **Sign-out and empty state:** Sign out shows "Sign in to Daymark"; another user's empty account shows "All clear for today" + "Add task".

**Not verified:** offline ticks/adds (2.1, 2.3, 3.5), the Next reminder widget's Done (section 4), roll-over and reboot (sections 5 and 7), widget sizes other than 4x2, dark-mode widgets, and anything on iOS.

**Phones with the old build:** uninstall `com.devquorix.daymark`, install the new build, and add both widgets again. Widgets placed from the old package keep pointing at the old app.

## Sign-off
| Platform | Device / OS | Build | Result | Tester | Date |
|---|---|---|---|---|---|
| Android | Pixel 8 emulator / Android 17 (API 37) | FIX-02, debug + release | Partial (see FIX-02 results) | Claude Code | 2026-11-27 |
| iOS | | | | | |
