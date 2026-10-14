import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/screens/profile/widgets/profile_avatar_widget.dart';
import 'package:notes_app/views/screens/profile/widgets/profile_info_tile.dart';

Widget buildProfileWidget({
  required ProfileData profileData,
}) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.symmetric(vertical: 24.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        profileAvatarWidget(
          name: profileData.name ?? "User",
          gender: profileData.gender ?? "",
        ),
        SizedBox(height: 24.h),
        Divider(
          color: AppColors.neutral20,
          thickness: 1,
          indent: 20.w,
          endIndent: 20.w,
        ),
        SizedBox(height: 8.h),
        profileInfoTile(
          icon: Icons.email_outlined,
          label: "Email",
          value: profileData.email ?? "",
        ),
        profileInfoTile(
          icon: Icons.phone_outlined,
          label: "Mobile",
          value: profileData.mobile ?? "",
        ),
        profileInfoTile(
          icon: Icons.badge_outlined,
          label: "User ID",
          value: profileData.id?.toString() ?? "",
        ),
      ],
    ),
  );
}
