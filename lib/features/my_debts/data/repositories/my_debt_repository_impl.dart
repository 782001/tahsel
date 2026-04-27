import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_person_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/datasources/my_debt_item_remote_data_source.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_person_model.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';

class MyDebtRepositoryImpl implements MyDebtRepository {
  final MyDebtPersonRemoteDataSource personRemoteDataSource;
  final MyDebtItemRemoteDataSource itemRemoteDataSource;

  MyDebtRepositoryImpl({
    required this.personRemoteDataSource,
    required this.itemRemoteDataSource,
  });

  @override
  Future<Either<Failure, List<MyDebtPersonEntity>>> getMyDebtPersons(String uid) async {
    try {
      final persons = await personRemoteDataSource.getPersons(uid);
      return Right(persons);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveMyDebtPerson(String uid, MyDebtPersonEntity person) async {
    try {
      await personRemoteDataSource.savePerson(uid, MyDebtPersonModel.fromEntity(person));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyDebtPersonPhone(String uid, String name, String phoneNumber) async {
    try {
      await personRemoteDataSource.updatePersonPhone(uid, name, phoneNumber);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMyDebtPersonPreference(String uid, String name, String preference) async {
    try {
      await personRemoteDataSource.updatePersonPreference(uid, name, preference);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> addMyDebtItem(MyDebtItemEntity debt) async {
    try {
      final id = await itemRemoteDataSource.addDebtItem(MyDebtItemModel.fromEntity(debt));
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyDebtItemEntity>>> getMyDebtItems(String uid, String personName) async {
    try {
      final items = await itemRemoteDataSource.getDebtItems(uid, personName);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMyDebtItem(String uid, String debtId) async {
    try {
      await itemRemoteDataSource.deleteDebtItem(uid, debtId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMyDebtItemAsPaid(String uid, String debtId) async {
    try {
      final items = await itemRemoteDataSource.getDebtsStream(uid).first;
      final item = items.firstWhere((e) => e.id == debtId);
      await itemRemoteDataSource.payItem(
        uid: uid,
        debtId: debtId,
        amount: item.remainingAmount,
        note: 'Full settlement',
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> payMyDebtItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
  }) async {
    try {
      await itemRemoteDataSource.payItem(
        uid: uid,
        debtId: debtId,
        amount: amount,
        note: note,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> distributeMyDebtPayment({
    required String uid,
    required String personName,
    required double amount,
    String? note,
  }) async {
    try {
      await itemRemoteDataSource.distributePayment(uid, personName, amount, note: note);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyDebtOperationEntity>>> getMyDebtPersonOperations(String uid, String personName) async {
    try {
      final ops = await personRemoteDataSource.getPersonOperations(uid, personName);
      return Right(ops);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getMyDebtItemPayments(String uid, String debtId) async {
    try {
      final payments = await itemRemoteDataSource.getDebtItemPayments(uid, debtId);
      // Map MyDebtPaymentModel to PaymentEntity since Customer Debts UI expects PaymentEntity
      final entities = payments.map((p) => PaymentEntity(
        id: p.id,
        debtId: p.debtId,
        amountPaid: p.amountPaid,
        remainingAmount: 0.0,
        createdAt: p.createdAt,
        type: _mapType(p.type),
        activityName: p.note,
      )).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  PaymentType _mapType(String type) {
    switch (type) {
      case 'full':
        return PaymentType.full;
      case 'partial':
        return PaymentType.partial;
      case 'settlement':
        return PaymentType.settlement;
      case 'debtAdded':
        return PaymentType.debtAdded;
      default:
        return PaymentType.partial;
    }
  }
}
