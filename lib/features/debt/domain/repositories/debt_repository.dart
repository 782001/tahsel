import 'package:dartz/dartz.dart';
import '../entities/debt_entity.dart';

abstract class DebtRepository {
  Future<Either<dynamic, String>> addDebt(DebtEntity debt);
  Future<Either<dynamic, List<DebtEntity>>> getDebts(String uid);
}
