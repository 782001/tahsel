import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_model.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class MyDebtRepositoryImpl implements MyDebtRepository {
  final MyDebtRemoteDataSource remoteDataSource;

  MyDebtRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MyDebtEntity>>> getMyDebts() async {
    try {
      final result = await remoteDataSource.getMyDebts();
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure('Server Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addMyDebt(MyDebtEntity debt, MyDebtTransactionEntity transaction) async {
    try {
      final debtModel = MyDebtModel(
        id: debt.id,
        personId: debt.personId,
        personName: debt.personName,
        totalAmount: debt.totalAmount,
        paidAmount: debt.paidAmount,
        remainingDebt: debt.remainingDebt,
        phoneNumber: debt.phoneNumber,
        notes: debt.notes,
        createdAt: debt.createdAt,
        lastTransactionDate: debt.lastTransactionDate,
      );
      
      final transactionModel = MyDebtTransactionModel(
        id: transaction.id,
        debtId: transaction.debtId,
        amount: transaction.amount,
        type: transaction.type,
        note: transaction.note,
        date: transaction.date,
      );
      
      await remoteDataSource.addMyDebt(debtModel, transactionModel);
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure('Server Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addMyDebtTransaction(MyDebtTransactionEntity transaction) async {
    try {
      final transactionModel = MyDebtTransactionModel(
        id: transaction.id,
        debtId: transaction.debtId,
        amount: transaction.amount,
        type: transaction.type,
        note: transaction.note,
        date: transaction.date,
      );
      await remoteDataSource.addMyDebtTransaction(transactionModel);
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure('Server Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyDebtTransactionEntity>>> getMyDebtTransactions(String debtId) async {
    try {
      final result = await remoteDataSource.getMyDebtTransactions(debtId);
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure('Server Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMyDebt(String debtId) async {
    try {
      await remoteDataSource.deleteMyDebt(debtId);
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure('Server Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyDebt(MyDebtEntity debt) async {
    try {
      final debtModel = MyDebtModel(
        id: debt.id,
        personId: debt.personId,
        personName: debt.personName,
        totalAmount: debt.totalAmount,
        paidAmount: debt.paidAmount,
        remainingDebt: debt.remainingDebt,
        phoneNumber: debt.phoneNumber,
        notes: debt.notes,
        createdAt: debt.createdAt,
        lastTransactionDate: debt.lastTransactionDate,
        notificationPreference: debt.notificationPreference,
      );
      await remoteDataSource.updateMyDebt(debtModel);
      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure('Server Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
