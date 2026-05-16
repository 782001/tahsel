import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';
import '../../../../core/error/failures.dart';

class GetCustomerDebtsUseCase implements BaseUseCase<List<DebtEntity>, GetCustomerDebtsParams> {
  final DebtRepository repository;

  GetCustomerDebtsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<DebtEntity>>> call(GetCustomerDebtsParams params) async {
    return await repository.getCustomerDebts(
      params.uid,
      params.customerName,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetCustomerDebtsParams {
  final String uid;
  final String customerName;
  final bool forceRefresh;

  GetCustomerDebtsParams({
    required this.uid,
    required this.customerName,
    this.forceRefresh = false,
  });
}
