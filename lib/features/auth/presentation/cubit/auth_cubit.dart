import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_logger.dart';

import '../../domain/usecases/login_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;

  AuthCubit({required this.loginUseCase}) : super(AuthInitial());

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
      AppLogger.printMessage('User logged in successfully: ${user.email}');
      AppLogger.printMessage('User logged in successfully: ${user.uid}');
      emit(AuthSuccess(user));
    });
  }
}
