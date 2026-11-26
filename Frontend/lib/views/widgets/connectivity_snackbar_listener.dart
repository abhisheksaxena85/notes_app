import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/services/connectivity_service.dart';

/// Shows "offline" / "back online" snackbars for the whole app.
///
/// Sits above `MaterialApp`, so app rebuilds (theme, locale, keyboard,
/// rotation) keep this state: it subscribes to [connectivity] once and
/// cancels in [State.dispose]. A change must last [debounce] before it is
/// shown, and "back online" is only shown after "offline" was.
class ConnectivitySnackbarListener extends StatefulWidget {
  final ConnectivityService connectivity;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Duration debounce;
  final Widget child;

  const ConnectivitySnackbarListener({
    super.key,
    required this.connectivity,
    required this.messengerKey,
    required this.child,
    this.debounce = const Duration(seconds: 2),
  });

  @override
  State<ConnectivitySnackbarListener> createState() =>
      _ConnectivitySnackbarListenerState();
}

class _ConnectivitySnackbarListenerState
    extends State<ConnectivitySnackbarListener> {
  StreamSubscription<bool>? _subscription;
  Timer? _debounce;
  bool _offlineShown = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.connectivity.online.listen(_onChange);
  }

  void _onChange(bool online) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _show(online));
  }

  void _show(bool online) {
    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    if (!online && !_offlineShown) {
      _offlineShown = true;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          failedSnackBar("You're offline. Changes are saved on this device."),
        );
    } else if (online && _offlineShown) {
      _offlineShown = false;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(successSnackBar("Back online. Syncing your changes."));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
