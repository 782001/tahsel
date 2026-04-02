import 'package:flutter/material.dart';
import 'package:tahsel/core/services/security_service.dart';
import 'package:tahsel/core/services/translation_helper.dart';
import 'package:tahsel/core/utils/app_constants.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
import 'package:tahsel/shared/widgets/buttons/theme_toggle_button.dart';
import 'package:tahsel/core/utils/app_colors.dart';

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
    if (mounted) {}
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.star_rounded,
                          size: 80,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextWidget(
                      Loc.tr(context, AppConstants.splashText),
                      style: TextStyles.font28WeightBoldWhite().copyWith(
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(top: 40, right: 16, child: ThemeToggleButton()),
        ],
      ),
    );
  }
}
