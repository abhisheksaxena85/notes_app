//
//  DaymarkWidgetIntent.swift
//  Compiled into both the Runner app and the DaymarkWidgets extension (W-06),
//  as home_widget's interactive-widget setup requires.
//
//  The widgets' buttons (iOS 17+): tick a task, answer a reminder Done.
//  The tap is recorded in the App Group first, so the widget shows it at once
//  and the app applies it on its next start even if Dart can't run now. In
//  the app process, home_widget then runs the Dart interactivity callback
//  (widgetInteractivityCallback, W-02), which saves it through the
//  repositories and the outbox and redraws the widgets.
//

import AppIntents
import Foundation
import WidgetKit

// DAYMARK_APP is set for the Runner target only (ios/scripts/
// add_widget_extension.rb): the extension doesn't link home_widget.
#if DAYMARK_APP
  import home_widget
#endif

@available(iOS 17, *)
public struct DaymarkWidgetIntent: AppIntent {
  public static var title: LocalizedStringResource = "Daymark widget action"
  public static var isDiscoverable: Bool = false

  @Parameter(title: "Widget URI")
  var url: URL?

  public init() {}

  public init(url: URL) {
    self.url = url
  }

  public func perform() async throws -> some IntentResult {
    guard let url else { return .result() }
    DaymarkShared.recordWidgetAction(url)
    WidgetCenter.shared.reloadAllTimelines()
    #if DAYMARK_APP
      // Never wait long: the background engine may not be up yet (the app
      // then applies the queued action when it starts).
      await DaymarkBackground.run(url, timeout: 8)
    #endif
    return .result()
  }
}

#if DAYMARK_APP
  /// Lets the system run the intent in the app (where Dart can run), as
  /// home_widget's docs describe.
  @available(iOS 17, *)
  @available(iOSApplicationExtension, unavailable)
  extension DaymarkWidgetIntent: ForegroundContinuableIntent {}

  /// Runs the Dart interactivity callback for [url], giving up waiting after
  /// [timeout] seconds (the callback still runs if the engine comes up later).
  enum DaymarkBackground {
    @available(iOS 17, *)
    static func run(_ url: URL, timeout: TimeInterval) async {
      let finished = Flag()
      Task {
        await HomeWidgetBackgroundWorker.run(url: url, appGroup: DaymarkShared.appGroup)
        finished.set()
      }
      let deadline = Date().addingTimeInterval(timeout)
      while !finished.isSet && Date() < deadline {
        try? await Task.sleep(nanoseconds: 200_000_000)
      }
    }

    private final class Flag: @unchecked Sendable {
      private let lock = NSLock()
      private var value = false

      var isSet: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
      }

      func set() {
        lock.lock()
        value = true
        lock.unlock()
      }
    }
  }
#endif
