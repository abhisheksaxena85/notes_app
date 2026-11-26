# REM-09 — Device QA matrix and sign-off

**Type:** QA · **Priority:** P1 · **Depends on:** REM-01 … REM-06 (and REM-08 if shipped)

Automated tests can't cover OS scheduling, Doze, reboots or killed-app callbacks. Run this matrix on real devices or emulators and record the results in `work_items/REM-09-results.md` (date, device, OS, build, pass/fail, notes).

## Devices
- Android 14 or 15 emulator (Pixel) **and** one real Android phone with an aggressive OEM skin if available (Samsung/Xiaomi/OnePlus).
- Android 12 or 13 (exact-alarm and POST_NOTIFICATIONS differences).
- iPhone on iOS 17+ (simulator for basics, real device for background behaviour).

## Scenarios (each on every device)
| # | Scenario | Expected |
|---|---|---|
| 1 | Fresh install → create the first reminder | pre-prompt → OS prompt → reminder saved |
| 2 | Reminder in 2 min, app in **foreground** | heads-up/banner with 3 actions |
| 3 | Same, app **backgrounded** | notification on time (±1 min with exact alarms) |
| 4 | Same, app **killed** (swiped away) | notification on time |
| 5 | Same, phone **locked / Doze** (`adb shell dumpsys deviceidle force-idle`) | notification on time with exact alarms |
| 6 | **Reboot** with a reminder scheduled in 10 min | still fires |
| 7 | Tap **Done** with the app killed, **offline** | card shows completed on next open; server updated after reconnect |
| 8 | Tap **Not done** | card shows missed (red) |
| 9 | Tap **Snooze** | fires again after 10 min |
| 10 | Tap the notification **body** (cold start) | app opens on the reminder sheet |
| 11 | DAILY reminder → Done | next one scheduled for tomorrow, card pending |
| 12 | Edit the time of a scheduled reminder | old time doesn't fire, new time does |
| 13 | Delete a scheduled reminder | doesn't fire |
| 14 | Logout | nothing fires for the logged-out user |
| 15 | Change the device time zone, reopen the app | fires at the same local wall-clock time |
| 16 | Notification permission revoked in settings | banner shows; no crash |
| 17 | Exact alarm permission revoked (Android 14) | falls back to inexact; settings shows "may be late" |
| 18 | 60+ future reminders on iOS | the nearest 50 scheduled; later ones scheduled as earlier ones are handled |
| 19 | Daily digest on, time in 2 min | fires; fires again next day |

## Sign-off
- [ ] All scenarios pass or have a written, accepted exception.
- [ ] Known OEM limitations documented in `Frontend/README.md` (for example: on some brands users must disable battery optimisation for Daymark).
