import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/reports_entity.dart';
import '../repositories/reports_repository.dart';

class GetAllTimeReportsParams {
  final bool forceRefresh;
  GetAllTimeReportsParams({this.forceRefresh = false});
}

class GetAllTimeReportsUseCase implements BaseUseCase<ReportsEntity, GetAllTimeReportsParams> {
  final ReportsRepository repository;

  GetAllTimeReportsUseCase(this.repository);

  @override
  Future<Either<Failure, ReportsEntity>> call(GetAllTimeReportsParams params) {
    return repository.getAllTimeReports(forceRefresh: params.forceRefresh);
  }
}
