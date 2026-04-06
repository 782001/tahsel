import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../entities/operation_entity.dart';
import '../repositories/operation_repository.dart';

class AddOperationUseCase implements BaseUseCase<String, AddOperationParams> {
  final OperationRepository repository;

  AddOperationUseCase({required this.repository});

  @override
  Future<Either<dynamic, String>> call(AddOperationParams params) async {
    return await repository.addOperation(params.operation);
  }
}

class AddOperationParams {
  final OperationEntity operation;

  AddOperationParams({required this.operation});
}
