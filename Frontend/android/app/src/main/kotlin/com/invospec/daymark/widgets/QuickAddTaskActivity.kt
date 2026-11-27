package com.invospec.daymark.widgets

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * W-03: the quick-add pop-up the Tasks widget's plus opens over the home screen.
 *
 * Runs its own Flutter engine with the `quickAddTaskMain` entrypoint (lib/main.dart), which shows
 * only the quick-add sheet on a transparent window. The Dart side finishes the activity after
 * saving or when the user taps outside the sheet. Declared with its own task affinity and excluded
 * from recents, so it never mixes with the app's task.
 */
class QuickAddTaskActivity : FlutterActivity() {
  private var channel: MethodChannel? = null

  override fun getDartEntrypointFunctionName(): String = "quickAddTaskMain"

  override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
  }

  /**
   * FIX-02: when the app's process is already running, Dart focuses the title before this window
   * has input focus, and Android ignores that keyboard request ("view is not served"). Tell Dart
   * once the window has focus so it can ask again.
   */
  override fun onWindowFocusChanged(hasFocus: Boolean) {
    super.onWindowFocusChanged(hasFocus)
    if (hasFocus) channel?.invokeMethod("windowFocused", null)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    channel = null
    super.cleanUpFlutterEngine(flutterEngine)
  }

  private companion object {
    const val CHANNEL = "com.invospec.daymark/quick_add"
  }
}
