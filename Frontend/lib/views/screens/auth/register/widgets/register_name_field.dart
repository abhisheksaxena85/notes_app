import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

Widget registerNameField({
  required TextEditingController controller,
  required bool isError,
  required String errorText,
  required Function(String value) onChanged,
}) {
  return customTextInputField(
    controller: controller,
    labelText: 'Full name',
    isError: isError,
    errorText: errorText,
    onChanged: onChanged,
    length: 50,
    prefixIcon: AppIcons.profile,
    inputFormatters: [],
    keyboardType: TextInputType.name,
  );
}
