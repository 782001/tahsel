import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tahsel/core/config/locale/app_localizations_setup.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/logo/project_logo_service.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/services/security_service.dart';
import 'package:tahsel/core/utils/app_constants.dart';
import 'package:tahsel/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_cubit.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
import 'package:tahsel/features/operation/presentation/cubit/operation_cubit.dart';
import 'package:tahsel/features/operation/presentation/cubit/ps_session_cubit.dart';
import 'package:tahsel/features/product/presentation/cubit/product_cubit.dart';
import 'package:tahsel/features/standard_features/error/presentation/screens/error_screen.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/no_internet.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';
import 'package:tahsel/features/update/presentation/cubit/update_cubit.dart';
import 'package:tahsel/firebase_options.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:window_manager/window_manager.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

void main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  // Lock portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Desktop Window Configuration
  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 900),
      minimumSize: Size(375, 812),
      // maximumSize: Size(950, 1500),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await initializeDateFormatting();

  SecurityService.isEnabled = false;
  await initDependencies();
  await ProjectLogoService.instance.init();

  // Global Error Handling for UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorScreen(errorDetails: details);
  };

  if (kReleaseMode) {
    // ── Sentry Initialization ──────────────────────────────────────────
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://7b62877558b3b8f81d757d9181881401@o4511819849596928.ingest.us.sentry.io/4511819859361792';
        options.sendDefaultPii = true;
        options.tracesSampleRate = .01;
        options.attachScreenshot = true;
        options.enableAutoPerformanceTracing = true;
        options.environment = kDebugMode ? 'development' : 'production';
      },
      appRunner: () {
        // Route Flutter framework errors to Sentry
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          Sentry.captureException(details.exception, stackTrace: details.stack);
        };

        // Catch errors outside the Flutter framework (async, platform, etc.)
        PlatformDispatcher.instance.onError = (error, stack) {
          Sentry.captureException(error, stackTrace: stack);
          return true;
        };

        runApp(const MyApp());
      },
    );
  } else {
    // Global Error Handling for Framework
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Add custom logging here if needed (e.g. Sentry)
    };

    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<CreateAccountCubit>()),
        BlocProvider(create: (context) => di.sl<LocaleCubit>()..getSavedLang()),
        BlocProvider(create: (context) => di.sl<ThemeCubit>()),
        BlocProvider(create: (context) => di.sl<ConnectivityCubit>()),
        BlocProvider(create: (context) => di.sl<CustomerCubit>()),
        BlocProvider(create: (context) => di.sl<ProductCubit>()),
        BlocProvider(create: (context) => di.sl<ExpenseCubit>()),
        BlocProvider(create: (context) => di.sl<OfflineSyncCubit>()),
        BlocProvider(create: (context) => di.sl<OperationCubit>()),
        BlocProvider(create: (context) => di.sl<PsSessionCubit>()),
        BlocProvider(create: (context) => di.sl<DebtCubit>()),
        BlocProvider(create: (context) => di.sl<MyDebtsCubit>()),
        // Update Feature
        BlocProvider(create: (context) => di.sl<UpdateCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final isDark = themeState.themeMode == ThemeMode.dark;

          // Unified Status Bar Style
          final systemOverlayStyle = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark
                ? Brightness.dark
                : Brightness.light, // iOS
            systemNavigationBarColor: isDark
                ? const Color(0xFF121212)
                : const Color(0xFFF8F8F8),
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          );

          // Force update SystemUI
          SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle);

          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp(
                    navigatorKey: sl<NavigatorService>().navigatorKey,
                    scaffoldMessengerKey:
                        sl<NavigatorService>().scaffoldMessengerKey,
                    debugShowCheckedModeBanner: false,
                    title: 'تحصيل',
                    scrollBehavior: AppScrollBehavior(),
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
                      appBarTheme: AppBarTheme(
                        systemOverlayStyle: systemOverlayStyle,
                        backgroundColor: const Color(0xFFF8F8F8),
                        elevation: 0,
                      ),
                    ),
                    darkTheme: ThemeData(
                      brightness: Brightness.dark,
                      primarySwatch: Colors.blue,
                      fontFamily: AppConstants.fontFamily,
                      scaffoldBackgroundColor: const Color(0xFF121212),
                      appBarTheme: AppBarTheme(
                        systemOverlayStyle: systemOverlayStyle,
                        backgroundColor: const Color(0xFF121212),
                        elevation: 0,
                      ),
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
