import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/reports_entity.dart';
import '../repositories/reports_repository.dart';

class GetAllTimeReportsUseCase implements BaseUseCase<ReportsEntity, NoParams> {
  final ReportsRepository repository;

  GetAllTimeReportsUseCase(this.repository);

  @override
  Future<Either<Failure, ReportsEntity>> call(NoParams params) {
    return repository.getAllTimeReports();
  }
}
