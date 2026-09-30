import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../domain/entities/custody_entity.dart';
import '../../domain/entities/custody_expense_item.dart';
import '../../domain/repositories/custody_repository.dart';
import '../datasources/custody_remote_data_source.dart';
import '../models/custody_model.dart';

class CustodyRepositoryImpl implements CustodyRepository {
  final CustodyRemoteDataSource remoteDataSource;

  CustodyRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, CustodyEntity>> createCustody({
    required String ownerUid,
    required String recipientName,
    String? recipientEmployeeId,
    required String recipientType,
    required double initialAmount,
    String? notes,
  }) async {
    try {
      final model = await remoteDataSource.createCustody(
        ownerUid: ownerUid,
        recipientName: recipientName,
        recipientEmployeeId: recipientEmployeeId,
        recipientType: recipientType,
        initialAmount: initialAmount,
        notes: notes,
      );

      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustodyEntity>>> getCustodies(
    String ownerUid,
  ) async {
    try {
      final models = await remoteDataSource.getCustodies(ownerUid);
      return Right(List<CustodyEntity>.from(models));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustodyEntity?>> getActiveCustodyForCurrentUser({
    String? userUid,
  }) async {
    try {
      final ownerUid = AppStrings.userToken;
      if (ownerUid.isNotEmpty) {
        final remoteCustody = await remoteDataSource.getActiveCustodyForRecipient(
          ownerUid,
          employeeUid: userUid ?? AppStrings.employeeAuthUid,
        );
        return Right(remoteCustody);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCustodyExpense({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItem expense,
  }) async {
    try {
      final model = CustodyExpenseItemModel.fromEntity(expense);
      await remoteDataSource.addCustodyExpense(
        ownerUid: ownerUid,
        custodyId: custodyId,
        expense: model,
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> settleCustody({
    required String ownerUid,
    required String custodyId,
    required double actualReturnedAmount,
    required double varianceAmount,
    required String settledBy,
    String? settlementNotes,
    String? deficitReason,
  }) async {
    try {
      await remoteDataSource.settleCustody(
        ownerUid: ownerUid,
        custodyId: custodyId,
        actualReturnedAmount: actualReturnedAmount,
        varianceAmount: varianceAmount,
        settledBy: settledBy,
        settlementNotes: settlementNotes,
        deficitReason: deficitReason,
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustodyNotes({
    required String ownerUid,
    required String custodyId,
    required String notes,
  }) async {
    try {
      await remoteDataSource.updateCustodyNotes(
        ownerUid: ownerUid,
        custodyId: custodyId,
        notes: notes,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustody(
    String ownerUid,
    String custodyId,
  ) async {
    try {
      await remoteDataSource.deleteCustody(ownerUid, custodyId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustodyExpenseItem({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItem expenseItem,
  }) async {
    try {
      final model = CustodyExpenseItemModel.fromEntity(expenseItem);
      await remoteDataSource.deleteCustodyExpenseItem(
        ownerUid: ownerUid,
        custodyId: custodyId,
        expenseItem: model,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
