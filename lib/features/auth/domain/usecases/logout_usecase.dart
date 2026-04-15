import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/base_usecase/base_usecase.dart';
import '../repositories/auth_repo_base.dart';

class NoParameters extends Equatable {
  @override
  List<Object?> get props => [];
}

class LogoutUseCase extends BaseUseCase<void, NoParameters> {
  final AuthBaseRepository baseRepository;

  LogoutUseCase({required this.baseRepository});

  @override
  Future<Either<dynamic, void>> call(NoParameters parameters) async {
    try {
      await baseRepository.logout();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
