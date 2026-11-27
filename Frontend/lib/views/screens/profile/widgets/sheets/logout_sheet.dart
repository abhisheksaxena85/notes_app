import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/login/login_screen.dart';

/// Logging out: the confirmation and the sign-out itself.
Future<void> confirmLogout(BuildContext context) async {
  final palette = context.daymark;
  // Signing out wipes this user's data from the device, including changes
  // that haven't reached the server yet: say so before they are lost.
  final unsynced = await getIt<SessionService>().unsyncedChangeCount();
  if (!context.mounted) return;
  final String message;
  if (unsynced == 0) {
    message = "Are you sure you want to sign out of Daymark on this device?";
  } else {
    final changes = unsynced == 1 ? "1 change" : "$unsynced changes";
    message =
        "$changes on this device ${unsynced == 1 ? "hasn't" : "haven't"} been synced yet. "
        "Signing out deletes ${unsynced == 1 ? "it" : "them"} for good.\n\n"
        "To keep ${unsynced == 1 ? "it" : "them"}, cancel, go online and wait for the sync to finish.";
  }
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        unsynced == 0 ? "Sign Out" : "Unsynced changes",
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.ink),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13.sp, color: palette.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text("Cancel", style: GoogleFonts.inter(color: palette.muted)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            logOutAndShowLogin(context);
          },
          child: Text(
            unsynced == 0 ? "Sign Out" : "Sign Out Anyway",
            style: GoogleFonts.inter(color: palette.danger, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Ends the session, wipes the user's local data and resets every
/// controller, so the next user starts clean.

Future<void> logOutAndShowLogin(BuildContext context) async {
  // Taken before the await: this widget may be gone by the time it returns.
  final container = ProviderScope.containerOf(context, listen: false);
  await getIt<SessionService>().logout();
  for (final controller in sessionScopedControllers) {
    container.invalidate(controller);
  }
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
