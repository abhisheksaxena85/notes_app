import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/background_graph.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/quick_add_task_sheet.dart';

/// W-03 (Android): the whole app QuickAddTaskActivity runs: only the
/// quick-add sheet, over the home screen, on a transparent window. It uses
/// the light task graph (FIX-02: no notifications, no reminder scheduler, no
/// sync loop, no get_it) and finishes after saving or when the user taps
/// outside.
void runQuickAddTaskApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuickAddTaskApp());
}

class QuickAddTaskApp extends StatefulWidget {
  const QuickAddTaskApp({
    super.key,
    this.openGraph = TaskGraph.open,
    this.widgetHost,
    this.onFinish,
  });

  /// Opens what saving a task needs (tests pass an in-memory one).
  final Future<TaskGraph> Function() openGraph;

  /// Where the widget snapshot goes (home_widget by default).
  final WidgetHost? widgetHost;

  /// Closes the pop-up (finishes the activity by default).
  final VoidCallback? onFinish;

  @override
  State<QuickAddTaskApp> createState() => _QuickAddTaskAppState();
}

class _QuickAddTaskAppState extends State<QuickAddTaskApp> {
  TaskGraph? _graph;
  Object? _error;
  ThemeMode _themeMode = ThemeMode.light;

  /// QuickAddTaskActivity says when its window gains input focus.
  static const _activity = MethodChannel('com.invospec.daymark/quick_add');

  @override
  void initState() {
    super.initState();
    _activity.setMethodCallHandler(_onActivityCall);
    unawaited(_open());
  }

  @override
  void dispose() {
    _activity.setMethodCallHandler(null);
    super.dispose();
  }

  /// FIX-02: with the app's process already running, the title is focused
  /// before the window has input focus and Android drops that keyboard
  /// request. Ask again once the window is focused.
  Future<void> _onActivityCall(MethodCall call) async {
    if (call.method != 'windowFocused') return;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused?.findAncestorWidgetOfExactType<EditableText>() == null) return;
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  Future<void> _open() async {
    try {
      final graph = await widget.openGraph();
      if (!mounted) {
        unawaited(graph.close());
        return;
      }
      // The app's appearance setting (light unless dark was chosen), like
      // ThemeModeNotifier.
      final dark = Preference().getBool(PreferenceKeys.IS_DARK_THEME) ?? false;
      setState(() {
        _graph = graph;
        _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
      });
    } catch (error, stackTrace) {
      // debugPrint too: log() never reaches logcat in release builds.
      log('Quick add could not start: $error', stackTrace: stackTrace);
      debugPrint('Quick add could not start: $error\n$stackTrace');
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _save(QuickAddTaskDraft draft) async {
    final graph = _graph!;
    await saveQuickAddTask(draft, repo: graph.taskRepo, userId: graph.userId);
    await WidgetSnapshotService(
      database: graph.database,
      host: widget.widgetHost ?? HomeWidgetHost(),
      currentUserId: () => graph.userId,
    ).refresh();
    // A short upload attempt; the app's sync sends it later otherwise.
    try {
      graph.sync.setUserId(graph.userId);
      await graph.sync.requestSync().timeout(const Duration(seconds: 3));
    } catch (error) {
      log('Quick-added task saved; it will sync later ($error)');
    }
  }

  void _finish() {
    unawaited(_graph?.close());
    final onFinish = widget.onFinish;
    if (onFinish != null) {
      onFinish();
    } else {
      unawaited(SystemNavigator.pop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final graph = _graph;
    return MaterialApp(
      title: 'Add task',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      color: Colors.transparent,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Tapping outside the sheet closes it.
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('quickAddScrim'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _finish,
                  child: ColoredBox(color: context.daymark.scrim),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: context.daymark.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: _body(context, graph),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TaskGraph? graph) {
    final palette = context.daymark;
    if (_error != null || (graph != null && graph.userId == 0)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _error != null ? 'Something went wrong' : 'Sign in to Daymark',
              style: DaymarkText.sheetTitle.copyWith(color: palette.ink),
            ),
            const SizedBox(height: 6),
            Text(
              _error == null
                  ? 'Open the app and sign in to add tasks from the widget.'
                  // Debug builds show what failed; release keeps it friendly.
                  : kDebugMode
                      ? 'Quick add could not start: $_error'
                      : 'Open Daymark and try again.',
              style: DaymarkText.preview.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Close', onPressed: _finish),
          ],
        ),
      );
    }
    if (graph == null) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return QuickAddTaskSheet(onSave: _save, onDone: _finish, onClose: _finish);
  }
}
