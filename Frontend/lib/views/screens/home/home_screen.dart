import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/home/widgets/notes_empty_widget.dart';
import 'package:notes_app/views/screens/home/widgets/notes_error_widget.dart';
import 'package:notes_app/views/screens/home/widgets/notes_floating_action_button.dart';
import 'package:notes_app/views/screens/home/widgets/notes_header_widget.dart';
import 'package:notes_app/views/screens/home/widgets/notes_list_view.dart';
import 'package:notes_app/views/screens/home/widgets/notes_loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeController);
    final notifier = ref.read(homeController.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 70.h),
        child: notesFloatingActionButton(context: context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withAlpha(25),
                blurRadius: 3,
                spreadRadius: 0,
                offset: Offset(1, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              notesHeaderWidget(onRefresh: () => notifier.getAllNotes()),
              Expanded(
                child: state.when(
                  data: (homeState) {
                    final notes = homeState.notesData?.data ?? [];
                    if (notes.isEmpty) {
                      return notesEmptyWidget(
                        onRefresh: () => notifier.getAllNotes(),
                      );
                    }
                    return notesListView(
                      notes: notes,
                      onRefresh: () => notifier.getAllNotes(),
                    );
                  },
                  loading: () => notesLoadingWidget(),
                  error: (error, stack) => notesErrorWidget(
                    message: error.toString(),
                    onRetry: () => notifier.getAllNotes(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
