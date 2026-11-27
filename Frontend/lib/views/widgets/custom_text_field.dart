/// @author Abhishek Saxena
/// Creation Date: 17-09-2025
/// Copyright © EL Nova Labs 2025. All rights reserved.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';

/// A labelled 48 px text field (login, register). [prefixIcon] is an
/// [AppIcons] path; [obscureText] adds the show / hide toggle.
Widget customTextInputField({
  required TextEditingController? controller,
  required String labelText,
  required bool isError,
  required String errorText,
  required Function(String value)? onChanged,
  required int? length,
  required List<TextInputFormatter> inputFormatters,
  required TextInputType keyboardType,
  Color? backgroundColor,
  bool? isEnabled,
  double? height,
  FocusNode? focusNode,
  String? prefixIcon,
  bool obscureText = false,
  String? hintText,
}) {
  return DaymarkTextField(
    controller: controller,
    label: labelText,
    errorText: isError ? errorText : null,
    onChanged: onChanged,
    maxLength: length,
    inputFormatters: inputFormatters,
    keyboardType: keyboardType,
    backgroundColor: backgroundColor,
    enabled: isEnabled,
    focusNode: focusNode,
    prefixIcon: prefixIcon,
    obscureText: obscureText,
    hintText: hintText,
  );
}

class DaymarkTextField extends StatefulWidget {
  const DaymarkTextField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.onChanged,
    this.maxLength,
    this.inputFormatters = const [],
    this.keyboardType = TextInputType.text,
    this.backgroundColor,
    this.enabled,
    this.focusNode,
    this.prefixIcon,
    this.obscureText = false,
    this.hintText,
  });

  final TextEditingController? controller;
  final String label;

  /// Shown below the field and turns the border `danger` when not empty.
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter> inputFormatters;
  final TextInputType keyboardType;
  final Color? backgroundColor;
  final bool? enabled;
  final FocusNode? focusNode;
  final String? prefixIcon;
  final bool obscureText;
  final String? hintText;

  @override
  State<DaymarkTextField> createState() => _DaymarkTextFieldState();
}

class _DaymarkTextFieldState extends State<DaymarkTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return LabeledField(
      label: widget.label,
      errorText: widget.errorText,
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          obscureText: _hidden,
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          maxLength: widget.maxLength,
          maxLines: 1,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
          textAlignVertical: TextAlignVertical.center,
          style: DaymarkText.custom(15, FontWeight.w400).copyWith(
            color: widget.enabled == false ? palette.muted : palette.ink,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            fillColor: widget.backgroundColor ?? palette.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: AppIcons.icon(widget.prefixIcon!, size: 18, color: palette.muted),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: AppIcons.icon(
                      AppIcons.show,
                      size: 18,
                      color: _hidden ? palette.muted : palette.accent,
                    ),
                  )
                : null,
            enabledBorder: border(hasError ? palette.danger : palette.line),
            focusedBorder: border(hasError ? palette.danger : palette.accent, 1.5),
            disabledBorder: border(palette.line),
          ),
        ),
      ),
    );
  }
}
