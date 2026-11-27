import 'package:flutter/material.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';

Widget registerGenderSelector({
  required String selectedGender,
  required Function(String gender) onGenderChanged,
}) {
  const options = [('Male', 'male'), ('Female', 'female'), ('Other', 'other')];
  return LabeledField(
    label: 'Gender',
    child: Wrap(
      spacing: 8,
      children: [
        for (final (label, value) in options)
          DaymarkChip(
            label: label,
            selected: selectedGender == value,
            style: DaymarkChipStyle.category,
            onTap: () => onGenderChanged(value),
          ),
      ],
    ),
  );
}
