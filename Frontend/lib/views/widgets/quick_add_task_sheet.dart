import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// When a quick-added task is due.
enum QuickAddDue { today, tomorrow, none }

/// What the quick-add sheet collected.
@immutable
class QuickAddTaskDraft {
  final String title;
  final QuickAddDue due;

  /// Only with a date.
  final TimeOfDay? time;

  const QuickAddTaskDraft({required this.title, this.due = QuickAddDue.today, this.time});

  /// The create request for [userId]: dates are the device's local day.
  CreateTaskRequestDto toRequest(int userId, DateTime now) {
    final day = switch (due) {
      QuickAddDue.today => wallClock(now.year, now.month, now.day),
      QuickAddDue.tomorrow => wallClock(now.year, now.month, now.day + 1),
      QuickAddDue.none => null,
    };
    final at = time;
    return CreateTaskRequestDto(
      userId: userId,
      title: title.trim(),
      dueDate: day == null ? null : formatDueDate(day),
      dueTime: day == null || at == null ? null : formatDueTime(wallClock(2000, 1, 1, at.hour, at.minute)),
      category: 'General',
      priority: 'MEDIUM',
    );
  }
}

/// W-03: saves a quick-added task the way the app saves every task (Drift
/// plus the outbox through [TaskRepo], which asks for a sync), then redraws
/// the home-screen widgets.
Future<void> saveQuickAddTask(
  QuickAddTaskDraft draft, {
  required TaskRepo repo,
  required int userId,
  WidgetSnapshotService? widgets,
  DateTime Function() now = DateTime.now,
}) async {
  await repo.enqueueTask(draft.toRequest(userId, now()));
  if (widgets != null) unawaited(widgets.refresh());
}

/// Opens the quick-add sheet over the app (the widget's plus on iOS, and
/// `daymark://quick-add-task`). Returns true when a task was added.
Future<bool?> showQuickAddTaskSheet(BuildContext context) {
  return showDaymarkSheet<bool>(
    context,
    builder: (_) => QuickAddTaskSheet(
      onSave: (draft) => saveQuickAddTask(
        draft,
        repo: getIt<TaskRepo>(),
        userId: getIt<SessionService>().userId,
        widgets: getIt<WidgetSnapshotService>(),
      ),
    ),
  );
}

/// W-03: a compact "add a task" sheet: the title (focused), Today /
/// Tomorrow / No date, an optional time and "Add task".
///
/// [onSave] stores the task; the sheet then calls [onDone] with true
/// (default: pops the route with true). [onClose] runs for the close button
/// (default: pops).
class QuickAddTaskSheet extends StatefulWidget {
  const QuickAddTaskSheet({super.key, required this.onSave, this.onDone, this.onClose});

  final Future<void> Function(QuickAddTaskDraft draft) onSave;
  final VoidCallback? onDone;
  final VoidCallback? onClose;

  @override
  State<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends State<QuickAddTaskSheet> {
  final _title = TextEditingController();
  QuickAddDue _due = QuickAddDue.today;
  TimeOfDay? _time;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty && !_saving;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(QuickAddTaskDraft(
        title: _title.text,
        due: _due,
        time: _due == QuickAddDue.none ? null : _time,
      ));
      if (!mounted) return;
      final done = widget.onDone;
      if (done != null) {
        done();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      log('Quick add failed: $error', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _saving = false;
          _error = userMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final time = _time;
    return SheetScaffold(
      title: 'New task',
      onClose: widget.onClose,
      footer: PrimaryButton(
        label: 'Add task',
        icon: AppIcons.plus,
        loading: _saving,
        onPressed: _canSave ? _save : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('quickAddTitle'),
            controller: _title,
            autofocus: true,
            style: DaymarkText.custom(15, FontWeight.w400).copyWith(color: palette.ink),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(hintText: 'What needs to be done?', errorText: _error),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (due, label) in const [
                (QuickAddDue.today, 'Today'),
                (QuickAddDue.tomorrow, 'Tomorrow'),
                (QuickAddDue.none, 'No date'),
              ])
                DaymarkChip(
                  label: label,
                  selected: _due == due,
                  style: DaymarkChipStyle.category,
                  onTap: () => setState(() => _due = due),
                ),
            ],
          ),
          if (_due != QuickAddDue.none) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PickerField(
                    icon: AppIcons.clock,
                    value: time == null ? 'Add a time (optional)' : time.format(context),
                    placeholder: time == null,
                    onTap: _pickTime,
                  ),
                ),
                if (time != null)
                  IconButton(
                    tooltip: 'Remove time',
                    onPressed: () => setState(() => _time = null),
                    icon: AppIcons.icon(AppIcons.close, color: palette.muted, size: 18),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
