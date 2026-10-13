import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/screens/home/home_screen.dart';
import 'package:notes_app/views/screens/profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final List<Widget> _pages = const [HomeScreen(), ProfileScreen()];

  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _pages.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: TabBarView(controller: _controller, children: _pages),
      floatingActionButton: Container(
        height: 60.h,
        margin: EdgeInsets.symmetric(horizontal: 32.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.iconColor, width: 0.1.r),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withAlpha(50),
              offset: Offset(0, 2),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            int index = _controller.index;
            return TabBar(
              dividerHeight: 0,
              padding: EdgeInsets.all(4.r),
              indicator: BoxDecoration(
                border: Border.all(color: AppColors.iconColor, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(24.r)),
              ),
              overlayColor: WidgetStateProperty.all<Color?>(Colors.transparent),
              tabs: [
                floatingTabItem(
                  index == 0
                      ? Icons.dashboard_rounded
                      : Icons.dashboard_outlined,
                  "Home",
                  isSelected: index == 0,
                ),
                floatingTabItem(
                  Icons.person,
                  "Profile",
                  isSelected: index == 1,
                ),
              ],
              controller: _controller,
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget floatingTabItem(
    IconData icon,
    String title, {
    required bool isSelected,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.iconTextColor : AppColors.iconColor,
            size: 22.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            title,
            style: GoogleFonts.googleSans(
              fontSize: isSelected ? 14.sp : 13.sp,
              color: isSelected ? AppColors.iconTextColor : AppColors.iconColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
