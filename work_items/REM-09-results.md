# REM-09 — Device QA results

Fill in one table per device. Scenarios and expected results are in [REM-09-qa-matrix.md](REM-09-qa-matrix.md).
Result: ✅ pass · ❌ fail · ⚠️ pass with an accepted exception (write it in Notes) · — not applicable.

Build under test: commit `__________` · `flutter build apk --debug` / iOS build `__________`
Backend: `__________` (URL / commit) — scenarios 7 and 11 need it reachable after reconnecting.

## Useful commands (Android)
- Doze: `adb shell dumpsys deviceidle force-idle` (back to normal: `adb shell dumpsys deviceidle unforce`)
- Exact alarms off (Android 14): Settings → Apps → Daymark → Alarms & reminders
- Scheduled alarms: `adb shell dumpsys alarm | grep -A3 com.devquorix.daymark`
- Offline: airplane mode, or `adb shell svc wifi disable && adb shell svc data disable`

---

## Device 1 — Android 14/15 emulator (Pixel)
Date: ______ · Device / image: ______ · OS: ______ · Build: ______ · Tester: ______

| # | Scenario | Expected | Result | Notes |
|---|---|---|---|---|
| 1 | Fresh install → create the first reminder | pre-prompt → OS prompt → reminder saved | | |
| 2 | Reminder in 2 min, app in foreground | heads-up with 3 actions | | |
| 3 | Same, app backgrounded | on time (±1 min with exact alarms) | | |
| 4 | Same, app killed (swiped away) | on time | | |
| 5 | Same, phone locked / Doze | on time with exact alarms | | |
| 6 | Reboot with a reminder in 10 min | still fires | | |
| 7 | Tap Done with the app killed, offline | card completed on next open; server updated after reconnect | | |
| 8 | Tap Not done | card missed (red) | | |
| 9 | Tap Snooze | fires again after 10 min | | |
| 10 | Tap the notification body (cold start) | app opens on the "Did you complete …?" sheet | | |
| 11 | DAILY reminder → Done | next one tomorrow, card pending, "Last: done ✓" | | |
| 12 | Edit the time of a scheduled reminder | old time doesn't fire, new time does | | |
| 13 | Delete a scheduled reminder | doesn't fire | | |
| 14 | Logout | nothing fires for the logged-out user | | |
| 15 | Change the device time zone, reopen the app | fires at the same local wall-clock time | | |
| 16 | Notification permission revoked in settings | banner shows; no crash | | |
| 17 | Exact alarm permission revoked | falls back to inexact; settings shows "may be late" | | |
| 18 | 60+ future reminders | nearest 50 scheduled; later ones follow | — (iOS limit; optional here) | |
| 19 | Daily digest on, time in 2 min | fires; fires again next day | | |

## Device 2 — real Android phone, OEM skin (Samsung / Xiaomi / OnePlus …)
Date: ______ · Device: ______ · OS / skin: ______ · Build: ______ · Battery optimisation for Daymark: on / off · Tester: ______

| # | Scenario | Expected | Result | Notes |
|---|---|---|---|---|
| 1 | Fresh install → create the first reminder | pre-prompt → OS prompt → reminder saved | | |
| 2 | Reminder in 2 min, app in foreground | heads-up with 3 actions | | |
| 3 | Same, app backgrounded | on time (±1 min with exact alarms) | | |
| 4 | Same, app killed (swiped away) | on time | | |
| 5 | Same, phone locked / Doze | on time with exact alarms | | |
| 6 | Reboot with a reminder in 10 min | still fires | | |
| 7 | Tap Done with the app killed, offline | card completed on next open; server updated after reconnect | | |
| 8 | Tap Not done | card missed (red) | | |
| 9 | Tap Snooze | fires again after 10 min | | |
| 10 | Tap the notification body (cold start) | app opens on the "Did you complete …?" sheet | | |
| 11 | DAILY reminder → Done | next one tomorrow, card pending, "Last: done ✓" | | |
| 12 | Edit the time of a scheduled reminder | old time doesn't fire, new time does | | |
| 13 | Delete a scheduled reminder | doesn't fire | | |
| 14 | Logout | nothing fires for the logged-out user | | |
| 15 | Change the device time zone, reopen the app | fires at the same local wall-clock time | | |
| 16 | Notification permission revoked in settings | banner shows; no crash | | |
| 17 | Exact alarm permission revoked | falls back to inexact; settings shows "may be late" | | |
| 18 | 60+ future reminders | nearest 50 scheduled; later ones follow | — (optional) | |
| 19 | Daily digest on, time in 2 min | fires; fires again next day | | |

