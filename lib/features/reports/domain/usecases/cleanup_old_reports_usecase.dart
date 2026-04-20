import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/reports_repository.dart';

class CleanupOldReportsUseCase {
  final ReportsRepository repository;

  CleanupOldReportsUseCase(this.repository);

  Future<Either<Failure, int>> call() {
    return repository.cleanupOldReports();
  }
}
