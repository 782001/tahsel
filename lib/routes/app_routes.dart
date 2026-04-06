import 'package:flutter/material.dart';
import 'package:tahsel/features/standard_features/security/presentation/screens/security_warning_screen.dart';
import 'package:tahsel/features/splash/splash_screen.dart';
import 'package:tahsel/features/main_layout/presentation/screens/main_layout_screen.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/auth/presentation/screens/login_screen.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
import 'package:tahsel/features/expenses/presentation/screens/add_expense_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String mainLayout = '/main-layout';
  static const String login = '/login';
  static const String securityWarning = '/security-warning';
  static const String addExpense = '/add-expense';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case mainLayout:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => di.sl<MainLayoutCubit>(),
            child: const MainLayoutScreen(),
          ),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case securityWarning:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SecurityWarningScreen(
            isRooted: args?['isRooted'] ?? false,
            isDevMode: args?['isDevMode'] ?? false,
          ),
        );
      case addExpense:
        return MaterialPageRoute(
          builder: (_) => const AddExpenseScreen(),
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
      mainLayout: (_) => BlocProvider(
            create: (context) => di.sl<MainLayoutCubit>(),
            child: const MainLayoutScreen(),
          ),
      login: (_) => const LoginScreen(),
      securityWarning: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return SecurityWarningScreen(
          isRooted: args?['isRooted'] ?? false,
          isDevMode: args?['isDevMode'] ?? false,
        );
      },
      addExpense: (_) => const AddExpenseScreen(),
    };
  }
}
