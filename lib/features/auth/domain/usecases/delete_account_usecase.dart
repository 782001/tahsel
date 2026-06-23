import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../../../../../core/base_usecase/base_usecase.dart';
import '../repositories/auth_repo_base.dart';

class DeleteAccountUseCase extends BaseUseCase<void, NoParams> {
  final AuthBaseRepository baseRepository;

  DeleteAccountUseCase({required this.baseRepository});

  @override
  Future<Either<Failure, void>> call(NoParams parameters) async {
    return baseRepository.deleteAccount();
  }
}
