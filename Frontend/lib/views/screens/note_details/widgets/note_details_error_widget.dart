import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/widgets/state_message.dart';

Widget noteDetailsErrorWidget({
  required String message,
  required VoidCallback onRetry,
}) {
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            icon: AppIcons.icon(AppIcons.back, size: 20, color: context.daymark.ink),
          ),
        ),
        Expanded(
          child: Center(
            child: StateMessage(
              icon: AppIcons.note,
              danger: true,
              title: "Failed to load note",
              message: message.isNotEmpty
                  ? message
                  : "Something went wrong while fetching note details.",
              actionLabel: "Retry",
              onAction: onRetry,
            ),
          ),
        ),
      ],
    ),
  );
}
