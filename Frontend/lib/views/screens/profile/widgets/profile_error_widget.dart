import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/widgets/state_message.dart';

Widget profileErrorWidget({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: StateMessage(
      icon: AppIcons.profile,
      danger: true,
      title: "Unable to load profile",
      message: message.isNotEmpty
          ? message
          : "Something went wrong while fetching user profile.",
      actionLabel: "Retry",
      onAction: onRetry,
    ),
  );
}
