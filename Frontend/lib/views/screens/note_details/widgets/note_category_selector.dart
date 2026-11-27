import 'package:flutter/material.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';

/// Note categories, shared by the note editor and the task/reminder sheets.
const noteCategories = ["General", "Work", "Personal", "Planning", "Ideas", "Study"];

/// Horizontally scrollable category chips; the selection matches
/// case-insensitively.
Widget noteCategorySelector({
  required String selectedCategory,
  required Function(String) onCategorySelected,
}) {
  final selected = noteCategories.firstWhere(
    (c) => c.toLowerCase() == selectedCategory.toLowerCase(),
    orElse: () => selectedCategory,
  );
  return CategoryChipRow(
    categories: noteCategories,
    selected: selected,
    onSelected: onCategorySelected,
  );
}
