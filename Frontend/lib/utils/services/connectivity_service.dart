import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';

/// The app's one view of internet connectivity (registered in get_it).
///
/// It owns the only [InternetConnectionChecker] subscription; everything else
/// (the sync service, the snackbar listener) subscribes to [online].
class ConnectivityService {
  final Stream<InternetConnectionStatus> _statusChanges;
  final StreamController<bool> _online = StreamController<bool>.broadcast();
  StreamSubscription<InternetConnectionStatus>? _subscription;
  bool? _isOnline;

  /// [statusChanges] is the checker's status stream (a fake one in tests).
  ConnectivityService(this._statusChanges);

  /// Polls the network with the device's [InternetConnectionChecker].
  factory ConnectivityService.device() => ConnectivityService(
    InternetConnectionChecker.createInstance().onStatusChange,
  );

  /// Whether the last check reached the internet. Until the first check
  /// completes this is `true`: requests are tried and report their own errors.
  bool get isOnline => _isOnline ?? true;

  /// Emits `true` / `false` when connectivity changes (the first check is
  /// always emitted). Only changes are emitted, never the same value twice.
  Stream<bool> get online => _online.stream;

  /// Starts watching the network. Safe to call more than once.
  void start() {
    _subscription ??= _statusChanges.listen((status) {
      // `slow` still reaches the server.
      final online = status != InternetConnectionStatus.disconnected;
      if (online == _isOnline) return;
      _isOnline = online;
      _online.add(online);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _online.close();
  }
}
