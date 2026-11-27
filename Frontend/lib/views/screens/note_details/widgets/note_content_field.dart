import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The borderless `body` field of the note editor.
Widget noteContentField({
  required TextEditingController controller,
  required Function(String) onChanged,
  String? errorText,
}) {
  final hasError = errorText != null && errorText.isNotEmpty;

  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            minLines: 8,
            maxLines: null,
            style: DaymarkText.body.copyWith(color: palette.ink),
            decoration: InputDecoration(
              hintText: "Start writing…",
              hintStyle: DaymarkText.body.copyWith(color: palette.muted),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(errorText, style: DaymarkText.meta.copyWith(color: palette.danger)),
          ],
        ],
      );
    },
  );
}
