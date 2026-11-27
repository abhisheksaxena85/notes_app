import 'package:flutter/foundation.dart';

/// Deep links opened from the home-screen widgets (W-01).
///
/// - `daymark://task/<id>`: the Workspace with that task's sheet open
/// - `daymark://reminder/<id>`: the Workspace with that reminder's sheet open
/// - `daymark://quick-add-task`: the quick-add task sheet
/// - `daymark://new-reminder`: the new reminder sheet
/// - `daymark://workspace`: the Workspace
///
/// Ids are the app's item ids (server id, or minus the local id). The native
/// widgets add a `homeWidget` query parameter on iOS, which home_widget needs
/// to recognise a widget launch; it is ignored here.
sealed class WidgetLink {
  const WidgetLink();

  static const scheme = 'daymark';

  static WidgetLink? parse(Uri? uri) {
    if (uri == null || uri.scheme.toLowerCase() != scheme) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    int? idArg() => segments.isEmpty ? null : int.tryParse(segments.first);
    switch (uri.host.toLowerCase()) {
      case 'task':
        final id = idArg();
        return id == null ? null : OpenTaskLink(id);
      case 'reminder':
        final id = idArg();
        return id == null ? null : OpenReminderLink(id);
      case 'quick-add-task':
        return const QuickAddTaskLink();
      case 'new-reminder':
        return const NewReminderLink();
      case 'workspace':
        return const WorkspaceLink();
      default:
        return null;
    }
  }
}

final class OpenTaskLink extends WidgetLink {
  final int id;
  const OpenTaskLink(this.id);

  @override
  bool operator ==(Object other) => other is OpenTaskLink && other.id == id;
  @override
  int get hashCode => Object.hash('task', id);
}

final class OpenReminderLink extends WidgetLink {
  final int id;
  const OpenReminderLink(this.id);

  @override
  bool operator ==(Object other) => other is OpenReminderLink && other.id == id;
  @override
  int get hashCode => Object.hash('reminder', id);
}

final class QuickAddTaskLink extends WidgetLink {
  const QuickAddTaskLink();
}

final class NewReminderLink extends WidgetLink {
  const NewReminderLink();
}

final class WorkspaceLink extends WidgetLink {
  const WorkspaceLink();
}

/// Widget links waiting for the dashboard, which opens the screen or sheet
/// once it is on screen (so after the splash and login on a cold start),
/// like `reminderPromptRequests` for notification taps.
final widgetLinkRequests = ValueNotifier<WidgetLink?>(null);

/// Queues [uri] for the dashboard if it is a widget link.
void routeWidgetLaunch(Uri? uri) {
  final link = WidgetLink.parse(uri);
  if (link != null) widgetLinkRequests.value = link;
}
