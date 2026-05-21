import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/employee_paginated_lists.dart';
import '../repositories/employee_repository.dart';

class GetAdvancesParams {
  final String uid;
  final String employeeId;
  final int limit;
  final Object? lastDoc;

  GetAdvancesParams({
    required this.uid,
    required this.employeeId,
    this.limit = 15,
    this.lastDoc,
  });
}

class GetAdvancesUseCase {
  final EmployeeRepository repository;

  GetAdvancesUseCase({required this.repository});

  Future<Either<Failure, AdvancePaginatedList>> call(GetAdvancesParams params) {
    return repository.getAdvanceHistory(
      params.uid,
      params.employeeId,
      limit: params.limit,
      lastDoc: params.lastDoc,
    );
  }
}
