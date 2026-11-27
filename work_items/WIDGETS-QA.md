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
| 1.1 | Tasks 4x2 (Android) / Medium (iOS): header "Today" + count, + button, 3 rows, "+N more" | | | |
| 1.2 | Tasks 2x2 (Android): still readable, rows fit, nothing clipped | | n/a | |
| 1.3 | Tasks 4x4 (Android) / Large (iOS): 6 rows | | | |
| 1.4 | Overdue times are red; others muted; titles one line | | | |
| 1.5 | Next reminder 2x2 (Android) / Small (iOS): bell tile, title, time, "in N min", repeat label | | | |
| 1.6 | Next reminder 4x1 (Android) / Medium (iOS): Done button and the following reminder line | | | |
| 1.7 | Switch the phone to dark mode: both widgets switch colours without opening the app | | | |
| 1.8 | Widget picker shows the preview and description | | | |
| 1.9 | Empty states: no tasks → "All clear for today" + "Add task"; no reminders → "No upcoming reminders" + "New reminder" | | | |
| 1.10 | Tapping a task row opens the app on that task; a reminder opens that reminder; "+N more" opens the Workspace | | | |

## 2. Tick a task offline, check it syncs later
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 2.1 | Airplane mode, app closed. Tick a task: it fills green with a check and strikes through right away | | | |
| 2.2 | A few seconds later the row drops off and the count goes down | | | |
| 2.3 | Open the app: the task is completed there too | | | |
| 2.4 | Turn the network on: the task is completed on the server (check on the web/another device) | | | |
| 2.5 | Tap the same checkbox twice quickly: the task stays completed (not undone) | | | |
| 2.6 | iOS 15/16 only: tapping the circle opens the app, which completes the task | n/a | | |

## 3. Quick add
| # | Check | Android | iOS | Notes |
|---|---|---|---|---|
| 3.1 | Tasks widget **+**: Android shows the pop-up over the home screen; iOS opens the quick-add sheet over the Workspace | | | |
| 3.2 | Keyboard opens on the title; Today is selected; Tomorrow / No date / time work | | | |
| 3.3 | "Add task" saves, closes, and the task appears on the widget | | | |
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
| 6.1 | Log out: both widgets show "Sign in to Daymark", nothing of the old account | | | |
| 6.2 | Lock screen widget shows "Sign in to Daymark" too | n/a | | |
| 6.3 | Log in as another user: their data appears, not the previous user's | | | |

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

## Sign-off
| Platform | Device / OS | Build | Result | Tester | Date |
|---|---|---|---|---|---|
| Android | | | | | |
| iOS | | | | | |
