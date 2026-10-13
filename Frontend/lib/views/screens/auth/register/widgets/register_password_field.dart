import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

Widget registerPasswordField({
  required TextEditingController controller,
  required bool isError,
  required String errorText,
  required Function(String value) onChanged,
}) {
  return customTextInputField(
    controller: controller,
    labelText: 'Password',
    isError: isError,
    errorText: errorText,
    onChanged: onChanged,
    length: 100,
    inputFormatters: [],
    keyboardType: TextInputType.visiblePassword,
  );
}
