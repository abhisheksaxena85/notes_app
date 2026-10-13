import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

Widget registerMobileField({
  required TextEditingController controller,
  required bool isError,
  required String errorText,
  required Function(String value) onChanged,
}) {
  return customTextInputField(
    controller: controller,
    labelText: 'Mobile Number',
    isError: isError,
    errorText: errorText,
    onChanged: onChanged,
    length: 10,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    keyboardType: TextInputType.phone,
  );
}
