import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';

/// How long the "Undo" snackbar stays before the delete goes through.
const undoWindow = Duration(seconds: 5);

/// FE-06: delete with undo. [hide] takes the item off the screen at once and
/// a snackbar offers "Undo" for [duration]. Only when it closes without Undo
/// does [delete] run (the local delete plus its queued server delete), so an
/// undo never has to take back a change that may already be syncing. If the
/// app dies inside the window nothing was deleted: the item simply stays.
///
/// Showing another undo snackbar closes this one, which commits this delete.
/// [restore] puts the item back after an undo or a failed delete.
Future<void> deleteWithUndo({
  required ScaffoldMessengerState messenger,
  required String message,
  required VoidCallback hide,
  required VoidCallback restore,
  required Future<void> Function() delete,
  Duration duration = undoWindow,
}) async {
  hide();
  // A queued snackbar would wait for the current one; commit that instead.
  messenger.hideCurrentSnackBar();
  final reason = await messenger
      .showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          // Without this, a snackbar with an action never times out when
          // accessibility navigation is on, so the delete would never commit.
          persist: false,
          action: SnackBarAction(label: 'Undo', onPressed: () {}),
        ),
      )
      .closed;
  if (reason == SnackBarClosedReason.action) {
    restore();
    return;
  }
  try {
    await delete();
  } catch (e, st) {
    log('Delete failed: $e', stackTrace: st);
    restore();
    if (messenger.mounted) {
      messenger.showSnackBar(failedSnackBar(userMessage(e)));
    }
  }
}
