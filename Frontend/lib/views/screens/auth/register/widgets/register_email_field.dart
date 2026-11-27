import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

Widget registerEmailField({
  required TextEditingController controller,
  required bool isError,
  required String errorText,
  required Function(String value) onChanged,
}) {
  return customTextInputField(
    controller: controller,
    labelText: 'Email',
    isError: isError,
    errorText: errorText,
    onChanged: onChanged,
    length: 100,
    inputFormatters: [],
    keyboardType: TextInputType.emailAddress,
    prefixIcon: AppIcons.email,
  );
}
