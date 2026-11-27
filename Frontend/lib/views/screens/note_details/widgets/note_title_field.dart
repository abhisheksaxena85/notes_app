import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The borderless `display` title field of the note editor.
Widget noteTitleField({
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
            style: DaymarkText.display.copyWith(color: palette.ink),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            decoration: InputDecoration(
              hintText: "Title",
              hintStyle: DaymarkText.display.copyWith(color: palette.disabled),
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
