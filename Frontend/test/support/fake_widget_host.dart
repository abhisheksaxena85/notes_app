import 'dart:convert';

import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot.dart';

/// Records what the app would hand to home_widget (W-01).
class FakeWidgetHost implements WidgetHost {
  FakeWidgetHost({this.supported = true});

  final bool supported;
  final Map<String, String?> saved = {};
  int updates = 0;
  List<DateTime> scheduled = [];

  /// The last snapshot saved, decoded.
  Map<String, dynamic>? get snapshot {
    final raw = saved[WidgetSnapshot.storageKey];
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  bool get isSupported => supported;

  @override
  Future<void> saveString(String key, String? value) async => saved[key] = value;

  @override
  Future<String?> readString(String key) async => saved[key];

  @override
  Future<void> updateAll() async => updates++;

  @override
  Future<void> scheduleReminderRefreshes(List<DateTime> times) async => scheduled = times;
}
