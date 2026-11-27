import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';
import 'package:notes_app/viewmodel/note_details/note_details_viewmodel.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_action_button.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_category_selector.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_content_field.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_meta_info_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_title_field.dart';

class BuildNoteFormWidget extends StatefulWidget {
  final NoteDetailsState state;
  final NoteDetailsViewmodel notifier;

  const BuildNoteFormWidget({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  State<BuildNoteFormWidget> createState() => _BuildNoteFormWidgetState();
}

class _BuildNoteFormWidgetState extends State<BuildNoteFormWidget> {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];

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
  }

  @override
  void dispose() {
    _tagController.dispose();
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

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          noteTitleField(
            controller: widget.notifier.titleController,
            onChanged: (val) => widget.notifier.validateTitle(val),
            errorText: widget.state.titleErrorMsg,
          ),
          SizedBox(height: 14.h),

          // Content Field
          noteContentField(
            controller: widget.notifier.contentController,
            onChanged: (val) => widget.notifier.validateContent(val),
            errorText: widget.state.contentErrorMsg,
          ),
          SizedBox(height: 16.h),

          // Category Selector
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
          SizedBox(height: 16.h),

          // TAGS Section matching Figma
          Text(
            "TAGS",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.muted,
            ),
          ),
          SizedBox(height: 8.h),

          // Add Tag Input Row: Input + '+' Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: palette.line),
                  ),
                  child: TextField(
                    controller: _tagController,
                    onSubmitted: (_) => _addTag(),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: palette.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: "Add a tag...",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: palette.muted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _addTag,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: AppIcons.icon(
                      AppIcons.plus,
                      size: 20.sp,
                      color: palette.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Active Tags Row with ✕
          if (_tags.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: _tags.map((tag) {
                return GestureDetector(
                  onTap: () => _removeTag(tag),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        AppIcons.icon(
                          AppIcons.close,
                          size: 13.sp,
                          color: palette.accent,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (widget.state.isEditMode) ...[
            SizedBox(height: 16.h),
            noteMetaInfoWidget(
              createdAt: widget.state.createdAt,
              updatedAt: widget.state.updatedAt,
            ),
          ],

          SizedBox(height: 24.h),

          // Action button
          noteActionButton(
            isEditMode: widget.state.isEditMode,
            isSaving: widget.state.isSaving,
            onPressed: () => widget.notifier.saveOrUpdateNote(
              context,
              tags: _tags.join(', '),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

Widget buildNoteFormWidget({
  required BuildContext context,
  required NoteDetailsState state,
  required NoteDetailsViewmodel notifier,
}) {
  return BuildNoteFormWidget(state: state, notifier: notifier);
}
