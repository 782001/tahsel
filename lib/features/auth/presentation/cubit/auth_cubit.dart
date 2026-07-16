import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/operation/presentation/cubit/operation_cubit.dart';
import 'package:tahsel/features/product/presentation/cubit/product_cubit.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_cubit.dart';
import 'package:tahsel/routes/app_routes.dart';

import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  StreamSubscription? _authSubscription;
  bool _isDeletingAccount = false;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.deleteAccountUseCase,
  }) : super(AuthInitial()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.userChanges().listen((
      User? user,
    ) async {
      // Ignore background auth stream events while actively logging in or out
      if (state is AuthLoading || _isDeletingAccount) {
        AppLogger.printMessage(
          '[AuthCubit] Ignoring userChanges event during AuthLoading/AuthDeleting state',
        );
        return;
      }

      final bool hasInternet =
          await sl<InternetConnectionChecker>().hasConnection;

      if (user == null) {
        // Source of truth: Check if we have a local session stored securely
        final String? localToken = await sl<SecureStorageHelper>().getData(
          key: 'token',
        );
        final bool hasLocalSession =
            localToken != null && localToken.isNotEmpty;

        // Only trigger logout if we ARE online AND we have NO local session
        // or if we are online and Firebase explicitly cleared the user (meaning session expired).
        if (hasInternet) {
          if (!hasLocalSession) {
            // Already logged out locally, just ensure state is correct
            if (state is! AuthUnauthenticated && state is! AuthInitial) {
              await forceLogout();
            }
          } else {
            // Online but Firebase says null? This usually means the session is invalid.
            AppLogger.printMessage(
              'Firebase user is null while ONLINE - Session likely expired on server',
            );
            await forceLogout();
          }
        } else {
          // OFFLINE: If we have a local session, IGNORE Firebase being null.
          if (hasLocalSession) {
            AppLogger.printMessage(
              'Firebase Auth is null while OFFLINE, but local session exists. Keeping user logged in.',
            );
          } else {
            // No internet and no local session? Nothing to do, user is already out.
          }
        }
      } else {
        // User is present. We only reload to check server status if we are online.
        if (hasInternet) {
          try {
            await user.reload();
          } catch (e) {
            // Only logout if it's NOT a network error and NOT a "no-signed-in-user" status
            final errorStr = e.toString().toLowerCase();
            if (errorStr.contains('network-request-failed') ||
                errorStr.contains('connection-failed') ||
                errorStr.contains('no internet')) {
              AppLogger.printMessage(
                'User reload failed due to network - keeping session: $e',
              );
            } else if (errorStr.contains('no-signed-in-user') ||
                errorStr.contains('no-signed-in')) {
              AppLogger.printMessage(
                'User reload failed because user is already signed out: $e',
              );
            } else {
              AppLogger.printMessage(
                'User verification failed for non-network reason - logging out: $e',
              );
              await forceLogout();
            }
          }
        }
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    // Detect current platform: desktop = Windows, mobile = everything else
    String currentPlatform = 'mobile';
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        currentPlatform = 'desktop';
      }
    } catch (_) {
      // On web or other environments where Platform throws — default to mobile
    }

    final result = await loginUseCase.call(
      LoginParameters(
        email: email,
        password: password,
        currentPlatform: currentPlatform,
      ),
    );
    AppLogger.printMessage(result.toString());
    result.fold((failure) => emit(AuthFailure(failure.message)), (user) async {
      final secureStorage = sl<SecureStorageHelper>();
      await secureStorage.saveData(key: 'token', value: user.uid);
      await secureStorage.saveData(key: 'email', value: user.email);
      
      await secureStorage.saveData(
        key: AppStrings.userTypeKey,
        value: user.userType,
      );

      // Update global session strings
      AppStrings.userToken = user.uid;
      AppStrings.userType = user.userType;

      AppLogger.printMessage(
        'User logged in successfully: ${user.uid} (${user.userType})',
      );

      emit(AuthSuccess(user));
    });
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await logoutUseCase.call(const NoParams());
    await _clearSessionData();
    emit(AuthUnauthenticated());

    final context = sl<NavigatorService>().context;
    if (context != null && context.mounted) {
      sl<NavigatorService>().pushNamedAndRemoveUntil(AppRoutes.login);
    }
  }

  Future<void> forceLogout() async {
    // ABSOLUTE GUARD: Never force logout while offline.
    // This prevents accidental logouts during network transitions or stream glitches.
    final bool hasInternet =
        await sl<InternetConnectionChecker>().hasConnection;
    if (!hasInternet) {
      AppLogger.printMessage('Blocking forced logout: Device is OFFLINE');
      return;
    }

    if (state is AuthUnauthenticated) return;

    final isDeleteSuccess = state is AuthDeleteSuccess;

    await logoutUseCase.call(const NoParams());
    await _clearSessionData();
    emit(AuthUnauthenticated());

    final context = sl<NavigatorService>().context;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDeleteSuccess
                ? AppStrings.accountDeletedSuccessfully.tr()
                : AppStrings.sessionExpired.tr(),
            style: TextStyles.customStyle(color: AppColors.white),
          ),
          backgroundColor: isDeleteSuccess
              ? AppColors.success
              : AppColors.error,
        ),
      );
      sl<NavigatorService>().pushNamedAndRemoveUntil(AppRoutes.login);
    }
  }

  Future<void> _clearSessionData() async {
    // Clear global session strings
    AppStrings.userToken = '';
    AppStrings.userType = AppStrings.cafe;

    // Clear persistent secure storage
    final secureStorage = sl<SecureStorageHelper>();
    await secureStorage.deleteData(key: 'token');
    await secureStorage.deleteData(key: 'email');
    await secureStorage.deleteData(key: AppStrings.userTypeKey);

    // Clear feature caches
    sl<ReportsCubit>().clearCache();
    sl<CustomerCubit>().clearData();
    sl<ProductCubit>().clearData();
    sl<ExpenseCubit>().clearData();
    sl<DebtCubit>().clearData();
    sl<MyDebtsCubit>().clearData();
    sl<OperationCubit>().clearData();
  }

  Future<void> deleteAccount() async {
    _isDeletingAccount = true;
    emit(AuthDeleteLoading());

    final result = await deleteAccountUseCase.call(const NoParams());

    result.fold(
      (failure) {
        _isDeletingAccount = false;
        emit(AuthDeleteFailure(failure.message));
      },
      (_) async {
        emit(AuthDeleteSuccess());
        _isDeletingAccount = false;

        // Perform force logout to clean all local caches, storage, and navigate to login
        await forceLogout();
      },
    );
  }
}
