import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/profile/widgets/build_profile_widget.dart';
import 'package:notes_app/views/screens/profile/widgets/profile_error_widget.dart';
import 'package:notes_app/views/screens/profile/widgets/profile_loading_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var state = ref.watch(profileController);
    var notifier = ref.read(profileController.notifier);
    return Container(
      color: AppColors.bgColor,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: state.when(
            data: (profileState) {
              final data = profileState.profileData?.data;
              if (data == null) {
                return profileErrorWidget(
                  message: "No profile data available.",
                  onRetry: () => notifier.getUserDetails(),
                );
              }
              return buildProfileWidget(profileData: data);
            },
            error: (error, stack) => profileErrorWidget(
              message: error.toString(),
              onRetry: () => notifier.getUserDetails(),
            ),
            loading: () => profileLoadingWidget(),
          ),
        ),
      ),
    );
  }
}
