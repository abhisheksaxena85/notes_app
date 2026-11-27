import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';
import 'package:notes_app/viewmodel/note_details/note_details_viewmodel.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_category_selector.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_content_field.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_meta_info_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_title_field.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/confirm_dialog.dart';
import 'package:notes_app/views/widgets/dashed_border.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/section_header.dart';

class BuildNoteFormWidget extends StatefulWidget {
  final NoteDetailsState state;
  final NoteDetailsViewmodel notifier;

  /// Shown as the delete button in the bottom bar (edit mode).
  final VoidCallback? onDelete;

  const BuildNoteFormWidget({
    super.key,
    required this.state,
    required this.notifier,
    this.onDelete,
  });

  @override
  State<BuildNoteFormWidget> createState() => _BuildNoteFormWidgetState();
}

class _BuildNoteFormWidgetState extends State<BuildNoteFormWidget> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocus = FocusNode();
  final List<String> _tags = [];
  bool _addingTag = false;

  /// FIX-01: the note as it opened, to tell if anything changed.
  late final Object _openedWith;
  Object get _values => (
        widget.notifier.titleController.text.trim(),
        widget.notifier.contentController.text.trim(),
        widget.state.selectedCategory,
        widget.state.isPinned,
        _tags.join(','),
      );
  bool get _hasChanges => _values != _openedWith;
  bool _wasChanged = false;

  /// Typing doesn't rebuild the form; rebuild when "changed" flips so the
  /// back guard is current.
  void _onTextChanged() {
    if (_hasChanges != _wasChanged) setState(() => _wasChanged = _hasChanges);
  }

  Future<void> _onPopBlocked() async {
    if (!await confirmDiscardChanges(context)) return;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    if (widget.state.noteData?.tags != null &&
        widget.state.noteData!.tags!.isNotEmpty) {
      final split = widget.state.noteData!.tags!
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty);
      _tags.addAll(split);
    }
    if (widget.state.selectedCategory.isNotEmpty &&
        widget.state.selectedCategory != "General" &&
        !_tags.contains(widget.state.selectedCategory)) {
      _tags.add(widget.state.selectedCategory);
    }
    _openedWith = _values;
    widget.notifier.titleController.addListener(_onTextChanged);
    widget.notifier.contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // The controllers belong to the view model and may outlive this widget.
    widget.notifier.titleController.removeListener(_onTextChanged);
    widget.notifier.contentController.removeListener(_onTextChanged);
    _tagController.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _startAddingTag() {
    setState(() => _addingTag = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tagFocus.requestFocus());
  }

  void _finishAddingTag() {
    _addTag();
    setState(() => _addingTag = false);
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;

    // Saving and deleting close the editor with Navigator.pop, which skips
    // this guard; back (button, gesture, system) asks when something changed.
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                noteTitleField(
                  controller: widget.notifier.titleController,
                  onChanged: (val) => widget.notifier.validateTitle(val),
                  errorText: widget.state.titleErrorMsg,
                ),
                if (widget.state.isEditMode) ...[
                  const SizedBox(height: 8),
                  noteMetaInfoWidget(
                    createdAt: widget.state.createdAt,
                    updatedAt: widget.state.updatedAt,
                  ),
                ],
                const SizedBox(height: 16),

                // Category chips
                noteCategorySelector(
                  selectedCategory: widget.state.selectedCategory,
                  onCategorySelected: (cat) {
                    widget.notifier.setCategory(cat);
                    if (!_tags.contains(cat)) {
                      setState(() {
                        _tags.add(cat);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: palette.divider),
                const SizedBox(height: 16),

                // Body
                noteContentField(
                  controller: widget.notifier.contentController,
                  onChanged: (val) => widget.notifier.validateContent(val),
                  errorText: widget.state.contentErrorMsg,
                ),
                const SizedBox(height: 22),

                // Tags
                const OverlineLabel("Tags"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final tag in _tags) _tagChip(palette, tag),
                    _addingTag ? _tagInput(palette) : _addTagChip(palette),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom bar: delete + Save note
        Container(
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(top: BorderSide(color: palette.line)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              if (widget.onDelete != null) ...[
                noteDeleteButton(context, onPressed: widget.onDelete),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PrimaryButton(
                  label: "Save note",
                  loading: widget.state.isSaving,
                  onPressed: () => widget.notifier.saveOrUpdateNote(
                    context,
                    tags: _tags.join(', '),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _tagChip(DaymarkPalette palette, String tag) {
    return Semantics(
      button: true,
      label: 'Remove tag $tag',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _removeTag(tag),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          padding: const EdgeInsets.only(left: 10, right: 6),
          decoration: BoxDecoration(
            color: palette.tagFill,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag,
                style: DaymarkText.custom(13, FontWeight.w500).copyWith(color: palette.inkSecondary),
              ),
              const SizedBox(width: 4),
              AppIcons.icon(AppIcons.close, size: 14, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTagChip(DaymarkPalette palette) {
    return Semantics(
      button: true,
      label: 'Add tag',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _startAddingTag,
        behavior: HitTestBehavior.opaque,
        child: DashedBorder(
          color: palette.accent,
          radius: 9,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcons.icon(AppIcons.plus, size: 14, color: palette.accent),
                const SizedBox(width: 4),
                Text(
                  "Add tag",
                  style: DaymarkText.custom(13, FontWeight.w500).copyWith(color: palette.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagInput(DaymarkPalette palette) {
    return SizedBox(
      width: 150,
      height: 32,
      child: TextField(
        controller: _tagController,
        focusNode: _tagFocus,
        onSubmitted: (_) => _finishAddingTag(),
        onTapOutside: (_) => _finishAddingTag(),
        textInputAction: TextInputAction.done,
        style: DaymarkText.custom(13, FontWeight.w500).copyWith(color: palette.ink),
        decoration: InputDecoration(
          hintText: "New tag",
          hintStyle: DaymarkText.custom(13, FontWeight.w400).copyWith(color: palette.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: palette.accent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: palette.accent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: palette.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// The 52 px delete button of the editor's bottom bar. A null [onPressed]
/// greys it out (loading state).
Widget noteDeleteButton(BuildContext context, {VoidCallback? onPressed}) {
  final palette = context.daymark;
  return Semantics(
    button: true,
    label: 'Delete note',
    excludeSemantics: true,
    child: Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onPressed == null ? palette.line : palette.dangerBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: AppIcons.icon(
              AppIcons.delete,
              size: 20,
              color: onPressed == null ? palette.disabled : palette.danger,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget buildNoteFormWidget({
  required BuildContext context,
  required NoteDetailsState state,
  required NoteDetailsViewmodel notifier,
  VoidCallback? onDelete,
}) {
  return BuildNoteFormWidget(state: state, notifier: notifier, onDelete: onDelete);
}
