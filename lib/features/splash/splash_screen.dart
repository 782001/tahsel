import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/services/security_service.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/features/auth/domain/usecases/logout_usecase.dart';
import 'package:tahsel/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));

    _controller.forward();

    _navigateToNext();
  }

  void _navigateToNext() async {
    // 1. Perform security checks (e.g., root detection, developer mode)
    await SecurityService.checkSecurity();

    // 2. Minimum splash duration for branding
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final secureStorage = sl<SecureStorageHelper>();

      // 3. Load local session data (PRIORITY)
      final String? token = await secureStorage.getData(key: 'token');
      final String? userType = await secureStorage.getData(
        key: AppStrings.userTypeKey,
      );

      if (token != null && token.isNotEmpty) {
        // SUCCESS: Local session found
        AppStrings.userToken = token;
        AppStrings.userType = userType ?? AppStrings.cafe;

        // 4. Navigate IMMEDIATELY to Main Layout (Offline-first)
        nav().pushNamedAndRemoveUntil(AppRoutes.mainLayout);

        // 5. BACKGROUND: Verify with Firebase if online (Optional/Non-blocking)
        _verifySessionInBackground();
      } else {
        // FAILURE: No session, go to login
        nav().pushNamedAndRemoveUntil(AppRoutes.login);
      }
    }
  }

  /// Verifies the current Firebase session in the background.
  /// If the session is invalid (user deleted/disabled), it triggers a logout.
  void _verifySessionInBackground() async {
    final bool hasInternet =
        await sl<InternetConnectionChecker>().hasConnection;
    if (!hasInternet) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
      } else {
        // Firebase says no user but local said yes? Only clear if online.
        if (hasInternet) {
          _handleInvalidSession();
        }
      }
    } catch (e) {
      // Only logout if it's NOT a network error
      if (e.toString().contains('network-request-failed') ||
          e.toString().contains('connection-failed')) {
        return; // Ignore network errors, keep local session
      }
      // User likely deleted or disabled on server
      _handleInvalidSession();
    }
  }

  void _handleInvalidSession() async {
    await sl<LogoutUseCase>().call(NoParams());

    // Reset global strings
    AppStrings.userToken = '';
    AppStrings.userType = AppStrings.cafe;

    // If user is already in the app, the AuthCubit listener will handle
    // the redirection if it's set up, otherwise we can force a redirect here
    // but typically AuthCubit.userChanges handles this.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:  SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:AppColors.isDark? Brightness.light:Brightness.dark, // Dark icons
        statusBarBrightness: AppColors.isDark? Brightness.dark:Brightness.light, // iOS dark text
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          Assets.imagesAppLogo,
                          width: 180.h,
                          height: 180.h,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
