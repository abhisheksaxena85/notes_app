import Flutter
import UIKit
// Needed for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications
// W-02/W-06: widget buttons run Dart in a background engine.
import home_widget

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Interactive widgets (iOS 17): the engine home_widget starts for the
    // Dart callback needs the plugins (database, secure storage, ...).
    if #available(iOS 17, *) {
      HomeWidgetBackgroundWorker.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene / implicit-engine lifecycle: plugin setup happens here.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Reminder action buttons ("Done", "Not done", "Snooze") run Dart in a
    // background isolate; it needs the plugins registered too.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Deliver notification taps and actions to flutter_local_notifications,
    // and let it show reminders while the app is in the foreground.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
  }
}
