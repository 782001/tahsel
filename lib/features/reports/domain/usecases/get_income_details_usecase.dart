import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../operation/domain/entities/operation_entity.dart';
import '../repositories/reports_repository.dart';

class GetIncomeDetailsParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? type;
  final int limit;
  final DocumentSnapshot? lastDoc;

  GetIncomeDetailsParams({
    required this.startDate,
    required this.endDate,
    this.type,
    this.limit = 15,
    this.lastDoc,
  });
}

class GetIncomeDetailsUseCase
    implements
        BaseUseCase<
          (List<OperationEntity>, DocumentSnapshot?),
          GetIncomeDetailsParams
        > {
  final ReportsRepository repository;

  GetIncomeDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, (List<OperationEntity>, DocumentSnapshot?)>> call(
    GetIncomeDetailsParams params,
  ) {
    return repository.getIncomeDetails(
      params.startDate,
      params.endDate,
      type: params.type,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}
