import 'dart:convert';
import 'dart:developer';

import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';

/// W-03: tasks added outside the app on iOS ("Add task in Daymark" App
/// Intent from Siri, Shortcuts or the Action button) wait in a JSON "inbox"
/// in the App Group until the app imports them into Drift.
///
/// The intent appends an item to the JSON array under [key]:
/// `{"id": uuid, "title": text, "dueDate": "yyyy-MM-dd" or null, "createdAt": epochMillis}`.
/// The Tasks widget shows those items right away. [importAll] saves
/// each through [TaskRepo] (local first plus the outbox) with the inbox id as
/// its client id, so an item is never imported twice (the id is also the
/// server's idempotency key), then removes what it imported.
///
/// Runs on app start and resume, and in the background when the intent
/// wakes the app (`daymark://widget/import-inbox`).
class WidgetTaskInbox {
  static const key = 'daymark_task_inbox';

  final WidgetHost host;
  final TaskRepo repo;
  final int Function() currentUserId;

  Future<int>? _running;

  WidgetTaskInbox({required this.host, required this.repo, required this.currentUserId});

  /// Imports every waiting item for the signed-in user; returns how many
  /// tasks were added. Signed out, the items wait. Never throws.
  Future<int> importAll() {
    // One import at a time: a second one would find the same items.
    return _running ??= _import().whenComplete(() => _running = null);
  }

  Future<int> _import() async {
    if (!host.isSupported) return 0;
    final userId = currentUserId();
    if (userId == 0) return 0;
    try {
      final items = decode(await host.readString(key));
      if (items.isEmpty) return 0;
      var added = 0;
      final handled = <String>{};
      for (final item in items) {
        final clientId = item.id.toLowerCase();
        if (!await repo.hasTaskWithClientId(userId, clientId)) {
          await repo.enqueueTask(CreateTaskRequestDto(
            userId: userId,
            title: item.title,
            dueDate: item.dueDate,
            category: 'General',
            priority: 'MEDIUM',
            clientId: clientId,
          ));
          added++;
        }
        handled.add(item.id);
      }
      // Re-read: the intent may have added more while this ran.
      final remaining = decode(await host.readString(key))
          .where((item) => !handled.contains(item.id))
          .toList();
      await host.saveString(key, remaining.isEmpty ? null : encode(remaining));
      return added;
    } catch (error, stackTrace) {
      log('Importing the widget task inbox failed: $error', stackTrace: stackTrace);
      return 0;
    }
  }

  /// The valid items of an inbox value; anything unreadable is skipped.
  static List<InboxTask> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return const [];
      return [
        for (final entry in json) ?InboxTask.tryParse(entry),
      ];
    } on FormatException {
      return const [];
    }
  }

  static String encode(List<InboxTask> items) =>
      jsonEncode([for (final item in items) item.toJson()]);
}

class InboxTask {
  final String id;
  final String title;
  final String? dueDate;
  final int? createdAt;

  const InboxTask({required this.id, required this.title, this.dueDate, this.createdAt});

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static InboxTask? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    // 36 = a UUID, the server's limit for client ids.
    if (id is! String || id.isEmpty || id.length > 36) return null;
    if (title is! String || title.trim().isEmpty) return null;
    final dueDate = json['dueDate'];
    final createdAt = json['createdAt'];
    return InboxTask(
      id: id,
      title: title.trim(),
      dueDate: dueDate is String && _date.hasMatch(dueDate) ? dueDate : null,
      createdAt: createdAt is int ? createdAt : null,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'dueDate': dueDate,
    'createdAt': createdAt,
  };
}
