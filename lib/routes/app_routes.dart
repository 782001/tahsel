import 'package:flutter/material.dart';
import 'package:tahsel/features/standard_features/security/presentation/screens/security_warning_screen.dart';
import 'package:tahsel/features/splash/splash_screen.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String securityWarning = '/security-warning';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case securityWarning:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SecurityWarningScreen(
            isRooted: args?['isRooted'] ?? false,
            isDevMode: args?['isDevMode'] ?? false,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: TextWidget('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (_) => const SplashScreen(),
      securityWarning: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return SecurityWarningScreen(
          isRooted: args?['isRooted'] ?? false,
          isDevMode: args?['isDevMode'] ?? false,
        );
      },
    };
  }
}
