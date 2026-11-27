//
//  TasksWidget.swift
//  DaymarkWidgets (W-06): "Daymark Tasks", systemMedium (3 rows) and
//  systemLarge (6 rows).
//

import SwiftUI
import WidgetKit

struct TasksEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshotData
  /// Tasks from the "Add task in Daymark" intent the app hasn't imported yet.
  let inbox: [WidgetTaskItem]
  /// Ticks tapped on the widget, by task id (shown until the app confirms).
  let ticked: [Int64: Date]
}

struct TasksProvider: TimelineProvider {
  /// A ticked row shows its tick this long before it drops off.
  static let showDone: TimeInterval = 4

  func placeholder(in context: Context) -> TasksEntry { Self.sample }

  func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) {
    let entry = Self.current(at: Date())
    completion(context.isPreview && !entry.snapshot.loggedIn ? Self.sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
    let now = Date()
    let base = Self.current(at: now)
    // Redraw when a tick should drop off, when a task turns overdue and at
    // midnight ("today" changes); the app reloads on every data change.
    let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 3600)
    var dates = Set<Date>()
    for task in base.snapshot.tasks {
      if let done = task.doneAt ?? base.ticked[task.taskId ?? 0] {
        dates.insert(done.addingTimeInterval(Self.showDone + 0.5))
      }
      if let due = task.dueAt { dates.insert(due.addingTimeInterval(1)) }
    }
    for done in base.ticked.values { dates.insert(done.addingTimeInterval(Self.showDone + 0.5)) }
    let entries =
      [base]
      + dates.filter { $0 > now && $0 < midnight }.sorted().map {
        TasksEntry(date: $0, snapshot: base.snapshot, inbox: base.inbox, ticked: base.ticked)
      }
    completion(Timeline(entries: entries, policy: .after(midnight)))
  }

  static func current(at date: Date) -> TasksEntry {
    let ticked = DaymarkShared.recent(DaymarkShared.optimisticDoneKey, now: date).reduce(
      into: [Int64: Date]()
    ) { result, entry in
      if let id = Int64(entry.key) { result[id] = DaymarkShared.date(millis: entry.value) }
    }
    return TasksEntry(
      date: date,
      snapshot: .load(),
      inbox: DaymarkShared.inboxTasks().compactMap(WidgetTaskItem.init(inbox:)),
      ticked: ticked)
  }

  static var sample: TasksEntry {
    let now = Date()
    var snapshot = WidgetSnapshotData(loggedIn: true, taskCount: 4, tasks: [], reminders: [])
    snapshot.tasks = [
      WidgetTaskItem(sample: "Send the invoice", id: 1, dueAt: now.addingTimeInterval(-3600), overdue: true),
      WidgetTaskItem(sample: "Plan the week", id: 2, dueAt: now.addingTimeInterval(3 * 3600)),
      WidgetTaskItem(sample: "Water the plants", id: 3, dueAt: nil),
      WidgetTaskItem(sample: "Call the dentist", id: 4, dueAt: nil),
    ]
    return TasksEntry(date: now, snapshot: snapshot, inbox: [], ticked: [:])
  }
}

struct TasksWidgetView: View {
  let entry: TasksEntry
  @Environment(\.widgetFamily) private var family

  private struct Row: Identifiable {
    let task: WidgetTaskItem
    let doneAt: Date?
    var id: String { task.id }
  }

  var body: some View {
    Group {
      if entry.snapshot.loggedIn {
        list
      } else {
        signedOut
      }
    }
    .daymarkBackground()
  }

  private var rows: [Row] {
    let tasks =
      entry.inbox
      + entry.snapshot.tasks.map { task -> WidgetTaskItem in
        var copy = task
        if let tapped = entry.ticked[task.taskId ?? 0] {
          copy.doneAt = task.doneAt.map { min($0, tapped) } ?? tapped
        }
        return copy
      }
    return tasks.map { Row(task: $0, doneAt: $0.doneAt) }
      .filter { $0.doneAt == nil || entry.date.timeIntervalSince($0.doneAt!) < TasksProvider.showDone }
  }

