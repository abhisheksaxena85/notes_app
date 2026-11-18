import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/profile/widgets/build_profile_widget.dart';
import 'package:notes_app/views/screens/profile/widgets/profile_error_widget.dart';
import 'package:notes_app/views/screens/profile/widgets/profile_loading_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _refreshProfile(
    BuildContext context,
    Future<void> Function() refresh,
  ) async {
    try {
      await refresh();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh profile: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.daymark;
    final state = ref.watch(profileController);
    final notifier = ref.read(profileController.notifier);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: state.when(
          data: (profileState) {
            final data = profileState.profileData?.data;
            if (data == null) {
              return profileErrorWidget(
                message: "No profile data available.",
                onRetry: () =>
                    _refreshProfile(context, notifier.getUserDetails),
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  _refreshProfile(context, notifier.getUserDetails),
              color: palette.accent,
              child: buildProfileWidget(profileData: data),
            );
          },
          error: (error, stack) => profileErrorWidget(
            message: error.toString(),
            onRetry: () => _refreshProfile(context, notifier.getUserDetails),
          ),
          loading: () => profileLoadingWidget(),
        ),
      ),
    );
  }
}
