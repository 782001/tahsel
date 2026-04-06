import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/base_usecase/base_usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repo_base.dart';

class LoginUseCase extends BaseUseCase<UserEntity, LoginParameters> {
  final AuthBaseRepository baseRepository;

  LoginUseCase({required this.baseRepository});

  @override
  Future<Either<dynamic, UserEntity>> call(LoginParameters parameters) async {
    return await baseRepository.login(parameters: parameters);
  }
}

class LoginParameters extends Equatable {
  final String email;
  final String password;

  const LoginParameters({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