  private var pendingCount: Int {
    let tickedPending = entry.snapshot.tasks.filter { $0.doneAt == nil && entry.ticked[$0.taskId ?? 0] != nil }.count
    return max(0, entry.snapshot.taskCount - tickedPending) + entry.inbox.count
  }

  private var list: some View {
    let limit = family == .systemLarge ? 6 : 3
    let shown = Array(rows.prefix(limit))
    let more = pendingCount - shown.filter { $0.doneAt == nil }.count
    return VStack(alignment: .leading, spacing: 0) {
      header
      if shown.isEmpty {
        Spacer(minLength: 0)
        VStack(spacing: 10) {
          Text("All clear for today")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Palette.muted)
          Link(destination: WidgetLinks.quickAdd) { AccentPill(label: "Add task") }
        }
        .frame(maxWidth: .infinity)
        Spacer(minLength: 0)
      } else {
        Spacer(minLength: 6).frame(maxHeight: 8)
        ForEach(shown) { row in
          taskRow(row)
        }
        Spacer(minLength: 0)
        if more > 0 {
          Link(destination: WidgetLinks.workspace) {
            Text("+\(more) more")
              .font(.system(size: 12.5))
              .foregroundStyle(Palette.muted)
          }
        }
      }
    }
  }

  private var header: some View {
    HStack(spacing: 6) {
      Link(destination: WidgetLinks.workspace) {
        HStack(spacing: 6) {
          Text("Today").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
          Text("\(pendingCount)").font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.muted)
        }
      }
      Spacer()
      Link(destination: WidgetLinks.quickAdd) {
        Circle()
          .fill(Palette.accent)
          .frame(width: 32, height: 32)
          .overlay(
            Image("ic_plus").renderingMode(.template).resizable()
              .frame(width: 18, height: 18)
              .foregroundStyle(Palette.onAccent)
          )
          .accessibilityLabel("Add task")
      }
    }
    .frame(height: 32)
  }

  @ViewBuilder
  private func taskRow(_ row: Row) -> some View {
    let task = row.task
    let done = row.doneAt != nil
    let overdue = !done && (task.overdue || (task.dueAt.map { $0 < entry.date } ?? false))
    let due = WidgetFormat.taskDue(task, now: entry.date)
    HStack(spacing: 10) {
      checkbox(task, done: done)
      Link(destination: task.taskId.map(WidgetLinks.task) ?? WidgetLinks.workspace) {
        HStack(spacing: 8) {
          Text(task.title)
            .strikethrough(done)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(done ? Palette.muted : Palette.ink)
            .lineLimit(1)
            .privacySensitive()
          Spacer(minLength: 0)
          if let due {
            Text(due)
              .font(.system(size: 12.5))
              .foregroundStyle(overdue ? Palette.danger : Palette.muted)
              .lineLimit(1)
          }
        }
      }
    }
    .frame(height: 30)
  }

  @ViewBuilder
  private func checkbox(_ task: WidgetTaskItem, done: Bool) -> some View {
    let mark = ZStack {
      if done {
        Circle().fill(Palette.success)
        Image("ic_check").renderingMode(.template).resizable()
          .frame(width: 13, height: 13)
          .foregroundStyle(Palette.onAccent)
      } else {
        Circle().strokeBorder(Palette.accent, lineWidth: 1.6)
      }
    }
    .frame(width: 20, height: 20)
    .frame(width: 28, height: 28)
    .contentShape(Rectangle())
    .accessibilityLabel(done ? "Done" : "Complete \(task.title)")
    if let id = task.taskId, !done {
      WidgetActionButton(url: WidgetLinks.toggleTask(id)) { mark }
    } else {
      mark
    }
  }

  private var signedOut: some View {
    VStack(spacing: 8) {
      Image("ic_check").renderingMode(.template).resizable()
        .frame(width: 24, height: 24)
        .foregroundStyle(Palette.accent)
      Text("Sign in to Daymark")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Palette.ink)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetURL(WidgetLinks.workspace)
  }
}

struct TasksWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: DaymarkShared.tasksKind, provider: TasksProvider()) { entry in
      TasksWidgetView(entry: entry)
    }
    .configurationDisplayName("Daymark Tasks")
    .description("Today's tasks: tick them off or add one without opening Daymark.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}
