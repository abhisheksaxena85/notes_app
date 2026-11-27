//
//  WidgetModels.swift
//  DaymarkWidgets (W-06)
//
//  The snapshot the Flutter app writes (lib/utils/services/home_widgets/
//  widget_snapshot.dart). Times are epoch millis, so the widgets decide
//  "overdue" and which reminder is next when they render.
//

import Foundation

struct WidgetSnapshotData {
  var loggedIn: Bool
  var taskCount: Int
  var tasks: [WidgetTaskItem]
  var reminders: [WidgetReminderItem]

  static let signedOut = WidgetSnapshotData(loggedIn: false, taskCount: 0, tasks: [], reminders: [])

  static func load() -> WidgetSnapshotData {
    guard let json = DaymarkShared.json(DaymarkShared.snapshotKey) as? [String: Any],
      json["loggedIn"] as? Bool == true
    else { return .signedOut }
    let tasks = json["tasks"] as? [String: Any]
    return WidgetSnapshotData(
      loggedIn: true,
      taskCount: (tasks?["count"] as? NSNumber)?.intValue ?? 0,
      tasks: (tasks?["items"] as? [[String: Any]] ?? []).compactMap(WidgetTaskItem.init(json:)),
      reminders: (json["reminders"] as? [[String: Any]] ?? []).compactMap(WidgetReminderItem.init(json:))
    )
  }
}

struct WidgetTaskItem: Identifiable {
  /// The app's item id; nil for an inbox item not imported yet.
  let taskId: Int64?
  let inboxId: String?
  let title: String
  let dueAt: Date?
  let hasTime: Bool
  let overdue: Bool
  var doneAt: Date?

  var id: String { inboxId ?? "\(taskId ?? 0)" }

  init?(json: [String: Any]) {
    guard let id = (json["id"] as? NSNumber)?.int64Value else { return nil }
    taskId = id
    inboxId = nil
    title = json["title"] as? String ?? ""
    dueAt = (json["dueAt"] as? NSNumber).map { DaymarkShared.date(millis: $0.int64Value) }
    hasTime = json["hasTime"] as? Bool ?? false
    overdue = json["overdue"] as? Bool ?? false
    doneAt = (json["doneAt"] as? NSNumber).map { DaymarkShared.date(millis: $0.int64Value) }
  }

  /// A task added through the "Add task in Daymark" intent, shown until the
  /// app imports it.
  init?(inbox json: [String: Any]) {
    guard let id = json["id"] as? String, let title = json["title"] as? String else { return nil }
    taskId = nil
    inboxId = id
    self.title = title
    dueAt = nil
    hasTime = false
    overdue = false
    doneAt = nil
  }

  init(sample title: String, id: Int64, dueAt: Date?, overdue: Bool = false) {
    taskId = id
    inboxId = nil
    self.title = title
    self.dueAt = dueAt
    hasTime = dueAt != nil
    self.overdue = overdue
    doneAt = nil
  }
}

struct WidgetReminderItem: Identifiable {
  let reminderId: Int64
  let title: String
  let fireAt: Date
  let occurrence: String
  let repeatInterval: String?
  let snoozed: Bool

  var id: String { "\(reminderId)@\(occurrence)" }

  init?(json: [String: Any]) {
    guard let id = (json["id"] as? NSNumber)?.int64Value,
      let fire = (json["fireAt"] as? NSNumber)?.int64Value
    else { return nil }
    reminderId = id
    title = json["title"] as? String ?? ""
    fireAt = DaymarkShared.date(millis: fire)
    occurrence = json["occurrence"] as? String ?? ""
    repeatInterval = json["repeat"] as? String
    snoozed = json["snoozed"] as? Bool ?? false
  }

  init(sample title: String, id: Int64, fireAt: Date, repeatInterval: String? = nil) {
    reminderId = id
    self.title = title
    self.fireAt = fireAt
    occurrence = ""
    self.repeatInterval = repeatInterval
    snoozed = false
  }

  var repeatLabel: String? {
    switch repeatInterval {
    case "DAILY": return "Daily"
    case "WEEKLY": return "Weekly"
    case "MONTHLY": return "Monthly"
    default: return nil
    }
  }
}

/// daymark:// links. `homeWidget` lets home_widget recognise a widget launch.
enum WidgetLinks {
  private static func link(_ path: String, _ query: [URLQueryItem] = []) -> URL {
    var components = URLComponents(string: "daymark://\(path)")!
    components.queryItems = query + [URLQueryItem(name: "homeWidget", value: nil)]
    return components.url!
  }

  static func task(_ id: Int64) -> URL { link("task/\(id)") }
  static func reminder(_ id: Int64) -> URL { link("reminder/\(id)") }
  static let quickAdd = link("quick-add-task")
  static let newReminder = link("new-reminder")
  static let workspace = link("workspace")

  static func toggleTask(_ id: Int64) -> URL {
    link("widget/toggle-task", [URLQueryItem(name: "id", value: "\(id)")])
  }

  static func reminderDone(_ reminder: WidgetReminderItem) -> URL {
    link(
      "widget/reminder-done",
      [
        URLQueryItem(name: "id", value: "\(reminder.reminderId)"),
        URLQueryItem(name: "occurrence", value: reminder.occurrence),
      ])
  }
}

enum WidgetFormat {
  /// Whole days from the day of [now] to the day of [date].
  static func days(from now: Date, to date: Date) -> Int {
    let calendar = Calendar.current
    return calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)
    ).day ?? 0
  }

  static func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }

  private static func templated(_ template: String, _ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate(template)
    return formatter.string(from: date)
  }

  /// A task's due label: its time today, "Today", "Yesterday", or the date.
  static func taskDue(_ task: WidgetTaskItem, now: Date) -> String? {
    guard let due = task.dueAt else { return nil }
    switch days(from: now, to: due) {
    case 0: return task.hasTime ? time(due) : "Today"
    case -1: return "Yesterday"
    case 1: return task.hasTime ? "Tomorrow, \(time(due))" : "Tomorrow"
    default: return templated("dMMM", due)
    }
  }

  /// "6:00 PM", "Tomorrow, 9:00 AM" or "Fri 4 Dec, 9:00 AM".
  static func reminderTime(_ date: Date, now: Date) -> String {
    switch days(from: now, to: date) {
    case 0: return time(date)
    case 1: return "Tomorrow, \(time(date))"
    default: return "\(templated("EEEdMMM", date)), \(time(date))"
    }
  }
}
