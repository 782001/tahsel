import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
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
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final ConnectivityCubit connectivityCubit;
  StreamSubscription? _authSubscription;
  bool _isDeletingAccount = false;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.deleteAccountUseCase,
    required this.connectivityCubit,
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

      final bool isOnlineAndStable =
          connectivityCubit.state is ConnectivityConnected;

      if (user == null) {
        // Source of truth: Check if we have a local session stored securely
        final String? localToken = await sl<SecureStorageHelper>().getData(
          key: 'token',
        );
        final bool hasLocalSession =
            localToken != null && localToken.isNotEmpty;

        // Only trigger logout if we have NO local session
        if (!hasLocalSession) {
          if (state is! AuthUnauthenticated && state is! AuthInitial) {
            await forceLogout();
          }
        } else {
          AppLogger.printMessage(
            'Firebase Auth user is null, but local session exists. Keeping user logged in.',
          );
        }
      } else {
        // User is present. We only reload to check server status if we are online.
        if (isOnlineAndStable) {
          try {
            await user.reload();
          } catch (e) {
            final errorStr = e.toString().toLowerCase();

            // ONLY logout if server explicitly revoked or disabled the user account.
            // Generic/internal SDK errors (like 'unknown-error' on Windows C++ SDK) must NOT logout the user.
            final isExplicitLogoutError = errorStr.contains('user-disabled') ||
                errorStr.contains('user-not-found') ||
                errorStr.contains('user-token-expired') ||
                errorStr.contains('invalid-user-token') ||
                errorStr.contains('user-revoked');

            if (isExplicitLogoutError) {
              AppLogger.printMessage(
                'User session explicitly revoked/disabled on server - logging out: $e',
              );
              await forceLogout();
            } else {
              AppLogger.printMessage(
                'User reload encountered non-fatal error - keeping session active: $e',
              );
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
      await secureStorage.saveData(
        key: AppStrings.isVipKey,
        value: user.isVip.toString(),
      );

      // Update global session strings
      AppStrings.userToken = user.uid;
      AppStrings.userType = user.userType;
      AppStrings.isVip = user.isVip;

      AppLogger.printMessage(
        'User logged in successfully: ${user.uid} (${user.userType}, isVip: ${user.isVip})',
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

  Future<void> forceLogout({bool bypassConnectivityCheck = false}) async {
    // ABSOLUTE GUARD: Never force logout while offline or internet unstable.
    // This prevents accidental logouts during network transitions or stream glitches.
    // Exception: when called after successful account deletion (bypass = true).
    if (!bypassConnectivityCheck) {
      final bool isOnlineAndStable =
          connectivityCubit.state is ConnectivityConnected;
      if (!isOnlineAndStable) {
        AppLogger.printMessage('Blocking forced logout: Internet is not stable');
        return;
      }
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
    AppStrings.isVip = false;

    // Clear persistent secure storage
    final secureStorage = sl<SecureStorageHelper>();
    await secureStorage.deleteData(key: 'token');
    await secureStorage.deleteData(key: 'email');
    await secureStorage.deleteData(key: AppStrings.userTypeKey);
    await secureStorage.deleteData(key: AppStrings.isVipKey);

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

        // Perform force logout to clean all local caches, storage, and navigate to login.
        // Bypass connectivity check because the server-side deletion already succeeded.
        await forceLogout(bypassConnectivityCheck: true);
      },
    );
  }

  /// Sends a password reset email via Firebase Auth.
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.isValidEmail()) {
      showfailureToast(AppStrings.validationEmailInvalid.tr());
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      showSuccessToast(AppStrings.passwordResetSent.tr());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showfailureToast(AppStrings.userNotFound.tr());
      } else if (e.code == 'invalid-email') {
        showfailureToast(AppStrings.validationEmailInvalid.tr());
      } else {
        showfailureToast(AppStrings.failedToSendResetEmail.tr());
      }
    } catch (e) {
      showfailureToast(AppStrings.failedToSendResetEmail.tr());
    }
  }
}
