import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

Widget registerNameField({
  required TextEditingController controller,
  required bool isError,
  required String errorText,
  required Function(String value) onChanged,
}) {
  return customTextInputField(
    controller: controller,
    labelText: 'Full Name',
    isError: isError,
    errorText: errorText,
    onChanged: onChanged,
    length: 50,
    inputFormatters: [],
    keyboardType: TextInputType.name,
  );
}
