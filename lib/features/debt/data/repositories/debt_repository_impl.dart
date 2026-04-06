import 'package:dartz/dartz.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_remote_data_source.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtRemoteDataSource remoteDataSource;

  DebtRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<dynamic, String>> addDebt(DebtEntity debt) async {
    try {
      final deptModel = DebtModel.fromEntity(debt);
      final id = await remoteDataSource.addDebt(deptModel);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<dynamic, List<DebtEntity>>> getDebts(String uid) async {
    try {
      final result = await remoteDataSource.getDebts(uid);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
