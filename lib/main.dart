import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/config/locale/app_localizations_setup.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/services/security_service.dart';
import 'package:tahsel/core/utils/app_constants.dart';
import 'package:tahsel/features/standard_features/error/presentation/screens/error_screen.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/no_internet.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SecurityService.isEnabled = false;
  await initDependencies();

  // Global Error Handling for UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorScreen(errorDetails: details);
  };

  // Global Error Handling for Framework
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Add custom logging here if needed (e.g. Sentry)
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<LocaleCubit>()..getSavedLang()),
        BlocProvider(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider(create: (context) => di.sl<ConnectivityCubit>()),
        BlocProvider(create: (context) => di.sl<CustomerCubit>()),
        BlocProvider(create: (context) => di.sl<ExpenseCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            buildWhen: (previousState, currentState) {
              return previousState != currentState;
            },
            builder: (context, localeState) {
              return ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp(
                    navigatorKey: sl<NavigatorService>().navigatorKey,
                    debugShowCheckedModeBanner: false,
                    title: 'تحصيل',
                    locale: localeState.locale,
                    themeMode: themeState.themeMode,
                    supportedLocales: AppLocalizationsSetup.supportedLocales,
                    localeResolutionCallback:
                        AppLocalizationsSetup.localeResolutionCallback,
                    localizationsDelegates:
                        AppLocalizationsSetup.localizationsDelegates,
                    theme: ThemeData(
                      brightness: Brightness.light,
                      primarySwatch: Colors.blue,
                      fontFamily: AppConstants.fontFamily,
                      scaffoldBackgroundColor: const Color(0xFFF8F8F8),
                    ),
                    darkTheme: ThemeData(
                      brightness: Brightness.dark,
                      primarySwatch: Colors.blue,
                      fontFamily: AppConstants.fontFamily,
                      scaffoldBackgroundColor: const Color(0xFF121212),
                    ),
                    initialRoute: AppRoutes.splash,
                    onGenerateRoute: AppRoutes.generateRoute,
                    builder: (context, child) {
                      return NoInternetHandler(child: child!);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
