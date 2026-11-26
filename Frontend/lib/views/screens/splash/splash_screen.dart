import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/screens/auth/login/login_screen.dart';
import 'package:notes_app/views/screens/dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _indicatorFade;
  late final Animation<double> _indicatorProgress;
  late final Animation<double> _footerFade;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _indicatorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
      ),
    );

    _indicatorProgress = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();

    // After animation, smoothly transition to Dashboard or Login screen
    _navigationTimer = Timer(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: getIt<SessionService>().isLoggedIn
                ? const DashboardScreen()
                : const LoginScreen(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Column(
              children: [
                const Spacer(flex: 3),

                // Logo Card
                SlideTransition(
                  position: _logoSlide,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: AppIcons.splashLogo(
                        context: context,
                        size: 84.r,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Title & Tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'Daymark',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 34.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            color: palette.ink,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Thoughtful daily notes',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 36.h),

                // Animated Progress Bar
                FadeTransition(
                  opacity: _indicatorFade,
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _indicatorProgress.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 4),

                // Footer
                FadeTransition(
                  opacity: _footerFade,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Column(
                      children: [
                        Text(
                          'A CALM SPACE FOR YOUR THOUGHTS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: palette.muted,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'DAYMARK · VERSION 1.0.0',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: palette.brightness == Brightness.dark
                                ? const Color(0xFF525B54)
                                : const Color(0xFFB0B6B1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
