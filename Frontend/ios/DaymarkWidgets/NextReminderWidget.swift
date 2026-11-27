//
//  NextReminderWidget.swift
//  DaymarkWidgets (W-06): "Next reminder", systemSmall, systemMedium and,
//  on the lock screen, accessoryRectangular and accessoryInline.
//
//  Rolls over without the app: the timeline has an entry just after each
//  upcoming reminder, and each entry shows the first one later than its date.
//  The countdown is Text(date, style: .relative), which WidgetKit keeps live.
//

import SwiftUI
import WidgetKit

struct ReminderEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshotData
  /// Occurrences answered Done on the widget, until the app confirms.
  let answered: Set<String>

  var upcoming: [WidgetReminderItem] {
    snapshot.reminders
      .filter { $0.fireAt > date && !answered.contains("\($0.reminderId)@\($0.occurrence)") }
      .sorted { $0.fireAt < $1.fireAt }
  }
}

struct ReminderProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReminderEntry { Self.sample }

  func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
    let entry = Self.current(at: Date())
    completion(context.isPreview && !entry.snapshot.loggedIn ? Self.sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
    let now = Date()
    let base = Self.current(at: now)
    let entries =
      [base]
      + base.upcoming.map {
        ReminderEntry(date: $0.fireAt.addingTimeInterval(1), snapshot: base.snapshot, answered: base.answered)
      }
    // After the last one, ask again (the app has usually written new data).
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  static func current(at date: Date) -> ReminderEntry {
    ReminderEntry(
      date: date,
      snapshot: .load(),
      answered: Set(DaymarkShared.recent(DaymarkShared.answeredRemindersKey, now: date).keys))
  }

  static var sample: ReminderEntry {
    let now = Date()
    var snapshot = WidgetSnapshotData(loggedIn: true, taskCount: 0, tasks: [], reminders: [])
    snapshot.reminders = [
      WidgetReminderItem(sample: "Stretch and drink water", id: 1, fireAt: now.addingTimeInterval(25 * 60), repeatInterval: "DAILY"),
      WidgetReminderItem(sample: "Call Sam back", id: 2, fireAt: now.addingTimeInterval(3 * 3600)),
    ]
    return ReminderEntry(date: now, snapshot: snapshot, answered: [])
  }
}

struct NextReminderView: View {
  let entry: ReminderEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if isLockScreen {
      lockScreen.daymarkBackground(.clear)
    } else {
      home.daymarkBackground()
    }
  }

  private var isLockScreen: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return family == .accessoryRectangular || family == .accessoryInline
    }
    return false
  }

  private var isInline: Bool {
    if #available(iOSApplicationExtension 16.0, *) { return family == .accessoryInline }
    return false
  }

  // MARK: Home screen

  @ViewBuilder
  private var home: some View {
    if !entry.snapshot.loggedIn {
      VStack(spacing: 8) {
        BellTile()
        Text("Sign in to Daymark")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(Palette.ink)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .widgetURL(WidgetLinks.workspace)
    } else if let next = entry.upcoming.first {
      if family == .systemMedium {
        medium(next, following: entry.upcoming.dropFirst().first)
      } else {
        details(next)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .widgetURL(WidgetLinks.reminder(next.reminderId))
      }
    } else {
      VStack(spacing: 10) {
        BellTile()
        Text("No upcoming reminders")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
        if family == .systemMedium {
          Link(destination: WidgetLinks.newReminder) { AccentPill(label: "New reminder") }
        } else {
          AccentPill(label: "New reminder")
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .widgetURL(WidgetLinks.newReminder)
    }
  }

  private func details(_ reminder: WidgetReminderItem) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        BellTile()
        Text("Next reminder").font(.system(size: 12)).foregroundStyle(Palette.muted).lineLimit(1)
      }
      Spacer(minLength: 6)
      Text(reminder.title)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Palette.ink)
        .lineLimit(2)
        .privacySensitive()
      Text(WidgetFormat.reminderTime(reminder.fireAt, now: entry.date))
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Palette.ink)
        .lineLimit(1)
        .padding(.top, 4)
      HStack(spacing: 4) {
        (Text("in ") + Text(reminder.fireAt, style: .relative))
          .font(.system(size: 12.5))
          .foregroundStyle(Palette.accent)
          .lineLimit(1)
        if let repeatLabel = reminder.repeatLabel {
          Image("ic_repeat").renderingMode(.template).resizable()
            .frame(width: 12, height: 12)
            .foregroundStyle(Palette.muted)
            .padding(.leading, 2)
          Text(repeatLabel).font(.system(size: 12.5)).foregroundStyle(Palette.muted).lineLimit(1)
        }
      }
    }
  }

  private func medium(_ next: WidgetReminderItem, following: WidgetReminderItem?) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top, spacing: 8) {
        Link(destination: WidgetLinks.reminder(next.reminderId)) {
          details(next).frame(maxWidth: .infinity, alignment: .leading)
        }
        WidgetActionButton(url: WidgetLinks.reminderDone(next)) { AccentPill(label: "Done") }
      }
      if let following {
        Link(destination: WidgetLinks.reminder(following.reminderId)) {
          Text("Then \(following.title) · \(WidgetFormat.reminderTime(following.fireAt, now: entry.date))")
            .font(.system(size: 12.5))
            .foregroundStyle(Palette.muted)
            .lineLimit(1)
            .privacySensitive()
        }
      }
    }
  }

  // MARK: Lock screen

  @ViewBuilder
  private var lockScreen: some View {
    if let next = entry.snapshot.loggedIn ? entry.upcoming.first : nil {
      if isInline {
        Label {
          Text("\(WidgetFormat.time(next.fireAt)) \(next.title)")
        } icon: {
          Image(systemName: "bell")
        }
        .privacySensitive()
        .widgetURL(WidgetLinks.reminder(next.reminderId))
      } else {
        VStack(alignment: .leading, spacing: 1) {
          HStack(spacing: 4) {
            Image(systemName: "bell.fill")
            Text(WidgetFormat.reminderTime(next.fireAt, now: entry.date)).lineLimit(1)
          }
          .font(.headline)
          Text(next.title).lineLimit(2).privacySensitive()
          (Text("in ") + Text(next.fireAt, style: .relative)).font(.caption).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(WidgetLinks.reminder(next.reminderId))
      }
    } else {
      Label(entry.snapshot.loggedIn ? "No upcoming reminders" : "Sign in to Daymark", systemImage: "bell")
        .widgetURL(entry.snapshot.loggedIn ? WidgetLinks.newReminder : WidgetLinks.workspace)
    }
  }
}

struct NextReminderWidget: Widget {
  private var families: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]
    }
    return [.systemSmall, .systemMedium]
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: DaymarkShared.reminderKind, provider: ReminderProvider()) { entry in
      NextReminderView(entry: entry)
    }
    .configurationDisplayName("Next reminder")
    .description("Your next reminder with a countdown. Mark it done from the home screen.")
    .supportedFamilies(families)
  }
}