## Device 3 — Android 12 or 13
Date: ______ · Device / image: ______ · OS: ______ · Build: ______ · Tester: ______

| # | Scenario | Expected | Result | Notes |
|---|---|---|---|---|
| 1 | Fresh install → create the first reminder | pre-prompt → OS prompt (13) / no OS prompt (12) → reminder saved | | |
| 2 | Reminder in 2 min, app in foreground | heads-up with 3 actions | | |
| 3 | Same, app backgrounded | on time (±1 min with exact alarms) | | |
| 4 | Same, app killed (swiped away) | on time | | |
| 5 | Same, phone locked / Doze | on time with exact alarms | | |
| 6 | Reboot with a reminder in 10 min | still fires | | |
| 7 | Tap Done with the app killed, offline | card completed on next open; server updated after reconnect | | |
| 8 | Tap Not done | card missed (red) | | |
| 9 | Tap Snooze | fires again after 10 min | | |
| 10 | Tap the notification body (cold start) | app opens on the "Did you complete …?" sheet | | |
| 11 | DAILY reminder → Done | next one tomorrow, card pending, "Last: done ✓" | | |
| 12 | Edit the time of a scheduled reminder | old time doesn't fire, new time does | | |
| 13 | Delete a scheduled reminder | doesn't fire | | |
| 14 | Logout | nothing fires for the logged-out user | | |
| 15 | Change the device time zone, reopen the app | fires at the same local wall-clock time | | |
| 16 | Notification permission revoked in settings | banner shows; no crash | | |
| 17 | Exact alarm permission revoked | falls back to inexact; settings shows "may be late" | | |
| 18 | 60+ future reminders | nearest 50 scheduled; later ones follow | — (optional) | |
| 19 | Daily digest on, time in 2 min | fires; fires again next day | | |

## Device 4 — iPhone, iOS 17+ (real device for background behaviour)
Date: ______ · Device: ______ · iOS: ______ · Build: ______ · Simulator or device: ______ · Tester: ______

| # | Scenario | Expected | Result | Notes |
|---|---|---|---|---|
| 1 | Fresh install → create the first reminder | pre-prompt → OS prompt → reminder saved | | |
| 2 | Reminder in 2 min, app in foreground | banner with 3 actions (long-press / pull down) | | |
| 3 | Same, app backgrounded | on time | | |
| 4 | Same, app killed (swiped away) | on time | | |
| 5 | Same, phone locked | on time | | |
| 6 | Reboot with a reminder in 10 min | still fires | | |
| 7 | Tap Done with the app killed, offline | card completed on next open; server updated after reconnect | | |
| 8 | Tap Not done | card missed (red) | | |
| 9 | Tap Snooze | fires again after 10 min | | |
| 10 | Tap the notification body (cold start) | app opens on the "Did you complete …?" sheet | | |
| 11 | DAILY reminder → Done | next one tomorrow, card pending, "Last: done ✓" | | |
| 12 | Edit the time of a scheduled reminder | old time doesn't fire, new time does | | |
| 13 | Delete a scheduled reminder | doesn't fire | | |
| 14 | Logout | nothing fires for the logged-out user | | |
| 15 | Change the device time zone, reopen the app | fires at the same local wall-clock time | | |
| 16 | Notification permission revoked in settings | banner shows; no crash; Settings row opens iOS Settings | | |
| 17 | Exact alarm permission revoked | — (Android only) | — | |
| 18 | 60+ future reminders | nearest 50 scheduled; later ones scheduled as earlier ones are handled | | |
| 19 | Daily digest on, time in 2 min | fires; fires again next day | | |

---

## Accepted exceptions
| # | Device | What happens | Why it is accepted | Accepted by / date |
|---|---|---|---|---|
| | | | | |

## Sign-off
- [ ] All scenarios pass or have a written, accepted exception above.
- [x] Known OEM limitations documented in `Frontend/README.md` ("Known OEM limitations").

Signed off by: ______ · Date: ______
