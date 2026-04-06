import 'package:dartz/dartz.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_remote_data_source.dart';
import '../models/operation_model.dart';


class OperationRepositoryImpl implements OperationRepository {
  final OperationRemoteDataSource remoteDataSource;

  OperationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<dynamic, void>> addOperation(OperationEntity operation) async {
    try {
      final model = OperationModel.fromEntity(operation);
      await remoteDataSource.addOperation(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
