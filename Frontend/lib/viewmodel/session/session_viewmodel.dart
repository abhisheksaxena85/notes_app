import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/session/session_service.dart';

/// The signed-in user id (0 when signed out), kept in step with
/// [SessionService]. Controllers watch it in `build()`, so they rebuild with
/// the new user's data on login and logout.
class SessionUserIdViewmodel extends Notifier<int> {
  @override
  int build() {
    final session = getIt<SessionService>();
    final subscription = session.changes.listen((userId) => state = userId);
    ref.onDispose(subscription.cancel);
    return session.userId;
  }
}
