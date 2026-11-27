//
//  AddTaskIntent.swift
//  Runner only (W-03 / W-06).
//
//  "Add task in Daymark" for Siri, Shortcuts and the Action button. Runs
//  without opening the app: the task goes into the App Group inbox, the Tasks
//  widget shows it at once, and the app imports it into its database (local
//  first plus the outbox) on its next start or resume, or right away when the
//  Dart background engine is running.
//

import AppIntents
import Foundation
import WidgetKit
import home_widget

@available(iOS 16, *)
struct AddTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Add task in Daymark"
  static var description = IntentDescription("Adds a task to today's list in Daymark.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Title", requestValueDialog: "What's the task?")
  var taskTitle: String

  static var parameterSummary: some ParameterSummary {
    Summary("Add \(\.$taskTitle) in Daymark")
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else {
      throw $taskTitle.needsValueError("What's the task?")
    }
    guard DaymarkShared.isSignedIn else {
      return .result(dialog: "Open Daymark and sign in first.")
    }
    DaymarkShared.appendInboxTask(title: String(title.prefix(255)), dueDate: DaymarkShared.dayString())
    WidgetCenter.shared.reloadAllTimelines()
    if #available(iOS 17, *), let url = URL(string: "daymark://widget/import-inbox") {
      await DaymarkBackground.run(url, timeout: 3)
    }
    return .result(dialog: "Added “\(title)” to Daymark.")
  }
}

@available(iOS 16, *)
struct DaymarkShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddTaskIntent(),
      phrases: [
        "Add task in \(.applicationName)",
        "Add a task in \(.applicationName)",
        "New \(.applicationName) task",
      ],
      shortTitle: "Add task",
      systemImageName: "plus.circle"
    )
  }
}
