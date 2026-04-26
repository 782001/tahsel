import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';

abstract class MyDebtRepository {
  Future<Either<Failure, List<MyDebtEntity>>> getMyDebts();
  Future<Either<Failure, void>> addMyDebt(MyDebtEntity debt, MyDebtTransactionEntity transaction);
  Future<Either<Failure, void>> addMyDebtTransaction(MyDebtTransactionEntity transaction);
  Future<Either<Failure, List<MyDebtTransactionEntity>>> getMyDebtTransactions(String debtId);
  Future<Either<Failure, void>> deleteMyDebt(String debtId);
  Future<Either<Failure, void>> updateMyDebt(MyDebtEntity debt);
}
