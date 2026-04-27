import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';

abstract class MyDebtRepository {
  // Person (Supplier/etc)
  Future<Either<Failure, List<MyDebtPersonEntity>>> getMyDebtPersons(String uid);
  Future<Either<Failure, void>> saveMyDebtPerson(String uid, MyDebtPersonEntity person);
  Future<Either<Failure, void>> updateMyDebtPersonPhone(String uid, String name, String phoneNumber);
  Future<Either<Failure, void>> updateMyDebtPersonPreference(String uid, String name, String preference);
  
  // Debt Items
  Future<Either<Failure, String>> addMyDebtItem(MyDebtItemEntity debt);
  Future<Either<Failure, List<MyDebtItemEntity>>> getMyDebtItems(String uid, String personName);
  Future<Either<Failure, void>> deleteMyDebtItem(String uid, String debtId);
  Future<Either<Failure, void>> markMyDebtItemAsPaid(String uid, String debtId);
  
  // Payments
  Future<Either<Failure, void>> payMyDebtItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
  });
  Future<Either<Failure, List<PaymentEntity>>> getMyDebtItemPayments(String uid, String debtId);
  Future<Either<Failure, void>> distributeMyDebtPayment({
    required String uid,
    required String personName,
    required double amount,
    String? note,
  });
  
  // Reports
  Future<Either<Failure, List<MyDebtOperationEntity>>> getMyDebtPersonOperations(String uid, String personName);
}
