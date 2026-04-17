import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/services/security_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
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
    await SecurityService.checkSecurity();
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check internet connection
        final bool hasInternet = await sl<InternetConnectionChecker>().hasConnection;
        
        if (hasInternet) {
          try {
            // Verify user still exists in Firebase Authentication if online
            await user.reload();
            nav().pushNamedAndRemoveUntil(AppRoutes.mainLayout);
          } catch (e) {
            // User deleted/disabled on server or token expired
            await sl<LogoutUseCase>().call(NoParams());
            nav().pushNamedAndRemoveUntil(AppRoutes.login);
          }
        } else {
          // No internet: Trust local session and navigate to Main Layout
          nav().pushNamedAndRemoveUntil(AppRoutes.mainLayout);
        }
      } else {
        nav().pushNamedAndRemoveUntil(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
