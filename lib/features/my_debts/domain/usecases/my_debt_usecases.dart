import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

class GetMyDebtsUseCase {
  final MyDebtRepository repository;
  GetMyDebtsUseCase(this.repository);

  Future<Either<Failure, List<MyDebtEntity>>> call() async {
    return await repository.getMyDebts();
  }
}

class AddMyDebtUseCase {
  final MyDebtRepository repository;
  AddMyDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(MyDebtEntity debt, MyDebtTransactionEntity transaction) async {
    return await repository.addMyDebt(debt, transaction);
  }
}

class AddMyDebtTransactionUseCase {
  final MyDebtRepository repository;
  AddMyDebtTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(MyDebtTransactionEntity transaction) async {
    return await repository.addMyDebtTransaction(transaction);
  }
}

class GetMyDebtTransactionsUseCase {
  final MyDebtRepository repository;
  GetMyDebtTransactionsUseCase(this.repository);

  Future<Either<Failure, List<MyDebtTransactionEntity>>> call(String debtId) async {
    return await repository.getMyDebtTransactions(debtId);
  }
}

class DeleteMyDebtUseCase {
  final MyDebtRepository repository;
  DeleteMyDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(String debtId) async {
    return await repository.deleteMyDebt(debtId);
  }
}

class UpdateMyDebtUseCase {
  final MyDebtRepository repository;
  UpdateMyDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(MyDebtEntity debt) async {
    return await repository.updateMyDebt(debt);
  }
}

class GetTotalPeopleCountUseCase {
  final MyDebtRepository repository;
  GetTotalPeopleCountUseCase(this.repository);

  Future<Either<Failure, int>> call() async {
    final result = await repository.getMyDebts();
    return result.fold(
      (failure) => Left(failure),
      (debts) {
        final Set<String> uniquePeople = {};
        for (var debt in debts) {
          // Count unique people based on personId or name fallback
          final key = debt.personId ?? debt.personName.trim().toLowerCase();
          uniquePeople.add(key);
        }
        return Right(uniquePeople.length);
      },
    );
  }
}
