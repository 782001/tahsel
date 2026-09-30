import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../entities/custody_entity.dart';
import '../entities/custody_expense_item.dart';

abstract class CustodyRepository {
  Future<Either<Failure, CustodyEntity>> createCustody({
    required String ownerUid,
    required String recipientName,
    String? recipientEmployeeId,
    required String recipientType,
    required double initialAmount,
    String? notes,
  });

  Future<Either<Failure, List<CustodyEntity>>> getCustodies(String ownerUid);

  Future<Either<Failure, CustodyEntity?>> getActiveCustodyForCurrentUser({String? userUid});

  Future<Either<Failure, void>> addCustodyExpense({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItem expense,
  });

  Future<Either<Failure, void>> settleCustody({
    required String ownerUid,
    required String custodyId,
    required double actualReturnedAmount,
    required double varianceAmount,
    required String settledBy,
    String? settlementNotes,
    String? deficitReason,
  });

  Future<Either<Failure, void>> updateCustodyNotes({
    required String ownerUid,
    required String custodyId,
    required String notes,
  });

  Future<Either<Failure, void>> deleteCustody(String ownerUid, String custodyId);

  Future<Either<Failure, void>> deleteCustodyExpenseItem({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItem expenseItem,
  });
}
