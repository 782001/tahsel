import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class DeleteCustomerDebtUseCase implements BaseUseCase<void, DeleteDebtParams> {
  final DebtRepository repository;

  DeleteCustomerDebtUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(DeleteDebtParams params) {
    return repository.deleteCustomerDebts(params.uid, params.customerName);
  }
}

class DeleteDebtParams {
  final String uid;
  final String customerName;

  DeleteDebtParams({required this.uid, required this.customerName});
}
