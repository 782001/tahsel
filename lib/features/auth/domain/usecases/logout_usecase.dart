import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../../../../../core/base_usecase/base_usecase.dart';
import '../repositories/auth_repo_base.dart';

class LogoutUseCase extends BaseUseCase<void, NoParams> {
  final AuthBaseRepository baseRepository;

  LogoutUseCase({required this.baseRepository});

  @override
  Future<Either<Failure, void>> call(NoParams parameters) async {
    try {
      await baseRepository.logout();
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('auth_default_error'));
    }
  }
}
