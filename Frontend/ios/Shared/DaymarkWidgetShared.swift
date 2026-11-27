//
//  DaymarkWidgetShared.swift
//  Compiled into both the Runner app and the DaymarkWidgets extension (W-06).
//
//  The App Group data the Flutter app and the widgets share. The Flutter side
//  is lib/utils/services/home_widgets/ (keys must match).
//

import Foundation

enum DaymarkShared {
  /// App Group of the Runner and the DaymarkWidgets extension.
  static let appGroup = "group.com.devquorix.daymark"

  /// Written by the app (WidgetSnapshot.storageKey).
  static let snapshotKey = "daymark_widget_snapshot"
  /// Tasks added by the "Add task in Daymark" intent, imported by the app
  /// (WidgetTaskInbox.key).
  static let inboxKey = "daymark_task_inbox"
  /// Widget button taps the app still has to apply (WidgetPendingActions.key).
  static let pendingActionsKey = "daymark_widget_pending_actions"
  /// Shown at once by the widgets until the app confirms (trusted 60 s).
  static let optimisticDoneKey = "daymark_widget_optimistic_done"
  static let answeredRemindersKey = "daymark_widget_answered_reminders"

  /// WidgetKit kinds (DaymarkWidgets.tasksIOS / reminderIOS in Dart).
  static let tasksKind = "DaymarkTasksWidget"
  static let reminderKind = "DaymarkNextReminderWidget"

  static let trustSeconds: TimeInterval = 60

  static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

  static func millis(_ date: Date = Date()) -> Int64 { Int64(date.timeIntervalSince1970 * 1000) }

  static func date(millis: Int64) -> Date { Date(timeIntervalSince1970: TimeInterval(millis) / 1000) }

  // MARK: JSON stored as strings (home_widget reads and writes strings)

  static func json(_ key: String) -> Any? {
    guard let raw = defaults?.string(forKey: key), let data = raw.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data)
  }

  static func setJSON(_ value: Any?, _ key: String) {
    guard let value, let data = try? JSONSerialization.data(withJSONObject: value),
      let raw = String(data: data, encoding: .utf8)
    else {
      defaults?.removeObject(forKey: key)
      return
    }
    defaults?.set(raw, forKey: key)
  }

  /// Entries of a `{key: epochMillis}` map younger than [trustSeconds].
  static func recent(_ key: String, now: Date = Date()) -> [String: Int64] {
    guard let map = json(key) as? [String: Any] else { return [:] }
    var result: [String: Int64] = [:]
    for (entry, value) in map {
      guard let time = (value as? NSNumber)?.int64Value else { continue }
      if now.timeIntervalSince(date(millis: time)) < trustSeconds { result[entry] = time }
    }
    return result
  }

  static func markRecent(_ key: String, entry: String, now: Date = Date()) {
    var map = recent(key, now: now)
    map[entry] = millis(now)
    setJSON(map, key)
  }

  /// Whether the app last wrote a signed-in snapshot.
  static var isSignedIn: Bool {
    (json(snapshotKey) as? [String: Any])?["loggedIn"] as? Bool ?? false
  }

  // MARK: Widget actions

  /// Remembers a widget button tap: the widgets show it at once, and the app
  /// applies it (idempotently) even if the background Dart callback can't run.
  static func recordWidgetAction(_ url: URL, now: Date = Date()) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let query = Dictionary(
      (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { a, _ in a })
    switch components?.path {
    case "/toggle-task":
      if let id = query["id"] { markRecent(optimisticDoneKey, entry: id, now: now) }
    case "/reminder-done":
      if let id = query["id"], let occurrence = query["occurrence"] {
        markRecent(answeredRemindersKey, entry: "\(id)@\(occurrence)", now: now)
      }
    default:
      break
    }
    var pending = json(pendingActionsKey) as? [String] ?? []
    let link = url.absoluteString
    if !pending.contains(link) { pending.append(link) }
    setJSON(pending, pendingActionsKey)
  }

  // MARK: Inbox (W-03)

  /// Appends a task for the app to import; returns its id.
  @discardableResult
  static func appendInboxTask(title: String, dueDate: String?, now: Date = Date()) -> String {
    let id = UUID().uuidString.lowercased()
    var items = json(inboxKey) as? [[String: Any]] ?? []
    var item: [String: Any] = ["id": id, "title": title, "createdAt": millis(now)]
    if let dueDate { item["dueDate"] = dueDate }
    items.append(item)
    setJSON(items, inboxKey)
    return id
  }

  static func inboxTasks() -> [[String: Any]] { json(inboxKey) as? [[String: Any]] ?? [] }

  /// `yyyy-MM-dd` of [date] in the device's calendar.
  static func dayString(_ date: Date = Date()) -> String {
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }
}
