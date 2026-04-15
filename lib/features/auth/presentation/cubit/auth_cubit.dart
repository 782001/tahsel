import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  StreamSubscription? _authSubscription;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user == null) {
        if (state is! AuthUnauthenticated && state is! AuthInitial) {
          AppLogger.printMessage('Firebase Auth state changed to null - triggering forced logout');
          await forceLogout();
        }
      } else {
        // User is present, but we need to verify if they still exist on the server
        try {
          // Force a reload to check if user was deleted/disabled in console
          await user.reload();
          AppLogger.printMessage('User session verified: ${user.uid}');
        } catch (e) {
          AppLogger.printMessage('User verification failed (user likely deleted from console): $e');
          await forceLogout();
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
    final result = await loginUseCase.call(
      LoginParameters(email: email, password: password),
    );

    result.fold((failure) => emit(AuthFailure(failure.toString())), (
      user,
    ) async {
      final secureStorage = sl<SecureStorageHelper>();
      await secureStorage.saveData(key: 'token', value: user.uid);
      await secureStorage.saveData(key: 'email', value: user.email);
      AppLogger.printMessage('User logged in successfully: ${user.uid}');
      emit(AuthSuccess(user));
    });
  }

  Future<void> forceLogout() async {
    if (state is AuthUnauthenticated) return;
    
    emit(AuthUnauthenticated());
    await logoutUseCase.call(NoParameters());

    final context = sl<NavigatorService>().context;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
             AppStrings.sessionExpired.tr(), 
             style: TextStyle(color: AppColors.white)
          ),
          backgroundColor: AppColors.error,
        ),
      );
      sl<NavigatorService>().pushNamedAndRemoveUntil(AppRoutes.login);
    }
  }
}
