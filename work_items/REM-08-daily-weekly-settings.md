# REM-08 — Make the "Daily reminder" and "Weekly summary" settings work

**Type:** Feature / bug · **Priority:** P2 · **Area:** Frontend · **Depends on:** REM-01, REM-02

## Problem
Profile → Notifications (`views/screens/profile/widgets/build_profile_widget.dart` ~300-445) has a **Daily reminder** toggle with a time picker and a **Weekly Activity Summary** toggle. `LocalReminderService` (`utils/services/local_reminder_service.dart`) only writes them to SharedPreferences. **No notification is ever scheduled.** `docs/IMPLEMENTATION_STATUS.md` lists it as "In Progress".

## Tasks
1. `LocalReminderService.setDailyReminder(enabled, time)`:
   - enabled → `zonedSchedule(id: 900001, …, matchDateTimeComponents: DateTimeComponents.time)` on channel `digests`, title "Plan your day", body "Open Daymark to review today's tasks and reminders." No action buttons.
   - disabled → `cancel(900001)`.
2. `setWeeklySummary(enabled)`: id 900002, Sunday 18:00 local, `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`. The body is computed when it's scheduled, for example "This week: 12 tasks done, 3 reminders missed", and **refreshed on each app open** (reschedule with updated counts). Note in code that the text can be up to a week old.
3. On app start, if the prefs say enabled but nothing is pending (reinstall, cleared data), schedule again. Include this in REM-03's reconcile or a small `reconcileDigests()`.
4. Turning a toggle on checks or requests permission via REM-02 first. If denied, flip the toggle back and explain.
5. Tapping a digest notification opens the Workspace (daily) or the Calendar (weekly).
6. Hide the section when `NotificationService.isSupported == false`.

## Acceptance criteria
- [ ] Daily reminder at a time 2 minutes ahead fires, and fires again the next day (test by moving the device clock).
- [ ] Turning it off cancels it. Changing the time reschedules it.
- [ ] Weekly summary is scheduled for the next Sunday 18:00 local.
- [ ] Unit tests with a fake `NotificationService`.
