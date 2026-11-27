package com.devquorix.daymark.widgets

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

/**
 * W-03: the quick-add pop-up the Tasks widget's plus opens over the home screen.
 *
 * Runs its own Flutter engine with the `quickAddTaskMain` entrypoint (lib/main.dart), which shows
 * only the quick-add sheet on a transparent window. The Dart side finishes the activity after
 * saving or when the user taps outside the sheet. Declared with its own task affinity and excluded
 * from recents, so it never mixes with the app's task.
 */
class QuickAddTaskActivity : FlutterActivity() {
  override fun getDartEntrypointFunctionName(): String = "quickAddTaskMain"

  override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent
}
