import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/features/create_account/domain/usecases/create_account_usecases.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_state.dart';

class CreateAccountCubit extends Cubit<CreateAccountState> {
  CreateAccountCubit({required CreateUserUseCase createUser})
    : _createUser = createUser,

      super(CreateAccountInitial());

  final CreateUserUseCase _createUser;

  Future<bool> createUser(CreateUserParams params) async {
    final result = await _createUser(params);
    return result.fold(
      (f) {
        AppLogger.printMessage("======================");
        AppLogger.printMessage(f.message);
        AppLogger.printMessage("======================");
        emit(CreateAccountError(f.message));
  
        return false;
      },
      (_) {
        emit(CreateAccountSuccess());

        return true;
      },
    );
  }
}
