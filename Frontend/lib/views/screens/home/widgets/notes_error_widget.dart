import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/widgets/state_message.dart';

Widget notesErrorWidget({
  required String message,
  required VoidCallback onRetry,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 32),
    child: Align(
      alignment: Alignment.topCenter,
      child: StateMessage(
        icon: AppIcons.info,
        danger: true,
        title: "Unable to load your workspace",
        message: message.isNotEmpty ? message : "Something went wrong while fetching notes.",
        actionLabel: "Try again",
        onAction: onRetry,
      ),
    ),
  );
}
